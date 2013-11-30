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
# == Table: intervention_casts
#
#  actor_id        :integer          
#  created_at      :datetime         not null
#  creator_id      :integer          
#  id              :integer          not null, primary key
#  intervention_id :integer          not null
#  lock_version    :integer          default(0), not null
#  population      :decimal(19, 4)
#  reference_name  :string(255)      not null
#  roles           :string(320)
#  shape           :spatial({:srid=>
#  updated_at      :datetime         not null
#  updater_id      :integer          
#  variant_id      :integer          
#

class InterventionCast < Ekylibre::Record::Base
  belongs_to :intervention, inverse_of: :casts
  belongs_to :actor, class_name: "Product", inverse_of: :intervention_casts
  belongs_to :variant, class_name: "ProductNatureVariant"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_length_of :reference_name, allow_nil: true, maximum: 255
  validates_length_of :roles, allow_nil: true, maximum: 320
  validates_presence_of :intervention, :reference_name
  #]VALIDATORS]
  # composed_of :population, class_name: "Measure", :mapping => [%w(measure_population value), %w(measure_unit unit)]

  delegate :name, to: :actor, prefix: true
  delegate :evaluated_price, to: :actor
  delegate :started_at, :stopped_at, to: :intervention
  delegate :matching_model, to: :variant

  scope :of_role, lambda { |role|
    # for nature in natures
    #   raise ArgumentError.new("Expected ProcedureNature, got #{nature.class.name}:#{nature.inspect}") unless nature.is_a?(ProcedureNature)
    # end
    where("roles ~ E?", "\\\\m#{role}\\\\M")
  }

  before_validation do
    if self.reference
      self.roles = self.reference.roles.join(', ')
    end
    if self.actor.is_a?(Product)
      self.variant  ||= self.actor.variant
      for indicator in self.actor.whole_indicators
        self.send("#{indicator}=", self.actor.send(indicator, at: self.started_at)) unless self.send(indicator)
      end
    end
  end

  validate do
    errors.add(:reference_name, :invalid) unless self.reference
  end

  # multiply evaluated_price of an actor(product) and used population in this cast
  def cost
    if self.actor and self.evaluated_price
      if self.input?
        self.evaluated_price * self.population
      else self.tool? or self.doer?
        duration = (self.stopped_at - self.started_at).in_second.convert(:hour).round(2)
        self.evaluated_price * duration.to_s.to_f
      end
    else
      return nil
    end
  end

  def reference
    self.intervention.reference.variables[self.reference_name]
  end

  def variable_name
    self.reference.human_name
  end

  def name
    self.reference.human_name
  end

  for role in [:input, :output, :target, :tool, :doer]
    code  = "def #{role}?(procedure_nature = nil)\n"
    code << "  if procedure_nature\n"
    code << "    self.roles_array.detect{|r| r.first == procedure_nature and r.second == :#{role}}\n"
    code << "  else\n"
    code << "    self.roles_array.detect{|r| r.second == :#{role}}\n"
    code << "  end\n"
    code << "end\n"
    class_eval(code)
  end

  def roles_array
    self.roles.split(/[\,[[:space:]]]+/).collect{|role| role.split(/\-/)[0..1].map(&:to_sym) }
  end

  # Define if the cast is valid for run
  def runnable?
    if self.reference.new?
      if self.reference.known_variant?
        return self.population.present?
      else
        return (self.variant and self.population.present?)
      end
    else
      return self.actor
    end
  end

end
