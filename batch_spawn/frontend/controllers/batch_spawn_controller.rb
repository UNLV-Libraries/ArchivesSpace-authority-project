class BatchSpawnController < ApplicationController

  set_access_control  "update_resource_record" => [:index,:spawn, :create]
									
  def index
  
  end
  
  					
  def create 
  
  Log.debug("ONE MOPRE TIME")
   accession_url = params[:target] 
   accession_id = accession_url.split('/').last
   
  Log.debug(accession_id)
   @resource = Resource.new(:title => I18n.t("resource.title_default", :default => ""))._always_valid!
   
   acc = Accession.find(accession_id, find_opts)
 Log.debug("HERE")
 Log.debug(acc)
 
   @resource.populate_from_accession(acc)
 Log.debug(@resource)
   flash.now[:info] = I18n.t("resource._frontend.messages.spawned", JSONModelI18nWrapper.new(:accession => acc))
   flash[:spawned_from_accession] = acc.id
   
    handle_crud(:instance => :resource,
                :on_invalid => ->(){
                  render action: "new"
                },
                :on_valid => ->(id){
                  redirect_to({
                                :controller => :resources,
                                :action => :edit,
                                :id => id
                              },
                              :flash => {:success => I18n.t("resource._frontend.messages.created", JSONModelI18nWrapper.new(:resource => @resource))})
                 })
  end
  def spawn
  
  Log.debug("starter")
   victims = params[:target] #Array.wrap(victims).map { |victim| { 'ref' => victim  } }
   
   @resource = Resource.new(:title => I18n.t("resource.title_default", :default => ""))._always_valid!

   acc = victims
 Log.debug("HERE")
 Log.debug(acc)
   @resource.populate_from_accession(acc)
   flash.now[:info] = I18n.t("resource._frontend.messages.spawned", JSONModelI18nWrapper.new(:accession => acc))
   flash[:spawned_from_accession] = acc.id
   
    handle_crud(:instance => :resource,
                :on_invalid => ->(){
                  render action: "new"
                },
                :on_valid => ->(id){
                  redirect_to({
                                :controller => :resources,
                                :action => :edit,
                                :id => id
                              },
                              :flash => {:success => I18n.t("resource._frontend.messages.created", JSONModelI18nWrapper.new(:resource => @resource))})
                 })
  end
  
end