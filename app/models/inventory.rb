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
# == Table: inventories
#
#  accounted_at      :datetime         
#  changes_reflected :boolean          
#  comment           :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  created_on        :date             not null
#  creator_id        :integer          
#  id                :integer          not null, primary key
#  journal_entry_id  :integer          
#  lock_version      :integer          default(0), not null
#  moved_on          :date             
#  number            :string(16)       
#  responsible_id    :integer          
#  updated_at        :datetime         not null
#  updater_id        :integer          
#


class Inventory < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :number, :allow_nil => true, :maximum => 16
  #]VALIDATORS]
  belongs_to :responsible, :class_name=>"User"
  has_many :lines, :class_name=>"InventoryLine", :dependent=>:destroy

  before_validation do
    self.created_on ||= Date.today
  end

  bookkeep :on=>:nothing do |b|
  end

  def reflect_changes(moved_on=Date.today)
    self.moved_on = moved_on
    self.changes_reflected = true
    for line in self.lines
      line.confirm_stock_move(moved_on)
    end
    self.save
  end

  def set_lines(lines)
    # (Re)init lines
    self.lines.clear
    # Load (new) values
    for line in lines
      l = self.lines.new(line.merge(:company_id=>self.company_id))
      l.stock_id = line[:stock_id].to_i if line[:stock_id]
      l.save!
    end
  end

  # def to_inventory_line(quantity, inventory_id)
  #   result = (self.quantity.to_f == quantity.to_f)
  #   puts self.quantity.to_f.inspect+quantity.to_f.inspect+result.inspect
  #   InventoryLine.create!(:product_id=>self.product_id, :warehouse_id=>self.warehouse_id, :inventory_id=>inventory_id, :theoric_quantity=>self.quantity, :quantity=>quantity, :company_id=>self.company_id)
  # end

end
