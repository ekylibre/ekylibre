require 'test_helper'

module Printers
  class TemplateFileProviderTest < Ekylibre::Testing::ApplicationTestCase
    setup do
      @tfp = TemplateFileProvider.new
    end

    test 'all natures have a template' do
      missing = %w[
        entity_sheet equipment_certification exchange_accountancy_file_fr fixed_asset_sheet incoming_delivery_docket journal
        manure_management_plan manure_management_plan_sheet outgoing_deliveries_journal phytosanitary_certification prescription
        products_sheet provisional_manure_management_plan purchases_estimate purchases_order purchases_original security_data_sheet
        stocks tax_assessment vine_phytosanitary_register wine_bottling_register wine_detention_register wine_manipulation_register
      ]

      # Keep the test up to date: If a nature is removed make sure it is not flagged as missing
      assert missing.all? {|s| Nomen::DocumentNature.all.include?(s)}

      # Missing elements should NOT have a template
      missing.each do |nature|
        assert_nil @tfp.find_by_nature(nature),"Found a template for nature #{nature} which is marked as missing in the test"
      end

      (Nomen::DocumentNature.all - missing).each do |nature|
        assert @tfp.find_by_nature(nature), "Unable to find template for nature #{nature}"
      end
    end
  end
end
