# UNLV MARCXML Exporter

Custom UNLV MARCXML exporter for resource MARC exports. Plugin Settings has been implemented in a way here that allows
the custom functionality for UNLV to be enabled and disabled. Instructions are included for adding or deleting these settings

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'unlv_marc_exporter' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'unlv_marc_exporter']
	 
Run the database setup script to update all tables:

    cd /path/to/archivesspace
    scripts/setup-database.sh

# Basic Info

# How to Use

1.	After signing in, you must have permission to manage the repository
2.	You only need to do the next part once if you don’t plan to change the settings
3.	Click on Plug-ins > UNLV Marc Export Settings
4.	Enable/Disable tags 
5.	Edit Special Settings
6.	Save.
7.	Exports will now export with these settings 

**New Features

1.	Enable/Disable
  * Tag 041
  *	Tag 099
  *	Tag 245 subfield code f
  *	Tag 351 
  *	Tag 500
  *	Tag 506
  *	Tag 520
  *	Tag 520 with ind1 = 3 
  *	Tag 541
  *	Tag 555
  *	Tag 852
  *	Tag 856
2.	Special Settings
  *	Strip hard returns 
  *	Replace period with a dash for identifier 
  *	Unite qualifier with name for Tag 610
  *	Search for tag 506 for url and create additional subfields for Tag 856
  *	Change label for created Tag 856
  *	Change label for created Tag 856
  *	Change label for finding aid content Tag 555

**For Developer: How to add/remove settings

1.	Open schemas/m_export_settings.rb 
  * This crates the tags to use
  * Add tag, use current tags as example
  * A format was used to keep easy track of each setting where x is the number or string that you need replaced
     * tag_xxx if you’re editing Tag xxx
     * tag_xxx_sc_x if you’re editing Tag xxx’s subfield code x
     * 	tag_xxx_ind1_x if you’re editing Tag xxx with ind1 = x
     * tag_ss_1 if you’re editing special settings (in this case the first special setting and then tag_ss_2 for the second and so on) 
     * tag_xxx_ss_1 if you’re editing special settings for a specific tag (continuing the second like the previous)
     * tag_xxx_sc_a_ss_1 if you’re editing a special setting for a specific tag and a specific subfield code (same as previous)
2.	Open frontend/views/m_export_settings
  *	This adds the tags to the page for viewing  
  *	Add tag to view, use current form tags as example
3.	Open locales/en.yml
  *	This adds the label and tool tip
  *	Add tag label with same name as the name you used in the schemas and a tooltip if applicable
  *	Use current tags as example
4.	Open backend/model/unlv_marc21_exporter	
  *	This edits the exporter to use the settings 
  *	To access the setting use 
    *	Example :: MarcExportSettings.m_export_settings[‘tag_xxx’]
  *	The handle_settings method checks if the tag can export or not (applying the Enable/Disable)
  *	For examples of using the settings do a Ctrl+f for MarcExportSetting
