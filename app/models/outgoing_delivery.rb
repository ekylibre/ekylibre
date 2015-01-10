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
# == Table: outgoing_deliveries
#
#  amount           :decimal(16, 2)   default(0.0), not null
#  comment          :text             
#  company_id       :integer          not null
#  contact_id       :integer          
#  created_at       :datetime         not null
#  creator_id       :integer          
#  currency_id      :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode_id          :integer          
#  moved_on         :date             
#  number           :string(255)      
#  planned_on       :date             
#  pretax_amount    :decimal(16, 2)   default(0.0), not null
#  reference_number :string(255)      
#  sale_id          :integer          not null
#  transport_id     :integer          
#  transporter_id   :integer          
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  weight           :decimal(16, 4)   
#


class OutgoingDelivery < CompanyRecord
  acts_as_numbered
  attr_readonly :company_id, :sale_id, :number
  belongs_to :company 
  belongs_to :contact
  belongs_to :mode, :class_name=>"OutgoingDeliveryMode"
  belongs_to :sale
  belongs_to :transport
  belongs_to :transporter, :class_name=>"Entity"
  has_many :lines, :class_name=>"OutgoingDeliveryLine", :foreign_key=>:delivery_id, :dependent=>:destroy
  has_many :stock_moves, :as=>:origin, :dependent=>:destroy
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :weight, :allow_nil => true
  validates_length_of :number, :reference_number, :allow_nil => true, :maximum => 255
  #]VALIDATORS]

  # autosave :transport
  sums :transport, :deliveries, :amount, :pretax_amount, :weight

  validates_presence_of :planned_on

  before_validation(:on=>:create) do
    self.company_id = self.sale.company_id if self.sale
  end

  before_validation do
    self.transporter_id ||= self.transport.transporter_id if self.transport
    return true
  end

  protect_on_update do
    return false unless self.moved_on.nil?
    return true
  end

#   transfer do |t|
#     for line in self.lines
#       t.move(:use=>line)
#     end
#   end


  # Ships the delivery and move the real stocks. This operation locks the delivery.
  # This permits to manage stocks.
  def ship(shipped_on=Date.today)
    # self.confirm_transfer(shipped_on)
    # self.lines.each{|l| l.confirm_move}
    for line in self.lines.find(:all, :conditions=>["quantity>0"])
      # self.stock_moves.create!(:name=>tc(:sale, :number=>self.order.number), :quantity=>line.quantity, :warehouse_id=>line.sale_line.warehouse_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :moved_on=>shipped_on, :company_id=>line.company_id, :virtual=>false, :input=>false, :origin_type=>Delivery.to_s, :origin_id=>self.id, :generated=>true)
      line.product.move_outgoing_stock(:origin=>line, :warehouse_id=>line.sale_line.warehouse_id, :planned_on=>self.planned_on, :moved_on=>shipped_on)
    end
    self.moved_on = shipped_on if self.moved_on.nil?
    self.save
  end
  
  def moment
    if self.planned_on <= Date.today-(3)
      "verylate"
    elsif self.planned_on <= Date.today
      "late"
    elsif self.planned_on > Date.today
      "advance"
    end
  end

  def label
    tc('label', :client=>self.sale.client.full_name.to_s, :address=>self.contact.address.to_s)
  end

  # Used with list for the moment
  def quantity
    ''
  end

  def contact_address
    self.contact.address if self.contact 
  end

  def address
    a = self.sale.client.full_name+"\n"
    a += (self.contact ? self.contact.address : self.sale.client.default_contact.address).gsub(/\s*\,\s*/, "\n")
    a
  end

  def parcel_sum
    self.lines.sum(:quantity)
  end

end
