#Author: Carlos Lemus
#Date: 9/6/2016

#Some code borrowed from:
#Title: archivesspace-api-workshop source code
#Author: Robery Doiel 
#Date: 8/9/2016
#https://rsdoiel.github.io

# Updated By: Seth Shaw
# Date Updated: 2/5/2018
# Updated to work with ArchivesSpace 2.2.0
# Requires Python 3

from xml.etree.ElementTree import ElementTree
import xml.etree.ElementTree as ET
import configparser 
import urllib.request
import urllib.parse
import urllib.error
import json
import logging
import getpass
import re
import os

def login (api_url, username, password):
    '''This function logs into the ArchivesSpace REST API returning an acccess token'''

    #Encode our password for sending the request
    data = urllib.parse.urlencode({'password': password}).encode('utf-8')
    
    #Create a request
    req = urllib.request.Request(
                url = api_url+'/users/'+username+'/login', 
                data = data)
    try:
        #Create a response 
        response = urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        print("Something went wrong when connecting to the website")
        print("Check the program log for more information")
        logging.error("Trouble loging in!")
        logging.error('Error Code: %s', e.code)
        logging.error('Error Message: %s', e.read())
        return None
    except urllib.error.URLError as e:
        print("Something is wrong with the URL") 
        print("Check the program log for more information")
        logging.error("Trouble loging in!")
        logging.error('Error Message: %s', e.reason)
        return None
    
    src = response.read().decode('utf-8')
    result = json.JSONDecoder().decode(src)
    
    # Session holds the value we want for auth_token
    return result['session']

def export_resources(api_url, auth_token, repo_id, ids,identifiers):
    '''This function exports an xml with record tags of the given id's marcxml export
    into one collection tag'''
    
    ET.register_namespace('', "http://www.loc.gov/MARC21/slim")
    root = ET.Element('collection', { 'xmlns:xsi':"http://www.w3.org/2001/XMLSchema-instance", 'xsi:schemaLocation': "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"})

    #Find the number to append to the new xml collection
    file_num = 0
    while os.path.exists("xmls/%s_etc%s.xml" % (identifiers[0], file_num)):
        file_num += 1

    #Find the number to append to the new log of created collections
    log_num = 0
    while os.path.exists("logs/resources_exported%s.log" % log_num):
        log_num += 1

        

    counter = 0
    try:
        #Create a text file logging all of the resources exported
        text_file = open("logs/resources_exported%s.log" % log_num, "w")
        for i in ids:
            #Make request for the marcxml
            marc_response = make_marcxml_request(api_url, auth_token, repo_id, i)    
            if(marc_response):
                    #Retrive the record from the collection xml
                    marc_element_tree = ET.fromstring(marc_response)
                    root.append(marc_element_tree[0])
                    #Report the record received
                    text_file.write((identifiers[counter]+ " "+ str(i) + " " + marc_element_tree[0][3][0].text + "\n").lstrip())
            counter += 1

    finally:
        if text_file is not None:
            text_file.close()

    #Write out to new collection file
    tree = ElementTree(root)
    
    #Check if we need to create a new version by appending a file_num or we can just put in the first identifier
    if (os.path.exists("xmls/%s_etc.xml" % (identifiers[0]))):
        tree.write('xmls/%s_etc%s.xml' % (identifiers[0], file_num))
    else:
        tree.write('xmls/%s_etc.xml' % (identifiers[0]))
    return

def make_marcxml_request(api_url,auth_token, repo_id, id):
    '''This function makes the request for the current resource id'''
    req = urllib.request.Request(
    url = api_url+'/repositories/' + str(repo_id) + '/resources/marc21/'+ str(id) + '.xml',
        data = None,
        headers = {'X-ArchivesSpace-Session': auth_token})

    try:
        response = urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        print("Something went wrong, check output log for more information")
        logging.error('Error Code: %s', e.code)
        logging.error('Error Message: %s', e.read())
        return None
    except urllib.error.URLError as e:
         print("Something went wrong, check output log for more information")               
         logging.error('Error Message: %s',e.reason)
         return None
    src = response.read().decode('utf-8')
      
    return src

def search_identifer(api_url,auth_token, repo_id, identifier):
    '''This function uses the search function and the id_1_u_sstr cusom facet to find the system resource id'''
    
    logging.info("Performing id search for: %s" % identifier);

    params =  urllib.parse.urlencode({'page': '1',
                                      "aq" :
                                      '{"query":{"field":"identifier","value":"%s","jsonmodel_type":"field_query"}}'  % (identifier) })
    url = api_url+'/repositories/' + str(repo_id) + '/search?%s' % params
    data = None
    headers = {'X-ArchivesSpace-Session': auth_token}

    #Make the request
    req = urllib.request.Request(url, data, headers)
    try:
        #Get the response
        response = urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        print("Something went wrong when connecting to the website")
        print("Check the program log for more information")
        logging.error('Error Code: %s', e.code)
        logging.error('Error Message: %s', e.read())
        return None
    except urllib.error.URLError as e:
        print("Something is wrong with the URL") 
        print("Check the program log for more information")
        logging.error('Error Message: %s',e.reason)
        return None
    
    src = response.read().decode('utf-8')
    result = json.JSONDecoder().decode(src)

    #Retrieve the system Id from the uri of the resource
    if(result['results']):
        resource_id = re.sub('.*?([0-9]*)$',r'\1',result['results'][0]['uri'])
        logging.info("repo id %s was found for : %s" % (resource_id, identifier));
        return resource_id
    else:
        print("The resource for %s was not found" % identifier)
        print("Check the program log for more information")
        logging.error('No Resource id found for %s: check that the resource exists', identifier)
        return None
    
    return None

def input_ids():
    '''This function requests comma seperated id_1 identifiers from user'''
    
    ids = input('Enter the resource identifer(s) comma seperated(i.e MS-00784, OH-00452):\n').split(',')
    return ids

def main_loop(config):
    '''This is the main loop for the program in case user wants to run multiple batches'''

    #Collect information from config
    api_url = config['login']['aspace_backend_url']
    username = config['login']['aspace_username']
    password = config['login']['aspace_password']
    repo_id = config['login']['repo_id']

    #Login and get authtoken          
    logging.info('Logging in to %s', api_url)
    auth_token = login(api_url, username, password)
    
    resource_ids = []
    tag_identifers = []
    if auth_token != None: 
         logging.info('Success!')

         #Collect ids from user 
         identifiers = input_ids()

         for i in identifiers:
            #Search for the identifer resource and return a system id
            resource_id = search_identifer(api_url, auth_token, repo_id, i.strip())
            if(resource_id):
                resource_ids.append(resource_id)
                tag_identifers.append(i)

         if(resource_ids):
            #export resources
            repos = export_resources(api_url, auth_token, repo_id, resource_ids,tag_identifers)

         print("Export has finished, check the program log for more information")
    else:
         logging.error('Could not retrive authentication token') 
    return None
    
if __name__ == '__main__':
        

    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                        filename='program.log',level=logging.DEBUG)

    logging.info("*******RUNNING  MULTI MARC EXPORTER*******")
    config = configparser.ConfigParser()
    configFilePath = r'config.ini'
    config.read(configFilePath)
     
    loop = True

    #Main loop
    while loop: 
        main_loop(config)
        again = input("Would you like to export another batch? Yes(y), anything else to exit: ")
        if(again == "y" or again == "Y"):
            loop = True
        else:
            loop = False
            
