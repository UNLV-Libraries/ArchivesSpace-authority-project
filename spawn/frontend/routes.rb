ArchivesSpace::Application.routes.draw do

  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|

    scope prefix do
      match('/plugins/spawn' => 'spawn#index', :via => [:get])
      match('/plugins/spawn/spawn' => 'spawn#spawn', :via => [:POST])
    end
  end
end