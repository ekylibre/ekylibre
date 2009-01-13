# == Schema Information
# Schema version: 20081127140043
#
# Table name: products
#
#  id                  :integer       not null, primary key
#  to_purchase         :boolean       not null
#  to_sale             :boolean       default(TRUE), not null
#  to_rent             :boolean       not null
#  nature              :string(8)     not null
#  supply_method       :string(8)     not null
#  name                :string(255)   not null
#  number              :integer       not null
#  active              :boolean       default(TRUE), not null
#  code                :string(64)    
#  code2               :string(64)    
#  ean13               :string(13)    
#  catalog_name        :string(255)   not null
#  catalog_description :text          
#  description         :text          
#  comment             :text          
#  service_coeff       :float         
#  shelf_id            :integer       not null
#  unit_id             :integer       not null
#  account_id          :integer       not null
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#

class Product < ActiveRecord::Base

  def before_validation
    self.code = self.name.codeize.upper if self.code.blank?
    if self.company_id
      if self.number.blank?
        last = Product.find(:first, :conditions=>{:company_id=>self.company_id}, :order=>'number DESC')
        self.number = last.nil? ? 1 : last.number+1 
      end
      while Product.find_by_company_id_and_code(self.company_id, self.code)
        self.code.succ!
      end
    end
    self.catalog_name = self.name if self.catalog_name.blank?
  end

  def to
    to = []
    to << :sale if self.to_sale
    to << :purchase if self.to_purchase
    to << :rent if self.to_rent
    to
  end

  def validate
    errors.add_to_base(lc(:unknown_use_of_product)) unless self.to_sale or self.to_purchase or self.to_rent
  end

  def self.natures
    [:product, :service]
  end


end
