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
#  started_at                  :datetime
#  state                       :string(255)      not null
#  stopped_at                  :datetime
#  updated_at                  :datetime         not null
#  updater_id                  :integer
#

class Intervention < Ekylibre::Record::Base
  attr_readonly :procedure, :production_id
  belongs_to :production, inverse_of: :interventions
  belongs_to :production_support
  belongs_to :incident
  belongs_to :prescription
  belongs_to :provisional_intervention, class_name: "Intervention"
  has_many :casts, :class_name => "InterventionCast", inverse_of: :intervention
  has_many :operations, inverse_of: :intervention
  enumerize :procedure, :in => Procedo.names.sort
  enumerize :state, :in => [:undone, :squeezed, :in_progress, :done], :default => :undone
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :natures, :procedure, :state, :allow_nil => true, :maximum => 255
  validates_inclusion_of :provisional, :in => [true, false]
  validates_presence_of :natures, :procedure, :production, :state
  #]VALIDATORS]
  validates_inclusion_of :procedure, :in => self.procedure.values


  delegate :storage, to: :production_support

  accepts_nested_attributes_for :casts, :operations

  # @TODO in progress - need to .all parent procedure to have the name of the procedure_nature

  scope :of_nature, lambda { |*natures|
    where("natures ~ E?", natures.sort.map { |nature| "\\\\m#{nature.to_s.gsub(/\W/, '')}\\\\M" }.join(".*"))
  }
  # scope :of_nature, lambda { |nature|
  #   raise ArgumentError.new("Unknown nature #{nature.inspect}") unless Nomen::ProcedureNatures[nature]
  #   where("natures ~ E?", "\\\\m#{nature}\\\\M")
  # }
  scope :provisional, -> { where(provisional: true) }
  scope :real, -> { where(provisional: false) }

  # scope :with_variable, lambda { |role, object|
  #    where("id IN (SELECT intervention_id FROM #{InterventionCast.table_name} WHERE target_id = ? AND role = ?)", object.id, role.to_s)
  # }
  scope :with_cast, lambda { |role, object|
     where("id IN (SELECT intervention_id FROM #{InterventionCast.table_name} WHERE actor_id = ? AND roles ~ E?)", object.id, role.to_s)
  }

  before_validation do
    self.state ||= self.class.state.default
    if p = self.reference
      self.natures = p.natures.sort.join(" ")
    end
    if op = self.operations.reorder("started_at").first
      self.started_at = op.started_at
    end
    if op = self.operations.reorder("stopped_at DESC").first
      self.stopped_at = op.stopped_at
    end
    self.natures = self.natures.to_s.strip.split(/[\s\,]+/).sort.join(" ")
  end

  validate do
   if self.production_support and self.production
     errors.add(:production_id, :invalid) if self.production_support.production != self.production
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

  def valid_for_run?(started_at, duration)
    if self.reference.minimal_duration < duration
      raise ArgumentError.new("The intervention cannot last less than the minimum")
    end
    for op in self.reference.operations

    end
  end

  def run!(period)
    started_at = period[:started_at]
    duration = period[:duration]
    reference = self.reference
    rep = reference.spread_time(duration)
    for op in reference.operations
      d = op.duration || rep
      self.operations.create!(started_at: started_at, stopped_at: started_at + d, position: op.id)
      started_at += d
    end
    self.reload
    self.state = :done
    self.save!
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
