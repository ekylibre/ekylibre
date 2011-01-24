Ekylibre::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':company/:controller(/:action(/:id(.:format)))', :company=>/\w+/
  match ':company', :to=>"company#index", :company=>/\w+/
  match 'authentication(/:action)', :controller=>'authentication'
  match 'application(/:action)', :controller=>'application'

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "company#index"
end
