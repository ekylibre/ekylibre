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
    working_duration = working_duration_of(nature: :intervention)

    assert_equal working_duration, (@intervention.working_duration / 3600).to_d
  end

  test 'no nature specified return sum of working periods for worker' do
    working_duration = working_duration_of(participation: @alice_participation,
                                           product: @alice)

    sum_working_periods = @alice_participation
                          .working_periods
                          .map(&:duration)
                          .inject(0, :+)
                          .to_d

    assert_equal working_duration, (sum_working_periods / 3600).to_d
  end

  test 'return sum of specified nature working periods for worker' do
    working_duration = working_duration_of(nature: :intervention,
                                           participation: @alice_participation,
                                           product: @alice)

    sum_working_periods = sum_working_periods_of(participation: @alice_participation, nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d

    working_duration = working_duration_of(nature: :travel,
                                           participation: @alice_participation,
                                           product: @alice)

    sum_working_periods = sum_working_periods_of(participation: @alice_participation, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d
  end

  test 'tool working duration without any tractors or tools return intervention working duration' do
    working_duration = working_duration_of(nature: :intervention,
                                           participations: @participations,
                                           product: Plant.first)

    assert_equal working_duration, @intervention.working_duration.to_d / 3600
  end

  test 'tractor working duration without any workers return tractor times' do
    @participations = [@second_tractor_participation]

    working_duration = working_duration_of(nature: :travel,
                                           participations: @participations,
                                           product: @tractor)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d

    working_duration = working_duration_of(nature: :intervention,
                                           participations: @participations,
                                           product: @tractor)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d
  end

  test 'Manual tool working duration without any workers return tool times' do
    @participations = [@second_tool_participation]

    @intervention.auto_calculate_working_periods = false
    @intervention.save

    working_duration = working_duration_of(nature: :travel,
                                           participation: @second_tool_participation,
                                           product: @second_tool)

    sum_working_periods = sum_working_periods_of(participation: @second_tool_participation, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d

    working_duration = working_duration_of(nature: :intervention,
                                           participation: @second_tool_participation,
                                           product: @second_tool)

    sum_working_periods = sum_working_periods_of(participation: @second_tool_participation, nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d
  end

  test 'Automatic tool working duration without any workers return tool times' do
    @participations = [@second_tool_participation]

    @intervention.auto_calculate_working_periods = true
    @intervention.save

    working_duration = working_duration_of(nature: :travel,
                                           participations: @participations,
                                           product: @tool)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d

    working_duration = working_duration_of(nature: :intervention,
                                           participations: @participations,
                                           product: @tool)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d
  end

  test 'Manual tractor calculated working duration' do
    @intervention.auto_calculate_working_periods = false
    @intervention.save

    working_duration = working_duration_of(nature: :intervention,
                                           participation: @third_tractor_participation,
                                           product: @third_tractor)

    sum_working_periods = sum_working_periods_of(participation: @third_tractor_participation,
                                                 nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d

    working_duration = working_duration_of(nature: :travel,
                                           participation: @third_tractor_participation,
                                           product: @third_tractor)

    sum_working_periods = sum_working_periods_of(participation: @third_tractor_participation, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d
  end

  test 'Automatic tractor calculated working duration' do
    @intervention.auto_calculate_working_periods = true
    @intervention.save

    working_duration = working_duration_of(nature: :intervention,
                                           participations: @participations,
                                           product: @tractor)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d

    working_duration = working_duration_of(nature: :travel,
                                           participations: @participations,
                                           product: @tractor)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d
  end

  test 'Automatic divise calculated working duration by two if they have two tractors' do
    @intervention.auto_calculate_working_periods = true
    @intervention.save

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    @participations << @second_tractor_participation

    working_duration = working_duration_of(nature: :intervention,
                                           participations: @participations,
                                           product: @tractor)

    assert_equal (sum_working_periods / 2).to_d.round(2), working_duration.round(2)
  end

  test 'Manual tool calculated working duration' do
    @intervention.auto_calculate_working_periods = false
    @intervention.save

    working_duration = working_duration_of(nature: :intervention,
                                           participation: @second_tool_participation,
                                           product: @second_tool)

    sum_working_periods = sum_working_periods_of(participation: @second_tool_participation, nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d

    working_duration = working_duration_of(nature: :travel,
                                           participation: @second_tool_participation,
                                           product: @second_tool)

    sum_working_periods = sum_working_periods_of(participation: @second_tool_participation, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 3600).to_d
  end

  test 'Manual tool calculated working duration for modal return nothing' do
    @intervention.auto_calculate_working_periods = false
    @intervention.save

    working_duration = working_duration_of(nature: :intervention,
                                           participation: @second_tool_participation,
                                           product: @second_tool,
                                           modal: true)

    assert_equal working_duration, 0
  end

  test 'Automatic tool calculated working duration' do
    @intervention.auto_calculate_working_periods = true

    working_duration = working_duration_of(nature: :intervention,
                                           participations: @participations,
                                           product: @tool)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :intervention)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d

    working_duration = working_duration_of(nature: :travel,
                                           participations: @participations,
                                           product: @tool)

    sum_working_periods = sum_working_periods_of(participations: @participations, nature: :travel)

    assert_equal working_duration, (sum_working_periods.to_d / 1).to_d
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

  def working_duration_of(nature: nil, participations: {}, participation: nil, product: nil, modal: false)
    working_params = working_duration_params(participations: participations,
                                             participation: participation,
                                             product: product)

    InterventionWorkingTimeDurationCalculationService
      .new(working_params)
      .perform(nature: nature, modal: modal)
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

    @third_tractor = Equipment.create!(
      name: 'Fake third tractor',
      variety: 'tractor',
      variant: ProductNatureVariant.where(variety: 'tractor').first
    )

    @tool = Equipment.create!(
      name: 'Fake seeder',
      variety: 'trailed_equipment',
      variant: ProductNatureVariant.where(variety: 'trailed_equipment').first
    )

    @second_tool = Equipment.create!(
      name: 'Fake second seeder',
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

    @third_tractor_participation = InterventionParticipation.create!(
      state: :done,
      request_compliant: false,
      procedure_name: :sowing,
      product: @third_tractor,
      working_periods_attributes: [
        {
          started_at: @now - 3.hours,
          stopped_at: @now - 2.hours,
          nature: 'travel'
        },
        {
          started_at: @now - 2.hours,
          stopped_at: @now - 30.minutes,
          nature: 'intervention'
        },
        {
          started_at: @now - 30.minutes,
          stopped_at: @now,
          nature: 'intervention'
        }
      ]
    )

    @second_tool_participation = InterventionParticipation.create!(
      state: :done,
      request_compliant: false,
      procedure_name: :sowing,
      product: @second_tool,
      working_periods_attributes: [
        {
          started_at: @now - 6.hours,
          stopped_at: @now - 3.hours,
          nature: 'travel'
        },
        {
          started_at: @now - 3.hours,
          stopped_at: @now,
          nature: 'intervention'
        }
      ]
    )

    @participations = [@alice_participation, @john_participation]
  end
end
