{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {	

		#Enable Tags 
		"accessrestrict_enable" => {"type" => "boolean", "default" => true},	
		"userestrict_enable" => {"type" => "boolean", "default" => true},	
		"subject_link_enable" => {"type" => "boolean", "default" => true},	
		"classifications_link_enable" => {"type" => "boolean", "default" => true},	
		"ead_id_tag_enable" => {"type" => "boolean", "default" => true},	
    
		
		#Special Settings
		"accessrestrict_text" => {"type" => "string"}, #Custom Access Restrcit note
		"userestrict_text" => {"type" => "string"}, #Custom User Acecess Note
		"subject_link" => {"type" => "string"}, #a unique link to a subject
    "classifications_link" => {"type" => "string"}, #a unique link to a classification
		"ead_id_tag" => {"type" => "string",}, #begining tag for ead id
	
    },
  },
}