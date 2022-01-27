#!/usr/bin/python

import base64
import ConfigParser
import json
import logging
import argparse, sys, csv
import urllib, urllib2

"""
Create Links to a proved URL in ArchivesSpace (CSV source)

Given an ArchivesSpace archival object URI, create a digital object and
associated digital object instance.

@author Seth Shaw
@date 2018-08-23

"""

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
    parser.add_argument("tsv", help="a TSV including URIs")
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

    do_field = 'did'
    ark_field = 'ark'
    ao_uri_field = 'uri'

    # Initialize AS client
    aspace_client = ASClient(config.get('archivesspace','api-prefix'),
                             config.get('archivesspace','username'),
                             config.get('archivesspace','password'))
    repository = config.get('archivesspace','repository')

    with open(args.tsv, 'rU') as csvfile: #'rU' because Mac Excel exports are wierd
        reader = csv.DictReader(csvfile, delimiter='\t')
        for row in reader:

            # REPORT abd SKIP if the do has no identifier
            if not do_field in row:
                logging.warn('SKIPPING: no identifier ID (field: %s) for row: %s' % (do_field,json.dumps(row)))
                continue

            # REPORT and SKIP if the do has no ARK
            if ark_field and not row[ark_field]:
                logging.warn('SKIPPING: no ARK (field: %s) for row: %s' % (ark_field,json.dumps(row)))
                continue

            # REPORT and SKIP if the do has no Archival Object URI
            if ao_uri_field and not row[ao_uri_field]:
                logging.warn('SKIPPING: no Archival Object URI (field: %s) for row: %s' % (ao_uri_field,json.dumps(row)))
                continue

            #  REPORT and SKIP if the do has no title
            if not 'title' in row:
                logging.warn('SKIPPING: no Title for row: %s' % (json.dumps(row)))
                continue

            title = row['title'].replace('&#x27;', "'").replace('&quot;','"')

            # CREATE the AS Digital Object
            as_do = {'title':title,
                     'digital_object_id':row[do_field],
                     'publish':True,
                     'file_versions':[{'file_uri':row[ark_field],
                                       'publish':True,
                                       'is_representative':True}],
                     }

            as_do_query = '{"query":{"op":"AND","subqueries":[{"field":"digital_object_id","value":"%s","jsonmodel_type":"field_query","negated":false,"literal":true},{"field":"primary_type","value":"digital_object","jsonmodel_type":"boolean_field_query"}],"jsonmodel_type":"boolean_query"},"jsonmodel_type":"advanced_query"}' % (urllib.quote_plus(row[do_field].replace('\n', '').replace('\r', '')))
            as_do_response = aspace_client.api_call('/repositories/%s/search?page=1&aq=%s' % (repository,as_do_query))

            as_do_uri = ''
            if as_do_response['total_hits'] == 0:
                # Make a new AS DO
                as_do_uri = 'FAKE/URI' # Incase the DRY option is enabled
                if dry:
                    logging.info('DRY: Would create AS digital object: %s' % (json.dumps(as_do)))
                else:
                    as_do_response = aspace_client.api_call('/repositories/%s/digital_objects' % (repository),'POST', as_do)
                    if not 'uri' in as_do_response:
                        logging.warn('FAILED to create AS digital object %s %s: %s' % ('/repositories/%s/digital_objects' % (repository), as_do, json.dumps(as_do_response)))
                        continue
                    as_do_uri = as_do_response['uri']
            else:
                as_do_uri = as_do_response['results'][0]['uri']
                logging.debug('FOUND: AS DO for %s: %s' % (row[do_field],as_do_uri))

            as_ao = aspace_client.api_call(row['uri'])

            # If the AS AO already has a DO with a matching URI, skip it.
            has_do = False
            for instance in as_ao['instances']:
                if  instance['digital_object']['ref'] == as_do_uri:
                    has_do = True
                    continue
            if has_do:
                logging.info('SKIPPING: Archival Object %s already linked to %s'% (as_ao['uri'],as_do_uri))
                continue

            # Update ao in AS with instance link using the ARK
            # based on https://github.com/djpillen/bentley_scripts/blob/master/update_archival_object.py
            # Update the Archival Object
            as_do_instance = {'instance_type':'digital_object','digital_object':{'ref':as_do_uri}}
            as_ao['instances'].append(as_do_instance)
            if dry:
                logging.info('DRY: Would update AS Archival Object %s with new instance %s' % (as_ao['uri'], as_do_instance))
            else:
                ao_update_response = aspace_client.api_call(as_ao['uri'],'POST', as_ao)
                if 'status' in ao_update_response:
                    logging.info('%s: AS Archival Object %s with AS Digital Object %s for CDM object %s : %s' % (ao_update_response['status'],ao_update_response['id'],as_do_uri,row[do_field],title))
                else:
                    logging.info('Unable to update AS Archival Object %s with AS Digital Object %s for CDM object %s : %s' % (as_ao['uri'],as_do_uri,row[do_field],title))
