# == Schema Information
# Schema version: 20081111111111
#
# Table name: prices
#
#  id                :integer       not null, primary key
#  amount            :decimal(16, 4 not null
#  amount_with_taxes :decimal(16, 4 not null
#  started_on        :date          not null
#  stopped_on        :date          
#  deleted           :boolean       not null
#  use_range         :boolean       not null
#  quantity_min      :decimal(16, 2 default(0.0), not null
#  quantity_max      :decimal(16, 2 default(0.0), not null
#  product_id        :integer       not null
#  list_id           :integer       not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class Price < ActiveRecord::Base
  attr_readonly :started_on


  def before_validation
    self.amount_with_taxes = self.amount
    if self.product
      for tax in self.taxes
        self.amount_with_taxes += tax.compute(self.amount)
      end
    end
    self.started_on = Date.today
    self.quantity_min ||= 0
    self.quantity_max ||= 0
  end

  def refresh
    self.save
  end

end
