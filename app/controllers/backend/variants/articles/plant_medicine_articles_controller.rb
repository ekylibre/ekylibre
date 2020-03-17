module Backend
  module Variants
    module Articles
      class PlantMedicineArticlesController < Backend::Variants::ArticleVariantsController

        importable_from_lexicon :registered_phytosanitary_products, model_name: "Variants::Articles::#{controller_name.classify}".constantize

        list(model: :product_nature_variants, conditions: variants_conditions, collection: true) do |t|
          t.action :edit, url: { controller: '/backend/product_nature_variants' }
          t.action :destroy, if: :destroyable?, url: { controller: '/backend/product_nature_variants' }
          t.column :name, url: { namespace: :backend }
          t.status
          t.column :number
          t.column :nature, url: { controller: '/backend/product_natures' }
          t.column :category, url: { controller: '/backend/product_nature_categories' }
          t.column :current_stock_displayed, label: :current_stock
          t.column :current_outgoing_stock_ordered_not_delivered_displayed
          t.column :unit_name
          t.column :variety
          t.column :derivative_of
          t.column :active
        end

        list(:registered_phytosanitary_usages, conditions: ['product_id = ?', 'ProductNatureVariant.find(params[:id]).phytosanitary_product.france_maaid'.c],
                                               order: [:state, :ephy_usage_phrase],
                                               per_page: 10) do |t|
          t.column :lib_court, label_method: :decorated_lib_court
          t.column :ephy_usage_phrase, label_method: :decorated_ephy_usage_phrase
          t.status
          t.column :dose_quantity, label_method: :decorated_dose_quantity, class: 'center-align'
          t.column :applications_count, class: 'center-align'
          t.column :pre_harvest_delay, label_method: :decorated_pre_harvest_delay, class: 'center-align'
          t.column :applications_frequency, label_method: :decorated_applications_frequency, class: 'center-align'
          t.column :untreated_buffer_aquatic, label_method: :decorated_untreated_buffer_aquatic, class: 'center-align'
          t.column :usage_conditions, label_method: :decorated_usage_conditions, class: 'center-align'
          t.column :decision_date, class: 'center-align', hidden: true
          t.column :development_stage_min, label_method: :decorated_development_stage_min, class: 'center-align', hidden: true
          t.column :untreated_buffer_arthropod, label_method: :decorated_untreated_buffer_arthropod, class: 'center-align', hidden: true
          t.column :untreated_buffer_plants, label_method: :decorated_untreated_buffer_plants, class: 'center-align', hidden: true
        end

        list(:registered_phytosanitary_risks, select: { 'rps.symbol_name' => 'symbol_name', "string_agg(rps.id, ', ')" => 'mentions' },
                                              joins: 'INNER JOIN registered_phytosanitary_symbols AS rps ON rps.id = registered_phytosanitary_risks.risk_code',
                                              conditions: ["product_id = ? AND rps.symbol_name <> ''", 'ProductNatureVariant.find(params[:id]).phytosanitary_product.france_maaid'.c],
                                              count: 'DISTINCT rps.symbol_name',
                                              group: 'rps.symbol_name',
                                              order: 'mentions',
                                              per_page: 10) do |t|
          t.column :type
          t.column :symbol_name, label_method: :decorated_symbol_name, class: 'center-align'
          t.column :description
          t.column :mentions
        end
      end
    end
  end
end
