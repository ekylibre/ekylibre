# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
#  procedure                   :string(255)      not null
#  production_id               :integer          not null
#  production_support_id       :integer
#  provisional                 :boolean          not null
#  provisional_intervention_id :integer
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
  attr_readonly :procedure, :production_id
  belongs_to :ressource , :polymorphic => true
  belongs_to :production, inverse_of: :interventions
  belongs_to :production_support
  belongs_to :incident
  belongs_to :prescription
  belongs_to :provisional_intervention, class_name: "Intervention"
  has_many :casts, -> { order(:variable) }, class_name: "InterventionCast", inverse_of: :intervention
  has_many :operations, inverse_of: :intervention
  enumerize :procedure, in: Procedo.names.sort
  enumerize :state, in: [:undone, :squeezed, :in_progress, :done], default: :undone, predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :natures, :procedure, :ressource_type, :state, allow_nil: true, maximum: 255
  validates_inclusion_of :provisional, in: [true, false]
  validates_presence_of :natures, :procedure, :production, :state
  #]VALIDATORS]
  validates_inclusion_of :procedure, in: self.procedure.values
  validates_presence_of  :started_at, :stopped_at


  delegate :storage, to: :production_support

  accepts_nested_attributes_for :casts, :operations

  # @TODO in progress - need to .all parent procedure to have the name of the procedure_nature

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
    # if op = self.operations.reorder("started_at").first
    #   self.started_at = op.started_at
    # end
    # if op = self.operations.reorder("stopped_at DESC").first
    #   self.stopped_at = op.stopped_at
    # end
    self.natures = self.natures.to_s.strip.split(/[\s\,]+/).sort.join(" ")
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
    Procedo[self.procedure]
  end

  # Returns variable names
  def casting
    self.casts.map(&:actor).compact.map(&:name).sort.to_sentence
  end

  def name
    reference.human_name
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
  
  def working_area(unit=:hectare)
    if self.casts.of_role(:target).count > 0
      target = self.casts.of_role(:target).where.not(actor_id: nil).first
      if target
        return target.actor.area.round(2)
      else
        return nil
      end
    end
    return nil
  end
  
  # def valid_for_run?(started_at, duration)
  #   if self.reference.minimal_duration < duration
  #     raise ArgumentError, "The intervention cannot last less than the minimum"
  #   end
  #   for op in self.reference.operations

  #   end
  # end

  def status
    (self.runnable? ? :waiting : self.state)
  end

  def runnable?
    return false unless self.undone?
    valid = true
    for variable in self.reference.variables.values
      valid = false unless cast = self.casts.find_by(variable: variable.name)
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
      reference = self.reference
      rep = reference.spread_time(duration)
      for id, operation in reference.operations
        d = operation.duration || rep
        self.operations.create!(started_at: started_at, stopped_at: started_at + d, position: id.to_i)
        started_at += d
      end
      # Check variables presence
      for variable in reference.variables.values
        unless self.casts.find_by(variable: variable.name)
          raise MissingVariable, "Variable #{variable.name} is missing"
        end        
      end
      # Build new products
      for variable in reference.new_variables
        genited = self.casts.find_by!(variable: variable.name)
        genitor = self.casts.find_by!(variable: variable.genitor_name)
        if variable.parted?
          # Parted from
          variant = genitor.variant
          genited.actor = variant.matching_model.create!(variant: variant, born_at: stopped_at, initial_owner: genitor.actor.owner, initial_container: genitor.actor.container, initial_arrival_cause: :birth, initial_population: genited.quantity)
        elsif variable.produced?
          # Produced by
          unless variant = genited.variant || variable.variant(self)
            raise StandardError, "No variant for #{variable.name} in intervention ##{self.id} (#{self.procedure})"
          end
          genited.actor = variant.matching_model.create!(variant: variant, born_at: started_at, initial_owner: genitor.actor.owner, initial_container: genitor.actor.container, initial_arrival_cause: :birth, initial_population: genited.quantity)
        else
          raise StandardError, "Don't known how to create the variable #{variable.name} for procedure #{variable.procedure_name}"
        end
        genited.save!
      end
      self.reload
      self.started_at = period[:started_at]
      self.stopped_at = started_at
      self.state = :done
      self.save!
    end
  end

  def add_cast(attributes)
    self.casts.create!(attributes)
  end

  def self.run!(attributes, period, &block)
    intervention = create!(attributes)
    yield intervention
    intervention.run!(period)
    return intervention
  end

end
