{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {	

		#Enable Tags 
		"tag_008" => {"type" => "boolean", "default" => false},	
		"tag_041" => {"type" => "boolean", "default" => false},	
		"tag_099" => {"type" => "boolean", "default" => true},	
		"tag_245_sc_f" => {"type" => "boolean",  "default" => false},
		"tag_245_sc_g" => {"type" => "boolean",  "default" => false},
		"tag_351" => {"type" => "boolean", "default" => false},
		"tag_500" => {"type" => "boolean", "default" => false},	
		"tag_506" => {"type" => "boolean", "default" => true},	
		"tag_520_ind1_3" => {"type" => "boolean", "default" => false},
		"tag_541" => {"type" => "boolean", "default" => false},	
		"tag_555" => {"type" => "boolean", "default" => true},	
		"tag_852" => {"type" => "boolean", "default" => false},	
		"tag_856" => {"type" => "boolean", "default" => true},	
		
		#Special Settings
		"tag_ss_1" => {"type" => "boolean", "default" => true}, #strip hard returns
		"tag_ss_2" => {"type" => "boolean", "default" => true}, #replace period with dash identifier
		"tag_610_sc_a_ss_1" => {"type" => "boolean", "default" => true}, #unique qualifier with name for Tag 610
		"tag_506_sc_a_ss_1" => {"type" => "boolean", "default" => true}, #Search for url in Tag 506 and create additional Tag 856
		"tag_ss_4" => {"type" => "boolean", "default" => false}, #Add agent notes 
		"tag_ss_3" => {"type" => "string", "required" => false}, #Change label for created Tag 856
		"tag_555_ss_1" => {"type" => "string", "required" => false}, #Change label for finding aid content Tag 555
		"tag_856_ss_1" => {"type" => "string", "required" => false}, #Change label for finding aid content Tag 856
	
	},
  },
}