require 'date'
class EADSerializer < ASpaceExport::Serializer
  serializer_for :ead

  def self.run_serialize_step(data, xml, fragments, context)
    Array(@extra_serialize_steps).each do |step|
      step.new.call(data, xml, fragments, context)
    end
  end

  def stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      begin

      ead_attributes = {
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd',
        'xmlns:xlink' => 'http://www.w3.org/1999/xlink'
      }

      if data.publish === false
        ead_attributes['audience'] = 'internal'
      end

      xml.ead( ead_attributes ) {

        xml.text (
          @stream_handler.buffer { |xml, new_fragments|
            serialize_eadheader(data, xml, new_fragments)
          })

        atts = {:level => data.level, :otherlevel => data.other_level}
        atts.reject! {|k, v| v.nil?}

        xml.archdesc(atts) {

          xml.did {


            if (val = data.language)
              xml.langmaterial {
                xml.language(:langcode => val) {
                  xml.text I18n.t("enumerations.language_iso639_2.#{val}", :default => val)
                }
              }
            end

            if (val = data.repo.name)
              xml.repository {
                xml.corpname { sanitize_mixed_content(val, xml, @fragments) }
              }
            end

            if (val = data.title)
              xml.unittitle  {   sanitize_mixed_content(val, xml, @fragments) }
            end

            serialize_origination(data, xml, @fragments)

            #change period to dash
            xml.unitid (0..3).map{|i| data.send("id_#{i}")}.compact.join('-')

            if @include_unpublished
              data.external_ids.each do |exid|
                xml.unitid  ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
              end
            end

            serialize_extents(data, xml, @fragments)

            serialize_languages(data, xml, @fragments)

            serialize_dates(data, xml, @fragments)

            serialize_did_notes(data, xml, @fragments)

            data.instances_with_sub_containers.each do |instance|
              serialize_container(instance, xml, @fragments)
            end

            EADSerializer.run_serialize_step(data, xml, @fragments, :did)

          }# </did>

           data.digital_objects.each do |dob|
                 serialize_digital_object(dob, xml, @fragments)
           end

           serialize_nondid_notes(data, xml, @fragments)

           serialize_bibliographies(data, xml, @fragments)

           serialize_indexes(data, xml, @fragments)

           serialize_controlaccess(data, xml, @fragments)

           EADSerializer.run_serialize_step(data, xml, @fragments, :archdesc)

           xml.dsc {

             data.children_indexes.each do |i|
               xml.text(
                        @stream_handler.buffer {|xml, new_fragments|
                          serialize_child(data.get_child(i), xml, new_fragments)
                        }
                        )
             end
           }
         }
       }

    rescue => e
      xml.text  "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF YOUR RESOURCE. THE FOLLOWING INFORMATION MAY HELP:\n
                MESSAGE: #{e.message.inspect}  \n
                TRACE: #{e.backtrace.inspect} \n "
    end



    end
    doc.doc.root.add_namespace nil, 'urn:isbn:1-931666-22-9'

    Enumerator.new do |y|
      @stream_handler.stream_out(doc, @fragments, y)
    end
  end

  def serialize_origination(data, xml, fragments)
    unless data.creators_and_sources.nil?
      data.creators_and_sources.each do |link|
        agent = link['_resolved']
        role = link['role']
        #add relator translations
        relator = case link['relator']
				  when 'ctb'; 'contributor'
				  when 'cre'; 'creator'
				  when 'col'; 'collector'
				  when 'pho'; 'photographer'
				  when 'ctr'; 'contractor'
				  when 'arc'; 'architect'
				  when 'cli'; 'client'
				  when 'eng'; 'engineer'
				  else 'creator'
				  end
        sort_name = agent['display_name']['sort_name']
        rules = agent['display_name']['rules']
        source = agent['display_name']['source']
        authfilenumber = agent['display_name']['authority_id']
        node_name = case agent['agent_type']
                    when 'agent_person'; 'persname'
                    when 'agent_family'; 'famname'
                    when 'agent_corporate_entity'; 'corpname'
                    end
        xml.origination(:label => relator) {
         atts = { :source => source, :rules => rules, :authfilenumber => authfilenumber}
         atts.reject! {|k, v| v.nil?}

          xml.send(node_name, atts) {
            sanitize_mixed_content(sort_name, xml, fragments )
          }
        }
      end
    end
  end

  def serialize_extents(obj, xml, fragments)
    if obj.extents.length
      obj.extents.each do |e|
        next if e["publish"] === false && !@include_unpublished
        audatt = e["publish"] === false ? {:audience => 'internal'} : {}
        xml.physdesc({:altrender => e['portion']}.merge(audatt)) {
          if e['number'] && e['extent_type']
            xml.extent({:altrender => 'materialtype spaceoccupied'}) {
              sanitize_mixed_content("#{e['number']} #{I18n.t('enumerations.extent_extent_type.'+e['extent_type'], :default => prettify_missing_enumeration(e['extent_type']))}", xml, fragments)
            }
          end
          if e['container_summary']
            xml.extent({:altrender => 'carrier'}) {
			  # add parentheses around container summary
              sanitize_mixed_content( "(#{e['container_summary']})", xml, fragments)
            }
          end
          xml.physfacet { sanitize_mixed_content(e['physical_details'],xml, fragments) } if e['physical_details']
          xml.dimensions  {   sanitize_mixed_content(e['dimensions'],xml, fragments) }  if e['dimensions']
        }
      end
    end
  end

  def serialize_languages(languages, xml, fragments)
    lm = []
    language_notes = languages.map {|l| l['notes']}.compact.reject {|e| e == [] }.flatten
    if !language_notes.empty?
      language_notes.each do |note|
        unless note["publish"] === false && !@include_unpublished
          audatt = note["publish"] === false ? {:audience => 'internal'} : {}
          content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)

          att = { :id => prefix_id(note['persistent_id']) }.reject {|k, v| v.nil? || v.empty? || v == "null" }
          att ||= {}

          xml.send(note['type'], att.merge(audatt)) {
            sanitize_mixed_content(content, xml, fragments, ASpaceExport::Utils.include_p?(note['type']))
          }
          lm << note
        end
      end
      if lm == []
        languages = languages.map {|l| l['language_and_script']}.compact
        xml.langmaterial {
          languages.map {|language|
            punctuation = language.equal?(languages.last) ? '.' : ', '
            lang_translation = I18n.t("enumerations.language_iso639_2.#{language['language']}", :default => language['language'])
            if language['script']
              xml.language(:langcode => language['language'], :scriptcode => language['script']) {
                xml.text(lang_translation)
              }
            else
              xml.language(:langcode => language['language']) {
                xml.text(lang_translation)
              }
            end
            xml.text(punctuation)
          }
        }
      end
    # ANW-697: If no Language Text subrecords are available, the Language field translation values for each Language and Script subrecord should be exported, separated by commas, enclosed in <language> elements with associated @langcode and @scriptcode attribute values, and terminated by a period.
    else
      languages = languages.map {|l| l['language_and_script']}.compact
      if !languages.empty?
        xml.langmaterial {
          languages.map {|language|
            punctuation = language.equal?(languages.last) ? '.' : ', '
            lang_translation = I18n.t("enumerations.language_iso639_2.#{language['language']}", :default => language['language'])
            if language['script']
              xml.language(:langcode => language['language'], :scriptcode => language['script']) {
                xml.text(lang_translation)
              }
            else
              xml.language(:langcode => language['language']) {
                xml.text(lang_translation)
              }
            end
            xml.text(punctuation)
          }
        }
      end
    end
  end

  def serialize_eadheader(data, xml, fragments)
    eadheader_atts = {:findaidstatus => data.finding_aid_status,
                      :repositoryencoding => "iso15511",
                      :countryencoding => "iso3166-1",
                      :dateencoding => "iso8601",
                      :langencoding => "iso639-2b"}.reject{|k,v| v.nil? || v.empty? || v == "null"}

    xml.eadheader(eadheader_atts) {

      eadid_atts = {:countrycode => data.repo.country,
              :url => data.ead_location,
              :mainagencycode => data.mainagencycode}.reject{|k,v| v.nil? || v.empty? || v == "null" }

      xml.eadid(eadid_atts) {
        xml.text data.ead_id
      }

      xml.filedesc {

        xml.titlestmt {

          titleproper = ""
          titleproper += "#{data.finding_aid_title} " if data.finding_aid_title
          titleproper += "#{data.title}" if ( data.title && titleproper.empty? )
          #REMOVE title proper <num> tag
          #titleproper += "<num>#{(0..3).map{|i| data.send("id_#{i}")}.compact.join('.')}</num>"
          xml.titleproper("type" => "filing") { sanitize_mixed_content(data.finding_aid_filing_title, xml, fragments)} unless data.finding_aid_filing_title.nil?
          xml.titleproper {  sanitize_mixed_content(titleproper, xml, fragments) }
          xml.subtitle {  sanitize_mixed_content(data.finding_aid_subtitle, xml, fragments) } unless data.finding_aid_subtitle.nil?
          xml.author { sanitize_mixed_content(data.finding_aid_author, xml, fragments) }  unless data.finding_aid_author.nil?
          xml.sponsor { sanitize_mixed_content( data.finding_aid_sponsor, xml, fragments) } unless data.finding_aid_sponsor.nil?

        }

        unless data.finding_aid_edition_statement.nil?
          xml.editionstmt {
            sanitize_mixed_content(data.finding_aid_edition_statement, xml, fragments, true )
          }
        end

        xml.publicationstmt {

		  val = Date.today.strftime("%Y") + " The Regents of the University of Nevada. All rights reserved."
		  xml.publisher { sanitize_mixed_content(val, xml, fragments) }
		  # add publisher
          xml.publisher { sanitize_mixed_content(data.repo.name.strip ,xml, fragments) }

          if data.repo.image_url
            xml.p ( { "id" => "logostmt" } ) {
              xml.extref ({"xlink:href" => data.repo.image_url,
                          "xlink:actuate" => "onLoad",
                          "xlink:show" => "embed",
                          "xlink:type" => "simple"
                          })
                          }
          end
          if (data.finding_aid_date)
            xml.p {
                  val = data.finding_aid_date
                  xml.date {   sanitize_mixed_content( val, xml, fragments) }
                  }
          end

          unless data.addresslines.empty?
            xml.address {
              data.addresslines.each do |line|
                xml.addressline { sanitize_mixed_content( line, xml, fragments) }
              end
              if data.repo.url
                xml.addressline ( "URL: " ) {
                  xml.extptr ( {
                          "xlink:href" => data.repo.url,
                          "xlink:title" => data.repo.url,
                          "xlink:type" => "simple",
                          "xlink:show" => "new"
                          } )
                 }
              end
            }
          end
        }

        if (data.finding_aid_series_statement)
          val = data.finding_aid_series_statement
          xml.seriesstmt {
            sanitize_mixed_content(  val, xml, fragments, true )
          }
        end
        if ( data.finding_aid_note )
            val = data.finding_aid_note
            xml.notestmt { xml.note { sanitize_mixed_content(  val, xml, fragments, true )} }
        end

      }

      xml.profiledesc {
        creation = "This finding aid was created by #{data.finding_aid_author} on <date>#{Time.now}</date>."
        xml.creation {  sanitize_mixed_content( creation, xml, fragments) }

        if (val = data.finding_aid_language)
          xml.langusage (fragments << val)
        end

        if (val = data.descrules)
          xml.descrules { sanitize_mixed_content(val, xml, fragments) }
        end
      }

      if data.revision_statements.length > 0
        xml.revisiondesc {
          data.revision_statements.each do |rs|
              if rs['description'] && rs['description'].strip.start_with?('<')
                xml.text (fragments << rs['description'] )
              else
                xml.change {
                  rev_date = rs['date'] ? rs['date'] : ""
                  xml.date (fragments <<  rev_date )
                  xml.item (fragments << rs['description']) if rs['description']
                }
              end
          end
        }
      end
    }
  end

  def serialize_container(inst, xml, fragments)
    atts = {}

    sub = inst['sub_container']
    top = sub['top_container']['_resolved']

    atts[:id] = prefix_id(SecureRandom.hex)
    last_id = atts[:id]

    atts[:type] = top['type']
    text = top['indicator']

    atts[:label] = I18n.t("enumerations.instance_instance_type.#{inst['instance_type']}",
                          prettify_missing_enumeration(inst['instance_type']))
    atts[:label] << " [#{top['barcode']}]" if top['barcode']

    if (cp = top['container_profile'])
      atts[:altrender] = cp['_resolved']['url'] || cp['_resolved']['name']
    end

    xml.container(atts) {
      sanitize_mixed_content(text, xml, fragments)
    }

    (2..3).each do |n|
      atts = {}

      next unless sub["type_#{n}"]

      atts[:id] = prefix_id(SecureRandom.hex)
      atts[:parent] = last_id
      last_id = atts[:id]

      atts[:type] = sub["type_#{n}"]
      text = sub["indicator_#{n}"]

      xml.container(atts) {
        sanitize_mixed_content(text, xml, fragments)
      }
    end
  end

  def serialize_note_content(note, xml, fragments)
      return if note["publish"] === false && !@include_unpublished
      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      content = note["content"]

      atts = {:id => prefix_id(note['persistent_id']) }.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)

      head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note['type']}", :default => prettify_missing_enumeration(note['type']))
      content, head_text = extract_head_text(content, head_text)
      xml.send(note['type'], atts) {
        xml.head { sanitize_mixed_content(head_text, xml, fragments) } unless ASpaceExport::Utils.headless_note?(note['type'], content )
        sanitize_mixed_content(content, xml, fragments, ASpaceExport::Utils.include_p?(note['type']) ) if content
        if note['subnotes']
          serialize_subnotes(note['subnotes'], xml, fragments, ASpaceExport::Utils.include_p?(note['type']))
        end
      }
  end
  def serialize_bibliographies(data, xml, fragments)
     data.bibliographies.each do |note|
       next if note["publish"] === false && !@include_unpublished
       content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
       note_type = note["type"] ? note["type"] : "bibliography"
       head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note_type}", :default => prettify_missing_enumeration( note_type ))
       audatt = note["publish"] === false ? {:audience => 'internal'} : {}

       atts = {:id => prefix_id(note['persistent_id']) }.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)

       xml.bibliography(atts) {
         xml.head { sanitize_mixed_content(head_text, xml, fragments) }
         sanitize_mixed_content( content, xml, fragments, true)
         note['items'].each do |item|
           xml.bibref { sanitize_mixed_content( item, xml, fragments) }  unless item.empty?
         end
       }
     end
   end
  def serialize_indexes(data, xml, fragments)
    data.indexes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
      head_text = nil
      if note['label']
        head_text = note['label']
      elsif note['type']
        head_text = I18n.t("enumerations._note_types.#{note['type']}", :default => prettify_missing_enumeration( note['type'] ) )
      end
      atts = {:id => prefix_id(note["persistent_id"]) }.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)

      content, head_text = extract_head_text(content, head_text)
      xml.index(atts) {
        xml.head { sanitize_mixed_content(head_text,xml,fragments ) } unless head_text.nil?
        sanitize_mixed_content(content, xml, fragments, true)
        note['items'].each do |item|
          next unless (node_name = data.index_item_type_map[item['type']])
          xml.indexentry {
            atts = item['reference'] ? {:target => prefix_id( item['reference']) } : {}
            if (val = item['value'])
              xml.send(node_name) {  sanitize_mixed_content(val, xml, fragments )}
            end
            if (val = item['reference_text'])
              xml.ref(atts) {
                sanitize_mixed_content( val, xml, fragments)
              }
            end
          }
        end
      }
    end
  end
end
def prettify_missing_enumeration(enumeration)
    #Take the machine readable enumeration codes and convert them to human readable (*only* use when localization values are missing)
    enumeration = enumeration.downcase.tr("_", " ")
    enumeration = enumeration.titleize

    return enumeration
end
