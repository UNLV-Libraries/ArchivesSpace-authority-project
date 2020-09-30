class MARCModel < ASpaceExport::ExportModel
  model_for :marc21

  include JSONModel

  def self.df_handler(name, tag, ind1, ind2, code)
    define_method(name) do |val|
      if(tag == '041') #check settings for enabling tag 041
        if(MarcExportSettings.m_export_settings['tag_041']) then df(tag, ind1, ind2).with_sfs([code, val]) end
      else
        df(tag, ind1, ind2).with_sfs([code, val])
      end
    end
    name.to_sym
  end

  @archival_object_map = {
    [:repository, :finding_aid_language] => :handle_repo_code,
    [:title, :linked_agents, :dates] => :handle_title,
    :linked_agents => :handle_agents,
    :subjects => :handle_subjects,
    :extents => :handle_extents,
    :lang_materials => df_handler('lang', '041', '0', ' ', 'a'),
  }

  def self.from_resource(obj, opts = {})
    marc = self.from_archival_object(obj, opts)
    marc.apply_map(obj, @resource_map)
    marc.leader_string = "00000np$ a2200000 u 4500"
    marc.leader_string[7] = obj.level == 'item' ? 'm' : 'c'

  #check 008 controlfield value
    if(MarcExportSettings.m_export_settings['tag_008']) then marc.controlfield_string = assemble_controlfield_string(obj) end

    marc
  end

  def handle_repo_code(repository, langcode)
    repo = repository['_resolved']
    return false unless repo

    sfa = repo['org_code'] ? repo['org_code'] : "Repository: #{repo['repo_code']}"
    if(MarcExportSettings.m_export_settings['tag_852']) #check settings enabling for tag 852
      df('852', ' ', ' ').with_sfs(
                ['a', sfa],
                ['b', repo['name']]
                )
    end
    df('040', ' ', ' ').with_sfs(['a', repo['org_code']], ['c', repo['org_code']])
  end

  def handle_primary_creator(linked_agents)
    link = linked_agents.find{|a| a['role'] == 'creator'}
    return nil unless link

    creator = link['_resolved']
    name = creator['display_name']
    notes = creator['notes']
    ind2 = ' '
    role_info = link['relator'] ? ['4', link['relator']] : ['e', 'creator']

    #handle_agent_notes(notes)

    case creator['agent_type']

    when 'agent_corporate_entity'
      code = '110'
      ind1 = '2'
      sfs = [
          ['a', name['primary_name']],
          ['b', name['subordinate_name_1']],
          ['b', name['subordinate_name_2']],
          ['n', name['number']],
          ['d', name['dates']],
          ['g', name['qualifier']],
        ]

    when 'agent_person'
      joint, ind1 = name['name_order'] == 'direct' ? [' ', '0'] : [', ', '1']
      name_parts = [name['primary_name'], name['rest_of_name']].reject{|i| i.nil? || i.empty?}.join(joint)

      code = '100'
      sfs = [
          ['a', name_parts],
          ['b', name['number']],
          ['c', %w(prefix title suffix).map {|prt| name[prt]}.compact.join(', ')],
          ['q', name['fuller_form']],
          ['d', name['dates']],
          ['g', name['qualifier']],
        ]

    when 'agent_family'
      code = '100'
      ind1 = '3'
      sfs = [
          ['a', name['family_name']],
          ['c', name['prefix']],
          ['d', name['dates']],
          ['g', name['qualifier']],
        ]
    end

    sfs << role_info
    df(code, ind1, ind2).with_sfs(*sfs)
  end

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

      #check special setting 4 (Add agent notes)
      if(MarcExportSettings.m_export_settings['tag_ss_4'])
        handle_agent_notes(notes)
      end
      case subject['agent_type']

      when 'agent_corporate_entity'
        code = '610'
        ind1 = '2'
        #check special setting 610 (combine name and qualifier)
        if(MarcExportSettings.m_export_settings['tag_610_sc_a_ss_1'] && !name['qualifier'].nil?)
          sfs = [
              ['a', name['primary_name'] + ' (' + name['qualifier'] + ')'],
              ['b', name['subordinate_name_1']],
              ['b', name['subordinate_name_2']],
              ['n', name['number']],
              ]
        else
          sfs = [
              ['a', name['primary_name'] ],
              ['b', name['subordinate_name_1']],
              ['b', name['subordinate_name_2']],
              ['n', name['number']],
              ['g', name['qualifier']],
              ]
      end
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
      df!(code, ind1, ind2).with_sfs(*sfs)
    end

  end

  #export the agent notes
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
            #check settings for enabling tag 520 and indicator 3
            if(MarcExportSettings.m_export_settings['tag_520_ind1_3'])
              ['520', '3', ' ', 'a']
            end
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
        if   handle_settings(marc_args)
          text = prefix ? "#{prefix}: " : ""
          #Strip hard returns
          if(MarcExportSettings.m_export_settings['tag_ss_1'])
            text += ASpaceExport::Utils.extract_note_text(note).delete("\n")
          else
            text += ASpaceExport::Utils.extract_note_text(note)
          end
          #add access restriction
          if(marc_args[0] == '506')
            if( MarcExportSettings.m_export_settings['tag_506_sc_a_ss_1'])
              urls = text.scan(/(?:http|https):\/\/[a-z0-9]+(?:[\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(?:(?::[0-9]{1,5})?\/[^\s]*)?/ix)
              unless urls.empty?
                 text = text.gsub(/(\. )[\s\S]*/, '. This collection has been digitized and is available online.')
                 ead_text = if MarcExportSettings.m_export_settings['tag_856_ss_1'].nil? then MarcExportSettings.m_export_settings['tag_856_ss_1'] else  "Finding aid online:" end
                 df('856', '4', '2').with_sfs(
                    ['z', ead_text],
                     ['u', urls[0].chomp(".")]
                )
              end
            end
          end
          df!(*marc_args[0...-1]).with_sfs([marc_args.last, *Array(text)])
        end
      end
    end
  end

  def handle_id(*ids)
    ids.reject!{|i| i.nil? || i.empty?}

    #connect using a hyphen instead of period
    if MarcExportSettings.m_export_settings['tag_099']
      if MarcExportSettings.m_export_settings['tag_ss_2']
        df('099', ' ', ' ').with_sfs(['a', ids.join('-')])
      else
        df('099', ' ', ' ').with_sfs(['a', ids.join('.')])
      end
    end
    if MarcExportSettings.m_export_settings['tag_852']
      if MarcExportSettings.m_export_settings['tag_ss_2']
        df('852', ' ', ' ').with_sfs(['a', ids.join('-')])
      else
        df('852', ' ', ' ').with_sfs(['a', ids.join('.')])
      end
    end
  end

  def handle_notes(notes)
    notes.each do |note|
      export = false
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
              #check settings for enabling tag 520 and indicator 3
              if(MarcExportSettings.m_export_settings['tag_520_ind1_3'])
                ['520', '3', ' ', 'a']
              end
              when 'prefercite'
              ['524', ' ', ' ', 'a']
              when 'acqinfo'
              ind1 = note['publish'] ? '1' : '0'
              ['541', ind1, ' ', 'a']
              when 'relatedmaterial'
              ['544','a']
              when 'bioghist'
              ['545', '1', ' ','a']
              when 'note_bioghist'
              ['545', '1', ' ','a']
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
      if   handle_settings(marc_args)
        text = prefix ? "#{prefix}: " : ""
        #Strip had returns
        if(MarcExportSettings.m_export_settings['tag_ss_1'])
          text += ASpaceExport::Utils.extract_note_text(note).delete("\n")
        else
          text += ASpaceExport::Utils.extract_note_text(note)
        end
        #add access restriction
        if(marc_args[0] == '506')
          if( MarcExportSettings.m_export_settings['tag_506_sc_a_ss_1'])
            urls = text.scan(/(?:http|https):\/\/[a-z0-9]+(?:[\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(?:(?::[0-9]{1,5})?\/[^\s]*)?/ix)
            unless urls.empty?
              text = text.gsub(/(\. )[\s\S]*/, '. This collection has been digitized and is available online.')
              ead_text = if MarcExportSettings.m_export_settings['tag_ss_3'].nil? then "Finding aid online:" else MarcExportSettings.m_export_settings['tag_ss_3'] end
              df('856', '4', '0').with_sfs(
                  ['z', ead_text],
                  ['u', urls[0].chomp(".")]
                )
            end
          end
        end
        df!(*marc_args[0...-1]).with_sfs([marc_args.last, *Array(text)])
      end
    end
    end
  end

  def handle_ead_loc(ead_loc)
    if( MarcExportSettings.m_export_settings['tag_555'])
      text = if MarcExportSettings.m_export_settings['tag_555_ss_1'].nil? then "Finding aid online:" else MarcExportSettings.m_export_settings['tag_555_ss_1'] end
      df('555', '8', ' ').with_sfs(
                  ['a', text],
                  ['u', ead_loc]
                  )
    end
    if( MarcExportSettings.m_export_settings['tag_856'])
      text = if MarcExportSettings.m_export_settings['tag_856_ss_1'].nil? then "Finding aid online:" else MarcExportSettings.m_export_settings['tag_856_ss_1'] end
      df('856', '4', '2').with_sfs(
                  ['z', text],
                  ['u', ead_loc]
                  )
    end
  end

  #Checks if there is a setting for the exporting tag
  #If there is and that tag is off don't export
  #else let the tag export
  def handle_settings(marc_args)
    export = true
    tag = 'tag_' + marc_args[0]
    if ( MarcExportSettings.m_export_settings.include? tag)
      if (!MarcExportSettings.m_export_settings[tag])
        export = false
      end
    end
    return export;
  end

  # Preserves the older handle_extents before subfield f was introduced
  # Could make this configurable, later.
  def handle_extents(extents)
    extents.each do |ext|
      e = ext['number']
      e << " #{I18n.t('enumerations.extent_extent_type.'+ext['extent_type'], :default => ext['extent_type'])}"

      if ext['container_summary']
        e << " (#{ext['container_summary']})"
      end

      df!('300').with_sfs(['a', e])
    end
  end

  # Newer marc21 models discontinue the handle_dates function.
  # We need to handle dates in handle_title now.
  def handle_title(title, linked_agents, dates)
    creator = linked_agents.find{|a| a['role'] == 'creator'}
    date_codes = []

    # process dates first, if defined.
    unless dates.empty?
      dates = [["single", "inclusive", "range"], ["bulk"]].map {|types|
        dates.find {|date| types.include? date['date_type'] }
      }.compact

      dates.each do |date|
        code, val = nil
        code = date['date_type'] == 'bulk' ? 'g' : 'f'
        if date['expression']
          val = date['expression']
        elsif date['end']
          val = "#{date['begin']} - #{date['end']}"
        else
          val = "#{date['begin']}"
        end

        if(code == 'f') #check settings for enabling tag subfield code f
          if(MarcExportSettings.m_export_settings['tag_245_sc_f']) then date_codes.push([code, val]) end
        elsif (code == 'g') #check settings for enabling tag subfield code g
          if(MarcExportSettings.m_export_settings['tag_245_sc_g']) then date_codes.push([code, val]) end
        else
          date_codes.push([code, val])
        end
      end
    end

    ind1 = creator.nil? ? "0" : "1"
    if date_codes.length > 0
      # we want to pass in all our date codes as separate subfield tags
      # e.g., with_sfs(['a', title], [code1, val1], [code2, val2]... [coden, valn])
      df('245', ind1, '0').with_sfs(['a', title + ","], *date_codes)
    else
      df('245', ind1, '0').with_sfs(['a', title])
    end
  end

end
