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
# == Table: procedure_variables
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  nomen        :string(255)      not null
#  procedure_id :integer          not null
#  roles        :string(255)
#  target_id    :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ProcedureVariable < Ekylibre::Record::Base
  attr_accessible :nomen, :target_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nomen, :roles, :allow_nil => true, :maximum => 255
  validates_presence_of :nomen, :procedure, :target
  #]VALIDATORS]
  belongs_to :procedure, :inverse_of => :variables
  belongs_to :target, :class_name => "Product"

  delegate :name, :to => :target, :prefix => true
  
   
  scope :of_role, lambda { |*natures|
    #for nature in natures
      #raise ArgumentError.new("Expected ProcedureNature, got #{nature.class.name}:#{nature.inspect}") unless nature.is_a?(ProcedureNature)
    #end
    #where('nature IN (?)', natures)
    where(:roles => ["input"])
  }
  
  def name
    self.procedure.reference.hash[self.procedure.uid].variables[self.nomen].human_name
  end
  
  def target_used_quantity
    self.target.real_quantity
  end
  
  def target_used_quantity_unit
    self.target.unit
  end

end
