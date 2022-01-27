#!/usr/bin/python

import json
import urllib, urllib2
import base64
import os, sys, ConfigParser, logging
import csv

TEST = True
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

    next_page = 1
    last_page = 1 #assume one page until told otherwise
    page_size = 300 #arbitrary large number
    while next_page <= last_page:
        logging.info("Loading Top Container Page %s of %s" % (next_page, last_page))
        container_obj = archivesspace_api_call('/repositories/%s/top_containers' % config.get('archivesspace',
                                                      'repository'), data={'page':next_page, 'page_size':page_size})
        # print("Page %s of %s" % (next_page, last_page))
        # print(json.dumps(location_obj))
        if container_obj['last_page'] != last_page:
            # print('Updating last page from %s to %s' % (last_page, location_obj['last_page']))
            last_page = container_obj['last_page']
        for container in container_obj['results']:
            if not container['collection']:
                logging.warning(u'Could not load %s (%s): No collection was found' %(container['long_display_string'],container['uri']))
                continue
            try:
                print '-'.join((
                    container['collection'][0]['identifier'].replace('--','-'),
                    container['type'],
                    container['indicator'].lstrip('0')
                    ))
                # print u'\t'.join(('-'.join((
                #     container['collection'][0]['identifier'],
                #     container['type'],
                #     container['indicator'].lstrip('0')
                #     )),container['uri'], container['display_string'],
                # coll_ident, coll_name, coll_uri,
                # ))
            except UnicodeEncodeError as err:
                logging.error(u"Could not load %s %s: %s" % (collection, container['long_display_string'], err))
            except:
                logging.warning(u'Could not load %s (%s): %s' %(container['long_display_string'],container['uri'],sys.exc_info()[0]))
        next_page += 1
