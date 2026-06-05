require 'test_helper'

module Phytosanitary
  module Register
    module Exporters
      class JsonExporterTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
        def fixed_payload
          generated_at = Time.utc(2026, 6, 5, 10, 30, 0)
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
            generated_at: generated_at,
            entries: [entry]
          )
        end

        test 'JSON exporter returns parseable JSON' do
          output = Phytosanitary::Register::Exporters::JsonExporter.call(fixed_payload)
          parsed = JSON.parse(output)
          assert parsed.key?('meta')
          assert parsed.key?('entries')
        end

        test 'meta block carries schema, version, holder, period' do
          output = Phytosanitary::Register::Exporters::JsonExporter.call(fixed_payload)
          meta = JSON.parse(output).fetch('meta')
          assert_equal 'urn:fr:agri:phyto:register:1.0', meta['schema']
          assert_equal '1.0', meta['format_version']
          assert_equal '12345678901234', meta['holder_siret']
          assert_equal 1, meta['entry_count']
          assert_equal '2026-01-01T00:00:00Z', meta['period_from']
          assert_equal '2026-12-31T23:59:59Z', meta['period_to']
        end

        test 'entry serializes BigDecimal as string' do
          output = Phytosanitary::Register::Exporters::JsonExporter.call(fixed_payload)
          entry = JSON.parse(output).fetch('entries').first
          assert_equal '2.5', entry['dose_value']
          assert_equal '1.5', entry['treated_area_value']
        end

        test 'entry serializes Date as ISO 8601' do
          output = Phytosanitary::Register::Exporters::JsonExporter.call(fixed_payload)
          entry = JSON.parse(output).fetch('entries').first
          assert_equal '2026-05-15', entry['application_date']
        end

        test 'entry serializes Time as UTC ISO 8601 with Z suffix' do
          output = Phytosanitary::Register::Exporters::JsonExporter.call(fixed_payload)
          entry = JSON.parse(output).fetch('entries').first
          assert_equal '2026-05-15T08:00:00Z', entry['application_started_at']
          assert_equal '2026-05-15T10:30:00Z', entry['application_stopped_at']
        end

        test 'identical input produces identical output (deterministic)' do
          out1 = Phytosanitary::Register::Exporters::JsonExporter.call(fixed_payload)
          out2 = Phytosanitary::Register::Exporters::JsonExporter.call(fixed_payload)
          assert_equal out1, out2
        end

        test 'empty payload still produces meta block' do
          payload = Phytosanitary::Register::Payload.new(
            holder_siret: '12345678901234', holder_name: 'Acme',
            campaign_name: '2026', period_from: nil, period_to: nil,
            generated_at: Time.utc(2026, 6, 5), entries: []
          )
          parsed = JSON.parse(Phytosanitary::Register::Exporters::JsonExporter.call(payload))
          assert_equal 0, parsed.dig('meta', 'entry_count')
          assert_equal [], parsed.fetch('entries')
        end
      end
    end
  end
end
