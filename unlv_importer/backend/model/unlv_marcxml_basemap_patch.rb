require 'logger'
MarcXMLBaseMap.module_eval do
	def set_authority 
		-> name, node {
			
		val = node.inner_text
	    name['authority_id'] = val
	}	
	end
	def authority
	{
		:map => {
			"self::controlfield" => {
				:obj => :name_person,
				:rel => :names,
				:map => {
					"self::controlfield" => set_authority
				},
				:defaults => {
					:name_order => 'direct',
					:source => 'ingest'
				}
			}
		}
	}
   end
end