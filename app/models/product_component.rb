class ProductComponent < ActiveRecord::Base

  attr_readonly :company_id, :quantity, :content_id, :package_id, :name, :comment

  def before_validation
    if self.quantity >= 2
      self.name = self.quantity.to_s+" "+self.component.unit.label+"s "+tc('of_product')+" "+self.component.name.to_s
    else
      self.name = self.quantity.to_s+" "+self.component.unit.label+" "+tc('of_product')+" "+self.component.name.to_s
    end
  end
  
  def before_validation_on_create    
    self.active = true
    self.started_at = Time.now
    #raise Exception.new self.inspect
  end


  def before_update
    #raise Exception.new "hhjhjhjh"
    self.stopped_at = Time.now
    ProductComponent.create!(self.attributes.merge({:started_at=>self.stopped_at, :stopped_at=>nil, :active=>true, :company_id=>self.company_id})) if self.active
    self.active = false
    true
  end

end
