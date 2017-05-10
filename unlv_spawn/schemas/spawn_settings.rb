{
  :schema => {
	"$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/spawn_settings", 
	"properties" => {
		"uri" => {"type" => "tring", "required" => false},
		
		"spawn_user_id" => {"type" => "integer"},
		
		"spawn_defaults" => {"type" => "JSONModel(:spawn_defaults) object"},
	},
  },
}