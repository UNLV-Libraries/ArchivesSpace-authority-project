# UNLV EAD Exporter

Custom UNLV EAD exporter for resource EAD exports. 

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'unlv_ead_exporter' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'unlv_ead_exporter']
	 
Run the database setup script to update all tables:

    cd /path/to/archivesspace
    scripts/setup-database.sh

# Basic Info

Stylesheets are included to accommodate the EAD export changes

**How to Use
1.	After signing in, you must have permission to export resources
2.	Exports will now export with these settings 

**New Features
1.	Fix unitid changed from period to dash 
2.	Remove titleproper <num> tag
3.	Add publisher copyright 
