ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do

	Resource.class_eval do
	
		require 'date'

		#ADD UNLV CUSTOM CHANGES
		def populate_from_accession(accession)
			values = accession.to_hash(:raw)
      
			repo_url = accession.repository["ref"]
      Log.debug(repo_url)
      Log.debug(repo_url.scan(/\d+$/).first)
      settings, global_repo_id = current_spawn_settings(repo_url.scan(/\d+$/).first)
      prefs = settings["repo"]["spawn_defaults"]

			# Recursively remove bits that don't make sense to copy (like "lock_version"
			# properties)
			values = JSONSchemaUtils.map_hash_with_schema(values, JSONModel(:accession).schema,
																[proc { |hash, schema|
																  hash = hash.clone
																  hash.delete_if {|k, v| k.to_s =~ /^(id_[0-9]|lock_version|instances|deaccessions|collection_management|user_defined|external_documents)$/}
																  hash
																}])

			# We'll replace this with our own relationship, linking us back to the
			# accession we were spawned from.
			values.delete('related_accessions')

			notes ||= []
			if accession.content_description
			#accesion locales changed and added (check en.yml)
			  notes << JSONModel(:note_multipart).from_hash(:type => "scopecontent",
															:label => I18n.t('accession.content_description'),
															:subnotes => [{
																			'content' => accession.content_description,
																			'jsonmodel_type' => 'note_text'
																		  }])
																			
			# Add abstract Note (same as scope and content)
			# notes << JSONModel(:note_singlepart).from_hash(:type => "abstract",
			#												:label => I18n.t('accession.abstract_note'),
			#												:content => [accession.content_description])
																			
			end

			if accession.condition_description
			  notes << JSONModel(:note_singlepart).from_hash(:type => "physdesc",
															 :label => I18n.t('accession.condition_description'),
															 :content => [accession.condition_description])
			end

			# Add General Note
			if accession.general_note
				notes << JSONModel(:note_multipart).from_hash(:type => "odd",
															:label => I18n.t('accession.general_note'),
															:subnotes => [{
																			'content' => accession.general_note,
																			'jsonmodel_type' => 'note_text'
																		  }])
																			
				
			end 
      
      if(prefs['accessrestrict_enable'] && !prefs['accessrestrict_text'].nil?) 
      Log.debug("accessrestrict_enable Enable")
        content = prefs['accessrestrict_text']
        #Self populate Conditions Governing Access note_multipart
        notes << JSONModel(:note_multipart).from_hash(:type => "accessrestrict",
														  :label => I18n.t('accession.access_note'),
														  :subnotes => [{
																			'content' => content,
																			'jsonmodel_type' => 'note_text'}])
			end
     if(prefs['userestrict_enable'] && !prefs['userestrict_text'].nil?) 
        content = prefs['userestrict_text']
			#Self populate Publication Note (Conditions Governing Use)
			notes << JSONModel(:note_multipart).from_hash(:type => "userestrict",
														  :label => I18n.t('accession.user_access_note'),
														  :subnotes => [{
																			'content' => content,
																			'jsonmodel_type' => 'note_text'}])
			end
			
			self.related_accessions = [{'ref' => accession.uri, '_resolved' => accession}]

			self.notes = notes

			self.update(values)

			self.rights_statements = Array(accession.rights_statements).map {|rights_statement|
			  rights_statement.clone.tap {|r| r.delete('identifier')}
			}

			if !self.extents || self.extents.empty?
			  self.extents = [JSONModel(:extent).new._always_valid!]
			end
			
			if !self.dates || self.dates.empty?
			  self.dates = [JSONModel(:date).new._always_valid!]
			end
			
			#Add identifier (Same identifier as in the accession record (OH in first box, 5 digit numerical string in second box)
			self.id_0 = accession.id_0
			self.id_1 = accession.id_1
			
			#Add Resource Type
			#self.resource_type = "records"
			
			#Add level of description (always collection) 
			self.level = "collection"
			
			#Add language (always English) use Enumeration value eng
			self.language = "eng"
			
			#Enable Plubish?
			self.publish = true
			
			#Enable Restrictions if the exist
			if accession.restrictions_apply || accession.access_restrictions || accession.use_restrictions
				self.restrictions = true
			end
			
			#Add Linked agent relator
			if self.linked_agents
				length = self.linked_agents.length - 1
				(0..length).each do |i|
					self.linked_agents[i]["relator"] = "cre" 
				end 
			end
			
			
			
			#ADD FINDING AID INFORMATION
			
			#Add ead id example US::NvLN::PH00041
     
      if(prefs['ead_id_tag_enable'] && !prefs['ead_id_tag'].nil?) 
        ead_id_tag = prefs['ead_id_tag']
        self.ead_id = ead_id_tag + accession.id_0 + accession.id_1 
      end
			self.finding_aid_title = "Guide to the " + accession.title

			#Add this years date
			self.finding_aid_date = "Copyright #{DateTime.now.year}"
			
			#Update Finding Aid Data with current logged in user 
			user = JSONModel::HTTP::get_json("/users/current-user")
			self.finding_aid_author =  user["name"]
			
			#self.finding_aid_filing_title = accession.title
			self.finding_aid_description_rules = "dacs"
			self.finding_aid_language = "English"
			self.finding_aid_status = "in_progress"
			
			#IMPORTANT: classification and subjects set specifically for OH Oral Histories (id = 2 )
			if !self.classifications || self.classifications.empty?
        if (prefs['classifications_link_enable'] && !prefs['classifications_link'].nil?)
          classifications_link = prefs['classifications_link']
      		self.classifications = [{'ref' => "#{repo_url}#{classifications_link}", '_resolved' => JSONModel::HTTP::get_json("#{repo_url}#{classifications_link}")}]
        end
			end
			
      if (prefs['subject_link_enable'] && !prefs['subject_link'].nil?)
        subject_link = prefs['subject_link']
        #Add link to oral history subject
        self.subjects = [{'ref' => "#{repo_url}#{subject_link}", '_resolved' => JSONModel::HTTP::get_json(subject_link)}] 
      end
      
    end

      
      private

      def current_spawn_settings(repo_id)
         current_settings = JSONModel::HTTP::get_json("/repositories/#{repo_id}/current_spawn_settings")
         repo_id = JSONModel(:repository).id_for(current_settings['global']['repository']['ref'])
        return current_settings, repo_id
      end

	end
end