{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {	

		#Enable Tags 
		"tag_041" => {"type" => "boolean", "default" => true},	
		"tag_099" => {"type" => "boolean", "default" => true},	
		"tag_245_sc_f" => {"type" => "boolean",  "default" => true},
		"tag_351" => {"type" => "boolean", "default" => true},
		"tag_500" => {"type" => "boolean", "default" => true},	
		"tag_506" => {"type" => "boolean", "default" => true},	
		"tag_520_ind1_3" => {"type" => "boolean", "default" => true},
		"tag_541" => {"type" => "boolean", "default" => true},	
		"tag_544" => {"type" => "boolean", "default" => true},
		"tag_555" => {"type" => "boolean", "default" => true},	
		"tag_610" => {"type" => "boolean", "default" => true},	
		"tag_852" => {"type" => "boolean", "default" => true},	
		"tag_856" => {"type" => "boolean", "default" => true},	
		
		#Special Settings
		"tag_ss_1" => {"type" => "boolean", "default" => true},
		"tag_ss_2" => {"type" => "boolean", "default" => true},
		"tag_506_sc_a_ss_1" => {"type" => "boolean", "default" => true},
		"tag_ss_3" => {"type" => "string", "required" => false},
		"tag_555_ss_1" => {"type" => "string", "required" => false},
		"tag_856_ss_1" => {"type" => "string", "required" => false},
		"tag_610_sc_a_ss_1" => {"type" => "boolean", "default" => true},
	
	},
  },
}