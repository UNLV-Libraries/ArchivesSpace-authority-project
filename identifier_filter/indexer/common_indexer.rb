class CommonIndexer

	self.add_indexer_initialize_hook do |indexer|
		if AppConfig[:plugins].include?('identifier_filter')
			indexer.add_document_prepare_hook {|doc, record|
				if doc['primary_type'] == 'accession'
					doc['id_0_u_sstr'] = record['record']['id_0']
				end
			}
		end
	end
end