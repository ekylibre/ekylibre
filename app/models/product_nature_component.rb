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
# == Table: product_nature_components
#
#  active            :boolean          not null
#  comment           :text             
#  component_id      :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  product_nature_id :integer          not null
#  quantity          :decimal(19, 4)   not null
#  started_at        :datetime         
#  stopped_at        :datetime         
#  updated_at        :datetime         not null
#  updater_id        :integer          
#


class ProductNatureComponent < CompanyRecord
  attr_accessible :active, :comment, :name, :product_id, :component_id, :quantity
  attr_readonly :quantity, :name, :comment
  belongs_to :component, :class_name => "ProductNature"
  belongs_to :product_nature
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :component, :name, :product_nature, :quantity
  #]VALIDATORS]

  autosave :product_nature

  before_validation do
    self.name = tg(:x_units_of_product_y, :quantity => self.quantity, :unit => self.component.unit.name, :product => self.component.name)
  end

  before_validation(:on => :create) do
    self.active = true
    self.started_at = Time.now
  end

  def update #_without_callbacks
    current_time = Time.now
    stamper = self.class.stamper_class.stamper rescue nil
    # raise stamper.inspect unless stamper.nil?
    stamper_id = stamper.id if stamper.is_a? Entity
    nc = self.class.create!(self.attributes.merge(:created_at => current_time, :updated_at => current_time, :creator_id => stamper_id, :updater_id => stamper_id).delete_if{|a| a.to_s == "id" }, :without_protection => true)
    self.class.update_all({:active => false}, {:id => self.id})
    return nc
  end

  def destroy #_without_callbacks
    unless new_record?
      self.class.update_all({:active => false, :stopped_at => Time.now}, {:id => self.id})
    end
  end

  def check_quantities(params, production_quantity)
    total = 0
    for p in params[self.id.to_s]
      total += p[1].to_d
    end
    value = (total == (self.quantity*production_quantity))
  end

end
