require_relative 'unlv_marcxml_subjects_basemap_patch'

class UNLVMarcXMLSubjectsConverter < MarcXMLConverter
	
	
	# Create the import type for marcxml subjects 
	def self.import_types(show_hidden = false)
		[
			{
				:name => "marcxml_subjects",
				:description => "Import MARC XML records as Subjects (UNLV)"
			}
		]
	end
	
	# Add the authority_id to the original resources when two resources are created
	def initialize(input_file)
		super(input_file)

		@subject_uris = []

		@batch.record_filter = ->(record) {
		
		  return false unless record.class.record_type == 'subject'
		
		  return true unless record['jsonmodel_type'] == 'subject' 
		  
		  other = @batch.working_area.find {|rec| rec['jsonmodel_type'] == 'subject'}

		  if other
			record.to_hash(:raw).each do |k, v|
			    if k == 'authority_id' then other[k] = " " end
				if k == 'source' then other[k] = "import" end #add source
				next if k == 'jsonmodel_type'
				next if k == 'name_order'
				next if k == 'source'
				next if k == 'external_ids'
				next if k == 'uri'
				next unless other[k].is_a? String 
				next if record[k].eql?(other[k]) 
				other[k] << "#{v}"
			end
			
			#other['terms'][0]['term'] = other['terms'][0][:term].chomp(".") #remove period
				
			false
		  else
			@subject_uris << record['uri']
			true
		  end
		  
		}
	 end 
	  
	def self.instance_for(type, input_file)
		if type == "marcxml_subjects"
			self.new(input_file)
		else
			nil
		end
	end
end

UNLVMarcXMLSubjectsConverter.configure do |config|

  config.doc_frag_nodes.uniq! 
  config["/record"][:map]["controlfield[@tag='001']"] =  UNLVMarcXMLSubjectsConverter.unlv_subject_authority
  
end