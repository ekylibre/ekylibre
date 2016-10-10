Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  concern :unroll do
    # get "unroll/:scope", action: :unroll, on: :collection
    get :unroll, on: :collection
  end

  concern :picture do
    match 'picture(/:style)', via: :get, action: :picture, as: :picture, on: :member
  end

  concern :list do
    get :list, on: :collection
  end

  concern :autocomplete do
    get 'complete/:column', on: :collection, action: :autocomplete, as: :autocomplete
  end

  concern :many do
    collection do
      get 'edit', action: :edit_many, as: :edit
      patch '', action: :update_many
    end
  end

  concern :incorporate do
    collection do
      get :pick
      post :incorporate
    end
  end

  concern :products do
    concerns :list, :unroll
    member do
      match 'picture(/:style)', via: :get, action: :picture, as: :picture
      get :list_carried_linkages
      get :list_carrier_linkages
      get :list_contained_products
      get :list_groups
      get :list_inspections
      get :list_intervention_product_parameters
      get :list_issues
      get :list_readings
      get :list_members
      get :list_parcel_items
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
      delete :detach_gaps
      post :finish
    end
  end

  # No namespace because authentication is for all sides
  devise_for :users, path: '',
                     module: :authentication,
                     skip: [:invitations, :registrations],
                     path_names: {
                       sign_in: 'sign-in',
                       sign_out: 'sign-out',
                       sign_up: 'sign-up'
                     }
  as :user do
    # Invitations
    get 'invitation/accept' => 'authentication/invitations#edit', as: :accept_user_invitation
    put 'invitation' => 'authentication/invitations#update', as: :user_invitation
    patch 'invitation' => 'authentication/invitations#update'

    # Registrations
    get 'signup' => 'authentication/registrations#new', as: :new_user_registration
    post 'signup' => 'authentication/registrations#create', as: :user_registration
  end

  # No '-' in API paths for now, only '_'
  namespace :api do
    namespace :v1, defaults: { format: 'json' } do
      resources :tokens, only: [:create, :destroy]
      resources :crumbs
      resources :interventions, only: [:index]
      resources :issues
      resources :plant_density_abaci
      resources :plant_countings
      resources :plants
    end
  end

  namespace :iot, path: 'iot/v1' do
    resources :analyses, only: [:create], path: 'a'
  end

  # Plugins can override backend routes but only complete API ones
  plugins

  # Backend
  namespace :backend do
    resource :myself, path: 'me', only: [:show, :update] do
      member do
        patch :change_password
      end
    end

    resource :settings, only: [:edit, :update] do
      member do
        get :about
      end
    end

    resources :dashboards, concerns: [:list] do
      collection do
        [:home, :relationship, :accountancy, :trade, :stocks, :production, :tools, :settings].each do |part|
          get part
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

    # resources :calculators, only: :index

    namespace :cells do
      resource :accountancy_balance_cell, only: :show
      resource :cashes_balance_cell, only: :show
      resource :cashes_balance_evolution_cell, only: :show
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
      resource :last_incoming_parcels_cell, only: :show, concerns: :list
      resource :last_issues_cell, only: :show, concerns: :list
      resource :last_intervention_cell, only: :show
      resource :last_movements_cell, only: :show, concerns: :list
      resource :last_outgoing_parcels_cell, only: :show, concerns: :list
      resource :last_products_cell, only: :show, concerns: :list
      resource :last_purchases_cell, only: :show, concerns: :list
      resource :last_sales_cell, only: :show, concerns: :list
      resource :main_settings_cell, only: :show
      resource :map_cell, only: :show
      resource :parts_cell, only: :show
      resource :quandl_cell, only: :show
      resource :revenues_by_product_nature_cell, only: :show
      resource :rss_cell, only: :show
      resource :settings_statistics_cell, only: :show
      resource :stewardship_cell, only: :show
      resource :stock_container_map_cell, only: :show
      resource :trade_counts_cell, only: :show
      resource :weather_cell, only: :show
      resource :working_sets_stocks_cell, only: :show
    end

    resources :accounts, concerns: [:list, :unroll] do
      collection do
        get :reconciliation
        get :list_reconciliation
        match 'load', via: [:get, :post]
      end
      member do
        match 'mark', via: [:get, :post]
        post :unmark
        get :list_journal_entry_items
        get :list_entities
      end
    end

    resources :activities, concerns: [:list, :unroll] do
      collection do
        get :family
        post :duplicate
      end
      member do
        get :list_distributions
        get :list_inspections
        # get :list_interventions
        get :list_productions
      end
    end

    resources :activity_budgets, concerns: [:unroll] do
      member do
        post :duplicate
      end
    end

    resources :activity_inspection_point_natures, concerns: [:autocomplete],
                                                  only: [], path: 'activity-inspection-point-natures'

    resources :activity_productions, concerns: [:unroll] do
      member do
        get :list_interventions
        get :list_target_distributions
      end
    end

    resources :activity_seasons, concerns: [:unroll]

    resources :affairs, concerns: [:list, :affairs], only: [:show, :index]

    resources :analyses, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    resources :analysis_items, only: [:new]

    resources :animal_groups, concerns: [:list, :picture, :unroll] do
      member do
        get :list_animals
        get :list_places
      end
    end

    resources :animals, concerns: :products do
      collection do
        # add routes for frontend animals column view
        match 'load_containers', via: [:get]
        match 'load_animals', via: [:get]
        match 'load_workers', via: [:get]
        match 'load_natures', via: [:get]
        match 'load_production_supports', via: [:get]
        put :change
        put :add_group
      end
      member do
        match :add_to_group, via: [:get, :post]
        match :add_to_variant, via: [:get, :post]
        match :add_to_container, via: [:get, :post]
        get :list_children
      end
    end

    resources :attachments, only: [:show, :create, :destroy]

    resources :bank_statements, concerns: [:list, :unroll], path: 'bank-statements' do
      collection do
        get :list_items
        match :import, via: [:get, :post]
      end
      member do
        match :reconciliation, via: [:get, :post]
      end
    end

    resources :bank_statement_items, only: [:new]

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

    resources :building_divisions, concerns: :products, path: 'building-divisions'

    resources :campaigns, concerns: [:list, :unroll] do
      collection do
        get :current
      end
      member do
        # get :list_activity_productions
        post :open
        delete :close
      end
    end

    resources :cap_islets, concerns: [:list, :unroll] do
      member do
        get :list_cap_land_parcels
        post :convert
      end
    end

    resources :cap_land_parcels, concerns: :list

    resources :cap_statements, concerns: [:list, :unroll] do
      member do
        get :list_cap_islets
        get :list_cap_land_parcels
      end
    end

    resources :cashes, concerns: [:list, :unroll] do
      member do
        get :list_deposits
        get :list_bank_statements
        get :list_sessions
      end
    end

    resources :cash_transfers, concerns: [:list, :unroll], path: 'cash-transfers'

    resources :catalog_items, concerns: [:list, :unroll], except: [:index]

    resources :catalogs, concerns: [:list, :unroll] do
      member do
        get :list_items
      end
    end

    resources :cobblers, only: [:update]

    resources :crumbs, only: [:index, :update, :destroy] do
      member do
        post :convert
      end
    end

    resources :cultivable_zones, concerns: [:list, :unroll], path: 'cultivable-zones' do
      member do
        get :list_productions
      end
    end

    resources :custom_fields, concerns: [:list, :unroll], path: 'custom-fields' do
      member do
        get :list_choices
        post :up
        post :down
        post :sort
      end
    end

    resources :custom_field_choices, except: [:index, :show], concerns: [:unroll], path: 'custom-field-choices' do
      member do
        post :up
        post :down
      end
    end

    resources :deliveries, concerns: [:list, :unroll] do
      member do
        get :list_parcels
        post :order
        post :prepare
        post :check
        post :start
        post :finish
        post :cancel
      end
    end

    resources :deposits, concerns: [:list, :unroll] do
      collection do
        get :list_unvalidateds
        get :list_depositable_payments
        match 'unvalidateds', via: [:get, :post]
      end
      member do
        get :list_payments
      end
    end

    resources :districts, concerns: [:list, :unroll]

    resources :document_templates, concerns: [:list, :unroll], path: 'document-templates' do
      collection do
        post :load
      end
    end

    resources :documents, concerns: [:list, :unroll]

    resource :draft_journal, only: [:show] do
      member do
        post :confirm
        get :list_journal_entry_items
      end
    end

    resources :entities, concerns: [:autocomplete, :list, :unroll] do
      collection do
        match 'import', via: [:get, :post]
        match 'merge',  via: [:get, :post]
      end
      member do
        match 'picture(/:style)', via: :get, action: :picture, as: :picture
        get :list_event_participations
        get :list_incoming_payments
        get :list_issues
        get :list_links
        get :list_purchases
        get :list_observations
        get :list_outgoing_payments
        get :list_sale_opportunities
        get :list_sales
        get :list_subscriptions
        get :list_tasks
      end
    end

    resources :entity_addresses, concerns: [:unroll]

    resources :entity_links

    resources :equipments, concerns: :products

    resources :event_participations

    resources :events, concerns: [:autocomplete, :list, :unroll] do
      collection do
        get :change_minutes
      end
      member do
        get :list_participations
      end
    end

    resources :exports, only: [:index, :show]

    resources :fixed_assets, concerns: [:list, :unroll], path: 'fixed-assets' do
      member do
        # get :cede
        # get :sell
        # post :depreciate
        get :list_depreciations
        get :list_products
      end
    end

    resources :financial_years, concerns: [:list, :unroll], path: 'financial-years' do
      member do
        match 'close', via: [:get, :post]
        match :generate_last_journal_entry, via: [:get, :post]
        post :compute_balances
        get :list_account_balances
        get :list_fixed_asset_depreciations
      end
    end

    resources :fungi, concerns: :products

    resources :gaps, concerns: [:list], except: [:new, :create, :edit, :update] do
      member do
        get :list_items
      end
    end

    resource :general_ledger, only: [:show], path: 'general-ledger' do
      member do
        get :list_journal_entry_items
      end
    end

    resources :georeadings, concerns: [:list, :unroll]

    resources :golumns, only: [:show, :update] do
      member do
        post :reset
      end
    end

    resources :guide_analyses, only: [:show], path: 'guide-analyses' do
      member do
        get :list_points
      end
    end

    resources :guides, concerns: [:list, :unroll] do
      member do
        post :run
        get :list_analyses
      end
    end

    resources :identifiers, concerns: [:list]

    resources :imports, concerns: [:list] do
      member do
        post :abort
        post :run
        get :progress
      end
    end

    resources :incoming_payments, concerns: [:list, :unroll]

    resources :incoming_payment_modes, concerns: [:list, :unroll] do
      member do
        post :up
        post :down
        post :reflect
      end
    end

    resources :integrations, except: [:show, :destroy] do
      collection do
        delete :destroy
      end
    end

    resources :interventions, concerns: [:list, :unroll] do
      collection do
        patch :compute
        get :modal
        post :change_state
      end
      member do
        post :sell
        post :purchase
        get :list_product_parameters
        get :list_record_interventions
      end
    end

    resources :inventories, concerns: [:list, :unroll] do
      member do
        post :reflect
        post :refresh
        get :list_items
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

    resources :januses, only: [] do
      member do
        post :toggle
        get :toggle
      end
    end

    resources :journals, concerns: [:list, :unroll] do
      collection do
        match 'bookkeep', via: [:get, :put, :post]
      end
      member do
        get :list_mixed
        get :list_items
        get :list_entries
        match 'close', via: [:get, :post]
        match 'reopen', via: [:get, :post]
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

    resources :labels, concerns: [:list, :unroll]

    resources :land_parcels, concerns: :products, path: 'land-parcels'

    resources :listing_nodes, except: [:index, :show], path: 'listing-nodes'

    resources :listings, concerns: [:list, :unroll], except: [:show] do
      member do
        get :extract
        post :duplicate
        match 'mail', via: [:get, :post]
      end
    end

    resources :loans, concerns: [:list, :unroll] do
      member do
        get :list_repayments
      end
    end

    resources :loan_repayments, only: [:index, :show], path: 'loan-repayments'

    resources :manure_management_plans, concerns: [:list, :unroll], path: 'manure-management-plans' do
      member do
        get :list_zones
      end
    end

    resources :map_backgrounds do
      collection do
        post :load
      end
      member do
        post :toggle
        put :star
        delete :destroy
      end
    end

    resources :map_editors, only: [] do
      collection do
        post :upload
      end
    end

    resources :matters, concerns: :products

    resources :net_services, concerns: [:list] do
      member do
        get :list_identifiers
      end
    end

    resources :notifications, only: [:show, :index, :destroy] do
      collection do
        delete :destroy
        get :unread
      end
    end

    resources :observations, except: [:index, :show]

    resources :outgoing_payments, concerns: [:list, :unroll]

    resources :outgoing_payment_modes, concerns: [:list, :unroll] do
      member do
        post :up
        post :down
      end
    end

    # resources :contacts, concerns: :entities

    resources :parcels, concerns: [:list, :unroll] do
      member do
        post :invoice
        get :list_incoming_items
        get :list_outgoing_items
        post :ship

        post :order
        post :prepare
        post :check
        post :give
        post :cancel
      end
    end

    resources :plant_density_abaci, concerns: [:list], path: 'plant-density-abaci'

    resources :plants, concerns: :products

    resources :postal_zones, concerns: [:autocomplete, :list, :unroll]

    resources :prescriptions, concerns: [:list, :unroll] do
      member do
        get :list_interventions
      end
    end

    resources :products, concerns: [:products]

    resources :inspections, concerns: [:list, :unroll] do
      member do
        get :export, defaults: { format: 'ods' }
      end
    end

    resources :product_groups, concerns: :products

    resources :product_localizations, except: [:index, :show]

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
        get :list_components
        get :list_catalog_items
        get :list_parcel_items
        get :list_products
        get :list_sale_items
        get :quantifiers
      end
    end

    resources :product_nature_variant_components, only: [],
                                                  concerns: [:autocomplete, :unroll]

    resources :purchase_natures, concerns: [:list, :unroll]

    resources :purchases, concerns: [:list, :unroll] do
      member do
        get :list_items
        get :list_parcels
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

    resources :sale_credits, only: [:new, :create], path: 'sale-credits'

    resources :sale_natures, concerns: [:list, :unroll], path: 'sale-natures'

    resources :sale_opportunities, concerns: [:list, :affairs], path: 'sale-opportunities' do
      member do
        get :list_tasks
        post :prospect
        post :evaluate
        post :lose
        post :negociate
        post :qualify
        post :quote
        post :win
      end
    end

    resources :sale_tickets, concerns: [:list, :affairs], only: [:index, :show], path: 'sale-tickets'

    resources :sales, concerns: [:list, :unroll] do
      collection do
        get :contacts
      end
      member do
        get :cancel
        get :list_items
        get :list_undelivered_items
        get :list_subscriptions
        get :list_parcels
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

    resources :sensors, concerns: [:list, :unroll] do
      collection do
        get :models
        get :detail
        get :last_locations
      end
      member do
        get :list_analyses
        post :retrieve
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

    resources :subscription_natures, concerns: [:list, :unroll], path: 'subscription-natures' do
      member do
        get :list_subscriptions
        get :list_product_natures
      end
    end

    resources :subscriptions, concerns: [:list, :unroll] do
      member do
        post :renew
        post :suspend
        post :takeover
      end
    end

    resources :supervisions, concerns: [:list, :unroll]

    resources :synchronizations, only: [:index] do
      member do
        post :run
      end
    end
    resources :target_distributions, concerns: [:list, :many], path: 'target-distributions' do
      collection do
        get :list_intervention_product_parameters
      end
    end

    resources :tasks, concerns: [:list] do
      member do
        post :reset
        post :start
        post :finish
      end
    end

    resources :taxes, concerns: [:list, :unroll] do
      collection do
        post :load
      end
    end

    resources :teams, concerns: [:list, :unroll]

    resources :tours, only: [] do
      member do
        post :finish
      end
    end

    resources :trackings, concerns: [:list, :unroll] do
      member do
        get :list_products
      end
    end

    resource :trial_balance, only: [:show], path: 'trial-balance'

    resources :users, concerns: [:list, :unroll] do
      member do
        post :lock
        post :unlock
      end
    end

    resources :visuals, only: [] do
      match 'picture(/:style)', via: :get, action: :picture, as: :picture
    end

    resources :wine_tanks, only: [:index], concerns: [:list]

    resources :workers, concerns: :products

    get :search, controller: :dashboards, as: :search

    root to: 'dashboards#home'

    get :invitations, to: 'invitations#index'
    get 'invitations/list', to: 'invitations#list'
    get 'invitations/new', to: 'invitations#new'
    post 'invitations', to: 'invitations#create'

    resources :registrations, only: [:index, :edit, :update, :destroy], concerns: [:list]
  end

  root to: 'public#index'
end
