# PDF Per Repository

The file located in the backend/model of this folder will allow different stylesheets to work with different repositories managed within a single local instance of ArchivesSpace.
Note: This was created for the community; it was not implemented at UNLV.

## Installing it

It is recommended to just copy the single file from backend/model to the
backend/model of your local plugin.

However, to install, you can activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'pdf_per_repository' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'pdf_per_repository']
		  
		
# How to use

1. To assign a stylesheet to a specific repository, find out the id of that repository
2. There are two ways to find the repository id
  * If you know to run a python script use the getrepositoriesids.py file. 
	For more information on how to do this visit:
	Robert Doiel's [ArchivesSpace API Workshop](https://rsdoiel.github.io)
  * Otherwise, navigate to your ArchivesSpace website in the Chrome browser.
  Bring the Select Repository menu down and right click on the name of your repository in the drop down menu and click inspect
  ![Inspect](https://cloud.githubusercontent.com/assets/4681350/17568652/845019ea-5ef9-11e6-96a0-42876215e821.PNG)
  
  Next, in the pop-up window below look at the values property corresponding with the repository you wish to assign a stylesheet
  

  ![Repository Ids](https://cloud.githubusercontent.com/assets/4681350/17568653/8454a014-5ef9-11e6-9ad0-00ff5a0617e4.PNG)


3. Next, navigate to your stylesheets in your local instance of ArchivesSpace
4. Make sure you have a default stylesheet with the file name as-ead-pdf.xsl.
It will default to this stylesheet if a specfic stylesheet does not exists for
its corresponding repository
5. Create a new stylesheet with the file name as-ead-pdf-REPOIDHERE.xsl (e.g as-ead-pdf-3.xsl)
![Stylsheet name] (https://cloud.githubusercontent.com/assets/4681350/17568654/84559a96-5ef9-11e6-9ebc-0093545f1606.PNG)
