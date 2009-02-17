# == Schema Information
# Schema version: 20081111111111
#
# Table name: price_lists
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  started_on   :date          not null
#  stopped_on   :date          
#  active       :boolean       default(TRUE), not null
#  deleted      :boolean       not null
#  comment      :text          
#  currency_id  :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class PriceList < ActiveRecord::Base
  attr_readonly :company_id, :started_on

  def before_validation
    self.started_on = Date.today
  end

  def price(product_id, quantity=1)
    price = nil
    prices = self.prices.find(:all, :conditions=>["product_id=? AND use_range AND ? BETWEEN quantity_min AND quantity_max", product_id, quantity])
    if prices.size == 1
      price = prices[0]
    elsif prices.empty?
      prices = self.prices.find(:all, :conditions=>["product_id=? AND NOT use_range", product_id])
      if prices.size == 1
        price = prices[0]
        #      elsif prices.empty?
        #        price = nil
        #      else
        #        raise Exception.new(tc(:error_range_overlap_detected))
      end
      #    else
      #      raise Exception.new(tc(:error_range_overlap_detected))
    end
    price
  end
  
  def update_price(product_id, amount, tax_id=nil) #,quantity_min=nil,quantity_max=nil)
    prices = self.prices.find(:all, :conditions=>["product_id=?  AND stopped_on IS NULL AND company_id = ? AND NOT use_range",product_id,self.company.id])
    if prices.empty?
      price =  self.prices.create!(:amount=>amount, :product_id=>product_id, :tax_id=>tax_id,:company_id=>self.company.id)
    elsif prices.size == 1
      for p in prices
        if p.amount == amount
          p.tax_id = tax_id
          price = p
          price.save
        else
          p.stopped_on = Date.today
          p.save
        end
      end
      if price.blank?
        price =  self.prices.create(:amount=>amount, :product_id=>product_id, :tax_id=>tax_id,:company_id=>self.company.id)
      end
    else
      raise Exception.new "gros probleme"
    end
    price                     
  end
  
end
