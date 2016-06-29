class ArchivesSpaceService < Sinatra::Base


   Endpoint.get('/repositories/:repo_id/jobs/:id/export')
    .description("Get a Job by ID")
    .params(["id", :id],
            ["resolve", :resolve],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:job)"]) \
  do
  
	Log.debug("STRoke9")
	Log.debug(params[:resolve])
	Log.debug(Job.to_jsonmodel(params[:id]))
	Log.debug(json_response(resolve_references(Job.to_jsonmodel(params[:id]), params[:resolve])))
    json_response(resolve_references(Job.to_jsonmodel(params[:id]), params[:resolve]))
  end

end
