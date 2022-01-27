#!/usr/bin/python

import json
import urllib, urllib2
import base64
import os, sys, ConfigParser, logging, csv
import datetime

TEST = True

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

    # EACH spreadsheet row

    with open(sys.argv[1], 'rU') as csvfile: #'rU' because Mac Excel exports are wierd

        reader = csv.DictReader(csvfile, dialect=csv.excel_tab)
        for row in reader:
            # Find the collection by MS
            if not 'Location' in row.keys():
                logging.warning("Location for this row not found")
                continue
            elif not 'Collection number' in row.keys() or not row['Collection number']:
                # print('No collection number for "%s" in %s %s' % (row['Collection Title'], row['Room'], row['Location']))
                print('No collection number for %s' % (row['Collection Title']))
                continue
            elif not row['Collection number'].startswith(('MS','PH','UA')) or len(row['Collection number']) < 8:
                # print('Unsupported Collection number (%s) in %s %s' % (row['Collection number'],row['Room'], row['Location']))
                print('Unsupported Collection number (%s): %s' % (row['Collection number'],row['Collection Title']))
                continue
            elif not row['Container']:
                print('Missing container information for %s, %s in %s %s' % (row['Collection number'],row['Collection Title'],row['Room'], row['Location']))
                continue

            # So good so far, we have all the pieces from the CSV we need.
            # Look up each container in this row
            for container in parse_containers(row['Container'], mss=row['Collection number']):
                print container
