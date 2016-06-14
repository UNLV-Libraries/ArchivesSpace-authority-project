EXPORT_TYPES = [
                   {"type" => "JSONModel(:subject) uri"},
                   {"type" => "JSONModel(:agent_person) uri"},
                   {"type" => "JSONModel(:agent_corporate_entity) uri"},
                   {"type" => "JSONModel(:agent_software) uri"},
                   {"type" => "JSONModel(:agent_family) uri"},
                   {"type" => "JSONModel(:resource) uri"},
                   {"type" => "JSONModel(:digital_object) uri"}
                  ]

{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "batch_export_types" => {
        "type" => "string",
        "ifmissing" => "error"
      },
	  "resources" => {
		"type" => "array",
        "minItems" => 1,
        "items" => {
          "type" => "string",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => EXPORT_TYPES, #may not need this 
              "ifmissing" => "error"
            },
          }
        }
      },
    }
  }
}