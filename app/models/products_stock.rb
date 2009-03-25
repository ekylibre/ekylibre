class ProductsStock < ActiveRecord::Base
  
  def before_validation
    self.quantity_min = self.product.quantity_min if !self.product.quantity_min.nil?
    self.critic_quantity_min = self.product.critic_quantity_min if !self.product.critic_quantity_min.nil?
    self.quantity_max = self.product.quantity_max if !self.product.quantity_max.nil?
  end

  def state
    if self.current_virtual_quantity <= self.product.critic_quantity_min
      css = "critic"
    elsif self.current_virtual_quantity <= self.product.quantity_min
      css = "minimum"
    else
      css = "enough"
    end
    css
  end

end
