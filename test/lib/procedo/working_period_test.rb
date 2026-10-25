require 'test_helper'

module Procedo
  class WorkingPeriodTest < Ekylibre::Testing::ApplicationTestCase
    WorkingPeriod = Procedo::Engine::Intervention::WorkingPeriod

    test 'a time with an offset keeps its instant' do
      Time.use_zone('UTC') do
        period = WorkingPeriod.new(1, started_at: '2026-10-24T09:00:00+02:00', stopped_at: '2026-10-24T10:00:00+02:00')

        assert_equal({ started_at: '2026-10-24 07:00', stopped_at: '2026-10-24 08:00' }, period.to_hash)
        assert_equal 1.hour, period.duration
      end
    end

    test 'a time with an offset is written in the current time zone' do
      Time.use_zone('Europe/Paris') do
        period = WorkingPeriod.new(1, started_at: '2026-10-24T07:00:00Z', stopped_at: '2026-10-24T08:00:00Z')

        assert_equal({ started_at: '2026-10-24 09:00', stopped_at: '2026-10-24 10:00' }, period.to_hash)
      end
    end

    test 'a time without offset is read in the current time zone' do
      Time.use_zone('Europe/Paris') do
        period = WorkingPeriod.new(1, started_at: '2026-10-24 09:00', stopped_at: '2026-10-24 10:30')

        assert_equal({ started_at: '2026-10-24 09:00', stopped_at: '2026-10-24 10:30' }, period.to_hash)
        assert_equal Time.zone.parse('2026-10-24 09:00'), period.started_at
      end
    end

    test 'missing or invalid times fall back to defaults' do
      period = WorkingPeriod.new(1, started_at: 'pas une date')

      assert_in_delta Time.zone.now - WorkingPeriod::DEFAULT_DURATION, period.started_at, 5
      assert_equal WorkingPeriod::DEFAULT_DURATION, period.duration
    end
  end
end
