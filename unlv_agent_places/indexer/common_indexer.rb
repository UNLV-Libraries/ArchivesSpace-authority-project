class CommonIndexer

  self.add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'agent_people'
        if record['record']['places']
          doc['places_place_role_u_ustring'] = record['record']['places']['place_role']
          doc['places_place_entry_u_ustring'] = record['record']['places']['place_entry']
          doc['places_place_role_u_ustring'] = record['record']['places']['place_role']
        end
      end
    }

  end

end