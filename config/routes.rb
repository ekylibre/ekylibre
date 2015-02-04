Ekylibre::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # No namespace because authentication is for all sides
  devise_for :users, path: "authentication", module: :authentication

  concern :unroll do
    # get "unroll/:scope", action: :unroll, on: :collection
    get :unroll, on: :collection
  end

  concern :picture do
    match "picture(/:style)", via: :get, action: :picture, as: :picture, on: :member
  end

  concern :list do
    get :list, on: :collection
  end

  concern :incorporate do
    collection do
      get :pick
      post :incorporate
    end
  end

  concern :entities do
    concerns :list, :unroll
    collection do
      get :autocomplete_for_origin
      match "import", via: [:get, :post]
      match "export", via: [:get, :post]
      match "merge",  via: [:get, :post]
    end
    member do
      match "picture(/:style)", via: :get, action: :picture, as: :picture
      get :list_cashes
      get :list_event_participations
      get :list_incoming_payments
      get :list_issues
      get :list_links
      get :list_purchases
      get :list_observations
      get :list_outgoing_payments
      get :list_sales
      get :list_subscriptions
    end
  end

  concern :products do
    concerns :list, :unroll
    member do
      match "picture(/:style)", via: :get, action: :picture, as: :picture
      get :list_carried_linkages
      get :list_carrier_linkages
      get :list_contained_products
      get :list_groups
      get :list_issues
      get :list_readings
      get :list_intervention_casts
      get :list_reading_tasks
      get :list_members
      get :list_places
      get :list_markers
    end
  end

  namespace :pasteque do
    namespace :v5 do
      pasteque_v5
    end
  end


  namespace :api do

    concern :v1 do
      resources :tokens, only: [:create, :destroy]
      resources :crumbs
    end

    namespace :v1 do
      concerns :v1
    end

    concerns :v1
  end


  # Backend
  namespace :backend do

    resource :myself, path: "me", only: [:show]

    resource :settings, only: [:edit, :update] do
      member do
        get :about
        get :backups
        post :backup
        post :restore
        match "import", via: [:get, :post]
      end
    end

    resource :dashboards, only: [] do
      collection do
        for mod in [:relationship, :accountancy, :trade, :stocks, :production, :tools, :settings, :legals]
          get mod
        end
        get :sandbox
      end
    end

    resources :helps, only: [:index, :show] do
      collection do
        post :toggle
      end
    end

    namespace :calculators do
    end

    resources :calculators, only: :index

    namespace :cells do
      resource :cash_balances_cell, only: :show, concerns: :list
      resource :calendar_cell, only: :show, concerns: :list
      resource :payable_taxes_cell, only: :show
      resource :cropping_plan_cell, only: :show
      resource :cropping_plan_on_cultivable_zones_cell, only: :show
      resource :current_stocks_by_variety_cell, only: :show
      resource :elapsed_interventions_times_by_activities_cell, only: :show
      resource :expenses_by_product_nature_category_cells, only: :show
      resource :events_cell, only: :show
      resource :guide_evolution_cell, only: :show
      resource :last_document_archives_cell, only: :show, concerns: :list
      resource :last_entities_cell, only: :show, concerns: :list
      resource :last_events_cell, only: :show, concerns: :list
      resource :last_incoming_deliveries_cell, only: :show, concerns: :list
      resource :last_issues_cell, only: :show, concerns: :list
      resource :last_interventions_cell, only: :show, concerns: :list
      resource :last_analyses_cell, only: :show, concerns: :list
      resource :last_outgoing_deliveries_cell, only: :show, concerns: :list
      resource :last_products_cell, only: :show, concerns: :list
      resource :last_purchases_cell, only: :show, concerns: :list
      resource :last_sales_cell, only: :show, concerns: :list
      resource :map_cell, only: :show
      resource :weather_cell, only: :show
      resource :placeholder_cell, only: :show
      resource :product_bar_cell, only: :show
      resource :production_cropping_plan_cell, only: :show
      resource :purchases_bar_cell, only: :show
      resource :purchases_expense_bar_cell, only: :show
      resource :revenues_by_product_nature_cell, only: :show
      resource :rss_cell, only: :show
      resource :stock_container_map_cell, only: :show
      resource :working_sets_stocks_cell, only: :show
    end

    # resources :account_balances

    resources :accounts, concerns: [:list, :unroll] do
      collection do
        get :reconciliation
        get :list_reconciliation
        get :autocomplete_for_origin
        match "load", via: [:get, :post]
      end
      member do
        match "mark", via: [:get, :post]
        post :unmark
        get :list_journal_entry_items
        get :list_entities
      end
    end

    resources :activities, concerns: [:list, :unroll] do
      member do
        get :list_productions
      end
    end

    resources :aggregators, only: [:index, :show]

    resources :analyses, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    # resources :analysis_items, concerns: [:list, :unroll]

    resources :analytic_distributions, concerns: [:list, :unroll]

    resources :animal_foods, only: [:index], concerns: [:list]

    resources :animal_groups, concerns: [:list, :picture, :unroll] do
      member do
        get :list_animals
        get :list_places
      end
    end

    resources :animal_medicines, only: [:index], concerns: [:list]

    resources :animal_products, only: [:index], concerns: [:list]

    resources :animals, concerns: :products do
      member do
        get :list_children
      end
    end

    resources :affairs, concerns: [:list] do
      member do
        get :select
        post :attach
        delete :detach
        post :finish
      end
    end

    resources :bank_statements, concerns: [:list, :unroll] do
      collection do
        get :list_items
      end
      member do
        match "point", via: [:get, :post]
      end
    end

    resources :buildings, concerns: :products do
      member do
        get :list_divisions
      end
    end

    resources :building_divisions, concerns: :products

    resources :campaigns, concerns: [:list, :unroll] do
      member do
        get :list_productions
      end
    end

    resources :cashes, concerns: [:list, :unroll] do
      member do
        get :list_deposits
        get :list_bank_statements
      end
    end

    resources :cash_transfers, concerns: [:list, :unroll]

    resources :catalog_items, concerns: [:list, :unroll] do
      member do
        post :stop
      end
    end

    resources :catalogs, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    resources :crumbs, only: [:index, :update, :destroy] do
      member do
        post :convert
      end
    end

    resources :cultivable_zones, concerns: :products do
      member do
        get :list_productions
      end
    end

    resources :custom_fields, concerns: [:list, :unroll] do
      member do
        get :list_choices
        post :up
        post :down
        post :sort
      end
    end
    resources :custom_field_choices, concerns: [:list, :unroll] do
      member do
        post :up
        post :down
      end
    end

    resources :deposits, concerns: [:list, :unroll] do
      collection do
        get :list_unvalidateds
        get :list_depositable_payments
        match "unvalidateds", via: [:get, :post]
      end
      member do
        get :list_payments
      end
    end

    resources :districts, concerns: [:list, :unroll]

    resources :document_archives

    resources :document_templates, concerns: [:list, :unroll] do
      collection do
        post :load
      end
    end

    resources :documents, concerns: [:list, :unroll] do
      member do
        get :list_archives
      end
    end

    resources :entities, concerns: :entities

    resources :entity_addresses, concerns: [:unroll]

    resources :entity_links

    resources :equipments, concerns: :products

    resources :establishments, concerns: [:list, :unroll]

    resources :event_natures, concerns: [:list, :unroll]

    resources :event_participations

    resources :events, concerns: [:list, :unroll] do
      collection do
        get :autocomplete_for_place
        get :change_minutes
      end
      member do
        get :list_participations
      end
    end

    resources :exports

    resources :financial_assets, concerns: [:list, :unroll] do
      member do
        get  :cede
        get  :sell
        post :depreciate
        get  :list_depreciations
        get  :list_products
      end
    end

    # resources :financial_asset_depreciations

    resources :financial_years, concerns: [:list, :unroll] do
      member do
        match "close", via: [:get, :post]
        match :generate_last_journal_entry, via: [:get, :post]
        post :compute_balances
        get  :list_account_balances
        get  :list_financial_asset_depreciations
      end
    end

    resources :fungi, concerns: :products

    resources :gaps, concerns: [:list, :unroll] do
      member do
        get  :list_items
      end
    end

    resources :georeadings, concerns: [:list, :unroll]

    resources :guide_analyses, concerns: [:list, :unroll] do
      member do
        get  :list_points
      end
    end

    resources :guides, concerns: [:list, :unroll] do
      member do
        post :run
        get  :list_analyses
      end
    end

    resources :identifiers, concerns: [:list, :unroll]

    resources :imports, concerns: [:list] do
      member do
        post :run
      end
    end

    resources :incoming_deliveries, concerns: [:list, :unroll] do
      member do
        match "confirm", via: [:get, :post]
        post :invoice
        get  :list_items
      end
    end

    resources :incoming_delivery_items, only: [:new]

    resources :incoming_delivery_modes, concerns: [:list, :unroll]

    resources :incoming_payments, concerns: [:list, :unroll]

    resources :incoming_payment_modes, concerns: [:list, :unroll] do
      member do
        post :up
        post :down
        post :reflect
      end
    end

    resources :intervention_casts

    resources :interventions, concerns: [:list, :unroll] do
      collection do
        get  :compute
      end
      member do
        get  :set
        post :run
        get  :list_casts
        get  :list_operations
      end
    end

    resources :inventories, concerns: [:list, :unroll] do
      member do
        post :reflect
        post :refresh
        get  :list_items
      end
    end

    resources :issues, concerns: [:list, :picture, :unroll] do
      member do
        post :abort
        post :close
        post :reopen
        get  :list_interventions
      end
    end

    resources :journals, concerns: [:list, :unroll] do
      collection do
        match "draft", via: [:get, :post]
        match "bookkeep", via: [:get, :put, :post]
        match "import", via: [:get, :post]
        get  :reports
        get  :balance
        get  :general_ledger
        get  :list_draft_items
        get  :list_general_ledger
      end
      member do
        get  :list_mixed
        get  :list_items
        get  :list_entries
        match "close", via: [:get, :post]
        match "reopen", via: [:get, :post]
      end
    end

    resources :journal_entries, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    resources :journal_entry_items, only: [:new, :show], concerns: [:list, :unroll]

    resources :kujakus, only: [], concerns: [:list, :unroll] do
      member do
        post :toggle
      end
    end

    resources :land_parcel_clusters, concerns: :products

    resources :land_parcel_groups, concerns: :products

    resources :land_parcels, concerns: :products

    resources :legal_entities, concerns: :entities

    resources :listing_nodes

    resources :listings, concerns: [:list, :unroll] do
      member do
        get :extract
        post :duplicate
        match "mail", via: [:get, :post]
      end
    end

    resources :manure_management_plans, concerns: [:list, :unroll] do
      member do
        get :list_zones
      end
    end

    resources :matters, concerns: :products

    resources :net_services, concerns: [:list, :unroll] do
      member do
        get :list_identifiers
      end
    end

    resources :observations

    resources :operations, concerns: [:list, :unroll]

    resources :outgoing_deliveries, concerns: [:list, :unroll] do
      member do
        post :invoice
        get :list_items
        post :ship
      end
    end

    # resources :outgoing_delivery_items

    resources :outgoing_delivery_modes, concerns: [:list, :unroll]

    resources :outgoing_payments, concerns: [:list, :unroll]

    resources :outgoing_payment_modes, concerns: [:list, :unroll] do
      member do
        post :up
        post :down
      end
    end

    resources :people, concerns: :entities

    resources :plant_fertilizers, only: [:index], concerns: [:list]

    resources :plant_medicines, only: [:index], concerns: [:list]

    resources :plant_products, only: [:index], concerns: [:list]

    resources :plant_seedlings, only: [:index], concerns: [:list]

    resources :plants, concerns: :products

    resources :postal_zones, concerns: [:list, :unroll] do
      collection do
        get :autocomplete_for_name
      end
    end

    # resources :preferences, concerns: [:list, :unroll]

    resources :prescriptions, concerns: [:list, :unroll] do
      member do
        get :list_interventions
      end
    end

    resources :products, concerns: :products

    resources :product_groups, concerns: :products

    # resources :product_readings, concerns: [:list, :unroll]

    # resources :product_linkages, concerns: [:list, :unroll]

    # resources :product_localizations, concerns: [:list, :unroll]

    resources :product_natures, concerns: [:incorporate, :list, :unroll] do
      member do
        get :list_variants
      end
    end

    resources :product_nature_categories, concerns: [:incorporate, :list, :unroll] do
      member do
        get :list_products
        get :list_product_natures
        get :list_taxations
      end
    end

    resources :product_nature_variant_readings

    resources :product_nature_variants, concerns: [:incorporate, :list, :picture, :unroll] do
      member do
        get :detail
        get :list_catalog_items
        get :list_products
      end
    end

    # resources :product_ownerships, concerns: [:list, :unroll]

    # resources :product_phases, concerns: [:list, :unroll]

    resources :productions, concerns: [:list, :unroll] do
      member do
        get :list_supports
        get :list_interventions
        get :list_markers
        get :indicator_measure
      end
    end

    # resources :production_support_markers, concerns: [:list, :unroll]

    resources :production_supports, concerns: [:list, :unroll] do
      member do
        get :list_interventions
        get :list_markers
      end
    end

    resources :production_support_markers, concerns: [:list, :unroll]

    resources :professions, concerns: [:list, :unroll]

    resources :purchase_natures, concerns: [:list, :unroll]

    resources :purchases, concerns: [:list, :unroll] do
      member do
        get  :list_items
        get  :list_undelivered_items
        get  :list_deliveries
        post :abort
        post :confirm
        post :correct
        post :invoice
        post :propose
        post :propose_and_invoice
        post :refuse
      end
    end

    resources :roles, concerns: [:incorporate, :list, :unroll] do
      member do
        get :list_users
      end
    end

    resources :sale_natures, concerns: [:list, :unroll]

    resources :sales, concerns: [:list, :unroll] do
      resources :items, only: [:new, :create], controller: :sale_items
      collection do
        get :contacts
      end
      member do
        get :list_items
        get :list_undelivered_items
        get :list_subscriptions
        get :list_deliveries
        get :list_credits
        get :list_creditable_items
        match "cancel", via: [:get, :post]
        post :abort
        post :confirm
        post :correct
        post :duplicate
        post :invoice
        post :propose
        post :propose_and_invoice
        post :refuse
      end
    end

    resources :sequences, concerns: [:list, :unroll] do
      collection do
        post :load
      end
    end

    resources :services, concerns: :products

    resources :settlements, concerns: :products

    resources :snippets, only: [] do
      member do
        post :toggle
      end
    end

    resources :subscription_natures, concerns: [:list, :unroll] do
      member do
        post :increment
        post :decrement
      end
    end

    resources :subscriptions, concerns: [:list, :unroll] do
      collection do
        get :coordinates
        get :message
      end
    end

    resources :synchronizations do
      member do
        post :run
      end
    end

    resources :taxes, concerns: [:list, :unroll] do
    end

    resources :teams, concerns: [:list, :unroll]

    resources :trackings, concerns: [:list, :unroll] do
      member do
        get :list_products
        #   get :list_sale_items
        #   get :list_purchase_items
        #   get :list_operation_items
      end
    end

    resources :transformed_products, only: [:index], concerns: [:list]

    resources :transports, concerns: [:list, :unroll] do
      collection do
        get :list_transportable_deliveries
      end
      member do
        get :list_deliveries
      end
    end

    # resources :transfers

    resources :users, concerns: [:list, :unroll] do
      member do
        post :lock
        post :unlock
      end
    end

    resources :versions, concerns: [:list, :unroll]

    resources :visuals, only: [] do
      match "picture(/:style)", via: :get, action: :picture, as: :picture
    end

    resources :wine_tanks, only: [:index], concerns: [:list]

    resources :wine_transformers, only: [:index], concerns: [:list]

    resources :workers, concerns: :products

    get :search, controller: :dashboards, as: :search

    root to: "dashboards#index"
  end

  root to: "public#index"
end
