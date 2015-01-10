# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: product_components
#
#  active       :boolean          not null
#  comment      :text             
#  company_id   :integer          not null
#  component_id :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  product_id   :integer          not null
#  quantity     :decimal(16, 4)   not null
#  started_at   :datetime         
#  stopped_at   :datetime         
#  updated_at   :datetime         not null
#  updater_id   :integer          
#  warehouse_id :integer          not null
#


class ProductComponent < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :company, :component, :name, :product, :quantity, :warehouse
  #]VALIDATORS]
  attr_readonly :company_id, :quantity, :name, :comment
  belongs_to :company
  belongs_to :component, :class_name=>"Product"
  belongs_to :warehouse
  belongs_to :product

  autosave :product

  before_validation do
    self.name = tg(:x_units_of_product_y, :quantity=>self.quantity, :unit=>self.component.unit.name, :product=>self.component.name)
  end
  
  before_validation(:on=>:create) do    
    self.active = true
    self.started_at = Time.now
  end

  def update #_without_callbacks
    current_time = Time.now
    stamper = self.class.stamper_class.stamper rescue nil
    # raise stamper.inspect unless stamper.nil?
    stamper_id = stamper.id if stamper.is_a? User
    nc = self.class.create!(self.attributes.delete_if{|k,v| k.to_s.match(/^company(\_id)?$/)}.merge(:company_id=>self.company_id, :created_at=>current_time, :updated_at=>current_time, :creator_id=>stamper_id, :updater_id=>stamper_id))
    self.class.update_all({:active=>false}, {:id=>self.id})
    return nc
  end

  def destroy #_without_callbacks
    unless new_record?
      self.class.update_all({:active=>false, :stopped_at=>Time.now}, {:id=>self.id})
    end
  end

  def check_quantities(params, production_quantity)
    total = 0
    for p in params[self.id.to_s]
      total += p[1].to_d
    end
    value = (total == (self.quantity*production_quantity))
  end
  
#   def stocks_move_create(params, production_id)
#     for p in params
#       if p[1] > 0
#         StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>p[1], :warehouse_id=>p[0], :product_id=>self.component_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>false, :origin_type=>Production.to_s, :origin_id=>production_id)
#       end
#     end

#   end

end
