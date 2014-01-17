Ekylibre::Application.routes.draw do




  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # No namespace because authentication is for all sides
  devise_for :users, path: "authentication", :module => :authentication

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

  concern :entities do
    concerns :list, :unroll
    collection do
      get :autocomplete_for_origin
      match "import", via: [:get, :post]
      match "export", via: [:get, :post]
      match "merge", via: [:get, :post]
    end
    member do
      match "picture(/:style)", via: :get, action: :picture, as: :picture
      get :list_cashes
      get :list_event_participations
      get :list_incoming_payments
      get :list_links
      get :list_mandates
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
      get :list_indicators
      get :list_intervention_casts
      get :list_measurements
      get :list_members
      get :list_places
      get :list_markers
    end
  end

  # Backend
  namespace :backend do

    resource :myself, :path => "me", only: [:show]

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
        for mod in [:relationship, :accountancy, :trade, :stocks, :production, :tools, :settings]
          get mod
        end
        get :list_my_future_events
        get :list_recent_events
        get :list_critic_stocks
      end
    end

    resources :helps, only: [:index, :show] do
      collection do
        post :toggle
      end
    end

    namespace :calculators do
      resource :nitrogen_inputs, only: :show
    end

    resources :calculators, only: :index

    namespace :cells do
      resource :bank_chart_cell, only: :show, concerns: :list
      resource :calendar_cell, only: :show, concerns: :list
      resource :collected_taxes_cell, only: :show
      resource :cropping_plan_cell, only: :show
      resource :cropping_plan_on_cultivable_land_parcels_cell, only: :show
      resource :current_stocks_by_product_nature_cell, only: :show
      resource :elapsed_interventions_times_by_activities_cell, only: :show
      resource :events_cell, only: :show
      resource :last_document_archives_cell, only: :show, concerns: :list
      resource :last_entities_cell, only: :show, concerns: :list
      resource :last_events_cell, only: :show, concerns: :list
      resource :last_incoming_deliveries_cell, only: :show, concerns: :list
      resource :last_issues_cell, only: :show, concerns: :list
      resource :last_interventions_cell, only: :show, concerns: :list
      resource :last_milk_result_cell, only: :show, concerns: :list
      resource :last_outgoing_deliveries_cell, only: :show, concerns: :list
      resource :last_products_cell, only: :show, concerns: :list
      resource :last_purchases_cell, only: :show, concerns: :list
      resource :last_sales_cell, only: :show, concerns: :list
      resource :map_cell, only: [:show, :update]
      resource :meteo_cell, only: :show
      resource :placeholder_cell, only: :show
      resource :product_bar_cell, only: :show
      resource :production_cropping_plan_cell, only: :show
      resource :purchases_bar_cell, only: :show
      resource :purchases_expense_bar_cell, only: :show
      resource :revenues_by_product_nature_cell, only: :show
      resource :rss_cell, only: :show
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

    resources :analytic_repartitions, concerns: [:list, :unroll]

    resources :animal_groups, concerns: [:list, :picture, :unroll] do
      member do
        get :list_animals
        get :list_places
      end
    end

    resources :animals, concerns: :products do
      member do
        get :list_children
      end
    end

    resources :animal_medicines, concerns: :products

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

    resources :catalog_prices, concerns: [:list, :unroll]

    resources :catalogs, concerns: [:list, :unroll] do
      member do
        get :list_prices
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

    # resources :deposit_items

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

    resources :entity_addresses, except: [:index], concerns: [:list, :unroll]

    resources :entity_links, except: [:index]

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

    resources :financial_assets, concerns: [:list, :unroll] do
      member do
        get :cede
        get :sell
        post :depreciate
        get :list_depreciations
      end
    end

    # resources :financial_asset_depreciations # , except: [:index]

    resources :financial_years, concerns: [:list, :unroll] do
      member do
        match "close", via: [:get, :post]
        match :generate_last_journal_entry, via: [:get, :post]
        post :compute_balances
        get :list_account_balances
        get :list_financial_asset_depreciations
      end
    end

    resources :gaps, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    resources :guides, concerns: [:list, :unroll]

    resources :guide_indicator_data, concerns: [:list, :unroll]

    resources :incoming_deliveries, concerns: [:list, :unroll] do
      member do
        get :list_items
        match "confirm", via: [:get, :post]
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

    resources :interventions, concerns: [:list, :unroll] do
      member do
        post :run
        get :list_casts
        get :list_operations
      end
    end

    resources :inventories, concerns: [:list, :unroll] do
      collection do
        get :list_items
        get :list_items_create
        get :list_items_update
      end
      member do
        match "reflect", via: [:get, :post]
      end
    end

    resources :issues, concerns: [:list, :picture, :unroll] do
      member do
        post :abort
        post :close
        post :reopen
        get :list_interventions
      end
    end

    resources :journals, concerns: [:list, :unroll] do
      collection do
        match "draft", via: [:get, :post]
        match "bookkeep", via: [:get, :put, :post]
        match "import", via: [:get, :post]
        get :reports
        get :balance
        get :general_ledger
        get :list_draft_items
        get :list_general_ledger
      end
      member do
        get :list_mixed
        get :list_items
        get :list_entries
        match "close", via: [:get, :post]
        match "reopen", via: [:get, :post]
      end
    end

    resources :journal_entries, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    resources :journal_entry_items, only: [:new, :show], concerns: [:list, :unroll] do
      collection do
      end
    end

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

    resources :versions, concerns: [:list, :unroll]

    resources :mandates, concerns: [:list, :unroll] do
      collection do
        get :autocomplete_for_family
        get :autocomplete_for_organization
        get :autocomplete_for_title
        match "configure", via: [:get, :post]
      end
    end

    resources :matters, concerns: :products

    resources :medicines, concerns: :products

    resources :mineral_matters, concerns: :products

    resources :observations

    resources :operations, concerns: [:list, :unroll]

    resources :organic_matters, concerns: :products

    resources :operation_tasks, concerns: [:list, :unroll]

    resources :outgoing_deliveries, concerns: [:list, :unroll] do
      member do
        get :list_items
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

    resources :plants, concerns: :products

    resources :plant_medicines, concerns: :products

    resources :postal_zones, concerns: [:list, :unroll] do
      collection do
        get :autocomplete_for_name
      end
    end

    resources :preferences, concerns: [:list, :unroll]

    resources :prescriptions, concerns: [:list, :unroll] do
      member do
        get :list_interventions
      end
    end

    resources :products, concerns: :products

    resources :product_groups, concerns: :products

    resources :product_indicator_data # , concerns: [:list, :unroll]

    resources :product_linkages, concerns: [:list, :unroll]

    resources :product_localizations, concerns: [:list, :unroll]

    resources :product_natures, concerns: [:list, :unroll] do
      collection do
        get :change_quantities
      end
      member do
        get :list_products
        get :list_product_nature_variants
      end
    end

    resources :product_nature_categories, concerns: [:list, :unroll] do
      member do
        get :list_products
        get :list_product_natures
      end
    end

    resources :product_nature_variant_indicator_data

    resources :product_nature_variants, concerns: [:list, :picture, :unroll] do
      member do
        get :list_products
        get :list_prices
      end
    end

    resources :product_ownerships, concerns: [:list, :unroll]

    resources :product_phases, concerns: [:list, :unroll]

    resources :product_processes, concerns: [:list, :unroll]

    resources :product_process_phases # , concerns: [:list, :unroll]

    resources :productions, concerns: [:list, :unroll] do
      member do
        get :list_supports
        get :list_interventions
        get :list_markers
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

    resources :purchase_items, except: [:index]

    resources :purchase_natures, concerns: [:list, :unroll]

    resources :purchases, concerns: [:list, :unroll] do
      member do
        get :list_items
        get :list_undelivered_items
        get :list_deliveries
        post :correct
        post :propose
        post :invoice
        post :confirm
        post :abort
        post :refuse
      end
    end

    resources :roles, concerns: [:list, :unroll]

    resources :sale_items, except: [:index], concerns: [:list, :unroll] do
      collection do
        get :detail
      end
    end

    resources :sale_natures, concerns: [:list, :unroll]

    resources :sales, concerns: [:list, :unroll] do
      resources :items, only: [:new, :create], controller: :sale_items
      collection do
        get :statistics
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

    resources :sequences, concerns: [:list, :unroll] do
      collection do
        post :load
      end
    end

    # resources :services, concerns: :products

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

    # resources :tax_declarations

    resources :taxes, concerns: [:list, :unroll]

    resources :teams, concerns: [:list, :unroll]

    resources :trackings, concerns: [:list, :unroll] do
      # collection do
      #   get :unroll
      # end
      # member do
      #   get :list_products
      #   get :list_sale_items
      #   get :list_purchase_items
      #   get :list_operation_items
      # end
    end

    # resources :tracking_states

    resources :transports, concerns: [:list, :unroll] do
      collection do
        # match "deliveries", via: [:get, :post]
        # match "delivery_delete", via: [:get, :post]
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

    resources :workers, concerns: :products

    get :search, :controller => :dashboards, :as => :search

    root :to => "dashboards#index"
  end

  root :to => "public#index"
end
