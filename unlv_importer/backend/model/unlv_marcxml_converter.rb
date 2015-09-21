
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
		  if record['jsonmodel_type'] == 'accession'
			record['linked_agents'].reject! {|la| !@agent_uris.include?(la[:ref])}
		  end


		  return true unless record['jsonmodel_type'] == 'agent_person' 

		  other = @batch.working_area.find {|rec| rec['jsonmodel_type'] == 'agent_person'}
		  # Log.debug("HELP")
		  # Log.debug(other)
		  # Log.debug(other['names'])
		  # record['names'].each do |name| 
			# Log.debug(name)
			# authority_id = name['authority_id']
			# Log.debug(authority_id)
		  # end
		  Log.debug(record)
		  if other
				other['names'].concat(record['names'])
			false
		  else
			@agent_uris << record['uri']
			true
		  end
		  
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