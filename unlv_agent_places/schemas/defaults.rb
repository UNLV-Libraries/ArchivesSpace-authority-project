{
	"places_place_role" => {"type" => "string", "maxLength" => 255, "required" => false},
	"places_place_entry" => {"type" => "string", "maxLength" => 255, "required" => false},
	"places_place_source" => {"type" => "string",  "minLength" => 1, "ifmissing" => "error", "dynamic_enum" => "place_source"},
}