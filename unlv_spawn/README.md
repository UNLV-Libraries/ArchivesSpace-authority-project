# Spawn

The Spawn plugin gives ArchivesSpace users the option to select an unlimited number of accession records to be “spawned” as a batch into resource records. Each spawned resource record reuses data from fields in the accession record while also pre-populating default note content. Once resource records are spawned in a batch they must be edited and saved one at a time.
Note: data that is created from spawn has been customized to fit UNLV's Oral Histories workflow. Also, the plugin does not batch spawn multiple accessions at once, it just facilitates the procedure for batch spawning records.
## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'spawn' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'spawn']
		  
# Basic Info

### How to spawn records

1.	Click on Plug-ins > Spawn Records
2.	Choose accession to spawn
3.	Create Links
4.	Open each link to your accessions individually 
5.	Varify the information spawn is correct
6.	Save the record
7.  An option to change settings will appear under cog->plug-ins->Spawn Settings and in the Spawn Records page as a button

### Spawn changes 

1. Changes to notes title
2. Add condition description notes
3. Add a general notes
4. Add Conditions Governing Access 
5. Add Publication Note
6. Add identifier (Oral history is the same as accession)
7. Add level of description
8. Add language
9. Add Restrictions
10. Add Finding Aid Information
11. Add classifications
12. Add linked agent relator

### Spawn settings
1. Access restrict enable & text
2. User restrict enable & text
3. Subject link enable & text
4. Classifications link enable & text
5. EAD id tag  enable & text
