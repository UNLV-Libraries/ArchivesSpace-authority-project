# Extents Extension

Adds a publish/unpublish button to the extents to aid staff in being able to select between cubic feet and linear feet when printing out EADs/PDFs for the convenience of preventing a confusion for users. 

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'extents_ext' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'extents_ext']
	 
Run the database setup script to update all tables:

    cd /path/to/archivesspace
    scripts/setup-database.sh
