# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: interventions
#
#  created_at                  :datetime         not null
#  creator_id                  :integer
#  id                          :integer          not null, primary key
#  incident_id                 :integer
#  lock_version                :integer          default(0), not null
#  natures                     :string(255)      not null
#  prescription_id             :integer
#  production_id               :integer          not null
#  production_support_id       :integer
#  provisional                 :boolean          not null
#  provisional_intervention_id :integer
#  recommended                 :boolean          not null
#  recommender_id              :integer
#  reference_name              :string(255)      not null
#  ressource_id                :integer
#  ressource_type              :string(255)
#  started_at                  :datetime
#  state                       :string(255)      not null
#  stopped_at                  :datetime
#  updated_at                  :datetime         not null
#  updater_id                  :integer
#

class MissingVariable < StandardError
end

class Intervention < Ekylibre::Record::Base
  attr_readonly :reference_name, :production_id
  belongs_to :ressource , :polymorphic => true
  belongs_to :production, inverse_of: :interventions
  belongs_to :production_support
  belongs_to :incident
  belongs_to :prescription
  belongs_to :provisional_intervention, class_name: "Intervention"
  belongs_to :recommender, class_name: "Entity"
  has_many :casts, -> { order(:reference_name) }, class_name: "InterventionCast", inverse_of: :intervention
  has_many :operations, inverse_of: :intervention
  has_one :activity, through: :production
  has_one :campaign, through: :production
  has_one :storage, through: :production_support
  enumerize :reference_name, in: Procedo.names.sort
  enumerize :state, in: [:undone, :squeezed, :in_progress, :done], default: :undone, predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :natures, :reference_name, :ressource_type, :state, allow_nil: true, maximum: 255
  validates_inclusion_of :provisional, :recommended, in: [true, false]
  validates_presence_of :natures, :production, :reference_name, :state
  #]VALIDATORS]
  validates_inclusion_of :reference_name, in: self.reference_name.values
  validates_presence_of  :started_at, :stopped_at
  validates_presence_of :recommender, :if => :recommended?


  delegate :storage, to: :production_support

  accepts_nested_attributes_for :casts, :operations

  # @TODO in progress - need to .all parent reference_name to have the name of the procedure_nature

  scope :between, lambda { |started_at, stopped_at|
    where("started_at BETWEEN ? AND ?", started_at, stopped_at)
  }

  scope :of_nature, lambda { |*natures|
    where("natures ~ E?", natures.sort.map { |nature| "\\\\m#{nature.to_s.gsub(/\W/, '')}\\\\M" }.join(".*"))
  }

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    end
    joins(:production).merge(Production.of_campaign(campaigns))
  }

  scope :of_activities, lambda { |*activities|
    activities.flatten!
    for activity in activities
      raise ArgumentError.new("Expected Activity, got #{activity.class.name}:#{activity.inspect}") unless activity.is_a?(Activity)
    end
    joins(:production).merge(Production.of_activities(activities))
  }

  scope :provisional, -> { where(provisional: true) }
  scope :real, -> { where(provisional: false) }

  # scope :with_variable, lambda { |role, object|
  #    where("id IN (SELECT intervention_id FROM #{InterventionCast.table_name} WHERE target_id = ? AND role = ?)", object.id, role.to_s)
  # }
  scope :with_cast, lambda { |role, object|
     where("id IN (SELECT intervention_id FROM #{InterventionCast.table_name} WHERE actor_id = ? AND roles ~ E?)", object.id, "\\\\m#{role}\\\\M")
  }

  before_validation do
    self.state ||= self.class.state.default
    if p = self.reference
      self.natures = p.natures.sort.join(" ")
    end
    self.natures = self.natures.to_s.strip.split(/[\s\,]+/).sort.join(" ")
    # set produciton_id
    if self.production_support
      self.production_id = self.production_support.production.id
    end
  end

  validate do
    if self.production_support and self.production
      errors.add(:production_id, :invalid) if self.production_support.production != self.production
    end
    if self.started_at and self.stopped_at
      if self.stopped_at <= self.started_at
        errors.add(:stopped_at, :greater_than, count: self.stopped_at.l)
      end
    end
  end


  # Main reference
  def reference
    Procedo[self.reference_name]
  end

  # Returns variable names
  def casting
    self.casts.map(&:actor).compact.map(&:name).sort.to_sentence
  end

  def name
    "models.intervention.name".t(intervention: self.reference.human_name, number: self.id)
  end

  def start_time
    self.started_at
  end
  # Returns total duration of an intervention
  def duration
    # if self.operations.count > 0
    #   self.operations.map(&:duration).compact.sum
    # else
    #   return 0
    # end
    return (self.stopped_at - self.started_at)
  end

  # sum all intervention_cast total_cost of a particular role (see ProcedureNature nomenclature for more details)
  def cost(role = :input)
    if self.casts.of_role(role).count > 0
      self.casts.of_role(role).where.not(actor_id: nil).map(&:cost).compact.sum
    else
      return nil
    end
  end

  def working_area(unit = :hectare)
    if self.casts.of_role(:target).any?
      if target = self.casts.of_role(:target).where.not(actor_id: nil).first
        return target.actor.area.round(2)
      else
        return nil
      end
    end
    return nil
  end

  def status
    (self.runnable? ? :waiting : self.state)
  end

  def runnable?
    return false unless self.undone?
    valid = true
    for variable in self.reference.variables.values
      valid = false unless cast = self.casts.find_by(reference_name: variable.name)
      valid = false unless cast.runnable?
    end
    return valid
  end

  # Run the procedure
  def run!(period = {})
    # TODO raise something unless runnable?
    # raise StandardError unless self.runnable?
    self.class.transaction do
      self.state = :in_progress
      self.save!

      started_at = period[:started_at] ||= self.started_at
      duration   = period[:duration]  ||= (self.stopped_at - self.started_at)
      stopped_at = started_at + duration

      reference = self.reference
      # Check variables presence
      for variable in reference.variables.values
        unless self.casts.find_by(reference_name: variable.name)
          raise MissingVariable, "Variable #{variable.name} is missing"
        end
      end
      # Build new products
      for variable in reference.new_variables
        produced = self.casts.find_by!(reference_name: variable.name)
        producer = self.casts.find_by!(reference_name: variable.producer_name)
        if variable.parted?
          # Parted from
          variant = producer.variant
          produced.actor = variant.matching_model.new(variant: variant, born_at: stopped_at, initial_owner: producer.actor.owner, initial_container: producer.actor.container, initial_arrival_cause: :birth, initial_population: produced.population, name: producer.name)
          unless produced.actor.save
            puts "*" * 80 + variant.matching_model.name
            puts produced.actor.inspect
            puts '-' * 80
            puts produced.actor.errors.inspect
            raise "Stop"
          end
          # produced.actor.is_measured!(:population,
        elsif variable.produced?
          # Produced by
          unless variant = produced.variant || variable.variant(self)
            raise StandardError, "No variant for #{variable.name} in intervention ##{self.id} (#{self.reference_name})"
          end
          produced.actor = variant.matching_model.create!(variant: variant, born_at: stopped_at, initial_owner: producer.actor.owner, initial_container: producer.actor.container, initial_arrival_cause: :birth, initial_population: produced.population)
        else
          raise StandardError, "Don't known how to create the variable #{variable.name} for procedure #{self.reference_name}"
        end
        produced.save!
      end
      # Load operations
      rep = reference.spread_time(duration)
      for name, operation in reference.operations
        d = operation.duration || rep
        self.operations.create!(started_at: started_at, stopped_at: started_at + d, reference_name: name)
        started_at += d
      end
      self.reload
      self.started_at = period[:started_at]
      self.stopped_at = started_at
      self.state = :done
      self.save!
    end
  end

  def add_cast!(attributes)
    self.casts.create!(attributes)
  end

  def self.run!(attributes, period, &block)
    intervention = create!(attributes)
    yield intervention
    intervention.run!(period)
    return intervention
  end

end
