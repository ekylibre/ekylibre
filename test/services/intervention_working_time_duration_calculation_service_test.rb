require 'test_helper'

class InterventionWorkingTimeDurationCalculationServiceTest < ActiveSupport::TestCase
  setup do
    @now = Time.zone.now

    create_workers
    create_equipments
    create_intervention
    create_participations

    @intervention.reload
  end

  test 'no participations return intervention working period' do
    duration = InterventionWorkingTimeDurationCalculationService
               .new(**working_duration_params)
               .perform(nature: :intervention)

    assert_equal duration, (@intervention.working_duration / 3600).to_d
  end

  test 'no nature specified return sum of working periods for worker' do
    working_params = working_duration_params(participation: @alice_participation,
                                             product: @alice)

    duration = InterventionWorkingTimeDurationCalculationService
               .new(working_params)
               .perform

    sum_working_periods = @alice_participation
                          .working_periods
                          .map(&:duration)
                          .inject(0, :+)
                          .to_d

    assert_equal duration, (sum_working_periods / 3600).to_d
  end

  test 'return sum of specified nature working periods for worker' do
    working_params = working_duration_params(participation: @alice_participation,
                                             product: @alice)

    intervention_duration = InterventionWorkingTimeDurationCalculationService
                            .new(working_params)
                            .perform(nature: :intervention)

    sum_working_periods = sum_working_periods_of(participation: @alice_participation, nature: :intervention)

    assert_equal intervention_duration, (sum_working_periods.to_d / 3600).to_d

    travel_duration = InterventionWorkingTimeDurationCalculationService
                      .new(working_params)
                      .perform(nature: :travel)

    sum_working_periods = sum_working_periods_of(participation: @alice_participation, nature: :travel)

    assert_equal travel_duration, (sum_working_periods.to_d / 3600).to_d
  end

  test 'tool working duration without any tractors or tools return intervention working duration' do
    working_params = working_duration_params(participations: @participations,
                                             product: Plant.first)

    duration = InterventionWorkingTimeDurationCalculationService
               .new(working_params)
               .perform(nature: :intervention)

    assert_equal duration, @intervention.working_duration
  end

  test 'test tractor calculated working duration' do
    working_params = working_duration_params(participations: @participations,
                                             product: @tractor)

    intervention_duration = InterventionWorkingTimeDurationCalculationService
                            .new(working_params)
                            .perform(nature: :intervention)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    assert_equal intervention_duration, (sum_working_periods.to_d / 1).to_d

    travel_duration = InterventionWorkingTimeDurationCalculationService
                      .new(working_params)
                      .perform(nature: :travel)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :travel)

    assert_equal travel_duration, (sum_working_periods.to_d / 1).to_d
  end

  test 'divise calculated working duration by two if they have two tractors' do
    working_params = working_duration_params(participations: @participations,
                                             product: @tractor)

    intervention_duration = InterventionWorkingTimeDurationCalculationService
                            .new(working_params)
                            .perform(nature: :intervention)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    @participations << @second_tractor_participation

    working_params = working_duration_params(participations: @participations,
                                             product: @tractor)

    intervention_duration = InterventionWorkingTimeDurationCalculationService
                            .new(working_params)
                            .perform(nature: :intervention)

    assert_equal (sum_working_periods / 2).to_d.round(2), intervention_duration.round(2)
  end

  test 'test tool calculated working duration' do
    working_params = working_duration_params(participations: @participations,
                                             product: @tool)

    intervention_duration = InterventionWorkingTimeDurationCalculationService
                            .new(working_params)
                            .perform(nature: :intervention)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    assert_equal intervention_duration, (sum_working_periods.to_d / 1).to_d

    travel_duration = InterventionWorkingTimeDurationCalculationService
                      .new(working_params)
                      .perform(nature: :travel)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :travel)

    assert_equal travel_duration, (sum_working_periods.to_d / 1).to_d
  end

  private

  def sum_working_periods_of(participation: nil, participations: {}, nature: nil)
    unless participations.empty?
      return participations
              .map(&:working_periods)
              .flatten
              .select { |working_period| working_period.nature == nature }
              .map(&:duration_gap)
              .inject(0, :+)
    end

    participation
      .working_periods
      .select { |working_period| working_period.nature.to_sym == nature }
      .map(&:duration)
      .inject(0, :+)
  end

  def working_duration_params(participations: {}, participation: nil, product: nil)
    unless participations.empty?
      return { intervention: @intervention,
               participations: participations,
               product: product }
    end

    { intervention: @intervention,
      participation: participation,
      product: product }
  end

  def fake_working_periods
    now = Time.zone.now
    [
      InterventionWorkingPeriod.new(started_at: now - 3.hours, stopped_at: now - 2.hours, nature: 'preparation'),
      InterventionWorkingPeriod.new(started_at: now - 2.hours, stopped_at: now - 90.minutes, nature: 'travel'),
      InterventionWorkingPeriod.new(started_at: now - 90.minutes, stopped_at: now - 30.minutes, nature: 'intervention'),
      InterventionWorkingPeriod.new(started_at: now - 30.minutes, stopped_at: now, nature: 'travel')
    ]
  end

  def create_workers
    @alice = Worker.create!(
      name: 'Alice',
      variety: 'worker',
      variant: ProductNatureVariant.first,
      person: Entity.contacts.first
    )

    @john = Worker.create!(
      name: 'John',
      variety: 'worker',
      variant: ProductNatureVariant.first,
      person: Entity.contacts.last
    )
  end

  def create_equipments
    @tractor = Equipment.create!(
      name: 'Fake tractor',
      variety: 'tractor',
      variant: ProductNatureVariant.where(variety: 'tractor').first
    )

    @second_tractor = Equipment.create!(
      name: 'Fake second tractor',
      variety: 'tractor',
      variant: ProductNatureVariant.where(variety: 'tractor').first
    )

    @tool = Equipment.create!(
      name: 'Fake seeder',
      variety: 'trailed_equipment',
      variant: ProductNatureVariant.where(variety: 'trailed_equipment').first
    )
  end

  def create_intervention
    @intervention = Intervention.create!(
      procedure_name: :sowing,
      actions: [:sowing],
      request_compliant: false,
      working_periods: fake_working_periods
    )

    @intervention.doers.create!(
      product: @alice,
      reference_name: 'land_parcel'
    )

    @intervention.doers.create!(
      product: @john,
      reference_name: 'land_parcel'
    )
  end

  def create_participations
    @alice_participation = InterventionParticipation.create!(
      state: :done,
      request_compliant: false,
      procedure_name: :sowing,
      product: @alice,
      working_periods_attributes: [
        {
          started_at: @now - 1.hour,
          stopped_at: @now - 30.minutes,
          nature: 'travel'
        },
        {
          started_at: @now - 30.minutes,
          stopped_at: @now - 15.minutes,
          nature: 'intervention'
        },
        {
          started_at: @now - 10.minutes,
          stopped_at: @now,
          nature: 'intervention'
        }
      ]
    )

    @john_participation = InterventionParticipation.create!(
      state: :done,
      request_compliant: false,
      procedure_name: :sowing,
      product: @john,
      working_periods_attributes: [
        {
          started_at: @now - 1.hour,
          stopped_at: @now,
          nature: 'intervention'
        }
      ]
    )

    @second_tractor_participation = InterventionParticipation.create!(
      state: :done,
      request_compliant: false,
      procedure_name: :sowing,
      product: @second_tractor
    )

    @participations = [@alice_participation, @john_participation]
  end
end
