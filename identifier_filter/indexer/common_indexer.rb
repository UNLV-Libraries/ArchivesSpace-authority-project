class CommonIndexer

	self.add_indexer_initialize_hook do |indexer|
		# Index extra Accession fields
		if AppConfig[:plugins].include?('identifier_filter')
			indexer.add_document_prepare_hook {|doc, record|
				if doc['primary_type'] == 'accession'
					doc['id_0_u_sstr'] = record['record']['id_0']
				end
			}
			
			indexer.add_document_prepare_hook {|doc, record|
				if doc['primary_type'] == 'resource'
					doc['id_1_u_sstr'] = record['record']['id_1']
					doc['id_0_u_sstr'] = record['record']['id_0']
				end
			}
		end
	end
end