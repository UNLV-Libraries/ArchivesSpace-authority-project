require_relative 'unlv_marcxml_basemap_patch'

class UNLVMarcXMLAgentsConverter < MarcXMLConverter
	
	# Create the import type for marcxml agents 
	def self.import_types(show_hidden = false)
		[
			{
				:name => "marcxml_agents",
				:description => "Import MARC XML records as Agents (UNLV)"
			}
		]
	end
	
	# Alter the information recieved from the resource 
	def initialize(input_file)
		super(input_file)

		@agent_uris = []

		@batch.record_filter = ->(record) {
		  if record['jsonmodel_type'] == 'resource'
			record['linked_agents'].reject! {|la| !@agent_uris.include?(la[:ref])}
		  else
		    record['names'][0]['source'] = 'import' #add source
			
			#Add the LOC link to the authority_id 
			record['names'][0]['authority_id'] = 'http://id.loc.gov/authorities/names/' + record['names'][0]['authority_id'].gsub(/\s+/, "")
			
			#Remove redundant punctuation ArchivesSpace adds after import
		    record['names'].each do |name|
				name.to_hash(:raw).each do |k, v|
					case k
					   when 'primary_name'
						  name[k] = v.chomp(",")
						  if record['jsonmodel_type'] == 'agent_corporate_entity'	
							name[k] = v.chomp(".")
						  end
					   when 'rest_of_name', 'title', 'suffix'
						  name[k] = v.chomp(",")
					   when 'fuller_form'
						  name[k] = v.chomp(",").delete('()') 
					   when 'dates', 'subordinate_name_1', 'subordinate_name_2', 'qualifier'
						  name[k] = v.chomp('.') 
					end
				end
			end
		  end
		  
		  return false unless AgentManager.known_agent_type?(record.class.record_type)
		  
		  if (record['jsonmodel_type'] != 'agent_person' && record['jsonmodel_type'] != 'agent_software' && record['jsonmodel_type'] != 'agent_corporate_entity'  && record['jsonmodel_type'] != 'agent_family')
			return true 
		  end
		  
		  other = @batch.working_area.find {|rec| (rec['jsonmodel_type'] == 'agent_person' && rec['jsonmodel_type'] == 'agent_software' && rec['jsonmodel_type'] == 'agent_corporate_entity'  && rec['jsonmodel_type'] == 'agent_family') }
		  
		  if other then 
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

  config.doc_frag_nodes.uniq! 
  #config["/record"][:map]["controlfield[@tag='001']"] =  UNLVMarcXMLAgentsConverter.mix(UNLVMarcXMLAgentsConverter.person_template,UNLVMarcXMLAgentsConverter.authority)

end