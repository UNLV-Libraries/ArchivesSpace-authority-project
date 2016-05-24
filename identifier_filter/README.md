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

