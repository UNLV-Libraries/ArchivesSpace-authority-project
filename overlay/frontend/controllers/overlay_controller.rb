
require 'logger'
class Log
  @@logger = Logger.new($stderr)
  def self.quiet_please
    @@logger.sev_threshold = Logger::FATAL
  end
  def self.exception(e)
    backtrace = e.backtrace.join("\n")
    @@logger.error("\n#{e}\n#{backtrace}")
  end
  def self.debug(s) @@logger.debug(s) end
  def self.info(s) @@logger.info(s) end
  def self.warn(s) @@logger.warn(s) end
  def self.error(s) @@logger.error(s) end
end

class OverlayController < ApplicationController

  set_access_control  "view_repository" => [:index, :overlay],
                      "update_agent_record" => [:overlay]
									
  def index
  
  end
  def overlay
   handle_overlay(params[:victim],
				params[:target],
                'agent')
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