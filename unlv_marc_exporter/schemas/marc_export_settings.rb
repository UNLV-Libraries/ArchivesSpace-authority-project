{
  :schema => {
	"$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/marc_export_settings", 
	"properties" => {
		"uri" => {"type" => "tring", "required" => false},
		
		"marc_export_user_id" => {"type" => "integer"},
		
		"m_export_settings" => {"type" => "JSONModel(:m_export_settings) object"},
	},
  },
}