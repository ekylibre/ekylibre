# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Mérigon
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
# == Table: operations
#
#  company_id     :integer          not null
#  consumption    :decimal(16, 4)   
#  created_at     :datetime         not null
#  creator_id     :integer          
#  description    :text             
#  duration       :decimal(16, 4)   
#  hour_duration  :decimal(16, 4)   
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  min_duration   :decimal(16, 4)   
#  moved_on       :date             
#  name           :string(255)      not null
#  nature_id      :integer          
#  planned_on     :date             not null
#  responsible_id :integer          not null
#  started_at     :datetime         not null
#  stopped_at     :datetime         
#  target_id      :integer          
#  target_type    :string(255)      
#  tools_list     :string(255)      
#  updated_at     :datetime         not null
#  updater_id     :integer          
#

class Operation < ActiveRecord::Base
  belongs_to :company
  belongs_to :nature, :class_name=>OperationNature.name
  belongs_to :responsible, :class_name=>User.name
  belongs_to :target, :polymorphic=>true
  has_many :tool_uses, :dependent=>:destroy
  has_many :lines, :class_name=>OperationLine.name, :dependent=>:destroy
  has_many :tools, :through=>:tool_uses

  attr_readonly :company_id
 
  def before_validation_on_create
    self.started_at = Time.now if self.started_at.nil?
  end

  def before_validation
    self.duration = (self.min_duration.to_i + (self.hour_duration.to_i)*60 )
  end

  def set_tools(tools)
    # Reinit tool uses
    self.tool_uses.clear
    # Add new tools
    unless tools.nil?
      tools.each do |tool|
        self.company.tool_uses.create!(:operation_id=>self.id, :tool_id=>tool[0].to_i)
      end
    end
    self.reload
    self.tools_list = self.tools.collect{|t| t.name}.join(", ")
    self.save
  end


  # Set all the lines in one time 
  def set_lines(lines)
    # Reinit stock if existing lines
    self.lines.clear
    # Reload (new) values
    for line in lines
      self.lines.create!(line)
    end
    return true
  end

  def make(made_on)
    ActiveRecord::Base.transaction do
      for line in lines
        # line.product.add_stock_move(:virtual=>false, :incoming=>line.out?, :origin=>line)
        line.product.move_stock(:incoming=>line.out?, :origin=>line)
      end
      self.update_attributes!(:moved_on=>made_on) 
    end
  end

end




# class Production < ActiveRecord::Base
#   attr_readonly :company_id, :product_id
#   belongs_to :company
#   belongs_to :product
#   belongs_to :location
#   belongs_to :tracking
#   has_one :real_stock_move, :class_name=>StockMove.name,  :conditions=>{:virtual=>false,  :input=>true}
#   has_one :virtual_stock_move, :class_name=>StockMove.name, :conditions=>{:virtual=>true, :input=>true}

#   def before_validation
#     self.planned_on = Date.today
#     self.moved_on = Date.today
#     locations = Location.find_all_by_company_id(self.company_id)
#     self.location_id = locations[0].id if locations.size == 1 and self.location_id.nil?

#     self.tracking_serial = self.tracking_serial.strip
#     unless self.tracking_serial.blank?
#       producer = self.company.entity
#       unless producer.has_another_tracking?(self.tracking_serial, self.product_id)
#         tracking = self.company.trackings.find_by_serial_and_producer_id(self.tracking_serial.upper, producer.id)
#         tracking = self.company.trackings.create!(:name=>self.tracking_serial, :product_id=>self.product_id, :producer_id=>producer.id) if tracking.nil?
#         self.tracking_id = tracking.id
#       end
#       self.tracking_serial.upper!
#     end

#   end

#   def validate
#     # Validate that tracking serial is not used for a different product
#     producer = self.company.entity
#     unless self.tracking_serial.blank?
#       errors.add(:tracking_serial, tc(:is_already_used_with_an_other_product)) if producer.has_another_tracking?(self.tracking_serial, self.product_id)
#     end
#     errors.add_to_base(tc(:location_can_receive_product, :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name)) unless self.location.can_receive(self.product_id)
#   end

 
#   def before_update
# #     old_real_move = StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :product_id=>self.product_id, :input=>true, :virtual=>false})
# #     old_virtual_move = StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :product_id=>self.product_id, :input=>true, :virtual=>true})
# #     old_real_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.location_id)
# #     old_virtual_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.location_id)
#     self.real_stock_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.location_id)
#     self.virtual_stock_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.location_id)    

#     # self.product.move_to_stock
#   end


#   def move_stocks(params={}, update=nil)
#     if !params.empty?
#       for component in self.product.components
#         for p in params[component.id.to_s]
#           if p[1].to_d > 0
#             virtual_move = StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :input=>false, :location_id=>p[0] , :product_id=>component.component_id, :virtual=>true})
#             real_move =  StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :input=>false, :location_id=>p[0] , :product_id=>component.component_id, :virtual=>false})
#             if virtual_move.nil?
#               StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>p[1], :location_id=>p[0], :product_id=>component.component_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>false, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
#               StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>p[1], :location_id=>p[0], :product_id=>component.component_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>false, :input=>false, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
#             else
#               real_move.update_attributes(:quantity=>p[1], :location_id=>p[0])
#               virtual_move.update_attributes(:quantity=>p[1], :location_id=>p[0])
#             end
#           end
#         end
#       end
#     end  
#     if update.nil?
#       StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
#       StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>false, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
#     end
#   end

#   def before_destroy 
#     stocks_moves = StockMove.find(:all, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id})
#     for stocks_move in stocks_moves
#       stocks_move.destroy
#     end
#   end

  
# end
