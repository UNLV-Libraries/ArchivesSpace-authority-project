class ArchivesSpaceService < Sinatra::Base

	Endpoint.post('/overlay_requests/agent')
		.description("Carry out an overlay request against Agent records")
		.params(["overlay_request",
				  JSONModel(:overlay_request), "A merge request",
				  :body => true])
		.permissions([:merge_agent_record])
		.permissions([:update_agent_record])
		.returns([200, :updated]) \
	do
		#turn string into accessable hash
		target, victims = parse_references(params[:overlay_request])
		
		
		#compare types to make sure types are the same
		if (victims.map {|r| r[:type]} + [target[:type]]).any? {|type| !AgentManager.known_agent_type?(type)}
			raise BadParamsException.new(:overlay_request => ["Agent merge request can only merge agent records"])
		end
		
		#sort out victim data to parse
		agent_model = AgentManager.model_for(target[:type]) 
		victim_obj = agent_model.to_jsonmodel(victims[0][:id])
		
		#data to overlay from first victim  
		authority_id = victim_obj['names'][0]['authority_id']
		
		#since target data is stored->merge the victim 
		agent_model.get_or_die(target[:id]).assimilate(victims.map {|v|
                                                    AgentManager.model_for(v[:type]).get_or_die(v[:id])
                                                  })
		
		#sort out target data to parse
		obj = agent_model.get_or_die(target[:id])
		target_obj = agent_model.to_jsonmodel(target[:id])
		
		#add to target data to victim 
		target_obj['names'][0]['authority_id'] = authority_id;
		
		#update target to database
		handle_overlay_update(obj, target_obj)
        #handle_update(agent_model,target[:id], target_obj)
		
		json_response(:status => "OK")
	end
	
	Endpoint.post('/overlay_requests/subject')
		.description("Carry out an overlay request against Agent records")
		.params(["overlay_request",
				  JSONModel(:overlay_request), "A merge request",
				  :body => true])
		.permissions([:merge_subject_record])
		.permissions([:update_subject_record])
		.returns([200, :updated]) \
	do
		#turn string into accessable hash
		target, victims = parse_references(params[:overlay_request])
		
		
		#compare types to make sure types are the same
		ensure_type(target, victims, 'subject')
		
		#sort out victim data to parse
		victim_obj = Subject.to_jsonmodel(victims[0][:id])
		
		#data to overlay from first victim  
		authority_id = victim_obj['authority_id']
		
		#since target data is stored->merge the victim 
		Subject.get_or_die(target[:id]).assimilate(victims.map {|v| Subject.get_or_die(v[:id])})
		
		#sort out target data to parse
		obj = Subject.get_or_die(target[:id])
		target_obj = Subject.to_jsonmodel(target[:id])
		
		#add to target data to victim 
		target_obj['authority_id'] = authority_id;
		
		#update target to database
		handle_overlay_update(obj, target_obj)
        #handle_update(agent_model,target[:id], target_obj)
		
		json_response(:status => "OK")
	end
	
private 

	# Override handle_update and update_from_json to solve nil:NilClass error 
	def handle_overlay_update(obj, json,extra_values = {}, apply_nested_records = true)
		
		if obj.values.has_key?(:suppressed)
			if obj[:suppressed] == 1
			  raise ReadOnlyException.new("Can't update an object that has been suppressed")
			end

			# No funny business.  If you want to set this you need to do it via the
			# dedicated controller.
			json["suppressed"] = false
		  end


		schema_defined_properties = json.class.schema["properties"].map{|prop, defn|
			prop if !defn['readonly']
		}.compact
	
		updated = Hash[schema_defined_properties.map {|property| [property, nil]}].
			merge(json.to_hash).
			merge(ASUtils.keys_as_strings(extra_values))
			
		  obj.class.strict_param_setting = false

		  obj.update(obj.class.prepare_for_db(json.class, updated).
					  merge(:user_mtime => Time.now,
							:last_modified_by => RequestContext.get(:current_username)))

		  if apply_nested_records
			obj.apply_nested_records(json)
		  end

		  obj.class.fire_update(json, obj)
		
		  updated_response(obj, json)
	end
	
	def ensure_type(target, victims, type)
		if (victims.map {|r| r[:type]} + [target[:type]]).any? {|t| t != type}
		  raise BadParamsException.new(:merge_request => ["This merge request can only merge #{type} records"])
		end
	end
end