#!/usr/bin/python

import csv
import sys

"""
The Special Collections Database was a home-grown solution for search and
discovery of archival holdings. It is no longer in use as so, by extension,
this script isn't either.
"""

fields = {
  'man': {
    'table': 'SPEC_MAN_MANUSCRIPTS_MAN',
    'pk': 'id_man',
    'collection_id': 'coll_man',
    'ark_column': 'link_guide',
    'csv_ark_field': 'Link to Guide',
    'csv_coll_field': 'Coll #',
  },
  'pho': {
    'table': 'SPEC_PC_PHOTOCOLL_PHO',
    'pk': 'id_pho',
    'collection_id': 'coll_number_pho',
    'ark_column': 'link_guide_pho',
    'csv_ark_field': 'Link to Guide',
    'csv_coll_field': 'Coll #',
  },
  'ua': {
    'table': 'SPEC_UNLV_ARCHIVES_UAR',
    'pk': 'id_uar',
    'collection_id': 'rec_grp_num',
    'ark_column': 'link_guide_uar',
    'csv_ark_field': 'Link to Collection Guide',
    'csv_coll_field': 'Record Group Number',
  },
  'oh': {
    'table': 'SPEC_ORAL_HISTORY_SOH',
    'pk': 'id_soh',
    'collection_id': 'coll_number_soh',
    'ark_column': 'link_guide_soh',
    'csv_ark_field': 'Link to Guide',
    'csv_coll_field': 'Collection #',
  },
}

"""
ArchivesSpace query for existing ARKs:
```
SELECT title,
       REPLACE(REPLACE(REPLACE(identifier, '","','-'),'["',''),'",null,null]','') AS identifier,
       ead_location
FROM resource
WHERE publish IS True
AND ead_location IS NOT Null
AND ead_location LIKE '%ark:%'
ORDER BY identifier;
```
"""
if __name__ == '__main__':

    # Ensure we have the two arguments
    if not len(sys.argv) > 3:
        print 'Please provide the type-key, archivesspace export (from db), and scdb export (from admin interface)'
        exit();

    # load up an identifier associative array storing arks for guides
    identifier_ark = {}
    table_settings = fields[sys.argv[1]]
    with open(sys.argv[2]) as csvfile:
        reader = csv.DictReader(csvfile, delimiter='\t')
        for row in reader:
            identifier_ark[row['identifier']] = row['ead_location']

    # Run through the DB entries and create update statements
    update_sql = ''
    with open(sys.argv[3], 'rU') as csvfile:
        reader = csv.DictReader(csvfile, delimiter='|')
        for r in reader:
            if r[table_settings['csv_ark_field']].find('ark:') > -1:
		print(r[table_settings['csv_coll_field']]+' already has an ark '+r[table_settings['csv_ark_field']])
                continue
            if r[table_settings['csv_coll_field']] in identifier_ark.keys():
                update_sql += "UPDATE {0} SET {1}='{2}' WHERE {3}='{4}';\n".format(table_settings['table'], table_settings['ark_column'], identifier_ark[r[table_settings['csv_coll_field']]].strip(), table_settings['pk'], r['id'])
            else:
                print(r[table_settings['csv_coll_field']]+' is not in ArchivesSpace')

    print(update_sql);
