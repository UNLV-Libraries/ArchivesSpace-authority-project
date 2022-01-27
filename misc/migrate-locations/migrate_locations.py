#!/usr/bin/python

import json
import urllib, urllib2
import base64
import os, sys, ConfigParser, logging, csv
import datetime

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


def parse_containers(to_parse, container_type='box', mss=''):
    containers = []

    #Clean-up input
    to_parse = to_parse.partition(' of ')[0] #trim box count if provided
    to_parse = to_parse.lower()
    to_parse = to_parse.replace('boxes','') #Clean up and remove default "Boxes"
    to_parse = to_parse.replace('box','') #Clean up and remove default "Boxes"
    to_parse = to_parse.strip() #Clean up and remove default "Boxes"

    for group in to_parse.split(','):
        if '-' in group:
            (start, part, end) = group.partition('-')
            if start.strip().isdigit() and end.strip().isdigit():
                for number in range(int(start),int(end)+1):
                    containers.append('-'.join((mss,container_type,str(number))))
            else:
                containers.append(mss+'-'+group.strip())
        elif 'to' in group:
            (start, part, end) = group.partition('to')
            if start.strip().isdigit() and end.strip().isdigit():
                for number in range(int(start),int(end)+1):
                    containers.append('-'.join((mss,container_type,str(number))))
            else:
                containers.append(mss+'-'+group.strip())
        elif ' and ' in group:
            for number in group.split(' and '):
                containers.append('-'.join((mss,container_type,number.strip().lstrip('0'))))
        elif group.strip().isdigit():
            containers.append('-'.join((mss,container_type,group.strip().lstrip('0'))))
        else:
            containers.append('-'.join((mss,group.strip().lstrip('0'))))

    return containers

if __name__ == '__main__':

    # Check arguments
    if len(sys.argv)<2:
        sys.exit("Please provide locations spreadsheet.")
    if os.path.isfile(sys.argv[1]) != True :
        sys.exit('"'+sys.argv[1] + '" is not a file. Please provide the locations spreadsheet.')

    # logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
    #                     filename='location-migration.log',level=logging.DEBUG)
    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                        level=logging.INFO)

    global config
    config = ConfigParser.ConfigParser()
    configFilePath = r'config-local.ini'
    config.read(configFilePath)

    #We will need today later
    today = datetime.datetime.now().isoformat('T')

    #LOAD Locations room-area-coords = uri
    logging.info("Starting to load locations...")
    locations = {}

    next_page = 1
    last_page = 1 #assume one page until told otherwise
    page_size = 200
    while next_page <= last_page:
        location_obj = archivesspace_api_call('/locations', data={'page':next_page, 'page_size':page_size})
        # print("Page %s of %s" % (next_page, last_page))
        # print(json.dumps(location_obj))
        if location_obj['last_page'] != last_page:
            # print('Updating last page from %s to %s' % (last_page, location_obj['last_page']))
            last_page = location_obj['last_page']
        for location in location_obj['results']:
            coords = ''
            for c in ['coordinate_1_indicator','coordinate_2_indicator','coordinate_3_indicator']:
                if c in location.keys():
                    if location[c].isdigit() and c != 'coordinate_3_indicator': #final coordinate is never buffed.
                        coords += format(int(location[c]),'02d')
                    else: #A-Z coordinates
                        coords += location[c]
                coords += '.'
            coords = coords.rstrip('.')
            # print('Room: %s Coordinates: %s URI: %s' % (location['room'],coords, location['uri']))
            locations[format('%s %s') % (location['room'],coords)] = location['uri']
        next_page += 1

    #SECOND VERSE, SAME AS THE FIRST - For Top Containers this time, (MS-00000-type-indicator = uri)
    logging.info("Starting to load top containers...")
    top_containers = {}

    #reset counters
    next_page = 1
    last_page = 1 #assume one page until told otherwise
    page_size = 200 #arbitrary large number
    while next_page <= last_page:
        container_obj = archivesspace_api_call('/repositories/%s/top_containers' % config.get('archivesspace',
                                                      'repository'), data={'page':next_page, 'page_size':page_size})
        # print("Page %s of %s" % (next_page, last_page))
        # print(json.dumps(location_obj))
        if container_obj['last_page'] != last_page:
            # print('Updating last page from %s to %s' % (last_page, location_obj['last_page']))
            last_page = container_obj['last_page']
        for container in container_obj['results']:
            index = ''
            collection = ''
            if container['collection'] and 'identifier' in container['collection'][0].keys():
                collection = container['collection'][0]['identifier']
            top_containers['-'.join((
                container['collection'][0]['identifier'],
                container['type'],
                container['indicator'].lstrip('0')
                ))] = container
        next_page += 1

    # print "Dumping top containers: %s" % json.dumps(top_containers)

    # EACH spreadsheet row

    with open(sys.argv[1], 'rU') as csvfile: #'rU' because Mac Excel exports are wierd

        reader = csv.DictReader(csvfile, dialect=csv.excel_tab)
        for row in reader:
            # Find the collection by MS
            if not 'Location' in row.keys():
                print "Location for this row not found"
                continue
            elif not 'Collection number' in row.keys():
                print '%s has no collection number associated with it: %s' % (row['Location'], json.dumps(row))
                continue
            elif not row['Collection number']:
                print '%s appears empty: %s' % (row['Location'], json.dumps(row))
                continue
            elif not row['Collection number'].startswith(('MS','PH')):
                print '%s has something other than an MS: %s' % (row['Location'], json.dumps(row))
                continue

            location_code = format('%s %s') % (row['Room'].strip(),row['Location'].strip())

            if not location_code in locations.keys():
                print "Could not find location %s in AS: %s" % (location_code,json.dumps(row))
                continue

            # So good so far, we have all the pieces from the CSV we need.
            # Look up each container in this row
            for container in parse_containers(row['Container'], mss=row['Collection number']):
                if not container in top_containers.keys():
                    print "Could not find container %s in AS, should be in location: %s" % (container, location_code)
                    continue

                if top_containers[container]['container_locations']:
                    print "Container %s already has a location: %s" % (container,json.dumps(top_containers[container]['container_locations']))
                    continue

                location_obj = {
                    'jsonmodel_type':'container_location',
                    'status':'current',
                    'ref':locations[location_code],
                    'start_date':today
                }
                top_containers[container]['container_locations'].append(location_obj)
                response_obj = archivesspace_api_call(top_containers[container]['uri'], 'POST', data=top_containers[container])
                if not isinstance(response_obj, dict) or not 'status' in response_obj.keys() or not response_obj['status'] == 'Updated':
                    logging.warning('Could not update container %s with location %s: %s' % (container, location_code, json.dumps(response_obj)))
                    continue

                print "Container %s is now in location %s (%s)" % (container, location_code, locations[location_code])

    # Do any top containers still not have locations???

    for container in top_containers:
        if not container['container_locations']:
            logging.warning('Top container %s (%s) does not have a location' % (container['long_display_string'],container['uri']))
