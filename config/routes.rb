Ekylibre::Application.routes.draw do
  resource :session, :only => [:new, :create, :destroy] do
    member do
      match "renew", :via => [:get, :post]
    end
  end
  resource :company, :only => [] do
    collection do
      match "register", :via => [:get, :post]
    end
  end
  resource :myself, :path => "me", :only => [] do
    member do
      get :statistics
      match "change_password", :via => [:get, :post]
    end
  end
  resource :settings, :only => [:edit, :update] do
    member do
      get :about
      get :backups
      post :backup
      post :restore
      match "import", :via => [:get, :post]
    end
  end

  # Permits to use dynamic dashboards
  dashboards
  resource :dashboards, :only => [] do
    collection do
      get :list_my_future_events
      get :list_recent_events
      get :list_critic_stocks
      get :welcome
    end
  end
  # get "dashboards", :to => "dashboards#index", :as => :dashboard
  # match '/dashboards/:action', :controller => "dashboards", :via => :get, :as => :dashboard
  match '/toggle/side' => "interfacers#toggle_side"
  match '/toggle/submenu/:id' => "interfacers#toggle_submenu", :as => :toggle_submenu
  match '/toggle/tab/:id' => "interfacers#toggle_tab"

  get '/select-options-in/:source/:filter/for/:model/:id' => "interfacers#select_options", :as => :select_options
  match '/autocomplete/:model/:property' => "interfacers#autocomplete", :via => :get, :as => :autocomplete
  match '/intf/:action', :controller => :interfacers, :via => :get

  resources :help, :only => [:index, :show]

  namespace :admin do
    namespace :cells do
      resource :animal_pie_cell, :only => :show
      resource :animal_bar_cell, :only => :show
      resource :demo_bar_cell, :only => :show
      resource :demo_pie_cell, :only => :show
      resource :placeholder_cell, :only => :show

      resource :last_events_cell, :only => :show do
        get :list, :on => :collection
      end
      resource :last_animals_cell, :only => :show do
        get :list, :on => :collection
      end
    end
  end

  # Check that the id is an integer
  # constraints(:id => /[0-9]+/) do

  # resources :account_balances
  resources :accounts do
    collection do
      get :list
      get :list_journal_entry_lines
      get :list_reconciliation
      get :list_entities
      get :reconciliation
      unroll_all
      match "load", :via => [:get, :post]
    end
    member do
      match "mark", :via => [:get, :post]
      post :unmark
    end
  end
  resources :animals do
    collection do
      get :list
      get :list_events
      get :list_children
      unroll_all
    end
  end
  resources :animal_diagnostics do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_diseases do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_drugs do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_drug_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_events do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_event_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_groups do
    collection do
      get :list
      get :list_animals
      get :list_events
      unroll_all
    end
  end
  resources :animal_posologies do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_prescriptions do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_races do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_race_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :animal_treatments do
    collection do
      get :list
      unroll_all
    end
  end
  resources :areas do
    collection do
      get :list
      unroll_all
    end
  end
  resources :assets, :path => "financial_assets" do
    collection do
      get :list
      unroll_all
    end
    member do
      get :cede
      get :sell
      post :depreciate
      get :list_depreciations
    end
  end
  resources :asset_depreciations, :except => [:index, :show]
  resources :bank_statements do
    collection do
      get :list
      get :list_lines
      unroll_all
    end
    member do
      match "point", :via => [:get, :post]
    end
  end
  resources :cashes do
    collection do
      get :list
      get :list_deposits
      get :list_bank_statements
      unroll_all
    end
  end
  resources :cash_transfers do
    collection do
      get :list
      unroll_all
    end
  end
  # resources :cultivations
  # resources :currencies
  resources :custom_fields do
    collection do
      get :list
      get :list_choices
      unroll_all
    end
    member do
      post :up
      post :down
      post :sort
    end
  end
  resources :custom_field_choices do
    member do
      post :up
      post :down
    end
  end
  # resources :custom_field_data
  resources :delays do
    collection do
      get :list
      unroll_all
    end
  end
  resources :departments do
    collection do
      get :list
      unroll_all
    end
  end
  resources :deposits do
    collection do
      get :list
      get :list_payments
      get :list_depositable_payments
      get :list_unvalidateds
      unroll_all
      match "unvalidateds", :via => [:get, :post]
    end
  end
  # resources :deposit_lines
  resources :districts do
    collection do
      get :list
      unroll_all
    end
  end
  resources :document_templates do
    collection do
      get :list
      post :load
      unroll_all
    end
    member do
      get :print
      post :duplicate
    end
  end
  resources :documents do
    collection do
      get :print
      unroll_all
    end
  end
  resources :entities do
    collection do
      get :list
      get :list_observations
      get :list_subscriptions
      get :list_sales
      get :list_purchases
      get :list_outgoing_payments
      get :list_mandates
      get :list_incoming_payments
      get :list_events
      get :list_addresses
      get :list_cashes
      get :list_links
      unroll_all
      match "import", :via => [:get, :post]
      match "export", :via => [:get, :post]
      match "merge", :via => [:get, :post]
    end
  end
  resources :entity_addresses, :except => [:index, :show] do
    collection do
      unroll_all
    end
  end
  resources :entity_categories do
    collection do
      unroll_all
      get :list
      get :list_prices
    end
  end
  resources :entity_links, :except => [:index, :show]
  resources :entity_link_natures do
    collection do
      unroll_all
      get :list
    end
  end
  resources :entity_natures do
    collection do
      unroll_all
      get :list
    end
  end
  resources :establishments do
    collection do
      get :list
      unroll_all
    end
  end
  resources :events do
    collection do
      get :list
      get :change_minutes
      unroll_all
    end
  end
  resources :event_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :financial_years do
    collection do
      get :list
      get :list_account_balances
      get :list_asset_depreciations
      unroll_all
    end
    member do
      match "close", :via => [:get, :post]
      match :generate_last_journal_entry, :via => [:get, :post]
      post :compute_balances
      get :synthesis
    end
  end
  resources :incoming_deliveries do
    collection do
      get :list
      unroll_all
    end
    member do
      match "confirm", :via => [:get, :post]
    end
  end
  # resources :incoming_delivery_lines
  resources :incoming_delivery_modes do
    collection do
      get :list
      unroll_all
    end
  end
  resources :incoming_payments do
    collection do
      get :list
      get :list_sales
      unroll_all
    end
  end
  resources :incoming_payment_modes do
    collection do
      get :list
      unroll_all
    end
    member do
      post :up
      post :down
      post :reflect
    end
  end
  resources :incoming_payment_uses
  resources :inventories do
    collection do
      get :list
      get :list_lines
      get :list_lines_create
      get :list_lines_update
      unroll_all
    end
    member do
      match "reflect", :via => [:get, :post]
    end
  end
  # resources :inventory_lines
  resources :journals do
    collection do
      match "draft", :via => [:get, :post]
      match "bookkeep", :via => [:get, :put, :post]
      match "import", :via => [:get, :post]
      get :reports
      get :balance
      get :general_ledger
      get :list
      get :list_draft_lines
      get :list_mixed
      get :list_lines
      get :list_entries
      get :list_general_ledger
      unroll_all
    end
    member do
      match "close", :via => [:get, :post]
      match "reopen", :via => [:get, :post]
    end
  end
  resources :journal_entries do
    collection do
      get :list_lines
    end
  end
  resources :journal_entry_lines, :only => [:new, :create]
  resources :land_parcels do
    collection do
      get :list
      get :list_operations
      post :merge
      unroll_all
    end
    member do
      match "divide", :via => [:get, :post]
    end
  end
  resources :land_parcel_groups do
    collection do
      get :list
      unroll_all
    end
  end
  # resources :land_parcel_kinships
  # resources :listing_node_items
  resources :listing_nodes
  resources :listings do
    collection do
      get :list
      unroll_all
    end
    member do
      get :extract
      post :duplicate
      match "mail", :via => [:get, :post]
    end
  end
  resources :mandates do
    collection do
      get :list
      unroll_all
      match "configure", :via => [:get, :post]
    end
  end
  resources :observations
  resources :operations do
    collection do
      get :list
      get :list_lines
      get :list_uses
      get :list_unvalidateds
      unroll_all
      match "unvalidateds", :via => [:get, :post]
    end
  end
  resources :operation_lines, :only => [:new, :create]
  resources :operation_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :operation_uses
  resources :outgoing_deliveries do
    collection do
      get :list
      get :list_lines
      unroll_all
    end
  end
  # resources :outgoing_delivery_lines
  resources :outgoing_delivery_modes do
    collection do
      get :list
      unroll_all
    end
  end
  resources :outgoing_payments do
    collection do
      get :list
      get :list_purchases
      unroll_all
    end
  end
  resources :outgoing_payment_modes do
    collection do
      get :list
      unroll_all
    end
    member do
      post :up
      post :down
    end
  end
  resources :outgoing_payment_uses
  # resources :preferences
  resources :prices do
    collection do
      get :list
      match "export", :via => [:get, :post]
      match "import", :via => [:get, :post]
      get :find
      unroll_all
    end
  end
  resources :preferences do
    collection do
      get :list
      unroll_all
    end
  end
  resources :products do
    collection do
      get :list
      get :list_prices
      get :list_stocks
      get :list_stock_moves
      get :list_components
      unroll_all
    end
  end
  resources :product_categories do
    collection do
      get :list
      get :list_products
      unroll_all
    end
  end
  resources :product_components, :except => [:show, :index]
  resources :production_chains do
    collection do
      get :list
      unroll_all
    end
  end
  resources :production_chain_conveyors
  resources :production_chain_work_centers do
    member do
      get :play
      post :down
      post :up
      unroll_all
    end
  end
  # resources :production_chain_work_centers_uses
  resources :professions do
    collection do
      get :list
      unroll_all
    end
  end
  resources :purchase_lines, :except => [:index, :show]
  resources :purchase_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :purchases do
    collection do
      get :list
      get :list_lines
      get :list_undelivered_lines
      get :list_deliveries
      get :list_payment_uses
      unroll_all
    end
    member do
      post :correct
      post :propose
      post :invoice
      post :confirm
      post :abort
      post :refuse
    end
  end
  resources :roles do
    collection do
      get :list
      unroll_all
    end
  end
  resources :sale_lines, :except => [:index, :show] do
    collection do
      get :list
      get :detail
      unroll_all
    end
  end
  resources :sale_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :sales do
    resources :lines, :only => [:new, :create], :controller => :sale_lines
    collection do
      get :list
      get :list_undelivered_lines
      get :list_subscriptions
      get :list_payment_uses
      get :list_deliveries
      get :list_credits
      get :list_creditable_lines
      get :statistics
      get :contacts
      unroll_all
    end
    member do
      get :list_lines
      match "cancel", :via => [:get, :post]
      post :duplicate
      post :correct
      post :propose
      post :invoice
      post :confirm
      post :abort
      post :refuse
      post :propose_and_invoice
    end
  end
  resources :sequences do
    collection do
      get :list
      post :load
      unroll_all
    end
  end
  # resources :stock_moves
  resources :stock_transfers do
    collection do
      get :list
      get :list_confirm
      unroll_all
      match "confirm_all", :via => [:get, :post]
    end
    member do
      match "confirm", :via => [:get, :post]
    end
  end
  resources :stocks do
    collection do
      get :list
      unroll_all
    end
  end
  resources :subscription_natures do
    collection do
      get :list
      unroll_all
    end
    member do
      post :increment
      post :decrement
    end
  end
  resources :subscriptions do
    collection do
      get :list
      unroll_all
      get :coordinates
      get :message
    end
  end
  # resources :tax_declarations
  resources :taxes do
    collection do
      get :list
      unroll_all
    end
  end
  resources :tools do
    collection do
      get :list
      get :list_operations
      unroll_all
    end
  end
  resources :tool_natures do
    collection do
      get :list
      unroll_all
    end
  end
  resources :trackings do
    collection do
      get :list_stocks
      get :list_sale_lines
      get :list_purchase_lines
      get :list_operation_lines
      unroll_all
    end
  end
  # resources :tracking_states
  resources :transports do
    collection do
      get :list
      get :list_deliveries
      get :list_transportable_deliveries
      unroll_all
      # match "deliveries", :via => [:get, :post]
      # match "delivery_delete", :via => [:get, :post]
    end
  end
  # resources :transfers
  resources :units do
    collection do
      get :list
      post :load
      unroll_all
    end
  end
  resources :users do
    collection do
      get :list
    end
    member do
      post :lock
      post :unlock
    end
  end
  resources :warehouses do
    collection do
      get :list
      get :list_stocks
      get :list_stock_moves
      unroll_all
    end
  end
  # end
  match "/dashboards" => "dashboards#index", :as => "admin"

  root :to => "dashboards#index"
end
