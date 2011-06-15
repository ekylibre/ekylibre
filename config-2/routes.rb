ActionController::Routing::Routes.draw do |map|

  map.resource :session, :only=>[:new, :create, :destroy], :member=>{:renew=>[:get, :post]}
  map.resource :company, :only=>[], :collection=>{:register=>[:get, :post]}

  map.with_options(:path_prefix => '/:company') do |company|
    company.resource :myself, :as=>"me", :only=>[], :member=>{:statistics=>:get, :change_password=>[:get, :post]}
    company.resources :dashboards, :only=>[], :collection=>{:welcome=>:get}
    # Permits to use dynamic dashboards
    company.dashboard '/dashboards/:action', :controller=>"dashboards", :conditions=>{:method=>:get}
    company.toggle_side '/toggle/side', :controller=>"interfacers", :action=>"toggle_side"
    company.toggle_submenu '/toggle/submenu/:id', :controller=>"interfacers", :action=>"toggle_submenu"
    company.toggle_tab '/toggle/tab/:id', :controller=>"interfacers", :action=>"toggle_tab"
    # company.resources :interfacers, :only=>[], :collection=>{:collected_account_dyli=>:get, :account_dyli=>:get, :entities=>:get, :paid_account=>:get}
    company.interfacer '/intf/:action', :controller=>:interfacers, :conditions=>{:method=>:get}
    company.resources :help, :only=>[:index, :show]
    # company.help '/help', :controller=>:help, :action=>:search
    # company.search_help '/help/:article', :controller=>:help, :action=>:search

    company.resources :account_balances
    company.resources :accounts, :collection=>{:list=>:get, :list_journal_entry_lines=>:get, :list_reconciliation=>:get, :list_entities=>:get, :load=>[:get, :post], :mark=>[:get, :post]}, :member=>{:unmark=>[:get, :post]}
    company.resources :areas, :collection=>{:list=>:get}
    company.resources :bank_statements, :collection=>{:list=>:get, :list_lines=>:get}, :member=>{:point=>[:get, :post]}
    company.resources :cashes, :collection=>{:list=>:get, :list_deposits=>:get, :list_bank_statements=>:get}
    company.resources :cash_transfers, :collection=>{:list=>:get}
    company.resources :contacts
    company.resources :cultivations
    company.resources :currencies
    company.resources :custom_fields, :collection=>{:list=>:get, :list_choices=>:get}, :member=>{:sort=>:post}
    company.resources :custom_field_choices, :member=>{:up=>:post, :down=>:post}
    company.resources :custom_field_data
    company.resources :delays, :collection=>{:list=>:get}
    company.resources :departments, :collection=>{:list=>:get}
    company.resources :deposits, :collection=>{:list=>:get, :list_payments=>:get, :list_depositable_payments=>:get, :unvalidateds=>:get, :list_unvalidateds=>:get}
    company.resources :deposit_lines
    company.resources :districts, :collection=>{:list=>:get}
    company.resources :document_templates, :collection=>{:list=>:get, :load=>:post}, :member=>{:print=>:get, :duplicate=>:post}
    company.resources :documents, :collection=>{:print=>:get}
    company.resources :entities, :collection=>{:list=>:get, :list_observations=>:get, :list_subscriptions=>:get, :list_sales=>:get, :list_purchases=>:get, :list_outgoing_payments=>:get, :list_mandates=>:get, :list_incoming_payments=>:get, :list_events=>:get, :list_contacts=>:get, :list_cashes=>:get, :list_links=>:get, :import=>[:get, :post], :export=>[:get, :post], :merge=>[:get, :post]}
    company.resources :entity_categories, :collection=>{:list=>:get, :list_prices=>:get}
    company.resources :entity_links, :except=>[:index, :show]
    company.resources :entity_link_natures, :collection=>{:list=>:get}
    company.resources :entity_natures, :collection=>{:list=>:get}
    company.resources :establishments, :collection=>{:list=>:get}
    company.resources :events, :collection=>{:list=>:get, :change_minutes=>:get}
    company.resources :event_natures, :collection=>{:list=>:get}
    company.resources :financial_years, :collection=>{:list=>:get}, :member=>{:close=>[:get, :post]}
    company.resources :incoming_deliveries, :collection=>{:list=>:get}, :member=>{:confirm=>[:get, :post]} do |id|
      id.resources :lines, :controller=>"incoming_delivery_lines"
    end
    company.resources :incoming_delivery_modes, :collection=>{:list=>:get}
    company.resources :incoming_payments, :collection=>{:list=>:get, :list_sales=>:get}
    company.resources :incoming_payment_modes, :collection=>{:list=>:get}, :member=>{:up=>:post, :down=>:post, :reflect=>:post}
    company.resources :incoming_payment_uses
    company.resources :inventories, :collection=>{:list=>:get, :list_lines_create=>:get, :list_lines_update=>:get}, :member=>{:reflect=>[:get, :post]} do |inventory|
      inventory.resources :lines, :controller=>"inventory_lines"
    end
    company.resources :journals, :collection=>{:list=>:get, :draft=>[:get, :post], :list_draft_lines=>:get, :list_mixed=>:get, :list_lines=>:get, :list_entries=>:get}, :member=>{:close=>[:get, :post], :reopen=>[:get, :post]}
    company.resources :journal_entries, :collection=>{:list_lines=>:get}
    company.resources :journal_entry_lines, :only=>[:new, :create]
    company.resources :land_parcels, :collection=>{:list=>:get, :list_operations=>:get}, :member=>{:divide=>[:get, :post]}
    company.resources :land_parcel_groups, :collection=>{:list=>:get}
    company.resources :land_parcel_kinships
    company.resources :listing_node_items
    company.resources :listing_nodes
    company.resources :listings, :collection=>{:list=>:get}, :member=>{:extract=>:get, :duplicate=>:post, :mail=>[:get, :post]}
    company.resources :mandates, :collection=>{:list=>:get, :configure=>[:get, :post]}
    company.resources :observations    
    company.resources :operations, :collection=>{:list=>:get, :list_lines=>:get, :list_uses=>:get, :unvalidateds=>[:get, :post]}
    company.resources :operation_lines, :only=>[:new, :create]
    company.resources :operation_natures, :collection=>{:list=>:get}
    company.resources :operation_uses
    company.resources :outgoing_deliveries, :collection=>{:list=>:get} do |od|
      od.resources :lines, :controller=>"outgoing_delivery_lines"
    end
    company.resources :outgoing_delivery_modes, :collection=>{:list=>:get}
    company.resources :outgoing_payments, :collection=>{:list=>:get, :list_purchases=>:get}
    company.resources :outgoing_payment_modes, :collection=>{:list=>:get}, :member=>{:up=>:post, :down=>:post}
    company.resources :outgoing_payment_uses
    company.resources :preferences
    company.resources :prices, :collection=>{:list=>:get, :export=>[:get, :post], :import=>[:get, :post], :find=>:get}
    company.resources :products, :collection=>{:list=>:get, :list_prices=>:get, :list_stocks=>:get, :list_stock_moves=>:get, :list_components=>:get}
    company.resources :product_categories, :collection=>{:list=>:get, :list_products=>:get}
    company.resources :product_components, :except=>[:show, :index]
    company.resources :production_chains, :collection=>{:list=>:get} do |pc|
      pc.resources :conveyors, :controller=>"production_chain_conveyors"
      pc.resources :work_centers, :controller=>"production_chain_work_centers"
      pc.resources :work_center_uses, :controller=>"production_chain_work_centers_uses"
    end
    company.resources :professions, :collection=>{:list=>:get}
    company.resources :purchase_lines, :except=>[:index, :show]
    company.resources :purchases, :collection=>{:list=>:get, :list_lines=>:get, :list_undelivered_lines=>:get, :list_deliveries=>:get, :list_payment_uses=>:get}, :member=>{:correct=>:post, :propose=>:post, :invoice=>:post, :confirm=>:post, :abort=>:get, :refuse=>:post, :cancel=>[:get, :post]}
    company.resources :roles, :collection=>{:list=>:get}
    company.resources :sale_lines, :except=>[:index, :show], :collection=>{:list=>:get, :detail=>:get}
    company.resources :sale_natures, :collection=>{:list=>:get}
    company.resources :sales, :collection=>{:list=>:get, :list_lines=>:get, :list_undelivered_lines=>:get, :list_subscriptions=>:get, :list_payment_uses=>:get, :list_deliveries=>:get, :list_credits=>:get, :list_creditable_lines=>:get, :statistics=>:get, :contacts=>[:get]}, :member=>{:duplicate=>:post, :correct=>:post, :propose=>:post, :invoice=>:post, :confirm=>:post, :abort=>:get, :refuse=>:post, :propose_and_invoice=>:post}
    company.resources :sequences, :collection=>{:list=>:get, :load=>:post}
    company.resources :stock_moves
    company.resources :stock_transfers, :collection=>{:list=>:get, :list_confirm=>:get, :confirm_all=>[:get, :post]}, :member=>{:confirm=>[:get, :post]}
    company.resources :stocks, :collection=>{:list=>:get}
    company.resources :subscription_natures, :collection=>{:list=>:get}, :member=>{:increment=>:post, :decrement=>:post}
    company.resources :subscriptions, :collection=>{:list=>:get, :coordinates=>:get, :message=>:get}
    company.resources :tax_declarations
    company.resources :taxes, :collection=>{:list=>:get}
    company.resources :tools, :collection=>{:list=>:get, :list_operations=>:get}
    company.resources :trackings, :collection=>{:list_stocks=>:get, :list_sale_lines=>:get, :list_purchase_lines=>:get, :list_operation_lines=>:get}
    company.resources :tracking_states
    company.resources :transports, :collection=>{:list=>:get, :list_deliveries=>:get, :deliveries=>[:get, :post], :delivery_delete=>[:get, :post]}
    company.resources :transfers
    company.resources :units, :collection=>{:list=>:get, :load=>:post}
    company.resources :users, :collection=>{:list=>:get}, :member=>{:lock=>:post, :unlock=>:post}
    company.resources :warehouses, :collection=>{:list=>:get, :list_stocks=>:get, :list_stock_moves=>:get}

    company.company_root "", :controller=>"dashboards", :action=>:general
  end


  # The priority is based upon order of creation: 
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  # map.connect ':company/:controller/:action/:id.:format'
  # map.connect ':company/:controller/:action/:id'
  # map.connect ':company/:controller/:action.:format'
  # map.connect ':company', :controller=>"company"
  # map.connect ':controller/:action', :controller=>'company', :action=>'index'
  # # map.connect '*path', :controller=>"company", :action=>"unknown_action"
  # map.connect 'authentication/:action', :controller=>'authentication', :action=>/(login|register)/
  # map.connect 'application/:action', :controller=>'application'

  # map.connect '/:company', :controller=>"dashboards"
  map.root :controller => "dashboards", :action=>:general
end
