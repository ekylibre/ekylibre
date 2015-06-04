Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

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
      get :take
    end
  end

  concern :affairs do
    concerns :unroll
    member do
      get :select
      post :attach
      delete :detach
      post :finish
    end
  end


  # No namespace because authentication is for all sides
  devise_for :users, path: "authentication", module: :authentication

  namespace :pasteque do
    # namespace :v6 do
    #   pasteque_v6
    # end
    namespace :v5 do
      pasteque_v5
    end
  end

  namespace :api do
    namespace :v1 do
      resources :tokens, only: [:create, :destroy]
      resources :crumbs
    end
  end

  # Plugins can override backend routes but only complete API ones
  plugins

  # Backend
  namespace :backend do

    # add routes for frontend animals column view
    # TODO refactorize and export to API
    get "remote_load_animals" => 'animals#remote_load_animals'
    get "remote_load_containers" => 'animals#remote_load_containers'


    resource :myself, path: "me", only: [:show]

    resource :settings, only: [:edit, :update] do
      member do
        get :about
      end
    end

    resources :dashboards, concerns: [:list] do
      collection do
        for mod in [:home, :relationship, :accountancy, :trade, :stocks, :production, :tools, :settings]
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
      resource :grains_commercialization_threshold_simulator, only: :show
    end

    # resources :calculators, only: :index

    namespace :cells do
      resource :cash_balances_cell, only: :show
      resource :calendar_cell, only: :show
      resource :payable_taxes_cell, only: :show
      resource :cropping_plan_cell, only: :show
      resource :cropping_plan_on_cultivable_zones_cell, only: :show
      resource :current_stocks_by_variety_cell, only: :show
      resource :elapsed_interventions_times_by_activities_cell, only: :show
      resource :expenses_by_product_nature_category_cell, only: :show
      resource :events_cell, only: :show
      resource :guide_evolution_cell, only: :show
      resource :last_analyses_cell, only: :show
      resource :last_documents_cell, only: :show, concerns: :list
      resource :last_entities_cell, only: :show, concerns: :list
      resource :last_events_cell, only: :show, concerns: :list
      resource :last_incoming_deliveries_cell, only: :show, concerns: :list
      resource :last_issues_cell, only: :show, concerns: :list
      resource :last_interventions_cell, only: :show
      resource :last_outgoing_deliveries_cell, only: :show, concerns: :list
      resource :last_products_cell, only: :show, concerns: :list
      resource :last_purchases_cell, only: :show, concerns: :list
      resource :last_sales_cell, only: :show, concerns: :list
      resource :map_cell, only: :show
      resource :placeholder_cell, only: :show
      resource :quandl_cell, only: :show
      resource :revenues_by_product_nature_cell, only: :show
      resource :rss_cell, only: :show
      resource :stock_container_map_cell, only: :show
      resource :threshold_commercialization_by_production_cell, only: :show
      resource :weather_cell, only: :show
      resource :working_sets_stocks_cell, only: :show
    end

    resources :accounts, concerns: [:list, :unroll] do
      collection do
        get :reconciliation
        get :list_reconciliation
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
      collection do
        get :family
      end
      member do
        get :list_productions
        get :list_distributions
      end
    end

    resources :analyses, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    resources :animal_groups, concerns: [:list, :picture, :unroll] do
      member do
        get :list_animals
        get :list_places
      end
    end

    resources :animals, concerns: :products do
      member do
        match :add_to_group, via: [:get, :post]
        get :list_children
      end
    end

    resources :affairs, concerns: [:list, :affairs]

    resources :bank_statements, concerns: [:list, :unroll], path: "bank-statements" do
      collection do
        get :list_items
      end
      member do
        match "point", via: [:get, :post]
      end
    end

    resources :beehives, only: [:update] do
      member do
        post :reset
      end
    end

    resources :buildings, concerns: :products do
      member do
        get :list_divisions
      end
    end

    resources :building_divisions, concerns: :products, path: "building-divisions"

    resources :campaigns, concerns: [:list, :unroll] do
      member do
        get :list_productions
      end
    end

    resources :cashes, concerns: [:list, :unroll] do
      member do
        get :list_deposits
        get :list_bank_statements
        get :list_sessions
      end
    end

    resources :cash_transfers, concerns: [:list, :unroll], path: "cash-transfers"

    resources :catalog_items, concerns: [:list, :unroll]

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

    resources :cultivable_zones, concerns: :products, path: "cultivable-zones" do
      member do
        get :list_productions
      end
    end

    resources :custom_fields, concerns: [:list, :unroll], path: "custom-fields" do
      member do
        get :list_choices
        post :up
        post :down
        post :sort
      end
    end
    resources :custom_field_choices, except: [:index, :show], concerns: [:unroll], path: "custom-field-choices" do
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

    resources :document_templates, concerns: [:list, :unroll], path: "document-templates" do
      collection do
        post :load
      end
    end

    resources :documents, concerns: [:list, :unroll]

    resource :draft_journal, only: [:show] do
      member do
        post :confirm
        get  :list_journal_entry_items
      end
    end

    resources :entities, concerns: :entities

    resources :entity_addresses, concerns: [:unroll]

    resources :entity_links

    resources :equipments, concerns: :products

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

    resources :exports, only: [:index, :show]

    resources :fixed_assets, concerns: [:list, :unroll], path: "fixed-assets" do
      member do
        get  :cede
        get  :sell
        post :depreciate
        get  :list_depreciations
        get  :list_products
      end
    end

    resources :financial_years, concerns: [:list, :unroll], path: "financial-years" do
      member do
        match "close", via: [:get, :post]
        match :generate_last_journal_entry, via: [:get, :post]
        post :compute_balances
        get  :list_account_balances
        get  :list_fixed_asset_depreciations
      end
    end

    resources :fungi, concerns: :products

    resources :gaps, concerns: [:list, :unroll] do
      member do
        get  :list_items
      end
    end

    resource :general_ledger, only: [:show], path: "general-ledger" do
      member do
        get  :list_journal_entry_items
      end
    end

    resources :georeadings, concerns: [:list, :unroll]

    resources :guide_analyses, only: [:show], path: "guide-analyses" do
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

    resources :incoming_payments, concerns: [:list, :unroll]

    resources :incoming_payment_modes, concerns: [:list, :unroll] do
      member do
        post :up
        post :down
        post :reflect
      end
    end

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

    resources :januses, only: [] do
      member do
        post :toggle
      end
    end

    resources :journals, concerns: [:list, :unroll] do
      collection do
        match "bookkeep", via: [:get, :put, :post]
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

    resources :journal_entry_items, only: [:new, :show], concerns: [:unroll]

    resources :kujakus, only: [] do
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

    resources :loans, concerns: [:list, :unroll] do
      member do
        get :list_repayments
      end
    end

    resources :loan_repayments

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

    resources :operations, only: [:index, :show]

    resources :outgoing_deliveries, concerns: [:list, :unroll] do
      member do
        post :invoice
        get :list_items
        post :ship
      end
    end

    resources :outgoing_payments, concerns: [:list, :unroll]

    resources :outgoing_payment_modes, concerns: [:list, :unroll] do
      member do
        post :up
        post :down
      end
    end

    resources :people, concerns: :entities

    resources :plants, concerns: :products

    resources :postal_zones, concerns: [:list, :unroll] do
      collection do
        get :autocomplete_for_name
      end
    end

    resources :prescriptions, concerns: [:list, :unroll] do
      member do
        get :list_interventions
      end
    end

    resources :products, concerns: :products

    resources :product_groups, concerns: :products

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

    resources :product_nature_variants, concerns: [:incorporate, :list, :picture, :unroll] do
      member do
        get :detail
        get :list_catalog_items
        get :list_products
        get :quantifiers
      end
    end

    resources :productions, concerns: [:list, :unroll] do
      member do
        get :list_budgets
        get :list_interventions
        get :list_supports
      end
    end

    resources :production_supports, only: [:show], concerns: [:unroll] do
      member do
        get :list_interventions
      end
    end

    resources :purchase_natures, concerns: [:list, :unroll]

    resources :purchases, concerns: [:list, :unroll] do
      member do
        get  :list_items
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

    resources :sale_credits, path: "sale-credits", only: [:index, :show, :new, :create]

    resources :sale_natures, concerns: [:list, :unroll], path: "sale-natures"

    resources :sale_opportunities, concerns: [:list, :affairs], path: "sale-opportunities" do
      member do
        match "evolve/:state" => :evolve, via: :patch
        post :evaluate
        post :lose
        post :negociate
        post :qualify
        post :quote
        post :win
      end
    end

    resources :sale_tickets, concerns: [:list, :affairs], path: "sale-tickets"

    resources :sales, concerns: [:list, :unroll] do
      collection do
        get :contacts
      end
      member do
        get :cancel
        get :list_items
        get :list_undelivered_items
        get :list_subscriptions
        get :list_deliveries
        get :list_credits
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

    resources :settlements, concerns: :products

    resources :snippets, only: [] do
      member do
        post :toggle
      end
    end

    resources :subscription_natures, concerns: [:list, :unroll], path: "subscription-natures" do
      member do
        post :increment
        post :decrement
      end
    end

    resources :subscriptions, concerns: [:list, :unroll]

    resources :synchronizations, only: [:index] do
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
      end
    end

    resources :transports, concerns: [:list, :unroll], except: [:new, :create] do
      member do
        get :list_deliveries
      end
    end

    resource :trial_balance, only: [:show], path: "trial-balance"

    resources :users, concerns: [:list, :unroll] do
      member do
        post :lock
        post :unlock
      end
    end

    resources :visuals, only: [] do
      match "picture(/:style)", via: :get, action: :picture, as: :picture
    end

    resources :wine_tanks, only: [:index], concerns: [:list]

    resources :workers, concerns: :products

    get :search, controller: :dashboards, as: :search

    root to: "dashboards#home"
  end

  root to: "public#index"
end
