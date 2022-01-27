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

    out = csv.DictWriter(sys.stdout, dialect=csv.excel, fieldnames=('uri','jsonmodel_type','is_linked_to_published_record','primary_name','prefix','rest_of_name','suffix','family_name','qualifier','fuller_form','number','title','dates','exist_begin','exist_end','use_begin','use_end','use_expression','rules','authority_id','roles','source'), extrasaction='ignore')
    out.writeheader()

    for path in ('/agents/families','/agents/people','/agents/corporate_entities'):
        for thing in archivesspace_api_call_paginated(path):
            # print "Found something: %s" % (json.dumps(thing, indent=4))
            thing_essentials={'uri':thing['uri'],'title':thing['title'],'is_linked_to_published_record':thing['is_linked_to_published_record']} # We need the title field for honorary titles
            #thing_essentials={'uri':thing['uri']}
            #Dates of existence:
            if 'dates_of_existence' in thing and len(thing['dates_of_existence']) > 0:
                thing_essentials['exist_begin'] = thing['dates_of_existence'][0].get('begin','')
                thing_essentials['exist_end'] = thing['dates_of_existence'][0].get('end','')
             

            for name in thing['names']:

              # add the uri for printing the csv
               name.update(thing_essentials)

               # Simplify the use dates:
               use_dates = name.get('use_dates')

               if use_dates:
                   name['use_expression'] = use_dates[0].get('expression','')
                   name['use_begin'] = use_dates[0].get('begin','')
                   name['use_end'] = use_dates[0].get('end','')

               # Ensure the writerow is using unicode (where appropriate)
               if name.get('is_display_name') == True:
                   out.writerow({k:(v.encode('utf8') if isinstance(v, unicode) else v) for k,v in name.items()})
