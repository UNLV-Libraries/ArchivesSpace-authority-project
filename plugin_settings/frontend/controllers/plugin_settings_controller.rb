
class PluginSettingsController < ApplicationController

  skip_before_filter :unauthorised_access
  def index
    @plugin_setting = JSONModel(:plugin_setting).new._always_valid!
  end
   

  def update
	 handle_crud(:instance => :plugin_setting,
                :obj => JSONModel(:plugin_setting).find(params[:id]),
                :params_check => ->(obj, params){
					
                },
                :on_invalid => ->(){
                  flash[:error] = I18n.t("plugins.plugin_settings._frontend.messages.error_update")
                  render :action => "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("plugins.plugin_settings._frontend.messages.updated")
                  redirect_to :action => :index
                })
  end
  def create

    handle_crud(:instance => :plugin_setting,
                :params_check => ->(obj, params){
                },
                :on_invalid => ->(){
                  flash[:error] = I18n.t("plugins.plugin_settings._frontend.messages.error_create")
                  render :action => "index"
                },
                :on_valid => ->(id){
                  if session[:user]
                    flash[:success] = "#{I18n.t("plugins.plugin_settings._frontend.messages.created")}"
                    redirect_to :action => :index
                  end
                })
  end
end

