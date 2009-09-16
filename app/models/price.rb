# == Schema Information
#
# Table name: prices
#
#  active            :boolean       default(TRUE), not null
#  amount            :decimal(16, 4 not null
#  amount_with_taxes :decimal(16, 4 not null
#  category_id       :integer       
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  currency_id       :integer       
#  default           :boolean       default(TRUE)
#  entity_id         :integer       
#  id                :integer       not null, primary key
#  lock_version      :integer       default(0), not null
#  product_id        :integer       not null
#  quantity_max      :decimal(16, 2 default(0.0), not null
#  quantity_min      :decimal(16, 2 default(0.0), not null
#  started_at        :datetime      
#  stopped_at        :datetime      
#  tax_id            :integer       not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#  use_range         :boolean       not null
#

class Price < ActiveRecord::Base
  belongs_to :category, :class_name=>EntityCategory.to_s
  belongs_to :company
  belongs_to :currency
  belongs_to :entity
  belongs_to :product
  belongs_to :tax
  has_many :delivery_lines
  has_many :invoice_lines
  has_many :taxes
  has_many :purchase_order_lines
  has_many :sale_order_lines

  validates_presence_of :category_id, :currency_id, :product_id

  attr_readonly :company_id, :started_at, :amount, :amount_with_taxes


  def before_validation
    self.currency_id ||= self.company.currencies.find(:first).id
    if self.amount_with_taxes.to_f > 0
      self.amount_with_taxes = self.amount_with_taxes.round(2)
      tax_amount = (self.tax ? self.tax.compute(self.amount_with_taxes, true) : 0)
      self.amount = self.amount_with_taxes - tax_amount.round(2)
    elsif self.amount.to_f > 0 
      tax_amount = (self.tax ? self.tax.compute(self.amount) : 0)
      self.amount_with_taxes = (self.amount+tax_amount).round(2)
      self.amount = self.amount_with_taxes - tax_amount.round(2)
    end
    self.started_at = Time.now
    self.quantity_min ||= 0
    self.quantity_max ||= 0
  end

  def validate
    #   if self.use_range
    #       price = self.company.prices.find(:first, :conditions=>["(? BETWEEN quantity_min AND quantity_max OR ? BETWEEN quantity_min AND quantity_max) AND product_id=? AND list_id=? AND id!=?", self.quantity_min, self.quantity_max, self.product_id, self.list_id, self.id])
    #       errors.add_to_base tc(:error_range_overlap, :min=>price.quantity_min, :max=>price.quantity_max) unless price.nil?
    #     else
    #       errors.add_to_base tc(:error_already_defined) unless self.company.prices.find(:first, :conditions=>["NOT use_range AND product_id=? AND stopped_on IS NULL AND list_id=? AND id!=COALESCE(?,0)", self.product_id, self.list_id, self.id]).nil?
    #     end
    errors.add(:price) if self.amount <= 0 and self.amount_with_taxes <= 0 
  end

  def after_save
    Price.update_all('"default"=false', ["product_id=? AND company_id=? AND id!=?", self.product_id, self.company_id, self.id||0]) if self.default
  end
  
  def refresh
    self.save
  end

  def change(amount, tax_id)
    conditions = {:product_id=>self.product_id,:amount=>amount, :tax_id=>tax_id, :active=>true, :entity_id=>self.entity_id, :currency_id=>self.currency_id}
    price = self.company.prices.find(:first, :conditions=>conditions)
    if price.nil?
      self.update_attribute(:active, false)
      price = self.company.prices.create!(conditions)
    end
    price
  end

  def all_taxes(company, options={})
    if self.new_record?
      options[:select] = "taxes.*, false AS used"      
    else
      options[:select] = "taxes.*, (pt.id IS NOT NULL)::boolean AS used"
      options[:joins]  = " LEFT JOIN price_taxes AS pt ON (taxes.id=tax_id)"
      options[:conditions]  = {:price_id=>self.id}
    end
    company.taxes.find(:all, options)
  end


  def range
    if self.use_range
      tc(:range, :min=>self.quantity_min, :max=>self.quantity_max)
    else
      tc(:no_range)
    end
  end

  def label
    tc(:label, :product=>self.product.name, :amount=>self.amount, :currency=>self.currency.code)
  end

end
