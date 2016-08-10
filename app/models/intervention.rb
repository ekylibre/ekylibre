# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: interventions
#
#  actions          :string
#  created_at       :datetime         not null
#  creator_id       :integer
#  custom_fields    :jsonb
#  description      :text
#  event_id         :integer
#  id               :integer          not null, primary key
#  issue_id         :integer
#  lock_version     :integer          default(0), not null
#  number           :string
#  prescription_id  :integer
#  procedure_name   :string           not null
#  started_at       :datetime
#  state            :string           not null
#  stopped_at       :datetime
#  updated_at       :datetime         not null
#  updater_id       :integer
#  whole_duration   :integer          default(0), not null
#  working_duration :integer          default(0), not null
#

class Intervention < Ekylibre::Record::Base
  include PeriodicCalculable, CastGroupable
  include Customizable
  attr_readonly :procedure_name, :production_id
  belongs_to :event, dependent: :destroy, inverse_of: :intervention
  belongs_to :issue
  belongs_to :prescription
  with_options inverse_of: :intervention do
    has_many :root_parameters, -> { where(group_id: nil) }, class_name: 'InterventionParameter', dependent: :destroy
    has_many :parameters, class_name: 'InterventionParameter'
    has_many :group_parameters, -> { order(:position) }, class_name: 'InterventionGroupParameter'
    has_many :product_parameters, -> { order(:position) }, class_name: 'InterventionProductParameter'
    has_many :doers, class_name: 'InterventionDoer'
    has_many :inputs, class_name: 'InterventionInput'
    has_many :outputs, class_name: 'InterventionOutput'
    has_many :targets, class_name: 'InterventionTarget'
    has_many :tools, class_name: 'InterventionTool'
    has_many :working_periods, class_name: 'InterventionWorkingPeriod'
    has_many :leaves_parameters, -> { where.not(type: InterventionGroupParameter) }, class_name: 'InterventionParameter'
  end
  enumerize :procedure_name, in: Procedo.procedure_names, i18n_scope: ['procedures']
  enumerize :state, in: [:undone, :squeezed, :in_progress, :done], default: :undone, predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :actions, :number, length: { maximum: 500 }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :procedure_name, :state, presence: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(intervention) { intervention.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :whole_duration, :working_duration, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  # ]VALIDATORS]
  validates :actions, presence: true
  # validates_associated :group_parameters, :doers, :inputs, :outputs, :targets, :tools, :working_periods

  serialize :actions, SymbolArray

  alias_attribute :duration, :working_duration

  calculable period: :month, column: :working_duration, at: :started_at, name: :sum

  acts_as_numbered
  accepts_nested_attributes_for :group_parameters, :doers, :inputs, :outputs, :targets, :tools, :working_periods, allow_destroy: true

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }

  scope :of_civil_year, lambda { |year|
    where('EXTRACT(YEAR FROM started_at) = ?', year)
  }

  scope :of_nature, ->(reference_name) { where(reference_name: reference_name) }
  scope :of_category, lambda { |category|
    where(procedure_name: Procedo.procedures_of_category(category).map(&:name))
  }
  scope :of_campaign, lambda { |campaign|
    where(id: InterventionTarget.select(:intervention_id).where(product_id: TargetDistribution.select(:target_id).of_campaign(campaign)))
  }
  scope :of_current_campaigns, -> { of_campaign(Campaign.current) }
  scope :of_activity_production, lambda { |production|
    where(id: InterventionTarget.of_activity_production(production).select(:intervention_id))
  }
  scope :of_activity, lambda { |activity|
    where(id: InterventionTarget.of_activity(activity).select(:intervention_id))
  }
  scope :of_activities, ->(*activities) { of_activity(activities.flatten) }
  scope :provisional, -> { where('stopped_at > ?', Time.zone.now) }
  scope :real, -> { where('stopped_at <= ?', Time.zone.now) }

  scope :with_generic_cast, lambda { |role, object|
    where(id: InterventionProductParameter.of_generic_role(role).of_actor(object).select(:intervention_id))
  }

  scope :with_targets, lambda { |*targets|
    where(id: InterventionTarget.of_actors(targets).select(:intervention_id))
  }

  scope :with_outputs, lambda { |*outputs|
    where(id: InterventionOutput.of_actors(outputs).select(:intervention_id))
  }

  scope :with_doers, lambda { |*doers|
    where(id: InterventionDoer.of_actors(doers).select(:intervention_id))
  }

  scope :done, -> {}

  before_validation do
    if self.started_at && self.stopped_at
      self.whole_duration = (stopped_at - started_at).to_i
    end
    self.state ||= self.class.state.default
    if procedure
      self.actions = procedure.actions.map(&:name) if actions && actions.empty?
    end
    true
  end

  validate do
    if procedure
      all_known = true
      actions.each do |action|
        all_known = false unless procedure.has_action?(action)
      end
      errors.add(:actions, :invalid) unless all_known
    end
    if self.started_at && self.stopped_at && self.stopped_at <= self.started_at
      errors.add(:stopped_at, :posterior, to: self.started_at.l)
    end
    true
  end

  before_save do
    columns = { name: name, started_at: self.started_at, stopped_at: self.stopped_at, nature: :production_intervention }
    if event
      # self.event.update_columns(columns)
      event.attributes = columns
    else
      event = Event.create!(columns)
      # self.update_column(:event_id, event.id)
      self.event_id = event.id
    end
    true
  end

  # Prevents from deleting an intervention that was executed
  protect on: :destroy do
    with_undestroyable_products?
  end

  def activity_productions
    ActivityProduction.of_intervention(self)
  end

  def with_undestroyable_products?
    outputs.map(&:product).detect do |product|
      next unless product
      InterventionProductParameter.of_actor(product).where.not(type: 'InterventionOutput').any?
    end
  end

  # Returns activities of intervention through TargetDistribution
  def activities
    # re active when Target Distribution works
    # Activity.of_intervention(self)
    a = []
    targets.each do |target|
      a << target.activity if target.activity
    end
    a.uniq
  end

  # Returns human tool names
  def human_activities_names
    activities.map(&:name).sort.to_sentence
  end

  def product_parameters
    InterventionProductParameter.where(intervention: self)
  end

  # The Procedo::Procedure behind intervention
  def procedure
    Procedo.find(procedure_name)
  end

  # Deprecated method to return procedure
  def reference
    ActiveSupport::Deprecation.warn 'Intervention#reference is deprecated.' \
                                    'Please use Intervention#procedure instead.'
    procedure
  end

  # Returns human target names
  def human_target_names
    targets.map(&:product).compact.map(&:work_name).sort.to_sentence
  end

  # Returns human doer names
  def human_doer_names
    doers.map(&:product).compact.map(&:work_name).sort.to_sentence
  end

  # Returns human tool names
  def human_tool_names
    tools.map(&:product).compact.map(&:work_name).sort.to_sentence
  end

  # Returns human actions names
  def human_actions_names
    actions.map { |action| Nomen::ProcedureAction.find(action).human_name }
           .to_sentence
  end

  def name
    # raise self.inspect if self.procedure_name.blank?
    tc(:name, intervention: (procedure ? procedure.human_name : "procedures.#{procedure_name}".t(default: procedure_name.humanize)), number: number)
  end

  def start_time
    started_at
  end

  def human_working_duration(unit = :hour)
    working_duration.in(:second).convert(unit).round(2).l
  end

  # Update temporality informations in intervention
  def update_temporality
    reload unless new_record? || destroyed?
    started_at = working_periods.minimum(:started_at)
    stopped_at = working_periods.maximum(:stopped_at)
    update_columns(
      started_at: started_at,
      stopped_at: stopped_at,
      working_duration: working_periods.sum(:duration),
      whole_duration: (stopped_at && started_at ? (stopped_at - started_at).to_i : 0)
    )
    event.update_columns(
      started_at: self.started_at,
      stopped_at: self.stopped_at
    ) if event
    outputs.find_each do |output|
      product = output.product
      next unless product
      product.born_at = self.started_at
      product.initial_born_at = product.born_at
      product.save!

      reading = product.initial_reading(:shape)
      unless reading.nil?
        reading.read_at = product.born_at
        reading.save!
      end

      movement = output.product_movement
      next unless movement
      movement.started_at = self.started_at
      movement.stopped_at = self.stopped_at
      movement.save!
    end

    inputs.find_each do |input|
      product = input.product
      next unless product

      movement = input.product_movement
      next unless movement
      movement.started_at = self.started_at
      movement.stopped_at = self.stopped_at
      movement.save!

      # to be sure last
      last_movement = product.movements.last_of_all
      last_movement.stopped_at = nil
      last_movement.save!
    end
  end

  # Sums all intervention product parameter total_cost of a particular role
  def cost(role = :input)
    params = product_parameters.of_generic_role(role)
    return params.map(&:cost).compact.sum if params.any?
    nil
  end

  def cost_per_area(role = :input, area_unit = :hectare)
    if working_zone_area > 0.0.in_square_meter
      params = product_parameters.of_generic_role(role)
      return (params.map(&:cost).compact.sum / working_zone_area(area_unit).to_d) if params.any?
      nil
    end
    nil
  end

  def total_cost
    [:input, :tool, :doer].map do |type|
      (cost(type) || 0.0).to_d
    end.sum
  end

  def total_cost_per_area(area_unit = :hectare)
    if working_zone_area > 0.0.in_square_meter
      return (total_cost / working_zone_area(area_unit).to_d)
    else
      return nil
    end
  end

  def currency
    Preference[:currency]
  end

  def earn(role = :output)
    params = product_parameters.of_generic_role(role)
    return params.map(&:earn).compact.sum if params.any?
    nil
  end

  def working_zone_area(*args)
    options = args.extract_options!
    unit = args.shift || options[:unit] || :hectare
    if targets.any?
      area = targets.with_working_zone.map(&:working_zone_area).sum.in(unit)
    end
    area ||= 0.0.in(unit)
    area
  end

  def human_working_zone_area(*args)
    options = args.extract_options!
    unit = args.shift || options[:unit] || :hectare
    precision = args.shift || options[:precision] || 2
    working_zone_area(unit: unit).round(precision).l(precision: precision)
  end

  def status
    if undone?
      return (runnable? ? :caution : :stop)
    elsif done?
      return :go
    end
  end

  def runnable?
    return false unless undone? && procedure
    valid = true
    # Check cardinality and runnability
    procedure.parameters.each do |parameter|
      all_parameters = parameters.where(reference_name: parameter.name)
      # unless parameter.cardinality.include?(parameters.count)
      #   valid = false
      # end
      all_parameters.each do |parameter|
        valid = false unless parameter.runnable?
      end
    end
    valid
  end

  # Run the intervention ie. the state is marked as done
  # Returns intervention
  def run!
    raise 'Cannot run intervention without procedure' unless runnable?
    update_attributes(state: :done)
    self
  end

  def add_working_period!(started_at, stopped_at)
    working_periods.create!(started_at: started_at, stopped_at: stopped_at)
  end

  class << self
    def used_procedures
      select(:procedure_name).distinct.pluck(:procedure_name).map do |name|
        Procedo.find(name)
      end.compact
    end

    # Create and run intervention
    def run!(*args)
      attributes = args.extract_options!
      attributes[:procedure_name] ||= args.shift
      intervention = transaction do
        intervention = Intervention.create!(attributes)
        yield intervention if block_given?
        intervention.run!
      end
      intervention
    end

    # Registers and runs an intervention directly
    def write(*args)
      options = args.extract_options!
      procedure_name = args.shift || options[:procedure_name]

      transaction do
        attrs = options.slice(:procedure_name, :description, :issue_id, :prescription_id)
        recorder = Intervention::Recorder.new(attrs)

        yield recorder

        recorder.write!
      end
    end

    # Find a product with given options
    #  - started_at
    #  - work_number
    #  - can
    #  - variety
    #  - derivative_of
    #  - filter: WSQL expression
    # Options for product creation only:
    #  - default_storage
    # Special options for worker creation only:
    #  - first_name
    #  - last_name
    #  - born_at
    #  - default_storage
    def find_products(model, options = {})
      relation = model
      relation = relation.where('COALESCE(born_at, ?) <= ? ', options[:started_at], options[:started_at]) if options[:started_at]
      relation = relation.of_expression(options[:filter]) if options[:filter]
      relation = relation.of_work_numbers(options[:work_number]) if options[:work_number]
      relation = relation.can(options[:can]) if options[:can]
      relation = relation.of_variety(options[:variety]) if options[:variety]
      relation = relation.derivative_of(options[:derivative_of]) if options[:derivative_of]
      return relation.all if relation.any?
    end

    # Returns an array of procedures matching the given actors ordered by relevance
    # whose structure is [[procedure, relevance, arity], [procedure, relevance, arity], ...]
    # where 'procedure' is a Procedo::Procedure object, 'relevance' is a float,
    # 'arity' is the number of actors matched in the procedure
    # ==== parameters:
    #   - actors, an array of actors identified for a given procedure
    # ==== options:
    #   - relevance: sets the relevance threshold above which results are wished.
    #     A float number between 0 and 1 is expected. Default value: 0.
    #   - limit: sets the number of wanted results. By default all results are returned
    #   - history: sets the use of actors history to calculate relevance.
    #     A boolean is expected. Default: false,since checking through history is slower
    #   - provisional: sets the use of actors provisional to calculate relevance.
    #     A boolean is expected. Default: false, since it's slower.
    #   - max_arity: limits results to procedures matching most actors.
    #     A boolean is expected. Default: false
    def match(actors, options = {})
      actors = [actors].flatten
      limit = options[:limit].to_i - 1
      relevance_threshold = options[:relevance].to_f
      maximum_arity = 0

      # Creating coefficients for relevance calculation for each procedure
      # coefficients depend on provisional, actors history and actors presence in procedures
      history = Hash.new(0)
      provisional = []
      actors_id = []
      actors_id = actors.map(&:id) if options[:history] || options[:provisional]

      # Select interventions from all actors history
      if options[:history]
        # history is considered relevant on 1 year
        history.merge!(Intervention.joins(:product_parameters)
                        .where("intervention_parameters.actor_id IN (#{actors_id.join(', ')})")
                        .where(started_at: (Time.zone.now.midnight - 1.year)..(Time.zone.now))
                        .group('interventions.procedure_name')
                        .count('interventions.procedure_name'))
      end

      if options[:provisional]
        provisional.concat(Intervention.distinct
                            .joins(:product_parameters)
                            .where("intervention_parameters.actor_id IN (#{actors_id.join(', ')})")
                            .where(started_at: (Time.zone.now.midnight - 1.day)..(Time.zone.now + 3.days))
                            .pluck('interventions.procedure_name')).uniq!
      end

      coeff = {}

      history_size = 1.0 # prevents division by zero
      history_size = history.values.reduce(:+).to_f if history.count >= 1

      denominator = 1.0
      denominator += 2.0 if options[:history] && history.present?
      denominator += 3.0 if provisional.present? # if provisional is empty, it's pointless using it for relevance calculation

      result = []
      Procedo.procedures do |procedure_key, procedure|
        coeff[procedure_key] = 1.0 + 2.0 * (history[procedure_key].to_f / history_size) + 3.0 * provisional.count(procedure_key).to_f
        matched_parameters = procedure.matching_parameters_for(actors)
        if matched_parameters.any?
          result << [procedure, (((matched_parameters.values.count.to_f / actors.count) * coeff[procedure_key]) / denominator), matched_parameters.values.count]
          maximum_arity = matched_parameters.values.count if maximum_arity < matched_parameters.values.count
        end
      end
      result.delete_if { |_procedure, relevance, _arity| relevance < relevance_threshold }
      result.delete_if { |_procedure, _relevance, arity| arity < maximum_arity } if options[:max_arity]
      result.sort_by { |_procedure, relevance, _arity| -relevance }[0..limit]
    end
  end
end
