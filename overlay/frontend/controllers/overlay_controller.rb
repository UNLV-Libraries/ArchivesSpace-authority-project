class OverlayController < ApplicationController

  set_access_control "update_agent_record" => [:index, :overlay]
  set_access_control "update_subject_record" => [:index, :overlay]
									
  def index
  
  end
  
  def overlay
   merge_type = params[:target].split('/')

   handle_overlay(params[:victim],
				params[:target],
                merge_type[1].chomp("s"))
  end
  
  private
  
  def handle_overlay(victims, target_uri, merge_type)
    request = JSONModel(:overlay_request).new
    request.target = {'ref' => target_uri}
    request.victims = Array.wrap(victims).map { |victim| { 'ref' => victim  } }
	
    begin
      request.save(:record_type => merge_type)
      flash[:success] = I18n.t("#{merge_type}._frontend.messages.merged")

      resolver = Resolver.new(target_uri)
      redirect_to(resolver.view_uri)
    rescue ValidationException => e
      flash[:error] = e.errors.to_s
	  redirect_to({:action => :index})
    rescue RecordNotFound => e
      flash[:error] = I18n.t("errors.error_404")
	  redirect_to({:action => :index})
    end
  end
end