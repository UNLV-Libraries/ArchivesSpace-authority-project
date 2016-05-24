require 'srusearcher'
require 'opensearcher'
require 'securerandom'
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
class LcnafController < ApplicationController

  set_access_control "update_agent_record" => [:search, :index, :import]

  def index
    @page = 1
    @records_per_page = 10

    flash.now[:info] = I18n.t("plugins.lcnaf.messages.service_warning")
  end


  def search
    results = do_search(params)

    render :json => results.to_json
  end


  def import
    if params[:lcnaf_service] == 'oclc'
      marcxml_file = searcher.results_to_marcxml_file(SRUQuery.lccn_search(params[:lccn]))
    elsif params[:lcnaf_service] == 'lcnaf' || params[:lcnaf_service] == 'lcsh'
      marcxml_file = searcher.results_to_marcxml_file(params[:lccn])
    end

    begin
		 #If params lcnaf do agents else do subjects
		 if params[:lcnaf_service] == 'lcnaf'
		  job = Job.new("import_job", {
						  "import_type" => "marcxml_agents",
						  "jsonmodel_type" => "import_job"
						  },
						{"lcnaf_import_#{SecureRandom.uuid}" => marcxml_file})
							
		elsif params[:lcnaf_service] == 'lcsh'
			job = Job.new("import_job", {
						  "import_type" => "marcxml_subjects",
						  "jsonmodel_type" => "import_job"
						  },
						{"lcnaf_import_#{SecureRandom.uuid}" => marcxml_file})
		else 
		  job = Job.new("import_job", {
						  "import_type" => "marcxml_lcnaf_subjects_and_agents",
						  "jsonmodel_type" => "import_job"
						  },
						{"lcnaf_import_#{SecureRandom.uuid}" => marcxml_file})
		end 
	
      response = job.upload
      render :json => {'job_uri' => url_for(:controller => :jobs, :action => :show, :id => response['id'])}
    rescue
      render :json => {'error' => $!.to_s}
    end
  end


  private

  def do_search(params)
    case params[:lcnaf_service]
    when 'oclc'
      query = SRUQuery.name_search(params[:family_name], params[:given_name]  )
      searcher.search(query, params[:page].to_i, params[:records_per_page].to_i)
    when 'lcnaf', 'lcsh'
      searcher.search(params[:family_name], params[:page].to_i, params[:records_per_page].to_i)
    end
  end


  def searcher
    case params[:lcnaf_service]
    when 'oclc'
      SRUSearcher.new('http://alcme.oclc.org/srw/search/lcnaf')
    when  'lcnaf'
      OpenSearcher.new('http://id.loc.gov/search/', 'http://id.loc.gov/authorities/names')
    when 'lcsh'
      OpenSearcher.new('http://id.loc.gov/search/', 'http://id.loc.gov/authorities/subjects')
    end
  end
end