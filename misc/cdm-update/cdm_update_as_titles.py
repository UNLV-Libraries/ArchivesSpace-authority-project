#!/usr/bin/python

import base64
import ConfigParser
import json
import logging
import argparse, sys
import urllib, urllib2

"""
Update Titles in ArchivesSpace from CONTENTdm digital objects

After an ArchivesSpace archival object and digital object pair link to a
CONTENTdm digital object, update titles (in AS) that don't match.

@author Seth Shaw
@date 2018-05-11

"""

class CDMQueryClient(object):
    """A CONTENTdm Query session."""
    def __init__(self, url):
        self.url = url + '/dmwebservices/index.php?q='

    # dmQuery/oclcsample/0/title!ark/pointer/5/0/1/0/0/1/json
    def query(self, alias, search='0', fields='0', sortby='0', maxrec=1024, start=1, suppress='1', docptr='0', suggest='0', facets='0', unpub='1', denormalize='1' ):
        """ Generator of search results. """
        alias = alias.lstrip('/')

        more = True
        while more == True:
            query= 'dmQuery/'+'/'.join((alias,search,fields,sortby,str(maxrec),str(start),suppress,docptr,suggest,facets,unpub,denormalize)) + '/json'
            logging.debug('Running %s' % (self.url + query))
            request = urllib2.Request(self.url + query)

            try:
                response = json.load(urllib2.urlopen(request))
            except urllib2.HTTPError as h:
                logging.error("Unable to process CONTENTdm wsAPI call (%s): %s - %s - %s" % (query, h.code, h.reason, h.read()))
                raise StopIteration
            except ValueError as v:
                logging.error("Invalid Response to CONTENTdm wsAPI call (%s): %s" % (query, v))
                raise StopIteration

            for record in response['records']:
                yield record

            # Paging
            if (maxrec+start) < response['pager']['total']:
                start += maxrec
            else:
                more = False

