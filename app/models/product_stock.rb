class ProductStock < ActiveRecord::Base
  
  def before_validation
    self.quantity_min = self.product.quantity_min if self.quantity_min.nil?
    self.critic_quantity_min = self.product.critic_quantity_min if self.critic_quantity_min.nil?
    self.quantity_max = self.product.quantity_max if self.quantity_max.nil?
    locations = StockLocation.find_all_by_company_id(self.company_id)
    self.location_id = locations[0].id if locations.size == 1
  end

  def state
    if self.current_virtual_quantity <= self.critic_quantity_min
      css = "critic"
    elsif self.current_virtual_quantity <= self.quantity_min
      css = "minimum"
    else
      css = "enough"
    end
    css
  end

  def add_or_update(params,product_id)
    #raise Exception.new params.inspect+"rrr"+product_id.inspect
    #raise Exception.new params[:quantity_max].inspect
    stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id})
    if stock.nil?
      #raise Exception.new params[:quantity_min].inspect
      ProductStock.create!(:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id, :quantity_min=>params[:quantity_min], :quantity_max=>params[:quantity_max], :critic_quantity_min=>params[:critic_quantity_min])
    else
      stock.update_attributes(params)
    end
    #raise Exception.new stocks.inspect
  end

end
