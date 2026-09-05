require 'test_helper'

module Phytosanitary
  module Register
    module Exporters
      class XmlExporterTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
        def fixed_payload
          entry = Phytosanitary::Register::Entry.new(
            intervention_id: 1,
            intervention_number: 'INT-0001',
            intervention_input_id: 10,
            intervention_target_id: 100,
            holder_siret: '12345678901234',
            beneficiary_siret: nil,
            product_name: 'GLYPHOS 360',
            amm_number: '2050008',
            active_substances: nil,
            application_date: Date.new(2026, 5, 15),
            application_started_at: Time.utc(2026, 5, 15, 8, 0, 0),
            application_stopped_at: Time.utc(2026, 5, 15, 10, 30, 0),
            dose_value: BigDecimal('2.5'),
            dose_unit: 'liter_per_hectare',
            treated_area_value: BigDecimal('1.5'),
            treated_area_unit: 'hectare',
            treated_volume_value: nil,
            treated_volume_unit: nil,
            crop_name: 'Blé tendre',
            crop_variety: 'wheat',
            organic_production: false,
            location_geometry: 'POINT(0 0)',
            location_rpg_islet: '1',
            location_rpg_parcel: '001',
            phenological_bbch_stage: 30,
            seed_lot_number: nil,
            targeted_pest_name: 'Vulpin',
            application_mode: 'boom_spraying',
            early_reentry: false,
            early_reentry_ppe_description: nil,
            early_reentry_reason: nil,
            weather_condition_code: '502',
            weather_temperature: 22,
            weather_wind: 10,
            weather_humidity: 68
          )
          Phytosanitary::Register::Payload.new(
            holder_siret: '12345678901234',
            holder_name: 'Acme Farm',
            campaign_name: '2026',
            period_from: Time.utc(2026, 1, 1, 0, 0, 0),
            period_to: Time.utc(2026, 12, 31, 23, 59, 59),
            generated_at: Time.utc(2026, 6, 5, 10, 30, 0),
            entries: [entry]
          )
        end

        def parsed
          @parsed ||= Nokogiri::XML(Phytosanitary::Register::Exporters::XmlExporter.call(fixed_payload))
        end

        test 'XML exporter returns parseable XML' do
          doc = Nokogiri::XML(Phytosanitary::Register::Exporters::XmlExporter.call(fixed_payload))
          assert doc.errors.empty?, "Parse errors: #{doc.errors}"
        end

        test 'root element is PhytoRegister with namespace and version' do
          root = parsed.root
          assert_equal 'PhytoRegister', root.name
          assert_equal 'urn:fr:agri:phyto:register:1.0', root.namespaces['xmlns']
          assert_equal '1.0', root['formatVersion']
        end

        test 'Meta block carries holder and period' do
          parsed.remove_namespaces!
          assert_equal '12345678901234', parsed.at_xpath('//Meta/HolderSiret').content
          assert_equal '2026-01-01T00:00:00Z', parsed.at_xpath('//Meta/PeriodFrom').content
          assert_equal '2026-12-31T23:59:59Z', parsed.at_xpath('//Meta/PeriodTo').content
          assert_equal '1', parsed.at_xpath('//Meta/EntryCount').content
        end

        test 'Entry uses ids as attributes' do
          parsed.remove_namespaces!
          entry = parsed.at_xpath('//Entries/Entry')
          assert_equal '1', entry['interventionId']
          assert_equal '10', entry['interventionInputId']
          assert_equal '100', entry['interventionTargetId']
        end

        test 'Entry skips nil fields entirely' do
          parsed.remove_namespaces!
          entry = parsed.at_xpath('//Entries/Entry')
          assert_nil entry.at_xpath('./BeneficiarySiret')
          assert_nil entry.at_xpath('./SeedLotNumber')
        end

        test 'identical input produces identical output (deterministic)' do
          out1 = Phytosanitary::Register::Exporters::XmlExporter.call(fixed_payload)
          out2 = Phytosanitary::Register::Exporters::XmlExporter.call(fixed_payload)
          assert_equal out1, out2
        end
      end
    end
  end
end
