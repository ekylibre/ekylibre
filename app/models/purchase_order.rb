# == Schema Information
#
# Table name: purchase_orders
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  dest_contact_id   :integer       
#  id                :integer       not null, primary key
#  invoiced          :boolean       not null
#  lock_version      :integer       default(0), not null
#  moved_on          :date          
#  number            :string(64)    not null
#  planned_on        :date          
#  shipped           :boolean       not null
#  supplier_id       :integer       not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

class PurchaseOrder < ActiveRecord::Base
  belongs_to :company
  belongs_to :dest_contact, :class_name=>Contact.name
  belongs_to :supplier, :class_name=>Entity.name
  has_many :lines, :class_name=>PurchaseOrderLine.name, :foreign_key=>:order_id
  
  validates_presence_of :planned_on
  attr_readonly :company_id

  def before_validation
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
      StockMove.create!(:name=>tc(:purchase)+"  "+self.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :company_id=>line.company_id, :virtual=>true, :input=>true, :origin_type=>PurchaseOrder.to_s, :origin_id=>self.id, :generated=>true)
    end
  end

  def real_stocks_moves_create
    for line in self.lines
      StockMove.create!(:name=>tc(:purchase)+"  "+line.order.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.planned_on, :moved_on=>Date.today, :company_id=>line.company_id, :virtual=>false, :input=>true, :origin_type=>PurchaseOrder.to_s, :origin_id=>self.id, :generated=>true)
    end
    self.moved_on = Date.today if self.moved_on.nil?
    self.save
  end

  def label 
     tc('label', :supplier=>self.supplier.full_name.to_s, :address=>self.dest_contact.address.to_s)
  end

  def quantity 
    ''
  end

end
