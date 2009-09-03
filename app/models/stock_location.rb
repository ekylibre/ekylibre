# == Schema Information
#
# Table name: stock_locations
#
#  account_id       :integer       not null
#  comment          :text          
#  company_id       :integer       not null
#  contact_id       :integer       
#  created_at       :datetime      not null
#  creator_id       :integer       
#  establishment_id :integer       
#  id               :integer       not null, primary key
#  lock_version     :integer       default(0), not null
#  name             :string(255)   not null
#  number           :integer       
#  parent_id        :integer       
#  product_id       :integer       
#  quantity_max     :float         
#  reservoir        :boolean       
#  unit_id          :integer       
#  updated_at       :datetime      not null
#  updater_id       :integer       
#  x                :string(255)   
#  y                :string(255)   
#  z                :string(255)   
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

  validates_presence_of :account_id

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
  
  def can_receive?(product_id)
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

  # obsolete
  def can_receive(product_id)
    self.can_receive?(product_id)
  end

end
