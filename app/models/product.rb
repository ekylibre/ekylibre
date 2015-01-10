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
# == Table: products
#
#  active                     :boolean          default(TRUE), not null
#  catalog_description        :text             
#  catalog_name               :string(255)      not null
#  category_id                :integer          not null
#  code                       :string(16)       
#  code2                      :string(64)       
#  comment                    :text             
#  company_id                 :integer          not null
#  created_at                 :datetime         not null
#  creator_id                 :integer          
#  critic_quantity_min        :decimal(16, 4)   default(1.0)
#  deliverable                :boolean          not null
#  description                :text             
#  ean13                      :string(13)       
#  for_immobilizations        :boolean          not null
#  for_productions            :boolean          not null
#  for_purchases              :boolean          not null
#  for_sales                  :boolean          default(TRUE), not null
#  id                         :integer          not null, primary key
#  immobilizations_account_id :integer          
#  lock_version               :integer          default(0), not null
#  name                       :string(255)      not null
#  nature                     :string(8)        not null
#  number                     :integer          not null
#  price                      :decimal(16, 2)   default(0.0)
#  published                  :boolean          not null
#  purchases_account_id       :integer          
#  quantity_max               :decimal(16, 4)   default(0.0)
#  quantity_min               :decimal(16, 4)   default(0.0)
#  reduction_submissive       :boolean          not null
#  sales_account_id           :integer          
#  service_coeff              :decimal(16, 4)   
#  stockable                  :boolean          not null
#  subscription_nature_id     :integer          
#  subscription_period        :string(255)      
#  subscription_quantity      :integer          
#  trackable                  :boolean          not null
#  unit_id                    :integer          not null
#  unquantifiable             :boolean          not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer          
#  weight                     :decimal(16, 3)   
#  with_tracking              :boolean          not null
#


