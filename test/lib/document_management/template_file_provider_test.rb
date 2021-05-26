require 'test_helper'

module Ekylibre
  module DocumentManagement
    class TemplateFileProviderTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @tfp = TemplateFileProvider.build
      end

      test 'all natures have a template' do
        missing = %w[
          entity_sheet equipment_certification exchange_accountancy_file_fr fixed_asset_sheet incoming_delivery_docket journal
          manure_management_plan manure_management_plan_sheet outgoing_deliveries_journal pfi_land_parcel_register
          phytosanitary_certification prescription products_sheet provisional_manure_management_plan purchases_estimate
          purchases_original security_data_sheet stocks tax_assessment vine_phytosanitary_register wine_bottling_register
          wine_detention_register wine_manipulation_register fec_data_error fec_structure_error wine_incoming_harvest_register
        ]

        # Keep the test up to date: If a nature is removed make sure it is not flagged as missing
        # Missing document is present in Nomenclature but not in Ekylibre
        missing.each do |nature|
          assert Onoma::DocumentNature.all.include?(nature), "Unable to find template for nature #{nature} in Onoma"
        end

        # Missing elements should NOT have a template
        missing.each do |nature|
          assert_nil @tfp.find_by_nature(nature), "Found a template for nature #{nature} which is marked as missing in the test"
        end

        (Onoma::DocumentNature.all - missing).each do |nature|
          assert @tfp.find_by_nature(nature), "Unable to find template for nature #{nature}"
        end
      end
    end
  end
end
