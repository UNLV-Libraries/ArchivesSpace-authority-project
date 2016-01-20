class CommonIndexer

	self.add_indexer_initialize_hook do |indexer|
		if AppConfig[:plugins].include?('identifier_filter')
			indexer.add_document_prepare_hook {|doc, record|
				if doc['primary_type'] == 'accession'
					doc['accession_date_year'] = Date.parse(record['record']['accession_date']).year
					doc['identifier'] = (0...4).map {|i| record['record']["id_#{i}"]}.compact.join("-")
					doc['id_0_u_sstr'] = record['record']['id_0']
					doc['title'] = record['record']['display_string']
			
					doc['acquisition_type'] = record['record']['acquisition_type']
					doc['accession_date'] = record['record']['accession_date']
					doc['resource_type'] = record['record']['resource_type']
					doc['restrictions_apply'] = record['record']['restrictions_apply']
					doc['access_restrictions'] = record['record']['access_restrictions']
					doc['use_restrictions'] = record['record']['use_restrictions']
				end
			}
		end
	end
end