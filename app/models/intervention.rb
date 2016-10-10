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
#  accounted_at            :datetime
#  actions                 :string
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string
#  custom_fields           :jsonb
#  description             :text
#  event_id                :integer
#  id                      :integer          not null, primary key
#  issue_id                :integer
#  journal_entry_id        :integer
#  lock_version            :integer          default(0), not null
#  nature                  :string           not null
#  number                  :string
#  prescription_id         :integer
#  procedure_name          :string           not null
#  request_intervention_id :integer
#  started_at              :datetime
#  state                   :string           not null
#  stopped_at              :datetime
#  trouble_description     :text
#  trouble_encountered     :boolean          default(FALSE), not null
#  updated_at              :datetime         not null
#  updater_id              :integer
#  whole_duration          :integer          default(0), not null
#  working_duration        :integer          default(0), not null
#

class Intervention < Ekylibre::Record::Base
  include PeriodicCalculable, CastGroupable
  include Customizable
  attr_readonly :procedure_name, :production_id, :currency
  refers_to :currency
  enumerize :procedure_name, in: Procedo.procedure_names, i18n_scope: ['procedures']
  enumerize :nature, in: [:request, :record], default: :record, predicates: true
  enumerize :state, in: [:in_progress, :done, :validated, :rejected], default: :done, predicates: true
  belongs_to :event, dependent: :destroy, inverse_of: :intervention
  belongs_to :request_intervention, -> { where(nature: :request) }, class_name: 'Intervention'
  belongs_to :issue
  belongs_to :prescription
  belongs_to :journal_entry, dependent: :destroy
  has_many :labellings, class_name: 'InterventionLabelling', dependent: :destroy, inverse_of: :intervention
  has_many :labels, through: :labellings
  has_many :record_interventions, -> { where(nature: :record) }, class_name: 'Intervention', inverse_of: 'request_intervention', foreign_key: :request_intervention_id

  has_and_belongs_to_many :activities
  has_and_belongs_to_many :activity_productions
  has_and_belongs_to_many :campaigns

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
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :actions, :number, length: { maximum: 500 }, allow_blank: true
  validates :description, :trouble_description, length: { maximum: 500_000 }, allow_blank: true
  validates :nature, :procedure_name, :state, presence: true
  validates :stopped_at, timeliness: { on_or_after: ->(intervention) { intervention.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :trouble_encountered, inclusion: { in: [true, false] }
  validates :whole_duration, :working_duration, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  # ]VALIDATORS]
  validates :actions, presence: true
  # validates_associated :group_parameters, :doers, :inputs, :outputs, :targets, :tools, :working_periods

  serialize :actions, SymbolArray

  alias_attribute :duration, :working_duration

  calculable period: :month, column: :working_duration, at: :started_at, name: :sum

  acts_as_numbered
  accepts_nested_attributes_for :group_parameters, :doers, :inputs, :outputs, :targets, :tools, :working_periods, allow_destroy: true
  accepts_nested_attributes_for :labellings, allow_destroy: true

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }

  scope :of_civil_year, lambda { |year|
    where('EXTRACT(YEAR FROM started_at) = ?', year)
  }

  scope :of_nature, ->(reference_name) { where(reference_name: reference_name) }
  scope :of_category, lambda { |category|
    where(procedure_name: Procedo::Procedure.of_category(category).map(&:name))
  }
  scope :of_campaign, lambda { |campaign|
    where(id: HABTM_Campaigns.select(:intervention_id).where(campaign: campaign))
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
  scope :real, -> { where(nature: :record).where('stopped_at <= ?', Time.zone.now) }

  scope :with_generic_cast, lambda { |role, object|
    where(id: InterventionProductParameter.of_generic_role(role).of_actor(object).select(:intervention_id))
  }

  scope :with_unroll, lambda { |*args|
    params = args.extract_options!
    search_params = []

    unless params[:q].blank?
      procedures = Procedo.selection.select { |l, _n| l.downcase.include? params[:q].strip }.map { |_l, n| "'#{n}'" }.join(',')

      search_params << if procedures.empty?
                         "#{Intervention.table_name}.number ILIKE '%#{params[:q]}%'"
                       else
                         "(#{Intervention.table_name}.number ILIKE '%#{params[:q]}%' OR procedure_name IN (#{procedures}))"
                      end
    end

    unless params[:procedure_name].blank?
      search_params << "#{Intervention.table_name}.procedure_name = '#{params[:procedure_name]}'"
    end

    unless params[:product_id].blank?
      search_params << "#{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_parameters WHERE type = 'InterventionTarget' AND product_id = '#{params[:product_id]}')"
    end

    unless params[:period_interval].blank? && params[:period].blank?

      period_interval = params[:period_interval]
      period = params[:period]

      if period_interval.to_sym == :day
        search_params << "EXTRACT(DAY FROM #{Intervention.table_name}.started_at) = #{period.to_date.day} AND EXTRACT(MONTH FROM #{Intervention.table_name}.started_at) = #{period.to_date.month} AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = #{period.to_date.year}"
      end

      if period_interval.to_sym == :week
        beginning_of_week = period.to_date.at_beginning_of_week.to_time.beginning_of_day
        end_of_week = period.to_date.at_end_of_week.to_time.end_of_day
        search_params << "#{Intervention.table_name}.started_at >= '#{beginning_of_week}' AND #{Intervention.table_name}.stopped_at <= '#{end_of_week}'"
      end

      if period_interval.to_sym == :month
        search_params << "EXTRACT(MONTH FROM #{Intervention.table_name}.started_at) = #{period.to_date.month} AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = #{period.to_date.year}"
      end

      if period_interval.to_sym == :year
        search_params << "EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = #{period.to_date.year}"
      end
    end

    unless params[:nature].blank?
      search_params << "#{Intervention.table_name}.nature = '#{params[:nature]}'"
      if params[:nature] == :request
        search_params << "#{Intervention.table_name}.request_intervention_id IS NULL"
      end
    end

    unless params[:state].blank?
      search_params << "#{Intervention.table_name}.state = '#{params[:state]}'"
    end

    where(search_params.join(' AND '))
      .includes(:doers)
      .references(product_parameters: [:product])
      .order(started_at: :desc)
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
    if started_at && stopped_at
      self.whole_duration = (stopped_at - started_at).to_i
    end
    self.currency ||= Preference[:currency]
    self.state ||= self.class.state.default_value
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
    if started_at && stopped_at && stopped_at <= started_at
      errors.add(:stopped_at, :posterior, to: started_at.l)
    end
    true
  end

  before_save do
    columns = { name: name, started_at: started_at, stopped_at: stopped_at, nature: :production_intervention }

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

  # This method permits to add stock journal entries corresponding to the interventions which consume or produce products
  # It depends on the preference which permit to activate the "permanent_stock_inventory" and "automatic bookkeeping"
  #       Mode Intervention      |     Debit                      |            Credit            |
  # outputs                      |    stock(3X)                   |   stock_movement(603X/71X)   |
  # inputs                       |  stock_movement(603X/71X)      |            stock(3X)         |
  bookkeep do |b|
    if Preference[:permanent_stock_inventory] && nature == :record
      stock_journal = Journal.find_or_create_by!(nature: :stocks)
      # inputs
      if inputs.any?
        for input in inputs
          label = tc(:bookkeep, resource: name, name: input.product.name)
          b.journal_entry(stock_journal, printed_on: printed_at.to_date, if: input.product_movement) do |entry|
            entry.add_debit(label, input.variant.stock_movement_account_id, input.stock_amount.round(2)) unless input.stock_amount.zero?
            entry.add_credit(label, input.variant.stock_account_id, input.stock_amount.round(2)) unless input.stock_amount.zero?
          end
        end
      end
      # outputs
      if outputs.any?
        for output in outputs
          label = tc(:bookkeep, resource: name, name: output.variant.name)
          b.journal_entry(stock_journal, printed_on: printed_at.to_date, if: output.product_movement) do |entry|
            entry.add_debit(label, output.variant.stock_account_id, output.stock_amount.round(2)) unless output.stock_amount.zero?
            entry.add_credit(label, output.variant.stock_movement_account_id, output.stock_amount.round(2)) unless output.stock_amount.zero?
          end
         end
      end
    end
  end

  def printed_at
    (stopped_at? ? stopped_at : created_at? ? created_at : Time.zone.now)
  end

  def with_undestroyable_products?
    outputs.map(&:product).detect do |product|
      next unless product
      InterventionProductParameter.of_actor(product).where.not(type: 'InterventionOutput').any?
    end
  end

  # Returns human activity names
  def human_activities_names
    activities.map(&:name).to_sentence
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

  def targets_list
    targets.map(&:product).compact.map(&:work_name).sort
  end

  # Returns human target names
  def human_target_names
    targets_list.to_sentence
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

  def completely_filled?
    reference_names = parameters.pluck(:reference_name).uniq
    reference_names = reference_names.map(&:to_sym)
    parameters_names = procedure.parameters.map(&:name).uniq

    result = parameters_names - reference_names | reference_names - parameters_names
    result.empty?
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

  def human_total_cost
    [:input, :tool, :doer].map do |type|
      (cost(type) || 0.0).to_d
    end.sum.round(Nomen::Currency.find(currency).precision)
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

  def working_area(unit = :hectare)
    ActiveSupport::Deprecation.warn 'Intervention#working_area is deprecated. Please use Intervention#working_zone_area instead.'
    working_zone_area(unit)
  end

  def status
    return :go if done?
  end

  def runnable?
    return false unless record? && procedure
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

    def convert_to_purchase(interventions)
      purchase = nil
      transaction do
        interventions = interventions
                        .collect { |intv| (intv.is_a?(self) ? intv : find(intv)) }
                        .sort_by(&:stopped_at)
        planned_at = interventions.last.stopped_at
        owners = interventions.map(&:doers).map { |t| t.map(&:product).map(&:owner).compact }.flatten.uniq
        supplier = owners.first unless owners.second.present?
        unless nature = PurchaseNature.actives.first
          unless journal = Journal.purchases.opened_at(planned_at).first
            raise 'No purchase journal'
          end
          nature = PurchaseNature.new(
            active: true,
            currency: Preference[:currency],
            with_accounting: true,
            journal: journal,
            by_default: true,
            name: PurchaseNature.tc('default.name', default: PurchaseNature.model_name.human)
          )
        end
        purchase = nature.purchases.new(
          supplier: supplier,
          planned_at: planned_at,
          delivery_address: supplier && supplier.default_mail_address,
          description: %(#{Intervention.model_name.plural.tl}:
\t- #{interventions.map(&:name).join("\n\t - ")})
        )

        # Adds items
        interventions.each do |intervention|
          hourly_params = {
            catalog: Catalog.by_default!(:cost),
            quantity_method: -> (_item) { intervention.duration.in_second.in_hour }
          }
          components = {
            doers:  hourly_params,
            tools:  hourly_params,
            inputs: {
              catalog: Catalog.by_default!(:purchase),
              quantity_method: -> (item) { item.quantity }
            }
          }

          components.each do |component, cost_params|
            intervention.send(component).each do |item|
              catalog_item = Maybe(cost_params[:catalog].items.find_by_variant_id(item.variant))
              quantity = cost_params[:quantity_method].call(item).round(3)
              purchase.items.new(
                variant: item.variant,
                unit_pretax_amount: catalog_item.pretax_amount.or_else(nil),
                tax: catalog_item.reference_tax.or_else(nil),
                quantity: quantity.value.to_f,
                annotation: %(#{Intervention.model_name.human} '#{intervention.name}' > \
#{Intervention.human_attribute_name(component).capitalize}
\t- #{item.product.name} x #{quantity.l(precision: 2)})
              )
            end
          end
        end
      end
      purchase
    end

    def convert_to_sale(interventions)
      sale = nil
      transaction do
        interventions = interventions
                        .collect { |intv| (intv.is_a?(self) ? intv : find(intv)) }
                        .sort_by(&:stopped_at)
        planned_at = interventions.last.stopped_at

        owners = interventions.map do |intervention|
          intervention.targets.map do |target|
            if target.product.is_a?(LandParcel)
              prod = target.activity_production
              owner = prod && prod.cultivable_zone && prod.cultivable_zone.farmer
            elsif target.product.is_a?(Equipment)
              owner = target.product.owner
            end
            owner
          end
        end
        owners = owners.flatten.uniq
        client = owners.first unless owners.count > 1
        unless nature = SaleNature.actives.first
          unless journal = Journal.sales.opened_at(planned_at).first
            raise 'No sale journal'
          end
          nature = SaleNature.new(
            active: true,
            currency: Preference[:currency],
            with_accounting: true,
            journal: journal,
            by_default: true,
            name: SaleNature.tc('default.name', default: SaleNature.model_name.human)
          )
        end
        sale = nature.sales.new(
          client: client,
          address: client && client.default_mail_address,
          description: %(#{Intervention.model_name.plural.tl}:
\t- #{interventions.map(&:name).join("\n\t - ")})
        )
        # Adds items
        interventions.each do |intervention|
          hourly_params = {
            catalog: Catalog.by_default!(:cost),
            quantity_method: -> (_item) { intervention.duration.in_second.in_hour }
          }
          components = {
            doers:  hourly_params,
            tools:  hourly_params,
            inputs: {
              catalog: Catalog.by_default!(:sale),
              quantity_method: -> (item) { item.quantity }
            }
          }

          components.each do |component, cost_params|
            intervention.send(component).each do |item|
              catalog_item = Maybe(cost_params[:catalog].items.find_by_variant_id(item.variant))
              quantity = cost_params[:quantity_method].call(item).round(3)
              sale.items.new(
                variant: item.variant,
                unit_pretax_amount: catalog_item.pretax_amount.or_else(nil),
                tax: catalog_item.reference_tax.or_else(nil),
                quantity: quantity.value.to_f,
                annotation: %(#{Intervention.model_name.human} '#{intervention.name}' > \
#{Intervention.human_attribute_name(component).capitalize}
\t- #{item.product.name} x #{quantity.l(precision: 2)})
              )
            end
          end
        end
      end
      sale
    end
  end
end
