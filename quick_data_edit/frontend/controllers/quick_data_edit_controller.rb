class QuickDataEditController < ApplicationController

	set_access_control "update_resource_record" => [:index, :quick_data_edit, :qde]
	
  def index
  
  end
	
  
  def quick_data_edit
    flash.clear
	#params 

	Log.debug("So the recokning... heh")
	Log.debug( params["quick_data_edit"]["target"])
	Log.debug( params["target"])
	#get the resource id for search i.e "target"=>"/repositories/2/resources/172"
	resource_id = params["quick_data_edit"]["target"].split('/').last
	
	Log.debug("So the recokning begins")
	Log.debug(resource_id)
	
	#use the resource tree to find children
	response = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/resources/#{resource_id}/tree")
	
	Log.debug("die hard")
	Log.debug(response)
	Log.debug("riseeee riseee my children of the night")
	
	counter = 0
	archival_record_children = JSONModel(:archival_record_children).new;
	Log.debug("one now 11 for the later")
	Log.debug(archival_record_children)
	
	children = response["children"]
	Log.debug(response["children"])
	@archival_objects = {"children"=>Array.new}
	
	children.each do |child|
		child_id = child["id"]
		@archival_objects["children"].push(clean_archival_object(child_id))
		counter += 1

	end
	#@archival_objects  = {"children"=>{"0"=>{"level"=>"class", "other_level"=>"", "publish"=>true, "title"=>"", "component_id"=>"", "language"=>"", "dates"=>{"expression"=>"", "date_type"=>"", "label"=>"", "begin"=>"", "end"=>""}, "extents"=>{"0"=>{"portion"=>"", "number"=>"", "extent_type"=>"", "container_summary"=>"", "physical_details"=>"", "dimensions"=>""}}, "instances"=>{"0"=>{"instance_type"=>"", "container"=>{"type_1"=>"", "indicator_1"=>"", "barcode_1"=>"", "type_2"=>"", "indicator_2"=>"", "type_3"=>"", "indicator_3"=>""}}}, "notes"=>[{"type"=>"", "jsonmodel_type"=>"note_singlepart", "label"=>"", "content"=>{"0"=>""}}]}}}
	#@archival_objects  = {"children"=>["level"=>"class" , "other_level"=>"", "publish"=>true, "title"=>"", "component_id"=>"", "language"=>"", "dates"=>["expression"=>"2005", "date_type"=>"", "label"=>"", "begin"=>"", "end"=>""]]}
	Log.debug(@archival_objects)
    # childs = JSONModel(:archival_record_children).from_hash({
     #   "children" => @archival_objects
     #})
	
	# Log.debug(childs)
	Log.debug("It")
	Log.debug(params)
	  
	#children_data = cleanup_params_for_schema(@archival_objects, JSONModel(:archival_record_children).schema)
	Log.debug("test")
	Log.debug(@archival_objects)
	#Log.debug(children_data)
	
    @parent = JSONModel(:archival_object).find(60453)
	 @children = ArchivalObjectChildren.from_hash(@archival_objects, false, true)
	#@children = ArchivalObjectChildren.from_hash(@archival_objects, false, true)
	
	Log.debug("Invest , never speculate")
	Log.debug(@children)
	
    @exceptions = []
	render "qde"
  end
  def qde
   # #MAY NOT BE NEEDED 
	# Log.debug("come up for air")
	# Log.debug("help")
	# Log.debug("come up for air")
	# Log.debug(params)
	
	# #Log.debug(response["id"])
	
	# #children = response["children"]
	# #Log.debug(children)
	# #Log.debug(children[0]["record_uri"])
	# #archival_object_id =children[0]["record_uri"].scan( /\d+$/ ).first
	# #Log.debug(archival_object_id)
	
	
	# #archival_object = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/archival_objects/#{archival_object_id}")
	
	# #Log.debug(archival_object)

	# #@archival_object["title"] = "Work for me now or pay the consequences ( plata o plomo)"
	
	# params[:opts] = {:instance => @archival_object}
	# #arojb = JSONModel(:archival_object).from_hash(archival_object)
	# Log.debug(@archival_object)
	# params.delete("quick_data_edit")
	# Log.debug("Light me up")
	# Log.debug(params)
	
	# params["archival_object"] = {"lock_version"=>"16", "parent"=>"", "resource"=>{"ref"=>"/repositories/2/resources/714"}, "position"=>0, "title"=>"Work for me now or pay the consequences ( plata o plomo)", "ref_id"=>"02abd081d8f415bdf71e5ef47fc22ae7", "component_id"=>"", "level"=>"file", "language"=>"", "repository_processing_note"=>"", "dates"=>{"0"=>{"lock_version"=>"0", "label"=>"Creation", "expression"=>"1941", "date_type"=>"single", "begin"=>"", "certainty"=>"", "era"=>"", "calendar"=>""}}, "instances"=>{"0"=>{"lock_version"=>"0", "instance_type"=>"mixed_materials", "container"=>{"lock_version"=>"0", "type_1"=>"Box", "indicator_1"=>"01", "barcode_1"=>"", "type_2"=>"", "indicator_2"=>"", "type_3"=>"", "indicator_3"=>"", "container_extent"=>"", "container_extent_type"=>"Linear Feet"}}}}
	
	# params["add_event"] = {"lock_version"=>""}
	# params["add_event_event_type"] = "accession"
	
	# Log.debug(params)
	# #Log.debug(arojb)
	# resource = @archival_object['resource']['_resolved']
    # parent = @archival_object['parent'] ? @archival_object['parent']['_resolved'] : false

	    # handle_crud(:instance => :archival_object,
                # :obj => @archival_object,
                # :on_invalid => ->(){ 
					# Log.debug("explain why") 
					# Log.debug(@exceptions) 
					# Log.debug(@record_is_stale) 
					# render "qde"
					# },
                # :on_valid => ->(id){
					# Log.debug("Llama la attencion")
                  # success_message = parent ?
                    # I18n.t("archival_object._frontend.messages.updated_with_parent", JSONModelI18nWrapper.new(:archival_object => @archival_object, :resource => @archival_object['resource']['_resolved'], :parent => parent)) :
                    # I18n.t("archival_object._frontend.messages.updated", JSONModelI18nWrapper.new(:archival_object => @archival_object, :resource => @archival_object['resource']['_resolved']))
                  # flash.now[:success] = success_message

                  # @refresh_tree_node = true

                  # render "qde"
                # })

    # #handle_crud(:instance => :archival_object,
	# #			:obj => arojb,
     # #           :on_invalid => ->(){ Log.debug ("HEY LOOK THIS DINDT WORKED SOMEHOE ")},
      # #          :on_valid => ->(id){ Log.debug ("HEY LOOK THIS  WORKED SOMEHOE ") })
	  
	# #@parent = Resource.find(response["id"])
	# #Log.debug("nails in my head")
	# #Log.debug(@parent)
	# #@children = ResourceChildren.new
   # # @exceptions = []
	# #render_aspace_partial :partial => "shared/rde"
	
	# render "qde"
  end
  
  private
  
  def clean_archival_object(child_id)
		archival_object = JSONModel(:archival_object).find(child_id, find_opts).to_hash
		
		archival_object["language"] = "eng"
		archival_object["extents"][0] = {"portion"=>"", "number"=>"", "extent_type"=>"", "container_summary"=>"", "physical_details"=>"", "dimensions"=>""}
		archival_object.delete("notes");
		#Delete all non archival_record_children
		archival_object.delete("lock_version")
		archival_object.delete("position")
		archival_object.delete("ref_id")
		archival_object.delete("display_string")
		archival_object.delete("restrictions_apply")
		archival_object.delete("created_by")
		archival_object.delete("last_modified_by")
		archival_object.delete("create_time")
		archival_object.delete("user_mtime")
		archival_object.delete("system_mtime")
		archival_object.delete("suppressed")
		archival_object.delete("uri")
		archival_object.delete("repository")
		archival_object.delete("resource")
		archival_object.delete("_resolved")
		archival_object["dates"][0].delete("lock_version")
		archival_object["dates"][0].delete("created_by")
		archival_object["dates"][0].delete("create_time")
		archival_object["dates"][0].delete("user_mtime")
		archival_object["dates"][0].delete("last_modified_by")
		archival_object["dates"][0].delete("system_mtime")
		
		archival_object["instances"][0].delete("lock_version")
		archival_object["instances"][0].delete("created_by")
		archival_object["instances"][0].delete("last_modified_by")
		archival_object["instances"][0].delete("system_mtime")
		archival_object["instances"][0].delete("user_mtime")
		
		
		Log.debug("I believe in you")
		Log.debug(archival_object)
		archival_object["instances"][0]["container"].delete("created_by")
		archival_object["instances"][0]["container"].delete("last_modified_by")
		archival_object["instances"][0]["container"].delete("system_mtime")
		archival_object["instances"][0]["container"].delete("create_time")
		archival_object["instances"][0]["container"].delete("user_mtime")
		
		#h = { "a" => 100, "b" => 200, "c" => 300 }
		#h.delete_if {|key, value| key >= "b" }   #=> {"a"=>100}
		
		Log.debug("I believe in you")
		Log.debug(archival_object)
		
		archival_object
		
		
  end 
  
end