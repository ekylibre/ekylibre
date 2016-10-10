class FixCustomFieldData < ActiveRecord::Migration
  CUSTOMIZABLE_TABLES = [:accounts, :activities, :activity_budgets, :activity_productions, :affairs, :analyses, :attachments, :bank_statements, :campaigns, :cap_islets, :cap_land_parcels, :cap_statements, :cash_transfers, :cashes, :catalog_items, :catalogs, :cultivable_zones, :dashboards, :deliveries, :delivery_tools, :deposits, :districts, :document_templates, :documents, :entities, :entity_links, :event_participations, :events, :financial_years, :fixed_assets, :georeadings, :guides, :identifiers, :imports, :incoming_payment_modes, :incoming_payments, :intervention_parameters, :intervention_working_periods, :interventions, :inventories, :issues, :journal_entries, :journals, :listings, :loan_repayments, :loans, :net_services, :notifications, :outgoing_payment_modes, :outgoing_payments, :parcels, :postal_zones, :prescriptions, :product_movements, :product_nature_categories, :product_nature_variants, :product_natures, :products, :purchase_natures, :purchases, :roles, :sale_natures, :sales, :sensors, :sequences, :subscription_natures, :subscriptions, :supervision_items, :supervisions, :tasks, :taxes, :teams, :trackings].freeze

  NO_MORE_CUSTOMIZABLE_TABLES = [:activity_budgets, :affairs, :attachments, :campaigns, :cap_islets, :cap_land_parcels, :cap_statements, :catalogs, :catalog_items, :dashboards, :delivery_tools, :districts, :document_templates, :entity_links, :event_participations, :georeadings, :guides, :identifiers, :imports, :incoming_payment_modes, :intervention_parameters, :intervention_working_periods, :journal_entries, :listings, :loan_repayments, :net_services, :notifications, :outgoing_payment_modes, :postal_zones, :product_movements, :purchase_natures, :roles, :sale_natures, :sequences, :subscription_natures, :supervision_items, :teams, :trackings, :taxes].freeze

  MODEL_TABLES = { 'Account' => :accounts, 'Activity' => :activities, 'ActivityBudget' => :activity_budgets, 'ActivityProduction' => :activity_productions, 'Affair' => :affairs, 'Analysis' => :analyses, 'Animal' => :products, 'AnimalGroup' => :products, 'Attachment' => :attachments, 'BankStatement' => :bank_statements, 'Bioproduct' => :products, 'Building' => :products, 'BuildingDivision' => :products, 'Campaign' => :campaigns, 'CapIslet' => :cap_islets, 'CapLandParcel' => :cap_land_parcels, 'CapStatement' => :cap_statements, 'Cash' => :cashes, 'CashTransfer' => :cash_transfers, 'Catalog' => :catalogs, 'CatalogItem' => :catalog_items, 'CultivableZone' => :cultivable_zones, 'CustomField' => :custom_fields, 'Dashboard' => :dashboards, 'Delivery' => :deliveries, 'DeliveryTool' => :delivery_tools, 'Deposit' => :deposits, 'District' => :districts, 'Document' => :documents, 'DocumentTemplate' => :document_templates, 'Easement' => :products, 'Entity' => :entities, 'EntityLink' => :entity_links, 'Equipment' => :products, 'Event' => :events, 'EventParticipation' => :event_participations, 'FinancialYear' => :financial_years, 'FixedAsset' => :fixed_assets, 'Fungus' => :products, 'Georeading' => :georeadings, 'Guide' => :guides, 'Identifier' => :identifiers, 'Import' => :imports, 'IncomingPayment' => :incoming_payments, 'IncomingPaymentMode' => :incoming_payment_modes, 'Intervention' => :interventions, 'InterventionAgent' => :intervention_parameters, 'InterventionParameter' => :intervention_parameters, 'InterventionProductParameter' => :intervention_parameters, 'InterventionWorkingPeriod' => :intervention_working_periods, 'Inventory' => :inventories, 'Issue' => :issues, 'Journal' => :journals, 'JournalEntry' => :journal_entries, 'LandParcel' => :products, 'Listing' => :listings, 'Loan' => :loans, 'LoanRepayment' => :loan_repayments, 'Matter' => :products, 'NetService' => :net_services, 'Notification' => :notifications, 'OutgoingPayment' => :outgoing_payments, 'OutgoingPaymentMode' => :outgoing_payment_modes, 'Parcel' => :parcels, 'Plant' => :products, 'PostalZone' => :postal_zones, 'Prescription' => :prescriptions, 'Product' => :products, 'ProductGroup' => :products, 'ProductMovement' => :product_movements, 'ProductNature' => :product_natures, 'ProductNatureCategory' => :product_nature_categories, 'ProductNatureVariant' => :product_nature_variants, 'Purchase' => :purchases, 'PurchaseNature' => :purchase_natures, 'Role' => :roles, 'Sale' => :sales, 'SaleNature' => :sale_natures, 'SaleOpportunity' => :affairs, 'SaleTicket' => :affairs, 'Sensor' => :sensors, 'Sequence' => :sequences, 'Settlement' => :products, 'SubZone' => :products, 'Subscription' => :subscriptions, 'SubscriptionNature' => :subscription_natures, 'Supervision' => :supervisions, 'SupervisionItem' => :supervision_items, 'Task' => :tasks, 'Tax' => :taxes, 'Team' => :teams, 'Tracking' => :trackings, 'User' => :users, 'VegetalActivity' => :activities, 'Worker' => :products, 'Zone' => :products }.freeze
  CUSTOM_DATA_COLUMN = :custom_fields

  def change
    CUSTOMIZABLE_TABLES.each do |table|
      next if NO_MORE_CUSTOMIZABLE_TABLES.include?(table)
      add_column table, CUSTOM_DATA_COLUMN, :jsonb
    end

    custom_fields = select_values('SELECT column_name, customized_type, nature, id FROM custom_fields')
    fields = custom_fields.each_with_object({}) do |field, hash|
      table = MODEL_TABLES[field['customized_type']]
      unless table
        # puts 'Unknown model: ' + field.inspect
        next
      end
      hash[table] ||= []
      hash[table] << {
        id: field[:id].to_i,
        nature: field[:nature].to_sym,
        column_name: field[:column_name].gsub(/(\A\_+|\_+\z)/, '').to_sym,
        old_column_name: field[:column_name].to_sym
      }
      hash
    end

    fields.each do |table, fields|
      unless NO_MORE_CUSTOMIZABLE_TABLES.include?(table)
        query = "UPDATE #{table} SET #{CUSTOM_DATA_COLUMN} = ('{' || "
        query << fields.map do |field|
          query << "'\"#{field[:column_name]}\":' || "
          query += if field[:nature] == :boolean
                     "CASE WHEN #{field[:old_column_name]} IS TRUE THEN 'true' ELSE 'false' END"
                   elsif field[:nature] == :decimal
                     "#{field[:old_column_name]}::VARCHAR"
                   else
                     "'\"' || REPLACE(#{field[:old_column_name]}, '\"', '\\\"') || '\"'"
                   end
        end.join(" || ',' || ")
        query << " || '}')::JSON".gsub("' || '", '')
        execute query
        execute "UPDATE custom_fields SET column_name = '#{field[:colum_name]}' WHERE id = #{field[:id]}"
      end
      fields.each do |field|
        remove_column table, field[:old_column_name]
      end
    end
  end
end
