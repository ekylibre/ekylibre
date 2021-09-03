class UpdateDocumentTemplateFileExtensionFix < ActiveRecord::Migration[5.0]
  NATURES = %w[account_journal_entry_sheet activity_cost fixed_asset_registry fixed_asset_sheet fr_pcg82_balance_sheet fr_pcg82_profit_and_loss_statement fr_pcga_balance_sheet intervention_register intervention_sheet inventory_sheet journal_entry_sheet loan_registry outgoing_delivery_docket phytosanitary_register purchases_invoice sales_estimate sales_invoice sales_order vat_register outgoing_delivery_docket purchases_invoice].freeze

  def up
    execute "UPDATE document_templates SET file_extension='odt' WHERE nature IN (#{NATURES.map { |v| "'#{v}'" }.join(', ')}) "
  end

  def down
    #Nope
  end
end
