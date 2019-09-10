# UNLV EAD Custom Importer

The current version of ArchivesSpace will reuse a digital object's title
as the caption value. The caption is a much smaller field than title, leading
to database errors for digital objects with long titles. This plugin simply 
removes the caption portion of the import. 

This is [a known issue](https://archivesspace.atlassian.net/browse/ANW-757) 
that will eventually be resolved, at which time we can decommission this plugin.

