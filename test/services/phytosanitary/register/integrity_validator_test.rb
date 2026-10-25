require 'test_helper'

module Phytosanitary
  module Register
    class IntegrityValidatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      def build_complete_entry(overrides = {})
        Entry.new({
          intervention_id: 1,
          intervention_input_id: 10,
          intervention_target_id: 100,
          holder_siret: '12345678901234',
          product_name: 'GLYPHOS 360',
          amm_number: '2050008',
          application_date: Date.new(2026, 5, 1),
          dose_value: BigDecimal('2.5'),
          dose_unit: 'liter_per_hectare',
          treated_area_value: BigDecimal('1.5'),
          crop_name: 'Blé tendre',
          location_geometry: 'POINT(0 0)'
        }.merge(overrides))
      end

      test 'complete payload validates with no errors' do
        payload = Payload.new(entries: [build_complete_entry])
        result = IntegrityValidator.call(payload)
        assert result.ok?
        assert_equal 0, result.total_errors
      end

      test 'empty payload validates trivially' do
        payload = Payload.new(entries: [])
        result = IntegrityValidator.call(payload)
        assert result.ok?
      end

      test 'missing single mandatory field is reported' do
        payload = Payload.new(entries: [build_complete_entry(amm_number: nil)])
        result = IntegrityValidator.call(payload)
        refute result.ok?
        assert_equal 1, result.total_errors
        errors = result.errors_by_entry.values.first
        assert_includes errors, :amm_number
      end

      test 'each mandatory field absent is reported individually' do
        IntegrityValidator::MANDATORY_FIELDS.each do |field|
          payload = Payload.new(entries: [build_complete_entry(field => nil)])
          result = IntegrityValidator.call(payload)
          refute result.ok?, "Field #{field} should be detected as missing"
          errors = result.errors_by_entry.values.first
          assert_includes errors, field, "errors should include :#{field}"
        end
      end

      test 'errors are keyed by [intervention_id, input_id, target_id]' do
        entry = build_complete_entry(holder_siret: nil, intervention_id: 7, intervention_input_id: 8, intervention_target_id: 9)
        payload = Payload.new(entries: [entry])
        result = IntegrityValidator.call(payload)
        assert_equal [[7, 8, 9]], result.errors_by_entry.keys
      end

      test 'empty string treated as missing' do
        payload = Payload.new(entries: [build_complete_entry(product_name: '')])
        result = IntegrityValidator.call(payload)
        refute result.ok?
        assert_includes result.errors_by_entry.values.first, :product_name
      end
    end
  end
end
