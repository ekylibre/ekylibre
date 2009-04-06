class ProductComponent < ActiveRecord::Base

  def before_validation
    if self.quantity >= 2
      self.name = self.quantity.to_s+" "+self.content.unit.label+"s "+self.content.name.to_s
    else
      self.name = self.quantity.to_s+" "+self.content.unit.label+" "+self.content.name.to_s
    end
  end
  

end
