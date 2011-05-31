ActionController::Routing::Routes.draw do |map|

  map.resources :sessions

  map.with_options(:path_prefix => '/general') do |general|
    general.resource :company
    general.resources :departments
    general.resources :document_templates
    general.resources :establishments
    general.resources :roles
    general.resources :units
    general.resources :users
    general.resources :listings
    general.resources :listing_nodes
    general.resources :listing_node_items
    general.resources :sequences
    general.resources :transfers
    general.resources :documents
    general.resources :preferences
  end

  map.with_options(:path_prefix => '/relations') do |relations|
    relations.resources :areas
    relations.resources :contacts
    relations.resources :custom_fields do |cf|
      cf.resources :choices, :controller=>"custom_field_choices"
      cf.resources :data, :controller=>"custom_field_data"
    end
    relations.resources :districts
    relations.resources :entities
    relations.resources :entity_categories
    relations.resources :entity_links
    relations.resources :entity_link_natures
    relations.resources :entity_natures
    relations.resources :events
    relations.resources :event_natures
    relations.resources :mandates
    relations.resources :observations    
    relations.resources :subscriptions
    relations.resources :subscription_natures    
  end  
  

  map.with_options(:path_prefix => '/accountancy') do |accountancy|
    accountancy.resources :accounts
    accountancy.resources :account_balances
    accountancy.resources :bank_statements
    accountancy.resources :currencies
    accountancy.resources :financial_years
    accountancy.resources :journals
    accountancy.resources :journal_entries do |je|
      je.resources :lines, :controller=>"journal_entry_lines"
    end
  end  

  map.with_options(:path_prefix => '/finances') do |finances|
    finances.resources :cashes
    finances.resources :cash_transfers 
    finances.resources :deposits
    finances.resources :deposit_lines
    finances.resources :incoming_payments
    finances.resources :incoming_payment_modes
    finances.resources :incoming_payment_uses
    finances.resources :outgoing_payments
    finances.resources :outgoing_payment_modes
    finances.resources :outgoing_payment_uses
    finances.resources :taxes
    finances.resources :tax_declarations
  end

  map.with_options(:path_prefix => '/management') do |management|
    management.resources :delays
    management.resources :incoming_deliveries do |id|
      id.resources :lines, :controller=>"incoming_delivery_lines"
    end
    management.resources :incoming_delivery_modes
    management.resources :inventories do |inventory|
      inventory.resources :lines, :controller=>"inventory_lines"
    end
    management.resources :outgoing_deliveries do |od|
      od.resources :lines, :controller=>"outgoing_delivery_lines"
    end
    management.resources :outgoing_delivery_modes
    management.resources :prices
    management.resources :products
    management.resources :product_categories
    management.resources :product_components
    management.resources :purchases do |purchases|
      purchases.resources :lines, :controller=>"purchase_lines"
    end
    management.resources :sales do |sales|
      sales.resources :lines, :controller=>"sale_lines"
    end
    management.resources :sale_natures
    management.resources :stocks do |stocks|
      stocks.resources :moves, :controller=>"stock_moves"
    end
    management.resources :stock_transfers
    management.resources :trackings
    management.resources :tracking_states
    management.resources :transports
    management.resources :warehouses
  end

  map.with_options(:path_prefix => '/production') do |production|
    production.resources :cultivations
    production.resources :land_parcels
    production.resources :land_parcel_groups
    production.resources :land_parcel_kinships
    production.resources :operations do |operations|
      operations.resources :lines, :controller=>"operation_lines"
    end
    production.resources :operation_natures
    production.resources :operation_uses
    production.resources :tools
    production.resources :production_chains do |pc|
      pc.resources :conveyors, :controller=>"production_chain_conveyors"
      pc.resources :work_centers, :controller=>"production_chain_work_centers"
      pc.resources :work_center_uses, :controller=>"production_chain_work_centers_uses"
    end
  end

  map.with_options(:path_prefix => '/resources') do |res|
    res.resources :professions    
  end


  # The priority is based upon order of creation: 
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':company/:controller/:action/:id.:format'
  map.connect ':company/:controller/:action/:id'
  map.connect ':company/:controller/:action.:format'
  map.connect ':company', :controller=>"company"
  map.connect ':controller/:action', :controller=>'company', :action=>'index'
  # map.connect '*path', :controller=>"company", :action=>"unknown_action"
  map.connect 'authentication/:action', :controller=>'authentication', :action=>/(login|register)/
  map.connect 'application/:action', :controller=>'application'

  map.root :controller => "company"
end
