# ArchivesSpace Implementation Project
  -------------------------------
The ArchivesSpace Authority Project is in place for the UNLV Libraries Special Collections to add and fix functionality to the imports and exports. It has evolved into an ArchivesSpace Implementation Project that encompasses many different kinds of plugins that add other functionalities.

# Plugins and Scripts

# UNLV Spawn

The Spawn plugin gives ArchivesSpace users the option to select an unlimited number of accession records to be “spawned” as a batch into resource records. Each spawned resource record reuses data from fields in the accession record while also pre-populating default note content. Once resource records are spawned in a batch they must be edited and saved one at a time.
Note: data that is created from spawn has been customized to fit UNLV's Oral Histories workflow. Also, the plugin does not batch spawn multiple accessions at once, it just facilitates the procedure for batch spawning records.

[UNLV Spawn](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/unlv_spawn).


# Extents Extension

Adds a publish/unpublish button to the extents to aid staff in being able to select between cubic feet and linear feet when printing out EADs/PDFs for the convenience of preventing a confusion for users. 

[Extents Extension](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/extents_ext).

# Identifier Filter

Custom Filter for the staff interfaces of the Accession Module and Resource Module that filters the records (left pane) by Accession ID, Resource ID, and Classification, to aid staff in sorting and filtering records. (By default, ASpace sorts by subject, published, level, and record type.)
For the multi_marc_export plugin to work, this plugin must be instantiated in your ArchivesSpace instance.

[Identifier Filter](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/identifier_filter).

# LC Authority Import 

An existing community plugin that enables import of authorized headings directly from the Library of Congress has been modified to include the Authority ID and further extended to work with UNLV’s custom MARCXML importer.

[UNLV LCNAF](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/lcnaf).

# UNLV MARCXML Importer

The UNLV MARCXML Importer allows ArchivesSpace users to import agent and subject records in MARCXML. 

[UNLV Importer](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/unlv_marc_importer)

# UNLV MARCXML Exporter

The UNLV MARCXML Exporter plugin allows for customization of the default MARCXML export for resource records. Customizations include the ability to insert certain default values, enable or disable export of specific MARC fields, and some reformatting. Most settings can be accessed through a configuration page added to the staff interface. The plugin also includes instructions for adding or deleting settings.

[UNLV MARC exporter](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/unlv_marc_exporter)

# UNLV EAD Exporter

The UNLV EAD exporter customizes data generated from EAD and PDF exports of resource records. The EAD exporter was designed to work in conjunction with the institution’s XSLT stylesheet. The EAD exporter makes the following adjustments: changes dash to period in the unitid (identifier); removes the titleproper tag (instead the finding aid title is rendered on PDF cover page); adds publisher to the copyright statement; adds relator translation (complete spelling instead of abbreviation); adds parentheses around container summary (part of extent).

[UNLV EAD exporter](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/unlv_ead_exporter)

# UNLV Overlay

The overlay plugin applies the same concept as the Merge function of ArchivesSpace.  While the Merge function completely replaces one record with another, the overlay function takes specific values from the victim record (data being merged from) and overlays only those specific values in the target record (data being merged into).  This permits staff to de-duplicate agent and subject records without losing hand-crafted values.  Existing unauthorized agent/ subject headings and Authority IDs can be overlaid with authorized values, while all other existing fields (biographies, relationships, notes) are protected. 

[Overlay](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/unlv_overlay)

# Multi MARCXML Exporter Script

The Multi Marc Exporter is not an ArchivesSpace plugin. It is a separate Python script that queries the ArchivesSpace API to export identified resource records as individual MARCXML records within the same file. 
[Multi Marc Exporter](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/multi_marc_exporter)

# PDF per Repository

The file located in the backend/model of this folder will allow different stylesheets to work with different repositories managed within a single local instance of ArchivesSpace.
Note: This was created for the community; it was not implemented at UNLV.

[PDF Per Repository](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/pdf_per_repository)

# UNLV Custom Reports

UNLV Custom Reports Plugin facilitates export of customized reports (e.g. sorted alphabetically by agent name or sorted alpha-numerically by Authority ID). 

[UNLV Custom Reports](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/UNLV)

# Place 

**Under Construction**

Place is a ArchivesSpace plugin to be able to add places to an agent.

[Place](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/place).

# Plugin Settings

Plugin Settings is a test to implement settings for a plugin following the structure of the preferences in ArchivesSpace.

[Plugin Settings](https://github.com/l3mus/ArchivesSpace-authority-project/tree/master/plugin_settings).

# XACT

XACT is used to transform an Excel spreadsheet collection inventory into an EAD for import into ArchivesSpace.

# Miscellaneous Scripts, Queries, and Transforms

*Note: all scripts are for python2 because that was the default python installed on OS X.*

- coll-mint: Used for adding ARKs to ArchivesSpace and exporting PDFs.
- ead-numbered-components_to_tsv.xsl: An XSLT for creating a TSV file of container titles from an EAD with numbered components.
- export-csv: Script to export Agents in a CSV via the API since the existing export is unusable.
- sql: SQL queries for reporting
- migrate-locations: Scripts used in exploring the option of moving from a locations management spreadsheet to the ArchivesSpace locations module. (2017)
- cdm-update (Deprecated): Scripts to populate ArchivesSpace digital object instances based on CONTENTdm objects.
  - cdm_update_as.py works by matching CDM object titles and a collection identifier to AS archival object titles and resource identifiers.
  - cdm_update_as_pho.py works by taking an Image ID from a CDM object field and matching it to an AS archival object component ID. *Currently only produces a TSV file of matches and errors. Needs to be updated to use ARKs instead once ARKs are minted for these CDM objects.*
  - csv_link_ref_id.py takes a CSV of ARKs, digital ids, titles, and ArchivesSpace ref_ids (usually from ead-numbered-components_to_tsv.xsl) to create digital object records in ArchivesSpace.