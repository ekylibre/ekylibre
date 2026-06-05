require 'test_helper'

module Phytosanitary
  module Register
    module Exporters
      class CsvExporterTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
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
            holder_siret: '12345678901234', holder_name: 'Acme Farm',
            campaign_name: '2026',
            period_from: nil, period_to: nil,
            generated_at: Time.utc(2026, 6, 5, 10, 30, 0),
            entries: [entry]
          )
        end

        test 'CSV first row is the header with Entry member names' do
          output = Phytosanitary::Register::Exporters::CsvExporter.call(fixed_payload)
          rows = CSV.parse(output)
          assert_equal Phytosanitary::Register::Entry.members.map(&:to_s), rows.first
        end

        test 'CSV has one row per entry plus header' do
          output = Phytosanitary::Register::Exporters::CsvExporter.call(fixed_payload)
          rows = CSV.parse(output)
          assert_equal 2, rows.size # header + 1 entry
        end

        test 'BigDecimal serialized without scientific notation' do
          output = Phytosanitary::Register::Exporters::CsvExporter.call(fixed_payload)
          rows = CSV.parse(output)
          headers = rows.first
          row = rows.last
          assert_equal '2.5', row[headers.index('dose_value')]
        end

        test 'Date serialized as YYYY-MM-DD' do
          output = Phytosanitary::Register::Exporters::CsvExporter.call(fixed_payload)
          rows = CSV.parse(output)
          headers = rows.first
          row = rows.last
          assert_equal '2026-05-15', row[headers.index('application_date')]
        end

        test 'force_quotes is enabled (strings wrapped in double quotes)' do
          output = Phytosanitary::Register::Exporters::CsvExporter.call(fixed_payload)
          first_data_line = output.lines[1]
          assert first_data_line.start_with?('"1"'), "expected first cell to be quoted, got #{first_data_line[0..20]}"
        end

        test 'empty payload produces header-only CSV' do
          payload = Phytosanitary::Register::Payload.new(
            holder_siret: '...', holder_name: '...',
            campaign_name: '...', period_from: nil, period_to: nil,
            generated_at: Time.utc(2026, 6, 5),
            entries: []
          )
          output = Phytosanitary::Register::Exporters::CsvExporter.call(payload)
          rows = CSV.parse(output)
          assert_equal 1, rows.size
        end

        test 'identical input produces identical output (deterministic)' do
          out1 = Phytosanitary::Register::Exporters::CsvExporter.call(fixed_payload)
          out2 = Phytosanitary::Register::Exporters::CsvExporter.call(fixed_payload)
          assert_equal out1, out2
        end
      end
    end
  end
end