class ASClient(object):
    """An ArchivesSpace Client"""

    SESSION = ''

    def __init__(self, api_root, username, password):
        self.api_root = api_root
        self.login(username, password)

    def api_call(self, path, method = 'GET', data = {}, as_obj = True):

        path = self.api_root + path

        # urllib2 will force a call to POST if the data element is provided.
        # So, a query string must be appended to path if you want a GET
        if method == 'GET':
            if data:
                request = urllib2.Request(path + '?' + urllib.urlencode(data))
            else:
                request = urllib2.Request(path)
        elif method == 'POST':
            if isinstance(data, dict):
                data = json.dumps(data)
            request = urllib2.Request(path, data)
        else:
            logging.error("Unknown or unused HTTP method: %s" % method)
            return

        if self.SESSION: #only absent during login.
            request.add_header("X-ArchivesSpace-Session",self.SESSION)

        logging.debug("ArchivesSpace API call (%s;%s): %s %s %s %s" % (path, json.dumps(data), json.dumps(request.header_items()), request.get_method(), request.get_full_url(), request.get_data()) )
        try:
            response = urllib2.urlopen(request)
        except urllib2.HTTPError as h:
            logging.error("Unable to process ArchivesSpace API call (%s): %s - %s - %s" % (path, h.code, h.reason, h.read()))
            return {}
        if as_obj:
            return json.load(response); #object
        else:
            return response #readable stream

    def api_call_paginated(self, path, method = 'GET', data = {}):
        objects = [] #The stuff we are giving back
        data['page'] = 1
        last_page = 1 #assume one page until told otherwise
        data['page_size'] = 200

        while data['page'] <= last_page:

            #The call
            archival_objs = self.api_call(path, method, data)

            #Debuggging and Pagination
            logging.debug("Page %s of %s" % (data['page'], last_page))
            # logging.debug(json.dumps(archival_objs))
            if archival_objs['last_page'] != last_page:
                logging.debug('Updating last page from %s to %s' % (last_page, archival_objs['last_page']))
                last_page = archival_objs['last_page']

            objects += archival_objs['results']

            #Next, please....
            data['page'] += 1

        return objects

    def login(self, username, password):
        path = '/users/%s/login' % (username)
        obj = self.api_call(path,'POST', urllib.urlencode({'password': password }))
        self.SESSION = obj["session"]

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("alias", help="a CONTENTdm collection alias", nargs='+')
    parser.add_argument("-c","--collection-id", help='an ArchivesSpace resource identifier. E. g., "MS-00425".')
    parser.add_argument("-f","--collection-id-field", help='the CONTENTdm field storing the source collection\'s identifier (overrides config.ini)')
    parser.add_argument("-k","--ark-field", help='the CONTENTdm field to use for the object ARKs (overrides config.ini)')
    parser.add_argument("-o","--digital-object-field", help='the CONTENTdm field to use for the digital object\'s identifier (overrides config.ini)')
    parser.add_argument("-r","--date-range-field", help='the CONTENTdm field storing digital object date ranges')
    parser.add_argument("-s","--date-single-field", help='the CONTENTdm field storing digital object single dates')
    parser.add_argument("-v","--verbosity", help="change output verbosity: DEBUG, INFO (default), ERROR")
    parser.add_argument("-d","--dry", help="doesn't update ArchivesSpace, used for testing", action="store_true")
    args = parser.parse_args()

    dry = False
    if args.dry:
        dry = True

    # Configuration
    verbosity = logging.INFO
    if args.verbosity:
        if args.verbosity == 'DEBUG':
            verbosity = logging.DEBUG
        if args.verbosity == 'INFO': # Redundant, I know, but it keeps the list clean
            verbosity = logging.INFO
        if args.verbosity == 'ERROR':
            verbosity = logging.ERROR
    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                        level=verbosity)

    global config
    config = ConfigParser.ConfigParser()
    configFilePath = r'config.ini'
    config.read(configFilePath)

    # Fields for CDM to return.
    # Will add the ark field, if used, and the collection id field later
    cdm_fields = ['title']

    # Which field holds the ARK?
    ark_field = None
    if config.get('cdm','ark-field'):
        ark_field = config.get('cdm','ark-field')
    if args.ark_field:
        ark_field = args.ark_field
    if ark_field:
        cdm_fields.append(ark_field)

    # Which field holds the Collection Identifier?
    cid_field = config.get('cdm','collid-field')
    if args.collection_id_field:
        cid_field = args.collection_id_field
    cdm_fields.append(cid_field)

    # Which field holds the Digital Object Identifier?
    do_field = config.get('cdm','doid-field')
    if args.digital_object_field:
        do_field = args.digital_object_field
    cdm_fields.append(do_field)

    # Which field holds the Digital Object Date Range?
    dr_field = config.get('cdm','date-range-field')
    if args.date_range_field:
        dr_field = args.date_range_field
    cdm_fields.append(dr_field)

    # Which field holds the Digital Object Signle Date?
    ds_field = config.get('cdm','date-single-field')
    if args.date_single_field:
        ds_field = args.date_single_field
    cdm_fields.append(ds_field)

    # Limit by AS collection id?
    query = '0'
    if args.collection_id:
        query = "%s^%s^exact" % (cid_field,args.collection_id)

    # Initialize the query client
    dmQuery = CDMQueryClient(config.get('cdm','wsAPI-url'))

    # Initialize AS client
    aspace_client = ASClient(config.get('archivesspace','api-prefix'),
                             config.get('archivesspace','username'),
                             config.get('archivesspace','password'))
    repository = config.get('archivesspace','repository')

    for alias in args.alias:

        alias = alias.lstrip('/') # The preceding / on an alias is annoying to work with. Chop it off if present.
        current_as_rid = None
        current_cid = None
        for result in dmQuery.query(alias,query,'!'.join(cdm_fields), sortby=cid_field):

            # REPORT and SKIP if the do has no ARK
            if ark_field and not result[ark_field]:
                logging.warn('SKIPPING: no ARK for %s/id/%d (%s:%s)' % (result['collection'],result['pointer'],current_cid,current_as_rid))
                continue

            #  REPORT and SKIP if the do has no title
            if not 'title' in result:
                logging.warn('SKIPPING: no Title for %s/id/%d' % (result['collection'],result['pointer']))
                continue

            #  REPORT and SKIP if the do has no collection identifier
            if not cid_field in result:
                logging.warn('SKIPPING: no Collection ID (%s) for %s/id/%d' % (cid_field,result['collection'],result['pointer']))
                continue
            else: #trim it
                result[cid_field] = result[cid_field].replace('\n', '').replace('\r', '')

            # REPORT and SKIP if no digital object identifier
            if not do_field in result:
                logging.warn('SKIPPING: no Digital Object ID (%s) for %s/id/%d' % (do_field,result['collection'],result['pointer']))
                continue
            else: #trim it
                result[do_field] = result[do_field].replace('\n', '').replace('\r', '')

            # Query ArchivesSpace for digital objects (ao) field digital_object_id matching CDM digital object field
            ao_query = '{"query":{"op":"AND","subqueries":[{"field":"digital_object_id","value":"%s","jsonmodel_type":"field_query","negated":false,"literal":true},{"field":"primary_type","value":"digital_object","jsonmodel_type":"boolean_field_query"}],"jsonmodel_type":"boolean_query"},"jsonmodel_type":"advanced_query"}' % (urllib.quote_plus(result[do_field].replace('"','\\"')))
            as_digital_objects = aspace_client.api_call('/repositories/%s/search?page=1&aq=%s' % (repository,ao_query))

            if not as_digital_objects['results']:
                logging.warn('SKIPPING: Could not find digital_object_id "%s" for %s/id/%s' % (result[do_field],alias,result['pointer']))
                continue
            # Check to see if we have different URIs, or multiple of the same
            ad_objs = list()
            for ao in as_digital_objects['results']:
                ao_obj = json.loads(ao['json'])
                # Have we seen this object in the results before?
                found_existing_uri = False
                for existing_ao in ad_objs:
                    if existing_ao['uri'] == ao_obj['uri']:
                        found_existing_uri = True
                        continue
                if not found_existing_uri:
                    ad_objs.append(ao_obj)

            # Still more than one result?
            if len(ad_objs) > 1:
                ad_objs_uris = []
                for ad_obj in ad_objs:
                    ad_objs_uris.extend(ad_obj['uri'])
                logging.warn('SKIPPING: Found multiple matches for digital_object_id "%s" (%s/id/%s): %s' % (result[do_field],alias,result['pointer'],', '.join(ad_objs_uris)))
                continue

            # Use the only match
            ad_obj = ad_objs[0]

            # Are the titles already the same?
            if ad_obj['title'] != result['title']:
                #update do
                logging.info('UPDATE: Titles did not match: CDM %s/id/%s "%s" AS %s "%s"' % (alias,result['pointer'],result['title'],ad_obj['uri'],ad_obj['title']))
                ad_obj['title'] = result['title']
                if dry:
                    logging.info('DRY: Would have updated AS %s with title "%s"' % (ad_obj['uri'],ad_obj['title']))
                else:
                    ad_update_response = aspace_client.api_call(ad_obj['uri'],'POST', ad_obj)
            else:
                logging.info('MATCH: CDM and AS DO titles for %s/id/%s and %s already match' % (alias,result['pointer'],ad_obj['uri']))

            for ao_uri in ad_obj['linked_instances']:
                ao_obj = aspace_client.api_call(ao_uri['ref'])
                if ao_obj['title'] != result['title']:
                    logging.info('UPDATE: Titles did not match: CDM %s/id/%s "%s" AS %s "%s"' % (alias,result['pointer'],result['title'],ao_obj['uri'],ao_obj['title']))
                    #update ao
                    ao_obj['title'] = result['title']
                    if dry:
                        logging.info('DRY: Would have updated AS %s with title "%s"' % (ad_obj['uri'],ad_obj['title']))
                    else:
                        ao_update_response = aspace_client.api_call(ao_obj['uri'],'POST', ao_obj)
                else:
                    logging.info('MATCH: CDM and AS AO titles for %s/id/%s and %s already match' % (alias,result['pointer'],ao_obj['uri']))
