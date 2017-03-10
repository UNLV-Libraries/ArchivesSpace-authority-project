# UNLV EAD Exporter

Custom UNLV EAD exporter for resource EAD exports. Changes to the EAD affect the ArchivesSpace Print to PDF function. 

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'unlv_ead_exporter' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'unlv_ead_exporter']
	 
	 Copy the stylesheets to your own stylesheets folder under:
	 
	 location_of_archivesspace/stylesheets

	 To change the logo add your own png file and in the as-ead-pdf.xsl file
	 change "logo-special-collections.png" to your own logo name
	 
# Basic Info


**How to Use

1.	After signing in, you must have permission to export resources
2.	EAD Exports will now export with these settings 

**New Features

1.	Fix unitid changed from period to dash 
2.	Remove titleproper <num> tag
3.	Add publisher copyright 
4.	Add relator translations 
5.	Add parentheses around container summary
6.  Fix enumerations exports
 *Custom enumerations need to be rendered on export 