class Product < CompanyRecord
  @@natures = [:product, :service, :subscrip] # , :transfer]
  attr_readonly :company_id
  belongs_to :purchases_account, :class_name=>"Account"
  belongs_to :company
  belongs_to :sales_account, :class_name=>"Account"
  belongs_to :subscription_nature
  belongs_to :category, :class_name=>"ProductCategory"
  belongs_to :unit
  has_many :available_stocks, :class_name=>"Stock", :conditions=>["quantity > 0"]
  has_many :components, :class_name=>"ProductComponent", :conditions=>{:active=>true}
  has_many :outgoing_delivery_lines
  has_many :prices
  has_many :purchase_lines
  # TODO rename warehouses to reservoirs
  has_many :warehouses, :conditions=>{:reservoir=>true}
  has_many :sale_lines
  has_many :stock_moves
  has_many :stock_transfers
  has_many :stocks
  has_many :subscriptions
  has_many :trackings
  has_many :units, :class_name=>"Unit", :finder_sql=>proc{ "SELECT #{Unit.table_name}.* FROM #{Unit.table_name} WHERE company_id=#{company_id} AND base=#{connection.quote(unit.base)} ORDER BY coefficient, label"}, :counter_sql=>proc{ "SELECT count(*) AS count_all FROM #{Unit.table_name} WHERE company_id=#{company_id} AND base=#{connection.quote(unit.base)}" }
  has_one :default_stock, :class_name=>"Stock", :order=>:name
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :number, :subscription_quantity, :allow_nil => true, :only_integer => true
  validates_numericality_of :critic_quantity_min, :price, :quantity_max, :quantity_min, :service_coeff, :weight, :allow_nil => true
  validates_length_of :nature, :allow_nil => true, :maximum => 8
  validates_length_of :ean13, :allow_nil => true, :maximum => 13
  validates_length_of :code, :allow_nil => true, :maximum => 16
  validates_length_of :code2, :allow_nil => true, :maximum => 64
  validates_length_of :catalog_name, :name, :subscription_period, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :deliverable, :for_immobilizations, :for_productions, :for_purchases, :for_sales, :published, :reduction_submissive, :stockable, :trackable, :unquantifiable, :with_tracking, :in => [true, false]
  validates_presence_of :catalog_name, :category, :company, :name, :nature, :number, :unit
  #]VALIDATORS]
  validates_presence_of :subscription_nature,   :if=>Proc.new{|u| u.nature.to_s=="subscrip"}
  validates_presence_of :subscription_period,   :if=>Proc.new{|u| u.nature.to_s=="subscrip" and u.subscription_nature and u.subscription_nature.period?}
  validates_presence_of :subscription_quantity, :if=>Proc.new{|u| u.nature.to_s=="subscrip" and u.subscription_nature and not u.subscription_nature.period?}
  validates_presence_of :sales_account, :if=>Proc.new{|p| p.for_sales}
  validates_presence_of  :purchases_account, :if=>Proc.new{|p| p.for_purchases}
  validates_uniqueness_of :code, :scope=>:company_id
  validates_uniqueness_of :name, :scope=>:company_id

  #validates_presence_of :product_account_id
  #validates_presence_of :charge_account_id

  before_validation do
    self.code = self.name.codeize.upper if !self.name.blank? and self.code.blank?
    self.code = self.code[0..7] unless self.code.blank?
    if self.company
      if self.number.blank?
        last = self.company.products.find(:first, :order=>'number DESC')
        self.number = last.nil? ? 1 : last.number+1 
      end
      while self.company.products.find(:first, :conditions=>["code=? AND id!=?", self.code, self.id||0])
        self.code.succ!
      end
    end
    self.stockable = false unless self.deliverable?
    self.trackable = false unless self.stockable?
    # self.stockable = true if self.trackable?
    # self.deliverable = true if self.stockable?
    self.for_productions = true if self.has_components?
    self.catalog_name = self.name if self.catalog_name.blank?
    self.subscription_nature_id = nil if self.nature != "subscrip"
    self.service_coeff = nil if self.nature != "service"
    
  end
 
  def to
    to = []
    to << :sales if self.for_sales
    to << :purchases if self.for_purchases
    to << :produce if self.for_productions
    to.collect{|x| tc('to.'+x.to_s)}.to_sentence
  end

  def self.natures
    @@natures.collect{|x| [self.nature_label(x), x] }
  end

  def self.nature_label(nature)
    tc('natures.'+nature.to_s)
  end

  def nature_label
    self.class.nature_label(self.nature)
  end

  def subscription?
    self.nature.to_s == :subscrip.to_s
  end

  def has_components?
    self.components.size > 0
  end

  def default_price(category_id)
    self.prices.find(:first, :conditions=>{:category_id=>category_id, :active=>true, :by_default=>true})
  end

  def label
    tc('label', :product=>self["name"], :unit=>self.unit["label"])
  end

  def informations
    tc('informations.'+(self.has_components? ? 'with' : 'without')+'_components', :product=>self.name, :unit=>self.unit.label, :size=>self.components.size)
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

  def default_subscription_label_for(entity)
    return nil unless self.nature == "subscrip"
    entity  = nil unless entity.is_a? Entity
    address = entity.default_contact.address rescue nil
    entity = entity.full_name rescue "???"
    if self.subscription_nature.nature == "period"
      return tc('subscription_label.period', :start=>::I18n.localize(Date.today), :finish=>::I18n.localize(Delay.compute(self.subscription_period.blank? ? '1 year, 1 day ago' : self.product.subscription_period)), :entity=>entity, :address=>address, :subscription_nature=>self.subscription_nature.name)
    elsif self.subscription_nature.nature == "quantity"
      return tc('subscription_label.quantity', :start=>self.subscription_nature.actual_number.to_i, :finish=>(self.subscription_nature.actual_number.to_i + ((self.subscription_quantity-1)||0)), :entity=>entity, :address=>address, :subscription_nature=>self.subscription_nature.name)
    end
  end

  # Create real stocks moves to update the real state of stocks
  def move_outgoing_stock(options={})
    add_stock_move(options.merge(:virtual=>false, :incoming=>false))
  end

  def move_incoming_stock(options={})
    add_stock_move(options.merge(:virtual=>false, :incoming=>true))
  end

  # Create virtual stock moves to reserve the products
  def reserve_outgoing_stock(options={})
    add_stock_move(options.merge(:virtual=>true, :incoming=>false))
  end

  def reserve_incoming_stock(options={})
    add_stock_move(options.merge(:virtual=>true, :incoming=>true))
  end

  # Create real stocks moves to update the real state of stocks
  def move_stock(options={})
    add_stock_move(options.merge(:virtual=>false))
  end

  # Create virtual stock moves to reserve the products
  def reserve_stock(options={})
    add_stock_move(options.merge(:virtual=>true))
  end


  # Generic method to add stock move in product's stock
  def add_stock_move(options={})
    return true unless self.stockable?
    incoming = options.delete(:incoming)
    attributes = options.merge(:generated=>true, :company_id=>self.company_id)
    origin = options[:origin]
    if origin.is_a? ActiveRecord::Base
      code = [:number, :code, :name, :id].detect{|x| origin.respond_to? x}
      attributes[:name] = tc('stock_move', :origin=>(origin ? ::I18n.t("activerecord.models.#{origin.class.name.underscore}") : "*"), :code=>(origin ? origin.send(code) : "*"))
      for attribute in [:quantity, :unit_id, :tracking_id, :warehouse_id, :product_id]
        unless attributes.keys.include? attribute
          attributes[attribute] ||= origin.send(attribute) rescue nil
        end
      end
    end
    attributes[:quantity] = -attributes[:quantity] unless incoming
    attributes[:warehouse_id] ||= self.stocks.first.warehouse_id if self.stocks.size > 0
    attributes[:planned_on] ||= Date.today
    attributes[:moved_on] ||= attributes[:planned_on] unless attributes.keys.include? :moved_on
    self.stock_moves.create!(attributes)
  end

  
end
