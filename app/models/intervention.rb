# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  created_at       :datetime         not null
#  creator_id       :integer
#  description      :text
#  event_id         :integer
#  id               :integer          not null, primary key
#  issue_id         :integer
#  lock_version     :integer          default(0), not null
#  number           :string
#  prescription_id  :integer
#  reference_name   :string           not null
#  started_at       :datetime
#  state            :string           not null
#  stopped_at       :datetime
#  updated_at       :datetime         not null
#  updater_id       :integer
#  whole_duration   :integer
#  working_duration :integer
#

class MissingVariable < StandardError
end

class Intervention < Ekylibre::Record::Base
  include PeriodicCalculable
  attr_readonly :reference_name, :production_id
  belongs_to :event, dependent: :destroy, inverse_of: :intervention
  belongs_to :issue
  belongs_to :prescription
  has_many :casts, -> { order(:position) }, class_name: 'InterventionCast', inverse_of: :intervention, dependent: :destroy
  has_many :doers, class_name: 'InterventionDoer', dependent: :destroy, inverse_of: :intervention
  has_many :inputs, class_name: 'InterventionInput', dependent: :destroy, inverse_of: :intervention
  has_many :outputs, class_name: 'InterventionOutput', dependent: :destroy, inverse_of: :intervention
  has_many :targets, class_name: 'InterventionTarget', dependent: :destroy, inverse_of: :intervention
  has_many :tools, class_name: 'InterventionTool', dependent: :destroy, inverse_of: :intervention
  has_many :working_periods, class_name: 'InterventionWorkingPeriod', dependent: :destroy, inverse_of: :intervention
  enumerize :reference_name, in: Procedo.procedure_names #  + ['animal_changing']
  enumerize :state, in: [:undone, :squeezed, :in_progress, :done], default: :undone, predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :whole_duration, :working_duration, allow_nil: true, only_integer: true
  validates_presence_of :reference_name, :state
  # ]VALIDATORS]
  # validates_inclusion_of :reference_name, in: self.reference_name.values
  # validates_presence_of :started_at, :stopped_at
  validates_associated :doers, :inputs, :outputs, :targets, :tools, :working_periods

  serialize :parameters, HashWithIndifferentAccess

  alias_attribute :duration, :working_duration

  delegate :storage, to: :production_support

  calculable period: :month, column: :working_duration, at: :started_at, name: :sum

  acts_as_numbered
  accepts_nested_attributes_for :doers, :inputs, :outputs, :targets, :tools, :working_periods

  # @TODO in progress - need to call parent reference_name to have the name of the procedure_nature

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }

  # scope :of_nature, lambda { |*natures|
  #   where('natures ~ E?', '\\\\m(' + natures.collect { |n| Nomen::ProcedureNature.all(n) }.flatten.sort.join('|') + ')\\\\M')
  # }
  scope :of_category, lambda { |category|
    # TODO
  }

  scope :of_campaign, lambda { |campaign|
    where('(started_at, stopped_at) OVERLAPS (?, ?)', campaign.started_on, campaign.stopped_on)
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
    where(id: InterventionCast.of_generic_role(role).of_actor(object).select(:intervention_id))
  }

  before_validation do
    self.state ||= self.class.state.default
    # if p = reference
    #   self.natures = p.natures.sort.join(' ')
    # end
    # set production_id
    # if production_support
    #   self.production_id ||= production_support.production_id
    # end
  end

  validate do
    # if production
    #   if production_support
    #     errors.add(:production_id, :invalid) if production_support.production != production
    #   else
    #     errors.add(:production_support_id, :blank) if production.with_supports
    #   end
    # end
    if self.started_at && self.stopped_at
      if self.stopped_at <= self.started_at
        errors.add(:stopped_at, :posterior, to: self.started_at.l)
      end
    end
  end

  before_save do
    # self.natures = self.natures.to_s.strip.split(/[\s\,]+/).sort.join(' ')
    # if reference
    #   if duration < reference.fixed_duration
    #     self.stopped_at += reference.fixed_duration
    #   end
    # end
    columns = { name: name, started_at: self.started_at, stopped_at: self.stopped_at, nature: :production_intervention }
    if event
      # self.event.update_columns(columns)
      event.attributes = columns
    else
      event = Event.create!(columns)
      # self.update_column(:event_id, event.id)
      self.event_id = event.id
    end
  end

  # prevents from deleting an intervention that was executed
  protect on: :destroy do
    self.done?
  end

  # Returns activities
  def activities
    Activity.of_intervention(self)
  end

  # Main reference
  def reference
    Procedo.find(reference_name)
  end

  # Returns variable names
  def casting
    casts.map(&:product).compact.map(&:name).sort.to_sentence
  end

  def name
    # raise self.inspect if self.reference_name.blank?
    tc(:name, intervention: (reference ? reference.human_name : "procedures.#{reference_name}".t(default: reference_name.humanize)), number: number)
  end

  def start_time
    started_at
  end

  # Update temporality informations in intervention
  def update_temporality
    started_at = working_periods.minimum(:started_at)
    stopped_at = working_periods.maximum(:stopped_at)
    update_columns(
      started_at: started_at,
      stopped_at: stopped_at,
      working_duration: working_periods.sum(:duration),
      whole_duration: ((stopped_at? && started_at) ? (stopped_at - started_at).to_i : 0)
    )
  end

  # Sums all intervention_cast total_cost of a particular role (see ProcedureNature nomenclature for more details)
  def cost(role = :input)
    selected_casts = casts.of_generic_role(role).with_actor
    if selected_casts.any?
      selected_casts = selected_casts.map(&:cost)
      selected_casts.compact!
      selected_casts.sum
    else
      return nil
    end
  end

  def earn
    if casts.of_generic_role(:output).any?
      casts.of_generic_role(:output).where.not(actor_id: nil).map(&:earn).compact.sum
    else
      return nil
    end
  end

  def working_area(_unit = :hectare)
    if casts.of_generic_role(:target).any?
      if target = casts.of_generic_role(:target).where.not(actor_id: nil).first
        return target.actor.net_surface_area.round(2)
      else
        return nil
      end
    end
    nil
  end

  def status
    if self.undone?
      return (self.runnable? ? :caution : :stop)
    elsif self.done?
      return :go
    end
  end

  def need_parameters?
    reference && reference.need_parameters?
  end

  def runnable?
    return false unless self.undone? && reference
    valid = true
    for variable in reference.variables.values
      unless cast = casts.find_by(reference_name: variable.name) and cast.runnable?
        valid = false
      end
    end
    valid
  end

  # Run the procedure
  def run!(period = {}, parameters = {})
    # TODO: raise something unless runnable?
    # raise StandardError unless self.runnable?
    fail 'Cannot run intervention without reference procedure' unless reference
    self.class.transaction do
      self.state = :in_progress
      self.parameters = parameters.with_indifferent_access if parameters
      self.save!

      started_at = period[:started_at] ||= self.started_at
      duration   = period[:duration] ||= (stopped_at - self.started_at)
      stopped_at = started_at + duration

      reference = self.reference
      # Check variables presence
      for variable in reference.variables.values
        unless casts.find_by(reference_name: variable.name)
          fail MissingVariable, "Variable #{variable.name} is missing"
        end
      end
      # Build new products
      for variable in reference.new_variables
        produced = casts.find_by!(reference_name: variable.name)
        producer = casts.find_by!(reference_name: variable.producer_name)
        if variable.parted?
          # Parted from
          unless variant = producer.variant
            puts "No variant given for #{variable.producer_name} in #{reference_name} (##{id})".red
          end
          produced.actor = producer.actor.part_with(produced.population, born_at: stopped_at, shape: produced.shape)
          unless produced.actor.save
            logger.debug '*' * 80 + variant.matching_model.name
            logger.debug produced.actor.inspect
            logger.debug '-' * 80
            logger.debug produced.actor.errors.inspect
            fail 'Stop'
          end
        elsif variable.produced?
          # Produced by
          unless variant = produced.variant || variable.variant(self)
            fail StandardError, "No variant for #{variable.name} in intervention ##{id} (#{reference_name})"
          end
          produced.actor = variant.matching_model.create!(variant: variant, initial_born_at: stopped_at, initial_owner: producer.actor.owner, initial_container: producer.actor.container, initial_population: produced.population, initial_shape: produced.shape, extjuncted: true)
        else
          fail StandardError, "Don't known how to create the variable #{variable.name} for procedure #{reference_name}"
        end
        produced.save!
      end
      # Load operations
      rep = reference.spread_time(duration)
      for name, operation in reference.operations
        d = operation.duration || rep
        operation = operations.create!(started_at: started_at, stopped_at: (started_at + d), reference_name: name)
        operation.perform_all!
        started_at += d
      end
      reload
      self.started_at = period[:started_at]
      self.stopped_at = started_at
      self.state = :done
      self.save!

      # Sets name for newborns
      for variable in reference.new_variables
        casts.find_by!(reference_name: variable.name).set_default_name!
      end
    end
  end

  def add_cast!(attributes)
    casts.create!(attributes)
  end

  class << self
    def force_started_at?
      Preference[:force_intervention_started_at]
    end

    def force_stopped_at?
      Preference[:force_intervention_stopped_at]
    end

    def run!(attributes, period, &_block)
      intervention = create!(attributes)
      yield intervention
      intervention.run!(period)
      intervention
    end

    # Register and runs an intervention directly with only one operation with "100" as reference
    # In next versions, all intervention will be considered as mono-operation and truly atomic.
    def write(*natures)
      options = natures.extract_options!
      options[:namespace] ||= 'base'
      options[:short_name] ||= natures.first
      options[:version] ||= 0
      unless options.key? :reference_name
        options[:reference_name] = "#{options[:namespace]}-#{options[:short_name]}-#{options[:version]}"
      end

      transaction do
        attrs = options.slice(:reference_name, :description, :issue_id, :prescription_id, :production, :production_support, :recommender_id, :started_at, :stopped_at)
        attrs[:started_at] ||= Time.zone.now
        attrs[:stopped_at] ||= Time.zone.now
        attrs[:natures] = natures.join(' ')
        recorder = Intervention::Recorder.new(attrs)

        yield recorder

        recorder.write!
      end
    end

    # match
    # Returns an array of procedures matching the given actors ordered by relevance
    # whose structure is [[procedure, relevance, arity], [procedure, relevance, arity], ...]
    # where 'procedure' is a Procedo::Procedure object, 'relevance' is a float, 'arity' is the number of actors
    # matched in the procedure
    # ==== parameters:
    #           - actors, an array of actors identified for a given procedure
    # ==== options:
    #           - relevance: sets the relevance threshold above which results are wished. A float number between 0 and 1
    #             is expected. Default value: 0.
    #           - limit: sets the number of wanted results. By default all results are returned
    #           - history: sets the use of actors history to calculate relevance. A boolean is expected.
    #             Default: false,since checking through history is slower
    #           - provisional: sets the use of actors provisional to calculate relevance. A boolean is expected.
    # Default: false, since it's slower
    #           - max_arity: limits results to procedures matching most actors. A boolean is expected. Default: false
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
        history.merge!(Intervention.joins(:casts)
                        .where("intervention_casts.actor_id IN (#{actors_id.join(', ')})")
                        .where(started_at: (Time.zone.now.midnight - 1.year)..(Time.zone.now))
                        .group('interventions.reference_name')
                        .count('interventions.reference_name'))
      end

      if options[:provisional]
        provisional.concat(Intervention.distinct
                            .joins(:casts)
                            .where("intervention_casts.actor_id IN (#{actors_id.join(', ')})")
                            .where(started_at: (Time.zone.now.midnight - 1.day)..(Time.zone.now + 3.days))
                            .pluck('interventions.reference_name')).uniq!
      end

      coeff = {}

      history_size = 1.0 # prevents division by zero
      history_size = history.values.reduce(:+).to_f if history.count >= 1

      denominator = 1.0
      denominator += 2.0 if options[:history] && history.present?
      denominator += 3.0 if provisional.present? # if provisional is empty, it's pointless using it for relevance calculation

      result = []
      Procedo.list.map do |procedure_key, procedure|
        coeff[procedure_key] = 1.0 + 2.0 * (history[procedure_key].to_f / history_size) + 3.0 * provisional.count(procedure_key).to_f
        matched_variables = procedure.matching_variables_for(actors)
        if matched_variables.count > 0
          result << [procedure, (((matched_variables.values.count.to_f / actors.count) * coeff[procedure_key]) / denominator), matched_variables.values.count]
          maximum_arity = matched_variables.values.count if maximum_arity < matched_variables.values.count
        end
      end
      result.delete_if { |_procedure, relevance, _arity| relevance < relevance_threshold }
      result.delete_if { |_procedure, _relevance, arity| arity < maximum_arity } if options[:max_arity]
      result.sort_by { |_procedure, relevance, _arity| -relevance }[0..limit]
    end
  end
end
