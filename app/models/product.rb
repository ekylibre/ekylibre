# == Schema Information
#
# Table name: products
#
#  active                 :boolean       default(TRUE), not null
#  catalog_description    :text          
#  catalog_name           :string(255)   not null
#  charge_account_id      :integer       
#  code                   :string(8)     
#  code2                  :string(64)    
#  comment                :text          
#  company_id             :integer       not null
#  created_at             :datetime      not null
#  creator_id             :integer       
#  critic_quantity_min    :decimal(16, 2 default(1.0)
#  description            :text          
#  ean13                  :string(13)    
#  id                     :integer       not null, primary key
#  lock_version           :integer       default(0), not null
#  manage_stocks          :boolean       not null
#  name                   :string(255)   not null
#  nature                 :string(8)     not null
#  number                 :integer       not null
#  price                  :decimal(16, 2 default(0.0)
#  product_account_id     :integer       
#  quantity_max           :decimal(16, 2 default(0.0)
#  quantity_min           :decimal(16, 2 default(0.0)
#  reduction_submissive   :boolean       not null
#  service_coeff          :float         
#  shelf_id               :integer       not null
#  subscription_nature_id :integer       
#  subscription_period    :string(255)   
#  subscription_quantity  :integer       
#  supply_method          :string(8)     not null
#  to_purchase            :boolean       not null
#  to_rent                :boolean       not null
#  to_sale                :boolean       default(TRUE), not null
#  unit_id                :integer       not null
#  unquantifiable         :boolean       not null
#  updated_at             :datetime      not null
#  updater_id             :integer       
#  weight                 :decimal(16, 3 
#

class Product < ActiveRecord::Base

  belongs_to :product_account, :class_name=>Account.to_s
  belongs_to :charge_account, :class_name=>Account.to_s
  belongs_to :company
  belongs_to :subscription_nature
  belongs_to :shelf
  belongs_to :unit
  has_many :delivery_lines
  has_many :invoice_lines
  has_many :prices
  has_many :purchase_order_lines
  # TODO rename locations to reservoirs
  has_many :locations, :class_name=>StockLocation.to_s, :conditions=>{:reservoir=>true}
  has_many :sale_order_lines
  has_many :stock_moves
  has_many :stock_transfers
  has_many :stocks, :class_name=>ProductStock.to_s
  has_many :subscriptions

  @@natures = [:product, :service, :subscrip, :transfer]

  attr_readonly :company_id

  validates_uniqueness_of :code, :scope=>:company_id

  validates_presence_of :subscription_period, :if=>Proc.new{|u| u.nature=="sub_date"}
  validates_presence_of :subscription_numbers, :actual_number, :if=>Proc.new{|u| u.nature=="sub_numb"}

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
    #[:product, :service, :sub_date, :sub_numb].collect{|x| [tc('natures.'+x.to_s), x] }
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
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

  def default_price(category_id)
    self.prices.find(:first, :conditions=>{:category_id=>category_id, :active=>true, :default=>true})
  end

  def informations
#     if self.has_components
#       # name = self.name+" ( "+self.unit.label+" ) "+tc('components_number')+self.components.size.to_s
#       tc('informations.with_components', :product=>self.name, :unit=>self.unit.label, :size=>self.components.size)
#     else
#       # name = self.name+" ( "+self.unit.label+" ) "+tc('raw_material')
#       tc('informations.without_components', :product=>self.name, :unit=>self.unit.label, :size=>self.components.size)
#     end
    tc('informations.with'+(self.has_components ? '' : 'out')+'_components', :product=>self.name, :unit=>self.unit.label, :size=>self.components.size)
  end

  def duration
    #raise Exception.new self.subscription_nature.nature.inspect+" blabla"
    if self.subscription_nature
      self.send('subscription_'+self.subscription_nature.nature)
    else
      return nil
    end
    
  end
  
  def duration=(value)
    #raise Exception.new subscription.inspect+self.subscription_nature_id.inspect
    if self.subscription_nature
      self.send('subscription_'+self.subscription_nature.nature+'=', value)
    end
  end

  def default_start
    # self.subscription_nature.nature == "period" ? Date.today.beginning_of_year : self.subscription_nature.actual_number
    self.subscription_nature.nature == "period" ? Date.today : self.subscription_nature.actual_number
  end

  def default_finish
    period = self.subscription_period || '1 year'
    # self.subscription_nature.nature == "period" ? Date.today.next_year.beginning_of_year.next_month.end_of_month : (self.subscription_nature.actual_number + ((self.subscription_quantity-1)||0))
    self.subscription_nature.nature == "period" ? Delay.compute(period+", 1 day ago", Date.today) : (self.subscription_nature.actual_number + ((self.subscription_quantity-1)||0))
  end

  # Create virtual stock moves to reserve the products
  def reserve_stock(quantity, options={})
    add_stock_move(quantity, true, false, options)
  end

  # Create real stocks moves to update the real state of stocks
  def take_stock_out(quantity, options={})
    add_stock_move(quantity, false, false, options)
  end

  def shelf_name
    self.shelf.name
  end

  private
  
  def add_stock_move(quantity, virtual, input, options={})
    if self.manage_stocks  and quantity>0
      attributes = options.merge(:quantity=>quantity, :virtual=>virtual, :input=>input, :generated=>true, :company_id=>self.company_id)
      origin = options[:origin]
      code = [:number, :code, :name, :id].detect{|x| origin.respond_to? x}
      attributes[:name] = tc('stock_move', :origin=>(origin ? tc("activerecord.models.#{origin.class.name.underscore}") : "*"), :code=>(origin ? origin.send(code) : "*"))
      attributes[:location_id] ||= self.locations.first.id
      attributes[:planned_on] ||= Date.today
      self.stock_moves.create!(attributes)      
    end    
  end

  
end
