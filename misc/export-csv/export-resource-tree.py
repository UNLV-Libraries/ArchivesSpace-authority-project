#!/usr/bin/python

import json
import urllib, urllib2
import base64
import os, sys, ConfigParser, logging, csv

class ASCSV:
    def __init__(self, writer, config):
        self.writer = writer
        self.config = config
        self.writer.writeheader()
        self.SESSION = ''
        self.stack = []

    def export(self, uri):
        # Get resource tree
        resource = self.api_call(uri+'/tree')
        # walk tree
        for child in resource['children']:
            self.walk(child)

    def walk(self, archival_obj_node):
        # get object json
        archival_obj = self.api_call(archival_obj_node['record_uri'])
        # push title onto stack
        self.stack.append(archival_obj['title'])
        # collect fields and write line
        data = {
            'uri':archival_obj['uri'],
            'type':archival_obj['level'],
            'date': self.parse_dates(archival_obj['dates']),
            'extent': self.parse_extents(archival_obj['extents'])
        }
        if archival_obj['instances']:
            instances = self.parse_instances(archival_obj['instances'])
            if instances:
                data.update()

        for i in range(0,6):
            c_level = 'c0'+str(i+1)
            data[c_level] = self.stack[i] if len(self.stack)-i > 0 else ''

        self.writer.writerow({k:v.encode('utf8') for k,v in data.items()})
        # walk children
        for child in archival_obj_node['children']:
            self.walk(child)
        # pop stack
        self.stack.pop()

    def parse_dates(self, dates):
        parsed_dates = []
        for date in dates:
            if 'expression' in date and date['expression']:
                parsed_dates.append(date['expression'])
        return '; '.join(parsed_dates)

    def parse_extents(self, extents):
        parsed_extents = []
        for extent in extents:
            extent_str = '%s %s' % (extent['number'],extent['extent_type'].replace('_', ' '))
            if 'container_summary' in extent:
                extent_str += ' (%s)' % (extent['container_summary'])
            parsed_extents.append(extent_str)
        return '; '.join(parsed_extents)

    def parse_instances(self, instances):
        parsed_instance = {}
        for instance in instances:
            # We are just going to use the first valid one
            # Don't want digital objects, just the others
            if instance['instance_type'] != 'digital_object':
                # Container 1 is the sub container/top container/ref
                top_container = self.api_call(instance['sub_container']['top_container']['ref'])
                parsed_instance['container_1_type'] = top_container['type']
                parsed_instance['container_1_value'] = top_container['indicator']
                # Container 2 is the sub container
                if 'type_2' in instance['sub_container']:
                    parsed_instance['container_2_type'] = instance['sub_container']['type_2']
                if 'indicator_2' in instance['sub_container']:
                    parsed_instance['container_2_value'] = instance['sub_container']['indicator_2']
                return parsed_instance

    def api_call(self, path, method = 'GET', data = {}, as_obj = True):

        #empty SESSION, we should log in, but not if we are trying to login now.
        if not self.SESSION and not path.endswith('login'):
            self.archivesspace_login()
        path = self.config.get('archivesspace','api-prefix') + path

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

        if self.SESSION:
            request.add_header("X-ArchivesSpace-Session",self.SESSION)

        logging.debug("ArchivesSpace API call (%s;%s): %s %s %s %s" % (
                        path, json.dumps(data),
                        json.dumps(request.header_items()),
                        request.get_method(),
                        request.get_full_url(), request.get_data() )
        )
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
            logging.debug(json.dumps(archival_objs))
            if archival_objs['last_page'] != last_page:
                logging.debug('Updating last page from %s to %s' % (last_page, archival_objs['last_page']))
                last_page = archival_objs['last_page']

            objects += archival_objs['results']

            #Next, please....
            data['page'] += 1

        return objects

    def archivesspace_login(self):
        path = '/users/%s/login' % self.config.get('archivesspace','username')
        obj = self.api_call(path,
                            'POST', urllib.urlencode({
                                'password':self.config
                                .get('archivesspace','password')
                                })
                            )
        self.SESSION = obj["session"]

if __name__ == '__main__':

    # logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
    #                     filename='location-migration.log',level=logging.DEBUG)
    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                        level=logging.INFO)

    config = ConfigParser.ConfigParser()
    configFilePath = r'config.ini'
    config.read(configFilePath)

    out = csv.DictWriter(sys.stdout, dialect=csv.excel,
                            fieldnames=('uri',
                                        'c01','c02','c03','c04','c05','c06',
                                        'type','date','extent',
                                        'container_1_type','container_1_value',
                                        'container_2_type','container_2_value'),
                            extrasaction='ignore')
    ascsv = ASCSV(out,config)
    try:
        ascsv.export(sys.argv[1])
    except:
        print("Could not export resource tree for '{0}'. Did you provide a relative URI (e.g. /repositories/2/resources/1)?".format(sys.argv[1]))
