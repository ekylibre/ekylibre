# == Schema Information
# Schema version: 20090406132452
#
# Table name: purchase_orders
#
#  id                :integer       not null, primary key
#  supplier_id       :integer       not null
#  number            :string(64)    not null
#  shipped           :boolean       not null
#  invoiced          :boolean       not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  dest_contact_id   :integer       
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#  planned_on        :date          
#  moved_on          :date          
#

class PurchaseOrder < ActiveRecord::Base
  
  validates_presence_of :planned_on
  attr_readonly :company_id

  def before_validation
    #raise Exception.new self.inspect
    if self.number.blank?
      last = self.supplier.purchase_orders.find(:first, :order=>"number desc")
      self.number = if last
                      last.number.succ!
                    else
                      '00000001'
                    end
    end


    self.amount = 0
    self.amount_with_taxes = 0
     for line in self.lines
       self.amount += line.amount
       self.amount_with_taxes += line.amount_with_taxes
     end
  end
  
  def refresh
    self.save
  end

  def stocks_moves_create
    locations = StockLocation.find_all_by_company_id(self.company_id)
    for line in self.lines
      if locations.size == 1
        line.update_attributes!(:location_id=>locations[0].id)
      end
      StockMove.create!(:name=>tc(:purchase)+"  "+self.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :company_id=>line.company_id, :virtual=>true, :input=>true, :origin_type=>PurchaseOrder.to_s, :origin_id=>self.id)
    end
  end

  def real_stocks_moves_create
    #raise Exception.new self.lines.inspect
    for line in self.lines
      StockMove.create!(:name=>tc(:purchase)+"  "+line.order.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :moved_on=>Date.today, :company_id=>line.company_id, :virtual=>false, :input=>true, :origin_type=>PurchaseOrder.to_s, :origin_id=>self.id)
      product = ProductStock.find(:first, :conditions=>{:product_id=>line.product_id, :location_id=>line.location_id, :company_id=>line.company_id})
      product = ProductStock.create!(:product_id=>line.product_id, :location_id=>line.location_id, :company_id=>line.company_id) if product.nil?
      product.update_attributes!(:current_real_quantity=>product.current_real_quantity + line.quantity)
    end
    self.moved_on = Date.today if self.moved_on.nil?
    self.save
  end

  def change_quantity(virtual, input )
    for line in self.lines
      product = ProductStock.find(:first, :conditions=>{:product_id=>line.product_id, :location_id=>line.location_id, :company_id=>line.company_id})
      product = ProductStock.create!(:product_id=>line.product_id, :location_id=>line.location_id, :company_id=>line.company_id) if product.nil?
      if virtual and input
        product.update_attributes(:current_virtual_quantity=>product.current_virtual_quantity + line.quantity)
      elsif virtual and !input
        product.update_attributes(:current_virtual_quantity=>product.current_virtual_quantity - line.quantity)
      elsif !virtual and input
        product.update_attributes(:current_real_quantity=>product.current_real_quantity + line.quantity)
      elsif !virtual and !input
        product.update_attributes(:current_real_quantity=>product.current_real_quantity - line.quantity)
      end
    end
  end

end
