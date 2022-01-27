#!/usr/bin/python

import base64
import configparser
import json
import logging
import argparse, sys
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError

"""
Migrate CONTENTdm digital objects to ArchivesSpace: PHOTOGRAPHS SPECIAL EDITION

Using a CONTENTdm field with a photograph identifier we can search for the
identifier in ArchivesSpace and create a new Digital Object instance linking
the ArchivesSpace object to the CONTENTdm object.

@author Seth Shaw
@date 2018-03
@updated 2018-12

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
            request = Request(self.url + query)

            try:
                response = json.load(urlopen(request))
            except HTTPError as h:
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

        # urllib will force a call to POST if the data element is provided.
        # So, a query string must be appended to path if you want a GET
        if method == 'GET':
            if data:
                request = Request(path + '?' + urlencode(data))
            else:
                request = Request(path)
        elif method == 'POST':
            # if isinstance(data, dict):
            #     data = json.dumps(data)
            request = Request(path, urlencode(data).encode('ascii'))
        else:
            logging.error("Unknown or unused HTTP method: %s" % method)
            return

        if self.SESSION: #only absent during login.
            request.add_header("X-ArchivesSpace-Session",self.SESSION)

        logging.debug("ArchivesSpace API call (%s;%s): %s %s %s %s" % (path, json.dumps(data), json.dumps(request.header_items()), request.get_method(), request.get_full_url(), request.data) )
        try:
            response = urlopen(request)
        except HTTPError as h:
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
        obj = self.api_call(path,'POST', {'password': password })
        self.SESSION = obj["session"]

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("alias", help="a CONTENTdm collection alias", nargs='+')
    parser.add_argument("-c","--collection-id", help='an ArchivesSpace resource identifier. E. g., "MS-00425".')
    parser.add_argument("-i","--image-id-field", help='the CONTENTdm field storing the source image\'s identifier')
    parser.add_argument("-k","--ark-field", help='the CONTENTdm field to use for the object ARKs (overrides config.ini)')
    parser.add_argument("-o","--digital-object-field", help='the CONTENTdm field to use for the digital object\'s identifier (overrides config.ini)')
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
    config = configparser.RawConfigParser()
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

    # Which field holds the Image Identifier?
    iid_field = 'physic'
    if args.image_id_field:
        iid_field = args.image_id_field
    cdm_fields.append(iid_field)

    # Which field holds the Digital Object Identifier?
    do_field = config.get('cdm','doid-field')
    if args.digital_object_field:
        do_field = args.digital_object_field
    cdm_fields.append(do_field)

    public_url = config.get('cdm','public-url')

    # # Limit by AS collection id?
    query = '0'
    if args.collection_id:
        query = '%s^%s^all^and' % ('source',args.collection_id)
        cdm_fields.append('source')

    # Initialize the query client
    dmQuery = CDMQueryClient(config.get('cdm','wsAPI-url'))

    # Initialize AS client
    aspace_client = ASClient(config.get('archivesspace','api-prefix'),
                             config.get('archivesspace','username'),
                             config.get('archivesspace','password'))
    repository = config.get('archivesspace','repository')

    for alias in args.alias:

        alias = alias.lstrip('/') # The preceding / on an alias is annoying to work with. Chop it off if present.
        for result in dmQuery.query(alias,query,'!'.join(cdm_fields), sortby=iid_field):

            # REPORT and SKIP if the do has no ARK
            if ark_field and not result[ark_field]:
                logging.info('SKIPPING: no ARK for %s/id/%d' % (result['collection'],result['pointer']))
                continue

            #  REPORT and SKIP if the do has no title
            if not 'title' in result:
                print('SKIPPING: No Title Found for %s/id/%d' % (result['collection'],result['pointer']))
                continue

            # Clean up the Image ID field to match AS
            iid = result[iid_field].rstrip().replace('Image ID: ','').replace('  ',' ').replace(' ', '_')
            if not iid:
                print('SKIPPING: No Photo ID Found for %s/id/%d' % (result['collection'],result['pointer']))
                continue

            # Find or Create an ArchivesSpace Digital Object
            # Query ArchivesSpace for archival objects (ao) with component idenfifier
            ado_uri = 'FAKE/URI' # Incase the DRY option is enabled
            do_query = '{"query":{"op":"AND","subqueries":[{"field":"digital_object_id","value":"%s","jsonmodel_type":"field_query","negated":false,"literal":true},{"field":"primary_type","value":"digital_object","jsonmodel_type":"boolean_field_query"}],"jsonmodel_type":"boolean_query"},"jsonmodel_type":"advanced_query"}' % (result[do_field])
            digital_objects = aspace_client.api_call('/repositories/%s/search?page=1&aq=%s' % (repository,do_query))

            if not 'results' in digital_objects or not digital_objects['results']:
                ado = {'title':result['title'],'digital_object_id':result[do_field],'publish':True,'file_versions':[{'file_uri':result[ark_field],'publish':True,'is_representative':True}]}

                if dry:
                    logging.info('DRY: Would create AS digital object: %s' % (result[do_field]))
                    logging.debug('DRY: New AS digital object JSON: %s' % (json.dumps(ado)))
                else:
                    ado_response = aspace_client.api_call('/repositories/%s/digital_objects' % (repository),'POST', ado)
                    if not 'uri' in ado_response:
                        logging.warn('FAILED to create AS digital object %s %s: %s' % ('/repositories/%s/digital_objects' % (repository), ado, json.dumps(ado_response)))
                        continue
                    ado_uri = ado_response['uri']
            else:
                ado = json.loads(digital_objects['results'][0]['json'])
                ado_uri = ado['uri']

            # Query ArchivesSpace for archival objects (ao) with component idenfifier
            ao_query = '{"query":{"op":"AND","subqueries":[{"field":"component_id","value":"%s","jsonmodel_type":"field_query","negated":false,"literal":true},{"field":"primary_type","value":"archival_object","jsonmodel_type":"boolean_field_query"}],"jsonmodel_type":"boolean_query"},"jsonmodel_type":"advanced_query"}' % (iid)
            archival_objects = aspace_client.api_call('/repositories/%s/search?page=1&aq=%s' % (repository,ao_query))

            if not 'results' in archival_objects or not archival_objects['results']:
                logging.info('SKIPPING: Could not find Component ID "%s" in ArchivesSpace for %s/id/%s' % (iid,alias,result['pointer']))
                continue

            # Check to see if we have different URIs, or multiple of the same
            ao_uris = list()
            for ao in archival_objects['results']:
                ao_uris.append(ao['uri'])
            ao_uris = set(ao_uris)
            if len(ao_uris) > 1:
                logging.info('SKIPPING: multiple Archival Objects with Component ID "%s" for %s/id/%s: %s'% (iid,alias,result['pointer'],','.join(ao_uris)))
                continue

            # Build a clean copy from search results json field
            archival_object = json.loads(archival_objects['results'][0]['json'])

            # If the AS AO already has a DO, we assume it is the same match we just identified.
            has_do = False
            for instance in archival_object['instances']:
                if not instance['instance_type'] == 'digital_object':
                    continue
                if  instance['digital_object']['ref'] == as_do_uri:
                    has_do = True
                    continue
            if has_do:
                logging.info('SKIPPING: Archival Object %s already linked to %s'% (archival_object['uri'],ado_uri))
                continue

            # Update ao in AS with instance link using the ARK
            # based on https://github.com/djpillen/bentley_scripts/blob/master/update_archival_object.py
            # Update the Archival Object
            as_do_instance = {'instance_type':'digital_object','digital_object':{'ref':ado_uri}}
            archival_object['instances'].append(as_do_instance)
            if dry:
                logging.info('DRY: Would update AS Archival Object %s with new instance for %s/id/%d' % (archival_object['uri'],result['collection'],result['pointer']))
            else:
                ao_update_response = aspace_client.api_call(archival_object['uri'],'POST', archival_object)
                logging.info('%s: AS Archival Object %s with AS Digital Object %s for CDM object %s : %s' % (ao_update_response['status'],ao_update_response['id'],as_do_uri,result[do_field],title))
