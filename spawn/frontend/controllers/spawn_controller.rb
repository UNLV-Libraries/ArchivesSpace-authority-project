class SpawnController < ApplicationController

	set_access_control "update_resource_record" => [:index, :spawn]
	
	def index
		@page = 1
		@records_per_page = 10
		
		flash.now[:info] = I18n.t("plugins.lcnaf.messages.service_warning")
	end
	
	def spawn
		render :json => params.to_json
	end
end