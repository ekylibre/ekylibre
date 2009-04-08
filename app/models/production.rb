class Production < ActiveRecord::Base


  def before_validation
    self.planned_on = Date.today
    self.moved_on = Date.today
    stock_locations = StockLocation.find_all_by_company_id(self.company_id)
    self.location_id = stock_locations[0].id if stock_locations.size == 1 and self.location_id.nil?
  end

 
  
  def single_stock_move_create
    
    StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id)

  end

  def stocks_moves_create(params)
    #raise Exception.new self.product.inspect
    for component in self.product.components
      #raise Exception.new params.inspect
      for p in params[component.id.to_s]
        if p[1].to_d > 0
          StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>p[1], :location_id=>p[0], :product_id=>component.component_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>false, :origin_type=>Production.to_s, :origin_id=>self.id)
        end
      end
    end
    
    StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id)
  end



end
