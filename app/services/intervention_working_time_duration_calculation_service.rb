# Permits to compute working time by nature (doer, tool) in intervention
# context.
class InterventionWorkingTimeDurationCalculationService
  attr_reader :intervention, :participations, :participation, :product

  def initialize(intervention: nil, participations: [], participation: nil, product: nil)
    @intervention = intervention
    @participations = participations
    @participation = participation
    @product = product
  end

  # TODO: Documentation on not_nature parameter
  def perform(nature: nil, not_nature: nil)
    return intervention_working_duration if @participations.empty? && @participation.nil?

    return worker_working_duration(nature) if worker?

    times = workers_times(nature: nature, not_nature: not_nature)

    # if times == 0 &&
    # (!any_tractor? && !any_tool?)
    # return 0 if @intervention.nil?
    # return intervention_working_duration
    # end

    if times == 0 && any_tractor?
      return tractor_working_periods(nature, not_nature)
             .map(&:duration)
             .inject(0, :+) / 3600
    end

    if times == 0 && any_tool?
      return tool_working_periods(nature, not_nature)
             .map(&:duration)
             .inject(0, :+) / 3600
    end

    if times > 0 && (!any_tractor? && !any_tool?)
      return 0 if @intervention.nil?
      return intervention_working_duration
    end

    return times.to_d / tools_count if tool?

    times.to_d / (tractors_count + prepelled_equipments_count)
  end

  private

  def worker_working_duration(nature)
    duration = if nature.nil?
                 @participation
                   .working_periods
                   .map(&:duration)
                   .inject(0, :+)
               else
                 @participation
                   .working_periods
                   .select { |working_period| working_period.nature.to_sym == nature }
                   .map(&:duration)
                   .inject(0, :+)
               end

    duration.to_d / 3600
  end

  def intervention_working_duration
    @intervention.working_duration.to_d / 3600
  end

  def worker?
    @product.is_a?(Worker)
  end

  def tractor?
    @product.is_a?(Equipment) && @product.try(:tractor?)
  end

  def any_tractor?
    tractors_count > 0 || prepelled_equipments_count > 0
  end

  def any_tool?
    tools_count > 0
  end

  def self_prepelled_equipment?
    @product.variety.to_sym == :self_prepelled_equipment
  end

  def tool?
    @product.is_a?(Equipment) && product.try(:tractor?) == false
  end

  def tractors_count
    count = @participations
            .select { |participation| participation.product.try(:tractor?) }
            .size

    count += 1 if tractor? && !product_participation?

    count
  end

  def tools_count
    count = @participations
            .select { |participation| participation.product.is_a?(Equipment) && participation.product.try(:tractor?) == false }
            .size

    count += 1 if !tractor? && tool? && !product_participation?

    count
  end

  def product_participation?
    @participations
      .select { |participation| participation.product == @product }
      .present?
  end

  def prepelled_equipments_count
    @participations
      .select { |participation| participation.product.variety.to_sym == :self_prepelled_equipment }
      .size
  end

  def workers_times(nature: nil, not_nature: nil)
    worker_working_periods(nature, not_nature)
      .map(&:duration_gap)
      .reduce(0, :+)
  end

  def worker_working_periods(nature, not_nature)
    participations = @participations.select { |participation| participation.product.is_a?(Worker) }

    working_periods(participations, nature, not_nature)
    # working_periods = nil

    # if nature.nil? && not_nature.nil?
    # return participations.map(&:working_periods).flatten
    # end

    # return working_periods_of_nature(participations, nature) unless nature.nil?

    # working_periods_not_nature(participations, nature)
  end

  def tractor_working_periods(nature, not_nature)
    participations = @participations.select do |participation|
      participation.product.variety == :tractor ||
        participation.product.variety == :self_prepelled_equipment
    end

    working_periods(participations, nature, not_nature)
  end

  def tool_working_periods(nature, not_nature)
    participations = @participations.select { |participation| participation.product.is_a?(Equipment) }

    working_periods(participations, nature, not_nature)
  end

  def working_periods(participations, nature, not_nature)
    working_periods = nil

    if nature.nil? && not_nature.nil?
      return participations.map(&:working_periods).flatten
    end

    return working_periods_of_nature(participations, nature) unless nature.nil?

    working_periods_not_nature(participations, nature)
  end

  def working_periods_of_nature(participations, nature, reverse_result: false)
    participations.map do |participation|
      participation.working_periods.select do |working_period|
        if reverse_result == false
          working_period.nature.to_sym == nature
        else
          working_period.nature.to_sym != nature
        end
      end
    end.flatten
  end

  def working_periods_not_nature(participations, nature)
    working_periods_of_nature(participations, nature, reverse_result: true)
  end
end
