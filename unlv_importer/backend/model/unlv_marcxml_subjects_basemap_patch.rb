require 'logger'
MarcXMLBaseMap.module_eval do
	
	#Get the authority_id and add the LOC link 
   def set_subjects_authority 
   	-> subject, node {
		val = node.inner_text
		val = 'http://id.loc.gov/authorities/subjects/' + val.gsub(/\s+/, "")
		subject['authority_id'] = val
   }	
   end
	
   def unlv_subject_authority
   {
		:obj => :subject,
		:rel => :subjects,
		:map => {
			"self::controlfield" => set_subjects_authority
		}, 
   }
   end
end