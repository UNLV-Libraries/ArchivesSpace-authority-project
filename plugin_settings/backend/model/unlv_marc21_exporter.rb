class MARCModel < ASpaceExport::ExportModel
	model_for :marc21
	
	include JSONModel
	def handle_agents(linked_agents)
	
		handle_primary_creator(linked_agents)
		
		subjects = linked_agents.select{|a| a['role'] == 'subject'}
		
		subjects.each_with_index do |link, i|
		  subject = link['_resolved']
		  name = subject['display_name']
		  notes = subject['notes']
		  relator = link['relator']
		  terms = link['terms']
		  ind2 = source_to_code(name['source'])
		  
		  handle_agent_notes(notes)
		  
		  case subject['agent_type']

		  when 'agent_corporate_entity'
			code = '610'
			ind1 = '2'
			sfs = [
					['a', name['primary_name']],
					['b', name['subordinate_name_1']],
					['b', name['subordinate_name_2']],
					['n', name['number']],
					['g', name['qualifier']],
				  ]

		  when 'agent_person'
			joint, ind1 = name['name_order'] == 'direct' ? [' ', '0'] : [', ', '1']
			name_parts = [name['primary_name'], name['rest_of_name']].reject{|i| i.nil? || i.empty?}.join(joint)
			ind1 = name['name_order'] == 'direct' ? '0' : '1'
			code = '600'
			sfs = [
					['a', name_parts],
					['b', name['number']],
					['c', %w(prefix title suffix).map {|prt| name[prt]}.compact.join(', ')],
					['q', name['fuller_form']],
					['d', name['dates']],
					['g', name['qualifier']],
				  ]

		  when 'agent_family'
			code = '600'
			ind1 = '3'
			sfs = [
					['a', name['family_name']],
					['c', name['prefix']],
					['d', name['dates']],
					['g', name['qualifier']],
				  ]

		  end

		  terms.each do |t|
			tag = case t['term_type']
			  when 'uniform_title'; 't'
			  when 'genre_form', 'style_period'; 'v'
			  when 'topical', 'cultural_context'; 'x'
			  when 'temporal'; 'y'
			  when 'geographic'; 'z'
			  end
			sfs << [(tag), t['term']]
		  end

		  if ind2 == '7'
			sfs << ['2', subject['source']]
		  end

		  df(code, ind1, ind2, i).with_sfs(*sfs)
		end


		creators = linked_agents.select{|a| a['role'] == 'creator'}[1..-1] || []
		creators = creators + linked_agents.select{|a| a['role'] == 'source'}

		creators.each do |link|
		  creator = link['_resolved']
		  name = creator['display_name']
		  relator = link['relator']
		  terms = link['terms']
		  role = link['role']

		  if relator
			relator_sf = ['4', relator]
		  elsif role == 'source'
			relator_sf =  ['e', 'former owner']
		  else
			relator_sf = ['e', 'creator']
		  end

		  ind2 = ' '

		  case creator['agent_type']

		  when 'agent_corporate_entity'
			code = '710'
			ind1 = '2'
			sfs = [
					['a', name['primary_name']],
					['b', name['subordinate_name_1']],
					['b', name['subordinate_name_2']],
					['n', name['number']],
					['g', name['qualifier']],
				  ]

		  when 'agent_person'
			joint, ind1 = name['name_order'] == 'direct' ? [' ', '0'] : [', ', '1']
			name_parts = [name['primary_name'], name['rest_of_name']].reject{|i| i.nil? || i.empty?}.join(joint)
			ind1 = name['name_order'] == 'direct' ? '0' : '1'
			code = '700'
			sfs = [
					['a', name_parts],
					['b', name['number']],
					['c', %w(prefix title suffix).map {|prt| name[prt]}.compact.join(', ')],
					['q', name['fuller_form']],
					['d', name['dates']],
					['g', name['qualifier']],
				  ]

		  when 'agent_family'
			ind1 = '3'
			code = '700'
			sfs = [
					['a', name['family_name']],
					['c', name['prefix']],
					['d', name['dates']],
					['g', name['qualifier']],
				  ]
		  end

		  sfs << relator_sf
		  df(code, ind1, ind2).with_sfs(*sfs)
		end

	  end

	def handle_agent_notes(notes)
		notes.each do |note|
			prefix =  case note['jsonmodel_type']
					    when 'note_dimensions'; "Dimensions"
					    when 'note_physdesc'; "Physical Description note"
					    when 'note_materialspec'; "Material Specific Details"
					    when 'note_physloc'; "Location of resource"
					    when 'note_phystech'; "Physical Characteristics / Technical Requirements"
					    when 'note_physfacet'; "Physical Facet"
					    when 'note_processinfo'; "Processing Information"
					    when 'note_separatedmaterial'; "Materials Separated from the Resource"
					    else; nil
				    end
		
			marc_args = case note['jsonmodel_type']
		
						when 'arrangement', 'fileplan'
						['351','b']
						when 'note_odd', 'note_dimensions', 'note_physdesc', 'note_materialspec', 'note_physloc', 
						'note_phystech', 'note_physfacet', 'note_processinfo', 'note_separatedmaterial'
						['500','a']
						when 'accessrestrict'
						['506','a']
						when 'note_scopecontent'
						['520', '2', ' ', 'a']
						when 'note_abstract'
						['520', '3', ' ', 'a']
						when 'note_prefercite'
						['524', ' ', ' ', 'a']
						when 'note_acqinfo'
						ind1 = note['publish'] ? '1' : '0'
						['541', ind1, ' ', 'a']
						when 'note_relatedmaterial'
						['544','a']
						when 'note_bioghist'
						['545', '1', ' ','a']
						when 'note_custodhist'
						ind1 = note['publish'] ? '1' : '0'
						['561', ind1, ' ', 'a']
						when 'note_appraisal'
						ind1 = note['publish'] ? '1' : '0'
						['583', ind1, ' ', 'a']
						when 'note_accruals'
						['584', 'a']
						when 'note_altformavail'
						['535', '2', ' ', 'a']
						when 'note_originalsloc'
						['535', '1', ' ', 'a']
						when 'note_userestrict', 'note_legalstatus'
						['540', 'a']
						when 'note_langmaterial'
						['546', 'a']
						else
						nil
					end

			unless marc_args.nil?
				text = prefix ? "#{prefix}: " : ""
				text += ASpaceExport::Utils.extract_note_text(note).delete("\n")
				df!(*marc_args[0...-1]).with_sfs([marc_args.last, *Array(text)])
			end
		end
    end
	
    def handle_id(*ids)
		ids.reject!{|i| i.nil? || i.empty?}
		df('099', ' ', ' ').with_sfs(['a', ids.join('-')])
		#connect using a hyphen instead of period
		df('852', ' ', ' ').with_sfs(['c', ids.join('-')])
	end
	def handle_notes(notes)
	
		notes.each do |note|

		    prefix = case note['type']
		  			    when 'dimensions'; "Dimensions"
		  			    when 'physdesc'; "Physical Description note"
		  			    when 'materialspec'; "Material Specific Details"
		  			    when 'physloc'; "Location of resource"
		  			    when 'phystech'; "Physical Characteristics / Technical Requirements"
		  			    when 'physfacet'; "Physical Facet"
		  			    when 'processinfo'; "Processing Information"
		  			    when 'separatedmaterial'; "Materials Separated from the Resource"
		  			    else; nil
		  			end
                        
		    marc_args = case note['type']
          
		  			  when 'arrangement', 'fileplan'
		  				['351','b']
		  			  when 'odd', 'dimensions', 'physdesc', 'materialspec', 'physloc', 'phystech', 'physfacet', 'processinfo', 'separatedmaterial'
		  				['500','a']
		  			  when 'accessrestrict'
		  				['506','a']
		  			  when 'scopecontent'
		  				['520', '2', ' ', 'a']
		  			  when 'abstract'
		  				['520', '3', ' ', 'a']
		  			  when 'prefercite'
		  				['524', ' ', ' ', 'a']
		  			  when 'acqinfo'
		  				ind1 = note['publish'] ? '1' : '0'
		  				['541', ind1, ' ', 'a']
		  			  when 'relatedmaterial'
		  				['544','a']
		  			  when 'bioghist'
		  				['545','a']
		  			  when 'note_bioghist'
		  				['545','a']
		  			  when 'custodhist'
		  				ind1 = note['publish'] ? '1' : '0'
		  				['561', ind1, ' ', 'a']
		  			  when 'appraisal'
		  				ind1 = note['publish'] ? '1' : '0'
		  				['583', ind1, ' ', 'a']
		  			  when 'accruals'
		  				['584', 'a']
		  			  when 'altformavail'
		  				['535', '2', ' ', 'a']
		  			  when 'originalsloc'
		  				['535', '1', ' ', 'a']
		  			  when 'userestrict', 'legalstatus'
		  				['540', 'a']
		  			  when 'langmaterial'
		  				['546', 'a']
		  			  else
		  				nil
		  			end

        unless marc_args.nil?
           text = prefix ? "#{prefix}: " : ""
           text += ASpaceExport::Utils.extract_note_text(note).delete("\n")
           df!(*marc_args[0...-1]).with_sfs([marc_args.last, *Array(text)])
        end

    end
  end
	def handle_ead_loc(ead_loc)
		ead_loc_text = PluginSettings.settings['ead_loc_text']
		df('555', ' ', ' ').with_sfs(
									  ['a', ead_loc_text],
									  ['u', ead_loc]
									)
		df('856', '4', '2').with_sfs(
									  ['z', ead_loc_text],
									  ['u', ead_loc]
									)
	end

end