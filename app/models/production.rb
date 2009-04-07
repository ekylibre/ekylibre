class Production < ActiveRecord::Base


  def before_validation
    self.planned_on = Date.today
    self.moved_on = Date.today
    stock_locations = StockLocation.find_all_by_company_id(self.company_id)
    self.location_id = stock_locations[0].id if stock_locations.size == 1 and self.location_id.nil?
  end

  
  def single_stock_move_create
    StockMove.create!(:name=>tc('production')+" "+self.id, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :virtual=>true, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id)

    product_stock = ProductStock.find(:first, :conditions=>{:product_id=>self.product_id, :location_id=>self.location_id, :company_id=>self.company_id})
    product_stock = ProductStock.create!(:product_id=>self.product_id, :location_id=>self.location_id, :company_id=>self.company_id) if product_stock.nil?
    product_stock.update_attributes(:current_virtual_quantity=>product_stock.current_virtual_quantity + self.quantity)
  end


  def many_stocks_moves_create
    StockMove.create!(:name=>tc('production')+" "+self.id, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :virtual=>true, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id

  end

end
