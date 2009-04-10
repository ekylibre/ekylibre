# == Schema Information
# Schema version: 20090407073247
#
# Table name: invoice_lines
#
#  id                :integer       not null, primary key
#  order_line_id     :integer       not null
#  product_id        :integer       not null
#  price_id          :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  position          :integer       
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#  invoice_id        :integer       
#

class InvoiceLine < ActiveRecord::Base

  belongs_to :company
  belongs_to :invoice
  belongs_to :price
  belongs_to :product
  belongs_to :order_line, :class_name=>SaleOrderLine.to_s
  
  def before_validation
    self.product = self.order_line.product
    self.price_id = self.order_line.price.id
    #self.unit_id = self.order_line.unit.id
  end

end
