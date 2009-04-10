# == Schema Information
# Schema version: 20090407073247
#
# Table name: product_stocks
#
#  id                       :integer       not null, primary key
#  product_id               :integer       not null
#  location_id              :integer       not null
#  current_real_quantity    :decimal(16, 2 default(0.0), not null
#  current_virtual_quantity :decimal(16, 2 default(0.0), not null
#  quantity_min             :decimal(16, 2 default(1.0), not null
#  critic_quantity_min      :decimal(16, 2 default(0.0), not null
#  quantity_max             :decimal(16, 2 default(0.0), not null
#  company_id               :integer       not null
#  created_at               :datetime      not null
#  updated_at               :datetime      not null
#  created_by               :integer       
#  updated_by               :integer       
#  lock_version             :integer       default(0), not null
#

class ProductStock < ActiveRecord::Base

  belongs_to :company
  belongs_to :product
  belongs_to :stock_location
  
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
    stock = ProductStock.find(:first, :conditions=>{:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id})
    if stock.nil?
      ProductStock.create!(:company_id=>self.company_id, :location_id=>params[:location_id], :product_id=>product_id, :quantity_min=>params[:quantity_min], :quantity_max=>params[:quantity_max], :critic_quantity_min=>params[:critic_quantity_min])
    else
      stock.update_attributes(params)
    end
  end

end
