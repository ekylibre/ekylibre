# == Schema Information
#
# Table name: price_taxes
#
#  amount       :decimal(16, 4 default(0.0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  price_id     :integer       not null
#  tax_id       :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class PriceTax < ActiveRecord::Base
  belongs_to :company
  belongs_to :price
  belongs_to :tax

  validates_presence_of :company_id
  attr_readonly :company_id

  def before_validation
    unless self.tax.nil?
      self.amount = self.tax.compute(self.price.amount)
    end
  end

  def after_save
    self.price.refresh
  end

end
