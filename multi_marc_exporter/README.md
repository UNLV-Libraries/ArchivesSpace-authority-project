# Multi MARC Exporter 

The Multi Marc Exporter is not an ArchivesSpace plugin. It is a python script using ArchivesSpace API to combine a list of MARC records under one resource. 

## Installing it

1. Download the latest version of Python at https://www.python.org/downloads/
2. Make sure you have the Identifier Filter installed by following the instructions https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/identifier_filter
3. Create a new file called config.ini
  *	Add with your own information:
  
     [login]
     aspace_username = username
     aspace_password = password
     aspace_backend_url = http://localhost:8089
     repo_id = 2
    

# Basic Info

### How to Use

1. Open the multi_marc_exporter.py or run using the Python IDLE
2. You will be prompted to enter a list of comma separated identifiers(i.e MS-00784, OH-00452)
3. Press Enter to submit command
4. Your new record will show up under xmls as the first identifier entered with an "_etc" indicating multiple MARC records
5. Duplicate records will add a leading number "_etc0", "_etc1", ...
6. The list of exported records will show up under the logs folder as resources_exported#.log 
7. The program.log will give you a report of the export 