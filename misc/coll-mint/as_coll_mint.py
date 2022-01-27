#!/usr/bin/python

import argparse
import base64
import ConfigParser
import csv
import json
import logging
import os
import sys
import urllib, urllib2

"""
as_coll_mint.py takes ArchivesSpace resource identifiers (see their uri) as a
series of arguments, mints an ARK, updates the resources' ead_location, and
exports a PDF.

@author Seth Shaw
@date 2017-08-02
@updated 2017-09-08: Use resource ids as args and add DC metadata support

Before running the configuration file must be complete.
Copy config.ini.example to config.ini and update the necessary values.

Note that this script assumes all resources are from the same repository.
The repository id is set in the config.ini file.
"""

SESSION = ''



# who_what_when is a dict with the keys who, what, and when. All other keys are ignored.
def mint_ark(identifier, dublin_core={}):
    request = urllib2.Request("%s/%s" % (config.get('ezid','minter-url'),
                              config.get('ezid','ark-shoulder')))
    request.add_header("Content-Type", "text/plain; charset=UTF-8")

    #Authentication
    encoded_auth = base64.encodestring('%s:%s' % (config.get('ezid','username'),
                                                  config.get('ezid','password')
                                                  )).replace('\n', '')
    request.add_header("Authorization","Basic %s" % encoded_auth)

    #Add target URL
    target = "%s/%s.pdf" % (config.get('archivesspace','pdf-url-prefix'),
                            identifier )
    data = "_target: %s\n" % (target)
    for descriptive_item_term, descriptive_item_value in dublin_core.iteritems():
        data += '%s: %s\n' % (descriptive_item_term, descriptive_item_value)

    request.add_data(data.encode("UTF-8"))

    try:
        response = urllib2.urlopen(request)
        answer = response.read()
        if answer.startswith('success'):
            code,ark = answer.split(": ")
            logging.info('Minted ARK for %s: %s => %s' % (identifier,
                                                          ark, target))
            return ark
        else:
            logging.error("Can't mint ark: %s", answer)
            return ''
    except urllib2.HTTPError, e:
        logging.error("%d %s\n" % (e.code, e.msg))
        if e.fp != None:
          response = e.fp.read()
          if not response.endswith("\n"): response += "\n"
          logging.error("Can't mint ark. Response: %s", response)

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

    parser = argparse.ArgumentParser()
    parser.add_argument('id', nargs='+', help="ArchivesSpace resouce identifiers to run.")
    parser.add_argument('-p', "--update-pdfs", help="Download a new PDF even if an ARK exists.", action="store_true")
    parser.add_argument('-c',"--coll-ids", help="Use Collection Identifier instead of Resource Identifier.", action="store_true")
    parser.add_argument("-d","--dry", help="Don't mint ARKs or update ArchivesSpace, used for testing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                        level=logging.INFO)

    global config
    config = ConfigParser.ConfigParser()
    configFilePath = r'config.ini'
    config.read(configFilePath)

    for id in args.id:
        logging.info("Attempting to Mint an ARK for %s" % id)
        resource = {}
        identifier = ''
        if args.coll_ids:
            #Advanced queries don't work well with URL Encode, so we do it manually and attach it to the path ourselves.
            resource_query = '{"query":{"op":"AND","subqueries":[{"field":"identifier","value":"%s","jsonmodel_type":"field_query","negated":false,"literal":true},{"field":"primary_type","value":"resource","jsonmodel_type":"boolean_field_query"}],"jsonmodel_type":"boolean_query"},"jsonmodel_type":"advanced_query"}' % (urllib.quote_plus(id))
            resources = archivesspace_api_call('/repositories/%s/search?page=1&aq=%s' % (config.get('archivesspace','repository'),resource_query))
            # Make sure what we get it good, or report back.
            if not resources['results']:
                logging.warning("Could not find a resource for %s" % (id))
                continue
            resource = json.loads(resources['results'][0]['json'])
            resource_identifier = resource['uri'].split('/')[-1]
            identifier = id

        else:
            #sanity Check
            if not id.isdigit():
                logging.warning("Not a digit (can't be a resource identifier): %s" % id)
                continue

            resource = archivesspace_api_call('/repositories/%s/resources/%s' % (config.get('archivesspace','repository'),id))
            logging.debug('RESOURCE JSON FOR %s: %s' % (id, json.dumps(resource)))
            if not resource:
                continue
            elif 'error' in resource.keys():
                logging.warning("Could not find a resource for %s: %s" % (id,resource['error']))
                continue

            resource_identifier = id
            #form the identifier
            id_separator = '-'
            identifier = resource['id_0']
            if 'id_1' in resource.keys():
                identifier += id_separator + resource['id_1']
            if 'id_2' in resource.keys():
                identifier += id_separator + resource['id_2']
            if 'id_3' in resource.keys():
                identifier += id_separator + resource['id_3']

        # ARKs!
        if 'ead_location' in resource.keys() and 'ark:' in resource['ead_location']: # ARK exists
            logging.info('Existing ARK for %s (%s): %s' % (id,identifier,resource['ead_location']))
            if not args.update_pdfs: # Download a PDF anyway?
                continue
        else: # Mint an ARK
            dublin_core = {}
            dublin_core['_profile'] = 'dc'
            if 'finding_aid_title' in resource.keys() and resource['finding_aid_title']:
                dublin_core['dc.title'] = resource['finding_aid_title']
            elif 'title' in resource.keys() and resource['title']:
                dublin_core['dc.title'] = resource['title']
            dublin_core['dc.type'] = 'finding aids'
            dublin_core['dc.creator'] = 'University of Nevada, Las Vegas University Libraries'
            dublin_core['dc.publisher'] = 'University of Nevada, Las Vegas University Libraries'
            dublin_core['dc.relation'] = identifier
            if 'finding_aid_date' in resource.keys() and resource['finding_aid_date']:
                dublin_core['dc.date'] = resource['finding_aid_date'].replace(u'\u00a9', '').strip()

            if args.dry:
                ark = '%s/fake' % (config.get('ezid','ark-resolver'))
            else:
                ark = '%s/%s' % (config.get('ezid','ark-resolver'),mint_ark(identifier, dublin_core))

                logging.info('Updating the EAD Location for %s' % id)
                resource['ead_location'] = ark
                archivesspace_api_call('/repositories/%s/resources/%s' % (
                            config.get('archivesspace', 'repository'),resource_identifier),
                        'POST', json.dumps(resource))
                # print "\n".join(['/repositories/%s/resources/%s' % (config.get('archivesspace', 'repository'),resource_identifier),'POST', json.dumps(resource)])
        # PDFs
        logging.info('Generating the PDF for %s (%s)' % (resource_identifier,identifier))
        if not os.path.isdir(config.get('pdf','export-location')):
            os.makedirs(os.path.normpath(config.get('pdf','export-location')))

        with open(os.path.normpath('%s/%s.pdf' % (config.get('pdf','export-location'), identifier )), "wb") as local_file:
            local_file.write(archivesspace_api_call("/repositories/%s/resource_descriptions/%s.pdf?include_daos=true" % (config.get('archivesspace', 'repository'), resource_identifier ), as_obj = False).read())
