# UNLV Importer

Custom UNLV MARCXML Importer for agents and subjects

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'unlv_importer' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'unlv_importer']
		  
# Basic Info

###How to Import Agents

1.	After signing in, click on Create > Background jobs
2.	For Job Type choose Import Data
3.	For Import Type choose MarcXML (Agents; UNLV)
4.	Add Files (must be agents)
5.	Click Queue Job
6.	Wait for process to finish and then your records should appear after clicking the refresh page

###New Items Imported 

1.	Add authority id.
  *	Add prefix LOC link and remove whitespace from authorityid
    * http://id.loc.gov/authorities/names/
2.	Add custom import source
3.	Remove unwanted commas and periods from 'primary_name' ,'rest_of_name', 'title', 'suffix', 'fuller_form' 'dates', 'subordinate_name_1', 'subordinate_name_2' that ArchivesSpace adds automatically on import


###How to Import Subjects

1.	After signing in, click on Create > Background jobs
2.	For Job Type choose Import Data
3.	For Import Type choose MarcXML (Subjects; UNLV)
4.	Add Files (must be subjects)
5.	Click Queue Job
6.	Wait for process to finish and then your records should appear after clicking the refresh page


###New Items Imported 

1.	Add authority id.
  *	Add prefix LOC link and remove whitespace from authorityid
    *	http://id.loc.gov/authorities/subjects/
2. Add custom source
