#!/usr/bin/python

import json
import urllib, urllib2
import base64
import os, sys, ConfigParser, logging, csv

SESSION = ''

def archivesspace_api_call(path, method = 'GET', data = {}, as_obj = True):

    #empty SESSION, we should log in, but not if we are trying to login now.
    if not SESSION and not path.endswith('login'):
        archivesspace_login()
    path = config.get('archivesspace','api-prefix') + path

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

    if SESSION:
        request.add_header("X-ArchivesSpace-Session",SESSION)

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

def archivesspace_api_call_paginated(path, method = 'GET', data = {}):
    objects = [] #The stuff we are giving back
    data['page'] = 1
    last_page = 1 #assume one page until told otherwise
    data['page_size'] = 200

    while data['page'] <= last_page:

        #The call
        archival_objs = archivesspace_api_call(path, method, data)

        #Debuggging and Pagination
        logging.debug("Page %s of %s" % (data['page'], last_page))
        logging.debug(json.dumps(archival_objs))
        if archival_objs['last_page'] != last_page:
            logging.debug('Updating last page from %s to %s' % (last_page, archival_objs['last_page']))
            last_page = archival_objs['last_page']

        objects += archival_objs['results']

        #Next, please....
        data['page'] += 1

    return objects

def archivesspace_login():
    global SESSION
    path = '/users/%s/login' % config.get('archivesspace','username')
    obj = archivesspace_api_call(path,
                                'POST',
                                urllib.urlencode(
                                    {'password':config.get('archivesspace',
                                        'password') }))
    SESSION = obj["session"]

if __name__ == '__main__':

    # logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
    #                     filename='location-migration.log',level=logging.DEBUG)
    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                        level=logging.INFO)

    global config
    config = ConfigParser.ConfigParser()
    configFilePath = r'config.ini'
    config.read(configFilePath)
    existing_matches = {}
    out = csv.DictWriter(sys.stdout, dialect=csv.excel, fieldnames=('name','uri','relator','description','target_name','target_uri'), extrasaction='ignore')
    out.writeheader()

    for path in ('/agents/families','/agents/people','/agents/corporate_entities'):
        for thing in archivesspace_api_call_paginated(path):
            # print "Found something: %s" % (json.dumps(thing, indent=4))
            # thing_essentials={'uri':thing['uri'],'title':thing['title'],'is_linked_to_published_record':thing['is_linked_to_published_record']} # We need the title field for honorary titles
            name = thing['title']
            uri = thing['uri']
            # I see a (uri) -> b (ref), no matches, so we save it as (a)ref: [(b)uri]
            # Next I see b (new uri)->a (new ref) so I should see if a(new ref) is a key and, if so, if b(new uri) is contained 
            for relation in thing['related_agents']:
                # print('FOUND '+uri+'->'+relation['ref'])
                if relation['ref'] in existing_matches.keys() and uri in existing_matches[relation['ref']]:
                        # print('SKIPPING '+uri+'->'+relation['ref']+': '+json.dumps(existing_matches[relation['ref']]))
                        continue
                elif uri in existing_matches.keys():
                    existing_matches[uri].append(relation['ref'])
                    # print('Creating new match '+relation['ref']+'->'+uri)
                else:
                    existing_matches.update({uri: [relation['ref']]})
                    # print('Creating new match '+relation['ref']+'->'+uri)
                
                target_ao = archivesspace_api_call(relation['ref'])
                target_name = target_ao['title'].encode('utf8') or 'N/A'
                
                relation.setdefault('description', '')
                out.writerow({
                    'name': name.encode('utf8'),
                    'uri': uri,
                    'relator': relation['relator'],
                    'description': relation['description'].replace("\n"," ").replace("\r"," ").rstrip().encode('utf8'),
                    'target_name': target_name,
                    'target_uri': relation['ref']
                })
    # print json.dumps(existing_matches)