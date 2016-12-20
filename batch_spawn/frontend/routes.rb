ArchivesSpace::Application.routes.draw do
	 match('/plugins/batch_spawn' => 'batch_spawn#index', :via => [:get])
	 match('/plugins/batch_spawn/batch_spawn' => 'batch_spawn#batch_spawn', :via => [:post])
end