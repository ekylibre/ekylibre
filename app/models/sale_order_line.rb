# == Schema Information
# Schema version: 20090123112145
#
# Table name: sale_order_lines
#
#  id                :integer       not null, primary key
#  order_id          :integer       not null
#  product_id        :integer       not null
#  price_list_id     :integer       not null
#  price_id          :integer       not null
#  invoiced          :boolean       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  unit_id           :integer       not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  position          :integer       
#  account_id        :integer       not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class SaleOrderLine < ActiveRecord::Base
  attr_readonly :company_id, :order_id

  def before_validation
    if self.price_list and self.product
      self.price = self.price_list.price(self.product_id, self.quantity)
      self.account_id = self.product.account_id
      self.unit_id = self.product.unit_id
      if self.price
        self.amount = self.price.amount*self.quantity
        self.amount_with_taxes = self.price.amount_with_taxes*self.quantity
      end
    end
  end

  def validate
    errors.add_to_base(tc(:error_no_found_price)) if self.price.nil?
  end
  
  def after_save
    self.order.refresh
  end

end
