# Identifier Filter

Custom Accession Filter to include the first id from the Accession's identifier. 

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'identifier_filter' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'identifier_filter']
	 
Run the database setup script to update all tables:

    cd /path/to/archivesspace

# Basic Info

**How to Use
1.	After signing in, you must have permission to export resources
2.	Exports will now export with these settings 

**New Features
1.	Fix unitid changed from period to dash 
2.	Remove titleproper <num> tag
3.	Add publisher copyright 