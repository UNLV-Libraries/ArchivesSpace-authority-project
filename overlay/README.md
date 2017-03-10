# Overlay 

Merge agents and subjects while still keeping data.

The overlay plugin applies the same concept as the Merge function in ArchivesSpace but it will take the certain data from the first victim (data being merged from) to the target (data being merged into) 

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'overlay' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'overlay']
		  
# Basic Info

**How to Use

1.	After signing in, you must have permission to update subjects and agents
2.	Click on Plug-ins > Overlay
3.	Select a target. 
  *	This is the where the data will be merged into 
  *	You can only select one 
4.	Select a victim 
  * This is where the data is coming from and will be deleted after overlay
5.	Click Overlay
6.	Confirm your decision


**Data overlaid onto the target record

1.	Authority Id
2.  Dates
3.	Linked Records

