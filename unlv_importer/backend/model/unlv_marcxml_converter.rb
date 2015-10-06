require_relative 'unlv_marcxml_basemap_patch'

class UNLVMarcXMLAgentsConverter < MarcXMLConverter
	
	def self.import_types(show_hidden = false)
		[
			{
				:name => "marcxml_agents",
				:description => "Import MARC XML records as Agents (UNLV)"
			}
		]
	end
	def initialize(input_file)
		super(input_file)

		@agent_uris = []

		@batch.record_filter = ->(record) {
		  if record['jsonmodel_type'] == 'resource'
			record['linked_agents'].reject! {|la| !@agent_uris.include?(la[:ref])}
		  end


		  return true unless record['jsonmodel_type'] == 'agent_person' 

			  Log.debug("HERE2")
			  Log.debug(record)
		  other = @batch.working_area.find {|rec| rec['jsonmodel_type'] == 'agent_person'}
		  
		  if other
			record['names'].each do |name|
			  Log.debug(name.to_hash(:raw))
			  name.to_hash(:raw).each do |k, v|
			   if k == 'authority_id'
				other['names'][0][k] = " " end
				next if k == 'jsonmodel_type'
				next if k == 'name_order'
				next unless other['names'][0][k].is_a? String
				other['names'][0][k] << " #{v}"
			  end
			end
			false
		  else
			@agent_uris << record['uri']
			true
		  end
		  
			  Log.debug("HERE3")
			  Log.debug(other)
			  Log.debug(record)
		}
	  end
	def self.instance_for(type, input_file)
		if type == "marcxml_agents"
			self.new(input_file)
		else
			nil
		end
	end
end

UNLVMarcXMLAgentsConverter.configure do |config|

  config.doc_frag_nodes.uniq! 
	
	config["/record"][:map]["controlfield[@tag='001']"] =  UNLVMarcXMLAgentsConverter.mix(UNLVMarcXMLAgentsConverter.person_template,UNLVMarcXMLAgentsConverter.authority)
	# config["/record"][:map]["controlfield[@tag='001']"] = -> resource, node {
		# existing_agent_uri = resource.linked_agents.find {|link| link[:ref] =~ /people/ }
		# Log.debug("hery")
		# Log.debug(existing_agent_uri)
		# Log.debug(@batch)
		# existing_agent = @batch.working_area.find {|obj| obj.uri == existing_agent_uri }
		# Log.debug(existing_agent)
		# make(:name_person) do |name|
			# name.primary = node.xpath("subfield[@code='a']").inner_text
			
			# # add more name fields as necessary
			
			# val = node.inner_text
			# name['authority_id'] = val  
			# existing_agent.names << name
		# end
	# }
	#TODO:work on getting the controlfield to work
	#NOT THIS ONE: config["/record"][:map]["//controlfield[@tag='001']"] =  MarcXMLConverter.mix(MarcXMLConverter.person_template,MarcXMLConverter.authority)
	#config["/record"][:map]["datafield[@tag='010'][@ind1='0' or @ind1='0']"] =  MarcXMLConverter.mix(MarcXMLConverter.person_template,MarcXMLConverter.authority1)
	#config["/record"][:map]["datafield[@tag='100' or @tag='700'][@ind1='0' or @ind1='1']"][:map]["self::datafield[@tag]"]

	# config["/record"][:map]["controlfield[@tag='001']"] = {
		 # :rel => -> resource, agent {
		    # resource[:linked_agents] << {
			 # #stashed value for the role
			  # :role => agent['_role'] || 'subject',
			  # :terms => agent['_terms'] || [],
			  # :relator => agent['_relator'],
			  # :ref => agent.uri
			# }
			# Log.debug(agent)
			# Log.debug(resource)
		 # },
		 # :obj => :agent_person,
		 # :map => {
			# "self::controlfield" => {
				# :obj => :name_person,
				# :rel => :names,
				# :map => {
					# "self::controlfield" => -> name, node {
						# val = node.inner_text						
						# name['authority_id'] = val
					# }
				# },
				# :defaults => {
					# :name_order => 'direct',
					# :source => 'ingest'
				# }
			# }
		# }
	# }
	#Log.debug(config["/record"][:map])
	#config["/record"][:map]["datafield[@tag='100' or @tag='700'][@ind1='0' or @ind1='1']"] =  MarcXMLConverter.mix(MarcXMLConverter.person_template,MarcXMLConverter.creators_and_sources)
		 
	
	
	#Log.debug(config["/record"])
	#Log.debug(config["/record"][:map]["//controlfield[@tag='001']"])
end
