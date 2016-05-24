{
  :schema => {
	"$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/plugin_settings",
	"properties" => {
		"uri" => {"type" => "tring", "required" => false},
		
		"user_id" => {"type" => "integer"},
		
		"settings" => {"type" => "JSONModel(:settings) object"},
	},
  },
}