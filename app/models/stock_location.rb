# == Schema Information
# Schema version: 20090520140946
#
# Table name: stock_locations
#
#  id               :integer       not null, primary key
#  name             :string(255)   not null
#  x                :string(255)   
#  y                :string(255)   
#  z                :string(255)   
#  comment          :text          
#  parent_id        :integer       
#  account_id       :integer       not null
#  establishment_id :integer       
#  contact_id       :integer       
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  updated_at       :datetime      not null
#  created_by       :integer       
#  updated_by       :integer       
#  lock_version     :integer       default(0), not null
#  reservoir        :boolean       
#  product_id       :integer       
#  quantity_max     :float         
#  unit_id          :integer       
#  number           :integer       
#

class StockLocation < ActiveRecord::Base
  belongs_to :account
  belongs_to :company
  belongs_to :contact
  belongs_to :establishment
  belongs_to :product
  has_many :product_stocks, :foreign_key=>:location_id
  has_many :purchase_order_lines
  has_many :sale_order_lines
  has_many :stock_locations
  has_many :stock_moves
  has_many :stock_transfers

  attr_readonly :company_id

  acts_as_tree


  def before_validation_on_create
    self.reservoir = true if !self.product_id.nil?
  end

  def before_validation
   #  if self.reservoir
#       product_stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :product_id=>self.product_id, :location_id=>self.id}) 
#       if !product_stock.nil?
#         self.product_id = nil if product_stock.current_real_quantity == 0
#       end
   # end
  end
  
  def can_receive(product_id)
    #raise Exception.new product_id.inspect+self.reservoir.inspect
    reception = true
    if self.reservoir 
      product_stock = ProductStock.find(:all, :conditions=>{:company_id=>self.company_id, :product_id=>self.product_id, :location_id=>self.id}) 
      if !product_stock[0].nil?
        reception = (self.product_id == product_id || product_stock[0].current_real_quantity <= 0)
        self.update_attributes!(:product_id=>product_id) if product_stock[0].current_real_quantity <= 0
        #if product_stock[0].current_real_quantity <= 0
        for ps in product_stock
          ps.destroy if ps.product_id != product_id and ps.current_real_quantity <=0
        end
        #end
      else
        self.update_attributes!(:product_id=>product_id)
      end
    end
    reception
  end

end
