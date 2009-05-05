class StockTransfer < ActiveRecord::Base

  belongs_to :company
  belongs_to :product
  belongs_to :location, :class_name=>StockLocation.to_s
  belongs_to :second_location, :class_name=>StockLocation.to_s

  attr_readonly :company_id

  def before_validation
    self.moved_on =  Date.today if self.planned_on <= Date.today
    self.second_location_id = nil if self.nature == "waste"
  end

  def validate
    #raise Exception.new self.location.can_receive(self.product_id).inspect+self.product.name.to_s+self.location.product.name.to_s
    if !self.second_location.nil?
      errors.add_to_base(tc:stock_location_can_receive_product, :location=>self.second_location.name, :product=>self.product.name, :contained_product=>self.second_location.product.name) unless self.second_location.can_receive(self.product_id)
    end
    errors.add_to_base(tc:stock_location_can_transfer_product, :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name) unless self.location.can_receive(self.product_id)
  end
  
  def after_create
    StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>true, :input=>false, :origin_type=>StockTransfer.to_s, :origin_id=>self.id)
    StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>false, :input=>false, :origin_type=>StockTransfer.to_s, :origin_id=>self.id) if !self.moved_on.nil?
    if self.nature == "transfer"
      StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :location_id=>self.second_location_id, :product_id=>self.product_id,:planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>true, :input=>true, :origin_type=>StockTransfer.to_s, :origin_id=>self.id)
      StockMove.create!(:name=>tc('natures.'+self.nature.to_s), :quantity=>self.quantity, :location_id=>self.second_location_id, :product_id=>self.product_id,:planned_on=>self.planned_on, :moved_on=>self.moved_on, :company_id=>self.company_id, :virtual=>false, :input=>true,:origin_type=>StockTransfer.to_s, :origin_id=>self.id) if !self.moved_on.nil?
    end
    
  end
  
  def after_update
    if self.nature == "transfer"
      stocks_moves = StockMove.find(:all, :conditions=>{:company_id=>self.company_id, :origin_type=>StockTransfer.to_s, :origin_id=>self.id, :location_id=>self.second_location_id})
      for stock_move in stocks_moves
        stock_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.second_location_id, :planned_on=>self.planned_on)
      end
    end
    output_stocks_moves = StockMove.find(:all, :conditions=>{:company_id=>self.company_id, :origin_type=>StockTransfer.to_s, :origin_id=>self.id, :second_location_id=>nil})
    for stocks_move in output_stocks_moves
      stocks_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.location_id, :planned_on=>self.planned_on)
    end
  end
  
  def before_destroy
    stocks_moves = StockMove.find(:all, :conditions=>{:company_id=>self.company_id, :origin_type=>StockTransfer.to_s, :origin_id=>self.id})
    for stock_move in stocks_moves
      stock_move.destroy
    end
  end
  
  def self.natures
    [:transfer, :waste].collect{|x| [tc('natures.'+x.to_s), x] }
  end


  def text_nature
    tc('natures.'+self.nature.to_s)
  end

end
