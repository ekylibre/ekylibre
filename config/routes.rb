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
  # resources :dashboards, :only => [] do
  #   collection do
  #     get :welcome
  #   end
  # end

  # Permits to use dynamic dashboards
  dashboards
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
      get :unroll
      get :unroll_charges
      get :unroll_client_thirds
      get :unroll_attorney_thirds
      get :unroll_supplier_thirds
      get :unroll_deposit_pending_payments
      get :unroll_banks
      get :unroll_cashes
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
      get :unroll
    end
  end
  resources :animal_diagnostics do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_diseases do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_drugs do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_drug_natures do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_events do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_event_natures do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_groups do
    collection do
      get :list
      get :list_animals
      get :list_events
      get :unroll
    end
  end
  resources :animal_posologies do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_prescriptions do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_races do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_race_natures do
    collection do
      get :list
      get :unroll
    end
  end
  resources :animal_treatments do
    collection do
      get :list
      get :unroll
    end
  end
  resources :areas do
    collection do
      get :list
      get :unroll
    end
  end
  resources :assets, :path => "financial_assets" do
    collection do
      get :list
      get :unroll
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
      get :unroll
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
      get :unroll
      get :unroll_bank_accounts
    end
  end
  resources :cash_transfers do
    collection do
      get :list
      get :unroll
    end
  end
  # resources :cultivations
  # resources :currencies
  resources :custom_fields do
    collection do
      get :list
      get :list_choices
      get :unroll
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
      get :unroll
    end
  end
  resources :departments do
    collection do
      get :list
      get :unroll
    end
  end
  resources :deposits do
    collection do
      get :list
      get :list_payments
      get :list_depositable_payments
      get :list_unvalidateds
      get :unroll
      match "unvalidateds", :via => [:get, :post]
    end
  end
  # resources :deposit_lines
  resources :districts do
    collection do
      get :list
      get :unroll
    end
  end
  resources :document_templates do
    collection do
      get :list
      post :load
      get :unroll
    end
    member do
      get :print
      post :duplicate
    end
  end
  resources :documents do
    collection do
      get :print
      get :unroll
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
      get :unroll_employees
      get :unroll
      match "import", :via => [:get, :post]
      match "export", :via => [:get, :post]
      match "merge", :via => [:get, :post]
    end
  end
  resources :entity_addresses
  resources :entity_categories do
    collection do
      get :unroll
      get :list
      get :list_prices
    end
  end
  resources :entity_links, :except => [:index, :show]
  resources :entity_link_natures do
    collection do
      get :unroll
      get :list
    end
  end
  resources :entity_natures do
    collection do
      get :unroll
      get :list
    end
  end
  resources :establishments do
    collection do
      get :list
      get :unroll
    end
  end
  resources :events do
    collection do
      get :list
      get :change_minutes
      get :unroll
    end
  end
  resources :event_natures do
    collection do
      get :list
      get :unroll
    end
  end
  resources :financial_years do
    collection do
      get :list
      get :list_account_balances
      get :list_asset_depreciations
      get :unroll
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
      get :unroll
    end
    member do
      match "confirm", :via => [:get, :post]
    end
  end
  # resources :incoming_delivery_lines
  resources :incoming_delivery_modes do
    collection do
      get :list
      get :unroll
    end
  end
  resources :incoming_payments do
    collection do
      get :list
      get :list_sales
      get :unroll
    end
  end
  resources :incoming_payment_modes do
    collection do
      get :list
      get :unroll
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
      get :unroll
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
      get :unroll
      get :unroll_banks
      get :unroll_cashes
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
      get :unroll
    end
    member do
      match "divide", :via => [:get, :post]
    end
  end
  resources :land_parcel_groups do
    collection do
      get :list
      get :unroll
    end
  end
  # resources :land_parcel_kinships
  # resources :listing_node_items
  resources :listing_nodes
  resources :listings do
    collection do
      get :list
      get :unroll
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
      get :unroll
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
      get :unroll
      match "unvalidateds", :via => [:get, :post]
    end
  end
  resources :operation_lines, :only => [:new, :create]
  resources :operation_natures do
    collection do
      get :list
      get :unroll
    end
  end
  resources :operation_uses
  resources :outgoing_deliveries do
    collection do
      get :list
      get :list_lines
      get :unroll
    end
  end
  # resources :outgoing_delivery_lines
  resources :outgoing_delivery_modes do
    collection do
      get :list
      get :unroll
    end
  end
  resources :outgoing_payments do
    collection do
      get :list
      get :list_purchases
      get :unroll
    end
  end
  resources :outgoing_payment_modes do
    collection do
      get :list
      get :unroll
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
      get :unroll
    end
  end
  resources :preferences do
    collection do
      get :list
      get :unroll
    end
  end
  resources :products do
    collection do
      get :list
      get :list_prices
      get :list_stocks
      get :list_stock_moves
      get :list_components
      get :unroll
      get :unroll_availables
      get :unroll_stockables
    end
  end
  resources :product_categories do
    collection do
      get :list
      get :list_products
      get :unroll
    end
  end
  resources :product_components, :except => [:show, :index]
  resources :production_chains do
    collection do
      get :list
      get :unroll
    end
  end
  resources :production_chain_conveyors
  resources :production_chain_work_centers do
    member do
      get :play
      post :down
      post :up
      get :unroll
    end
  end
  # resources :production_chain_work_centers_uses
  resources :professions do
    collection do
      get :list
      get :unroll
    end
  end
  resources :purchase_lines, :except => [:index, :show]
  resources :purchase_natures do
    collection do
      get :list
      get :unroll
    end
  end
  resources :purchases do
    collection do
      get :list
      get :list_lines
      get :list_undelivered_lines
      get :list_deliveries
      get :list_payment_uses
      get :unroll
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
      get :unroll
    end
  end
  resources :sale_lines, :except => [:index, :show] do
    collection do
      get :list
      get :detail
      get :unroll
    end
  end
  resources :sale_natures do
    collection do
      get :list
      get :unroll
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
      get :unroll
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
      get :unroll
    end
  end
  # resources :stock_moves
  resources :stock_transfers do
    collection do
      get :list
      get :list_confirm
      get :unroll
      match "confirm_all", :via => [:get, :post]
    end
    member do
      match "confirm", :via => [:get, :post]
    end
  end
  resources :stocks do
    collection do
      get :list
      get :unroll
    end
  end
  resources :subscription_natures do
    collection do
      get :list
      get :unroll
    end
    member do
      post :increment
      post :decrement
    end
  end
  resources :subscriptions do
    collection do
      get :list
      get :unroll
      get :coordinates
      get :message
    end
  end
  # resources :tax_declarations
  resources :taxes do
    collection do
      get :list
      get :unroll
    end
  end
  resources :tools do
    collection do
      get :list
      get :list_operations
      get :unroll
    end
  end
  resources :tool_natures do
    collection do
      get :list
      get :unroll
    end
  end
  resources :trackings do
    collection do
      get :list_stocks
      get :list_sale_lines
      get :list_purchase_lines
      get :list_operation_lines
      get :unroll
    end
  end
  # resources :tracking_states
  resources :transports do
    collection do
      get :list
      get :list_deliveries
      get :list_transportable_deliveries
      get :unroll
      # match "deliveries", :via => [:get, :post]
      # match "delivery_delete", :via => [:get, :post]
    end
  end
  # resources :transfers
  resources :units do
    collection do
      get :unroll
      get :list
      post :load
      get :unroll
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
      get :unroll
    end
  end
  # end
  match "/dashboards" => "dashboards#index", :as => "admin"

  root :to => "dashboards#index"
end
