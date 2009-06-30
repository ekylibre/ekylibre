# == Schema Information
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
#  amount              :decimal(16, 4 default(0.0), not null
#  code                :string(8)     
#  code2               :string(64)    
#  ean13               :string(13)    
#  catalog_name        :string(255)   not null
#  catalog_description :text          
#  description         :text          
#  comment             :text          
#  service_coeff       :float         
#  shelf_id            :integer       not null
#  unit_id             :integer       not null
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#  weight              :decimal(16, 3 
#  price               :decimal(16, 2 default(0.0)
#  quantity_min        :decimal(16, 2 default(0.0)
#  critic_quantity_min :decimal(16, 2 default(1.0)
#  quantity_max        :decimal(16, 2 default(0.0)
#  manage_stocks       :boolean       not null
#  product_account_id  :integer       
#  charge_account_id   :integer       
#

class Product < ActiveRecord::Base

  belongs_to :product_account, :class_name=>BankAccount.to_s
  belongs_to :charge_account, :class_name=>BankAccount.to_s
  belongs_to :company
  belongs_to :shelf
  belongs_to :unit
  has_many :delivery_lines
  has_many :invoice_lines
  has_many :prices
  has_many :stocks, :class_name=>ProductStock.to_s
  has_many :purchase_order_lines
  has_many :sale_order_lines
  has_many :locations, :class_name=>StockLocation.to_s
  has_many :stock_moves
  has_many :stock_transfers

  def before_validation
    self.code = self.name.codeize.upper if self.code.blank?
    self.code = self.code[0..7]
    if self.company_id

      if self.number.blank?
        last = self.company.products.find(:first, :order=>'number DESC')
        self.number = last.nil? ? 1 : last.number+1 
      end
      puts "gggglllll"
      while self.company.products.find(:first, :conditions=>["code=? AND id!=?", self.code, self.id||0])
        self.code.succ!
      end
      puts "jjj"
    end
    self.catalog_name = self.name if self.catalog_name.blank?
  end

  def to
    to = []
    to << :sale if self.to_sale
    to << :purchase if self.to_purchase
    to << :rent if self.to_rent
    to.collect{|x| tc('to.'+x.to_s)}.to_sentence
  end

  def validate
    #errors.add_to_base(lc(:unknown_use_of_product)) unless self.to_sale or self.to_purchase or self.to_rent
  end

  def self.natures
    [:product, :service].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def self.supply_methods
    [:buy, :produce].collect{|x| [tc('supply_methods.'+x.to_s), x] }
  end

  def has_components
    products = ProductComponent.find(:all, :conditions=>{:company_id=>self.company_id, :product_id=>self.id})
    !products.empty?
  end

  def components
    products = ProductComponent.find(:all, :conditions=>{:company_id=>self.company_id, :product_id=>self.id})
    products
  end

  def informations
    if self.has_components
      name = self.name+" ( "+self.unit.label+" ) "+tc('components_number')+self.components.size.to_s
    else
      name = self.name+" ( "+self.unit.label+" ) "+tc('raw_material')
    end
    name
  end

end
