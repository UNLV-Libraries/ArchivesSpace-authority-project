#Title: archivesspace-api-workshop source code
#Author: Robery Doiel 
#Date: 8/9/2016
#https://rsdoiel.github.io

import urllib.request
import urllib.parse
import urllib.error
import json
import re

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
            print(e.code)
            print(e.read())
            return ""
        except urllib.error.URLError as e:
            print(e.reason())
            return ""
        src = response.read().decode('utf-8')
        result = json.JSONDecoder().decode(src)
        # Session holds the value we want for auth_token
        return result['session']

def list_repos(api_url, auth_token):
        '''List all the repositories'''
        req = urllib.request.Request(
            url = api_url+'/repositories',
            data = None,
            headers = {'X-ArchivesSpace-Session': auth_token})
        try:
            response = urllib.request.urlopen(req)
        except urllib.error.HTTPError as e:
            print(e.code)
            print(e.read())
            return None
        except urllib.error.URLError as e:
            print(e.reason())
            return None
        src = response.read().decode('utf-8')
          
        return json.JSONDecoder().decode(src)
if __name__ == '__main__':
    import getpass
    api_url = input('ArchivesSpace API URL (e.g http://localhost:8089): ')
    
    #Input username and password request
    username = input('ArchivesSpace username: ')
    password = getpass.getpass('ArchivesSpace password: ')
    print('Logging in to', api_url)
    auth_token = login(api_url, username, password)
    print(auth_token)
    if auth_token != '':
        print('Success!')
    else:
        print('Ooops! something went wrong')
    # Test list_repos()
    repos = list_repos(api_url, auth_token)
    print("\nRepository IDs: ")
    if not repos:
         print ("No repos found or an error has occured")
    else:
        for i in repos:
            print(i['repo_code'], "repository ID: " + re.sub('.*?([0-9]*)$',r'\1',i['uri']))
