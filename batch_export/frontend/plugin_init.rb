Rails.application.config.after_initialize do

    JobsController.class_eval do
	
		#include IdentifierFilter
		 def new
			@job = JSONModel(:job).new._always_valid!
			@job_types = job_types
			@import_types = import_types 
			 # CUSTOM CHANGE FOR BATCH EXPORT
			@batch_export_types = batch_export_types 
			Log.debug("HERE")
			Log.debug(@batch_export_types)
			@report_data = JSONModel::HTTP::get_json("/reports")
		  end
		  
		  # CUSTOM CHANGE FOR BATCH EXPORT
		  def batch_export_types
			Job.available_batch_export_types.map {|e| [I18n.t("batch_export_job.batch_export_type_#{e['name']}"), e['name']]}
		  end

		  def create

			job_data = case params['job']['job_type']
					   when 'find_and_replace_job'
						 params['find_and_replace_job'].reject{|k,v| k === '_resolved'}
					   when 'print_to_pdf_job'
						 params['print_to_pdf_job'].reject{|k,v| k === '_resolved'}
					   when 'batch_export_job'
						 params['batch_export_job'].reject{|k,v| k === '_resolved'}
					   when 'report_job' 
						 params['report_job']
					   when 'import_job'
						 params['import_job']
					   end

			Log.debug("HERsdsaE")
			Log.debug(params['job']['job_type'])
			Log.debug(job_data)
			Log.debug( Hash[Array(params['files']).reject(&:blank?).map {|file| [file.original_filename, file.tempfile]}])
			Log.debug( params['job']['job_params'])
   

			job_data["repo_id"] ||= session[:repo_id]
			begin
			  job = Job.new(params['job']['job_type'], job_data, Hash[Array(params['files']).reject(&:blank?).map {|file| [file.original_filename, file.tempfile]}], params['job']['job_params'])

			rescue JSONModel::ValidationException => e

			  @exceptions = e.invalid_object._exceptions
			  @job = e.invalid_object
			  @job_types = job_types
			  @import_types = import_types
			  # CUSTOM CHANGE FOR BATCH EXPORT
			  @batch_export_types = batch_export_types

			Log.debug(@batch_export_types)
			  if params[:iframePOST] # IE saviour. Render the form in a textarea for the AjaxPost plugin to pick out.
				return render_aspace_partial :partial => "jobs/form_for_iframepost", :status => 400
			  else
				return render_aspace_partial :partial => "jobs/form", :status => 400
			  end
			end

			if params[:iframePOST] # IE saviour. Render the form in a textarea for the AjaxPost plugin to pick out.
			  render :text => "<textarea data-type='json'>#{job.upload.to_json}</textarea>"
			else
			  render :json => job.upload
			end
		  end
		  
    end
	Job.class_eval do
	def initialize(job_type, job_data, files_to_import, job_params = {})

			Log.debug("WINNER21")
		if job_type == 'import_job'
		  job_data[:filenames] = files_to_import.keys
		end

		@job = JSONModel(:job).from_hash(:job_type => job_type,
										 :job => job_data,
										 :job_params =>  ASUtils.to_json(job_params) )

		@files = files_to_import
	  end
	  # CUSTOM CHANGE FOR BATCH EXPORT
	  def self.available_batch_export_types
		Log.debug("WHATthe")
		#Log.debug(JSONModel(:job).uri_for("batch_export_types"))
		#JSONModel::HTTP.get_json(JSONModel(:job).uri_for("batch_export_types"))
		[
				{
					"name" => "accession_csv",
					"description" => "Export CSV records"
				},
				{
					"name" => "eac",
					"description" => "Export EAD records"
				},
				{
					"name" => "ead",
					"description" => "Export EAD records"
				},
				{
					"name" => "marcxml",
					"description" => "Export EAD records"
				}
		]
	  end
	  
				  
		  def upload
			unless @files.empty?

			Log.debug("HARRYPOTTER")
			  upload_files = @files.each_with_index.map {|file, i|
				(original_filename, stream) = file
				["files[#{i}]", UploadIO.new(stream, "text/plain", original_filename)]
			  }

			  response = JSONModel::HTTP.post_form("#{JSONModel(:job).uri_for(nil)}_with_files",
												   Hash[upload_files].merge('job' => @job.to_json),
												   :multipart_form_data)

			  ASUtils.json_parse(response.body)

			else

			Log.debug("Chivkendinner")
			  @job.save
			 uri = "/repositories/:repo_id/jobs/:id/export"

			Log.debug(uri)
			  {:uri => @job.uri}
			end

		  end

    end
	 # force load our JSONModels so the are registered rather than lazy initialised
	 # we need this for parse_reference to work
	 JSONModel(:batch_export_job)
end