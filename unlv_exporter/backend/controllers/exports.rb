class ArchivesSpaceService < Sinatra::Base

  include ExportHelpers
  
  Endpoint.get('/repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a corporate entity")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentCorporateEntity.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['primary_name']].compact.join("_")
    json_response({"filename" => "#{fn}_eac.xml".gsub(/\s+/, '_'),
                   "mimetype" => "application/xml"})
  end
 end