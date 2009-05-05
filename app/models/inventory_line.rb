class InventoryLine < ActiveRecord::Base


  def after_create
    puts self.validated_quantity.to_s+"   "+self.theoric_quantity.to_s+"    lllllllll"
    if self.validated_quantity != self.theoric_quantity
      rslt =  (self.validated_quantity.to_f != self.theoric_quantity.to_f)
      puts rslt
      input = self.validated_quantity < self.theoric_quantity ? false : true
      #raise Exception.new self.theoric_quantity.to_s+" "+self.validated_quantity.to_s+"   "+input.to_s
      if input
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.validated_quantity - self.theoric_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id)
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.validated_quantity - self.theoric_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id)
      else
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.theoric_quantity - self.validated_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id)
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.theoric_quantity - self.validated_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id)
      end
    end
  end
  
end
