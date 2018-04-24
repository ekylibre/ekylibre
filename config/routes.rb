Rails.application.routes.draw do
  # resources :interventions_costs, concerns: [:list, :unroll]
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
    concerns :list, :unroll, :picture
    member do
      get :list_carried_linkages
      get :list_carrier_linkages
      get :list_contained_products
      get :list_fixed_assets
      get :list_groups
      get :list_inspections
      get :list_intervention_product_parameters
      get :list_issues
      get :list_readings
      get :list_trackings
      get :list_members
      get :list_shipment_items
      get :list_reception_items
      get :list_parcel_item_storings
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
                     skip: %i[invitations registrations],
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
      resources :tokens, only: %i[create destroy]
      resources :contacts, only: [:index] do
        match 'picture(/:style)', via: :get, action: :picture, as: :picture
      end
      resources :crumbs, only: %i[index create]
      resources :interventions, only: %i[index create]
      resources :intervention_participations, only: [:create]
      resources :intervention_targets, only: [:show]
      resources :issues, only: %i[index create]
      resources :plant_density_abaci, only: %i[index show]
      resources :plant_countings, only: %i[create]
      resources :plants, only: %i[index]
    end
  end

  namespace :iot, path: 'iot/v1' do
    resources :analyses, only: [:create], path: 'a'
  end

  # Plugins can override backend routes but only complete API ones
  plugins

  # Backend
  namespace :backend do
    resource :myself, path: 'me', only: %i[show update] do
      member do
        patch :change_password
      end
    end

    resource :settings, only: [] do
      member do
        get :about
      end
    end

    resources :dashboards, concerns: [:list] do
      collection do
        %i[home relationship accountancy sales purchases stocks production humans tools settings].each do |part|
          get part
        end
        get :sandbox
      end
    end

    resources :debt_transfers, path: 'debt-transfers', only: %i[create destroy]

    resources :helps, only: %i[index show] do
      collection do
        post :toggle
      end
    end

    namespace :calculators do
    end

    # resources :calculators, only: :index

    namespace :cobbles do
      resource :production_cost_cobble, only: :show
      resource :stock_in_ground_cobble, only: :show
    end

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
      resource :last_purchases_invoices_cell, only: :show, concerns: :list
      resource :last_purchases_orders_cell, only: :show, concerns: :list
      resource :last_sales_cell, only: :show, concerns: :list
      resource :main_settings_cell, only: :show
      resource :map_cell, only: :show
      resource :parts_cell, only: :show
      resource :profit_and_loss_cell, only: :show
      resource :quandl_cell, only: :show
      resource :revenues_by_product_nature_cell, only: :show
      resource :rss_cell, only: :show
      resource :settings_statistics_cell, only: :show
      resource :stewardship_cell, only: :show
      resource :stock_container_map_cell, only: :show
      resource :trade_counts_cell, only: :show
      resource :unbalanced_clients_cell, only: :show, concerns: :list
      resource :unbalanced_suppliers_cell, only: :show, concerns: :list
      resource :weather_cell, only: :show
      resource :working_sets_stocks_cell, only: :show
    end

    resources :accounts, concerns: %i[list unroll] do
      collection do
        get :reconciliation
        get :list_reconciliation
        match 'load', via: %i[get post]
        patch :mask_lettered_items
      end
      member do
        match 'mark', via: %i[get post]
        post :unmark
        get :list_journal_entry_items
        get :list_entities
        get :list_product_nature_variants
      end
    end

    resources :activities, concerns: %i[list unroll] do
      collection do
        get :family
        post :duplicate
      end
      member do
        get :list_distributions
        get :list_inspections
        # get :list_interventions
        get :list_productions
        get :list_supports
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
      end
    end

    resources :activity_seasons, concerns: [:unroll]

    # resources :affairs, concerns: [:affairs, :list], only: [:show, :index]
    resources :affairs, only: [:unroll]

    resources :analyses, concerns: %i[list unroll] do
      member do
        get :list_items
      end
    end

    resources :analysis_items, only: [:new]

    resources :animal_groups, concerns: :products do
      member do
        get :list_animals
        get :list_places
      end
    end

    resources :animals, concerns: :products do
      collection do
        # add routes for frontend animals column view
        match 'load_animals', via: [:get]
        post :change
        put :add_group
        post :keep
        get :matching_interventions
      end
      member do
        match :add_to_group, via: %i[get post]
        match :add_to_variant, via: %i[get post]
        match :add_to_container, via: %i[get post]
        get :list_children
      end
    end

    resources :attachments, only: %i[show create destroy]

    namespace :bank_reconciliation, path: 'bank-reconciliation' do
      resources :gaps, only: %i[create]
      resources :items, only: [:index] do
        collection do
          get :reconciliate
          get :count
        end
      end
      resources :letters, only: %i[create destroy]
    end

    resources :bank_statements, concerns: %i[list unroll], path: 'bank-statements' do
      collection do
        get :list_items
        match :import, via: %i[get post]
        get :edit_interval
      end
    end

    resources :bank_statement_items, only: %i[new create destroy], path: 'bank-statement-items'

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

    resources :campaigns, concerns: %i[list unroll] do
      collection do
        get :current
      end
      member do
        # get :list_activity_productions
        post :open
        delete :close
      end
    end

    resources :cap_islets, concerns: %i[list unroll] do
      member do
        get :list_cap_land_parcels
        post :convert
      end
    end

    resources :cap_land_parcels, concerns: :list

    resources :cap_statements, concerns: %i[list unroll] do
      member do
        get :list_cap_islets
        get :list_cap_land_parcels
      end
    end

    resources :cashes, concerns: %i[list unroll] do
      member do
        get :list_deposits
        get :list_bank_statements
        get :list_sessions
      end
    end

    resources :cash_transfers, concerns: %i[list unroll], path: 'cash-transfers'

    resources :catalog_items, concerns: %i[list unroll], except: [:index]

    resources :catalogs, concerns: %i[list unroll] do
      member do
        get :list_items
      end
    end

    resources :cobblers, only: [:update]

    resource :company, only: %i[edit update]

    resources :contracts, concerns: [:list] do
      member do
        get :list_items
        get :list_receptions
        post :lose
        post :negociate
        post :prospect
        post :quote
        post :win
      end
    end

    resources :crumbs, only: %i[index update destroy] do
      member do
        post :convert
      end
    end

    resources :cultivable_zones, concerns: %i[list unroll], path: 'cultivable-zones' do
      member do
        get :list_productions
      end
    end

    resources :custom_fields, concerns: %i[list unroll], path: 'custom-fields' do
      member do
        get :list_choices
        post :up
        post :down
        post :sort
      end
    end

    resources :custom_field_choices, only: [], concerns: [:unroll], path: 'custom-field-choices' do
      member do
        post :up
        post :down
      end
    end

    resources :deliveries, concerns: %i[list unroll] do
      member do
        get :list_parcels
        get :list_receptions
        get :list_shipments
        post :order
        post :prepare
        post :check
        post :start
        post :finish
        post :cancel
      end
    end

    resources :deposits, concerns: %i[list unroll] do
      collection do
        get :list_unvalidateds
        get :list_depositable_payments
        match 'unvalidateds', via: %i[get post]
      end
      member do
        get :list_payments
      end
    end

    resources :districts, concerns: %i[list unroll]

    resources :document_templates, concerns: %i[list unroll], path: 'document-templates' do
      collection do
        post :load
      end
    end

    resources :documents, concerns: %i[list unroll]

    resource :draft_journal, only: [:show] do
      member do
        post :confirm
        get :list_journal_entry_items
      end
    end

    resources :entities, concerns: %i[autocomplete list unroll] do
      collection do
        match 'import', via: %i[get post]
        patch :mask_lettered_items
        match 'merge', via: %i[get post]
      end
      member do
        match 'picture(/:style)', via: :get, action: :picture, as: :picture
        post :toggle
        get :list_client_journal_entry_items
        get :list_contracts
        get :list_event_participations
        get :list_incoming_payments
        get :list_receptions
        get :list_issues
        get :list_links
        get :list_purchases
        get :list_purchase_invoices
        get :list_purchase_orders
        get :list_observations
        get :list_purchase_payments
        get :list_shipments
        get :list_sale_opportunities
        get :list_sales
        get :list_subscriptions
        get :list_supplier_journal_entry_items
        get :list_tasks
      end
    end

    resources :entity_addresses, concerns: [:unroll]

    resources :entity_links

    resources :equipments, concerns: :products

    resources :event_participations

    resources :events, concerns: %i[autocomplete list unroll] do
      collection do
        get :change_minutes
      end
      member do
        get :list_participations
      end
    end

    resources :exports, only: %i[index show]

    resources :fixed_assets, concerns: %i[list unroll], path: 'fixed-assets' do
      collection do
        post :depreciate, action: :depreciate_all
      end

      member do
        post :depreciate
        get :list_depreciations
        post :start_up
        post :sell
        post :scrap
      end
    end

    resources :fixed_asset_depreciations, path: 'fixed-asset-depreciations', only: [:show]

    resources :financial_years, concerns: %i[list unroll], path: 'financial-years' do
      member do
        match 'close', via: %i[get post]
        post :compute_balances
        get :list_account_balances
        get :list_fixed_asset_depreciations
        get :list_exchanges
      end
    end

    resources :financial_year_exchanges, path: 'financial-year-exchanges', only: %i[new create show] do
      member do
        get :list_journal_entries
        get :journal_entries_export
        get :journal_entries_import
        post :journal_entries_import
        get :notify_accountant
        get :close
      end
    end

    resources :fungi, concerns: :products

    resource :general_ledger, only: [:show], path: 'general-ledger' do
      member do
        get :list_journal_entry_items
      end
    end

    resources :georeadings, concerns: %i[list unroll]

    resources :golumns, only: %i[show update] do
      member do
        post :reset
      end
    end

    resources :guide_analyses, only: [:show], path: 'guide-analyses' do
      member do
        get :list_points
      end
    end

    resources :guides, concerns: %i[list unroll] do
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

    resources :incoming_payments, concerns: %i[list unroll]

    resources :incoming_payment_modes, concerns: %i[list unroll] do
      member do
        post :up
        post :down
        post :reflect
      end
    end

    resources :integrations, except: %i[show destroy] do
      collection do
        get ':nature/check', action: :check
        get ':nature', action: :new
        delete ':nature', action: :destroy
      end
    end

    resources :interventions, concerns: %i[list unroll] do
      collection do
        patch :compute
        get :modal
        post :change_state
        get :change_page
        get :purchase_order_items
      end
      member do
        post :sell
        post :purchase
        get :list_product_parameters
        get :list_record_interventions
        get :list_service_deliveries
      end
    end

    namespace :interventions do
      resources :costs, only: [] do
        collection do
          get :parameter_cost
        end
      end
    end

    resources :intervention_participations, only: %i[index update destroy] do
      collection do
        get :participations_modal
      end
      member do
        post :convert
      end
    end

    resources :inventories, concerns: %i[list unroll] do
      member do
        post :reflect
        post :refresh
        get :list_items
      end
    end

    resources :issues, concerns: %i[list picture unroll] do
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

    resources :journals, concerns: %i[list unroll] do
      collection do
        match 'bookkeep', via: %i[get put post]
      end
      member do
        get :list_mixed
        get :list_items
        get :list_entries
        match 'close', via: %i[get post]
        match 'reopen', via: %i[get post]
      end
    end

    resources :journal_entries, concerns: %i[list unroll] do
      collection do
        get :currency_state, path: 'currency-state'
        patch :toggle_autocompletion, path: 'toggle-autocompletion'
      end
      member do
        get :list_items
      end
    end

    resources :journal_entry_items, only: %i[show index], concerns: %i[list unroll]

    resources :kujakus, only: [] do
      member do
        post :toggle
      end
    end

    resources :labels, concerns: %i[list unroll]

    resources :land_parcels, concerns: :products, path: 'land-parcels'

    resources :listing_nodes, except: %i[index show], path: 'listing-nodes'

    resources :listings, concerns: %i[list unroll], except: [:show] do
      member do
        get :extract
        post :duplicate
        match 'mail', via: %i[get post]
      end
    end

    resources :loans, concerns: %i[list unroll] do
      collection do
        post :bookkeep
      end

      member do
        get :list_repayments

        post :confirm
        post :repay
      end
    end

    resources :loan_repayments, only: %i[index show edit update], path: 'loan-repayments'

    resources :manure_management_plans, concerns: %i[list unroll], path: 'manure-management-plans' do
      member do
        get :list_zones
      end
    end

    resources :map_layers, path: 'map-layers' do
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

    resources :map_editor_shapes, only: :index

    resources :matters do
      concerns :products, :list
    end

    resources :net_services, concerns: [:list] do
      member do
        get :list_identifiers
      end
    end

    resources :notifications, only: %i[show index destroy] do
      collection do
        delete :destroy
        get :unread, action: :index, mode: :unread
      end
    end

    resources :observations, except: %i[index show]

    resources :outgoing_payment_lists, only: %i[index show destroy new create], concerns: [:list] do
      member do
        get :list_payments
        get :export_to_sepa
      end
    end

    resources :outgoing_payment_modes, concerns: %i[list unroll] do
      member do
        post :up
        post :down
      end
    end

    # resources :contacts, concerns: :entities

    resources :receptions, concerns: %i[list unroll] do
      member do
        get :list_items
        get :list_storings

        post :give
      end
    end

    resources :shipments, concerns: %i[list unroll] do
      member do
        get :list_items

        post :ship

        post :order
        post :prepare
        post :check
        post :give
        post :cancel
      end
    end

    resources :payslip_affairs, concerns: %i[affairs list], only: %i[show index], path: 'payslip-affairs'

    resources :payslip_natures, concerns: %i[list unroll], path: 'payslip-natures'

    resources :payslip_payments, concerns: %i[list unroll], path: 'payslip-payments'

    resources :payslips, concerns: %i[list unroll] do
      member do
        post :correct
        post :invoice
      end
    end

    resources :plant_density_abaci, except: [:index], path: 'plant-density-abaci'

    resources :plant_density_abacus_items, only: [:new], concerns: [:unroll], path: 'plant-density-abacus-items'

    resources :plants, concerns: :products do
      member do
        get :list_plant_countings
      end
    end

    resources :postal_zones, concerns: %i[autocomplete list unroll]

    resources :prescriptions, concerns: %i[list unroll] do
      member do
        get :list_interventions
      end
    end

    resources :products, concerns: %i[products many]

    namespace :purchase_process do
      resources :reconciliation, only: [] do
        collection do
          get :purchase_orders_to_reconciliate
          get :receptions_to_reconciliate
        end
      end
    end

    resources :inspections, concerns: %i[list unroll] do
      member do
        get :export, defaults: { format: 'ods' }
      end
    end

    resources :plant_countings, concerns: [:list]

    resources :preferences, only: %i[update]

    resources :product_groups, concerns: :products

    resources :product_localizations, except: %i[index show]

    resources :product_natures, concerns: %i[incorporate list unroll] do
      member do
        get :list_variants
      end
    end

    resources :product_nature_categories, concerns: %i[incorporate list unroll] do
      member do
        get :list_products
        get :list_product_natures
        get :list_taxations
      end
    end

    resources :product_nature_variants, concerns: %i[incorporate list picture unroll] do
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
                                                  concerns: %i[autocomplete unroll]

    resources :purchase_affairs, concerns: %i[affairs list], only: %i[show index], path: 'purchase-affairs'

    resources :purchase_gaps, concerns: [:list], except: %i[new create edit update], path: 'purchase-gaps' do
      member do
        get :list_items
      end
    end

    resources :purchase_natures, concerns: %i[list unroll], path: 'purchase-natures'

    resources :purchase_payments, concerns: %i[list unroll], path: 'purchase-payments'

    resources :purchases, concerns: %i[list unroll] do
      member do
        get :list_items
        get :list_parcels
        get :payment_mode
        post :abort
        post :confirm
        post :correct
        post :invoice
        post :pay
        post :propose
        post :propose_and_invoice
        post :refuse
      end
    end

    namespace :purchases do
      resources :reconcilation_states, only: [] do
        member do
          get :put_reconcile_state
          get :put_to_reconcile_state
          get :put_accepted_state
        end
      end
    end

    resources :purchase_orders, concerns: %i[list unroll] do
      collection do
        get :reconciliate_modal
      end
      member do
        get :list_items
        post :open
        post :close
      end
    end

    resources :purchase_invoices, concerns: %i[list unroll] do
      member do
        get :list_items
        get :list_receptions
        get :payment_mode
        post :pay
      end
    end

    resources :quick_purchases, only: %i[new create], path: 'quick-purchases'
    resources :quick_sales,     only: %i[new create], path: 'quick-sales'

    resources :regularizations, only: %i[show create destroy]

    resources :roles, concerns: %i[incorporate list unroll] do
      member do
        get :list_users
      end
    end

    resources :sale_credits, only: %i[new create], path: 'sale-credits'

    resources :sale_gaps, concerns: [:list], except: %i[new create edit update], path: 'sale-gaps' do
      member do
        get :list_items
      end
    end

    resources :sale_natures, concerns: %i[list unroll], path: 'sale-natures'

    resources :sale_affairs, concerns: %i[affairs list], only: %i[index show], path: 'sale-affairs'

    resources :sale_opportunities, concerns: %i[affairs list], path: 'sale-opportunities' do
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

    resources :sale_tickets, concerns: %i[affairs list], only: %i[index show], path: 'sale-tickets'

    resources :sales, concerns: %i[list unroll] do
      collection do
        get :contacts
      end
      member do
        get :cancel
        get :list_items
        get :list_undelivered_items
        get :list_subscriptions
        get :list_shipments
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

    resources :sensors, concerns: %i[list unroll] do
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

    resources :sequences, concerns: %i[list unroll] do
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

    resources :subscription_natures, concerns: %i[list unroll], path: 'subscription-natures' do
      member do
        get :list_subscriptions
        get :list_product_natures
      end
    end

    resources :subscriptions, concerns: %i[list unroll] do
      member do
        post :renew
        post :suspend
        post :takeover
      end
    end

    resources :supervisions, concerns: %i[list unroll]

    resources :synchronizations, only: [:index] do
      member do
        post :run
      end
    end

    resources :tasks, concerns: [:list] do
      member do
        post :reset
        post :start
        post :finish
      end
    end

    resources :taxes, concerns: %i[list unroll] do
      collection do
        post :load
      end
    end

    resources :teams, concerns: %i[list unroll]

    resources :project_budgets, concerns: %i[list unroll]

    resources :tours, only: [] do
      member do
        post :finish
      end
    end

    resources :trackings, concerns: %i[list unroll] do
      member do
        get :list_products
      end
    end

    resource :trial_balance, only: [:show], path: 'trial-balance'

    resources :users, concerns: %i[list unroll] do
      member do
        post :lock
        post :unlock
      end
    end

    namespace :users do
      resources :wice_grid_preferences, only: [] do
        collection do
          post :save_column
        end
      end
    end

    resources :tax_declarations, concerns: %i[list unroll], path: 'tax-declarations' do
      member do
        post :propose
        post :confirm
      end
    end

    resources :unreceived_purchase_orders, concerns: [:list] do
      member do
        post :open
        post :close
      end
    end

    namespace :variants do
      resources :fixed_assets, only: [] do
        member do
          get :fixed_assets_datas
        end
      end
    end

    resources :visuals, only: [] do
      match 'picture(/:style)', via: :get, action: :picture, as: :picture
    end

    namespace :visualizations do
      resource :plants_visualizations, only: :show
      resource :map_cells_visualizations, only: :show
      resource :land_parcels_visualizations, only: :show
      resource :resources_visualizations, only: :show
    end

    resources :wine_tanks, only: [:index], concerns: [:list]

    resources :workers, concerns: :products

    get :search, controller: :dashboards, as: :search

    root to: 'dashboards#home'

    get :invitations, to: 'invitations#index'
    get 'invitations/list', to: 'invitations#list'
    get 'invitations/new', to: 'invitations#new'
    post 'invitations', to: 'invitations#create'

    resources :registrations, only: %i[index edit update destroy], concerns: [:list]
  end

  namespace :public do
    resources :financial_year_exchange_exports, path: 'financial-year-exchange-exports', only: [:show] do
      get :csv, on: :member
    end
  end

  root to: 'public#index'
end
