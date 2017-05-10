# Identifier Filter

Custom Filter for the staff interfaces of the Accession Module and Resource Module that filters the records (left pane) by Accession ID, Resource ID, and Classification, to aid staff in sorting and filtering records. (By default, ASpace sorts by subject, published, level, and record type.)
For the multi_marc_export plugin to work, this plugin must be instantiated in your ArchivesSpace instance.

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'identifier_filter' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'identifier_filter']
	 
Run the database setup script to update all tables:

    cd /path/to/archivesspace
    
Delete indexer_state and solr_state 

