require 'test_helper'

module Phytosanitary
  module Register
    class BuilderTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      test 'Builder.call with no campaign returns an empty payload structure' do
        payload = Phytosanitary::Register::Builder.call(campaign: nil)
        assert_instance_of Phytosanitary::Register::Payload, payload
        assert_kind_of Array, payload.entries
        assert_not_nil payload.generated_at
      end

      test 'Builder sets holder fields from Entity.of_company' do
        payload = Phytosanitary::Register::Builder.call(campaign: nil)
        holder = Entity.of_company
        assert_equal holder.siret_number, payload.holder_siret
        assert_equal holder.full_name, payload.holder_name
      end

      test 'Builder filters to phyto procedures only' do
        campaign = campaigns(:campaigns_001)
        payload = Phytosanitary::Register::Builder.call(campaign: campaign)

        payload.entries.each do |entry|
          intervention = Intervention.find(entry.intervention_id)
          assert_includes Intervention::PHYTO_PROCEDURE_NAMES, intervention.procedure_name
        end
      end

      test 'Builder freezes entries to prevent mutation' do
        payload = Phytosanitary::Register::Builder.call(campaign: nil)
        payload.freeze
        assert payload.frozen?
        payload.entries.each { |e| assert e.frozen? }
      end

      test 'Builder produces one entry per (intervention, input, target)' do
        campaign = campaigns(:campaigns_001)
        payload = Phytosanitary::Register::Builder.call(campaign: campaign)

        seen = {}
        payload.entries.each do |entry|
          key = [entry.intervention_id, entry.intervention_input_id, entry.intervention_target_id]
          refute seen[key], "Duplicate entry key #{key.inspect}"
          seen[key] = true
        end
      end

      test 'period_from/period_to respect explicit args over campaign bounds' do
        from = Time.zone.parse('2020-01-01')
        to = Time.zone.parse('2020-12-31')
        payload = Phytosanitary::Register::Builder.call(campaign: nil, from: from, to: to)
        assert_equal from, payload.period_from
        assert_equal to, payload.period_to
      end
    end
  end
end
