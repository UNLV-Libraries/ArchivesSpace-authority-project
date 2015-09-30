{
	:schema => {
		"$schema" => "http://www.archivesspace.org/archivesspace.json",
		"version" => 1,
		"type" => "object",
		
		"properties" => {
			"place_role" => {"type" => "string", "maxLength" => 255, "required" => false},
			"place_entry" => {"type" => "string", "maxLength" => 255, "required" => false},
			"place_source" => {"type" => "string", "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "place_source"},
		},
	},
}