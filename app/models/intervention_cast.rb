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
#  quantity        :decimal(19, 4)
#  roles           :string(320)
#  updated_at      :datetime         not null
#  updater_id      :integer
#  variable        :string(255)      not null
#
class InterventionCast < Ekylibre::Record::Base
  # attr_accessible :nomen, :target_id, :procedure_id, :role, :measure_quantity, :indicator, :measure_unit
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :variable, :allow_nil => true, :maximum => 255
  validates_length_of :roles, :allow_nil => true, :maximum => 320
  validates_presence_of :intervention, :variable
  #]VALIDATORS]
  belongs_to :intervention, :inverse_of => :casts
  belongs_to :actor, :class_name => "Product"
  # composed_of :quantity, :class_name => "Measure", :mapping => [%w(measure_quantity value), %w(measure_unit unit)]

  delegate :name, :to => :target, :prefix => true

  scope :of_role, lambda { |role|
    #for nature in natures
      #raise ArgumentError.new("Expected ProcedureNature, got #{nature.class.name}:#{nature.inspect}") unless nature.is_a?(ProcedureNature)
    #end
    where("role = ?", role.to_s)
  }

  #def name
   # self.procedure.reference.hash[self.procedure.uid].variables[self.nomen].human_name
  #end

end
