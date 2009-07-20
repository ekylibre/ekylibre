# == Schema Information
#
# Table name: product_components
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  product_id   :integer       not null
#  component_id :integer       not null
#  location_id  :integer       not null
#  quantity     :decimal(16, 2 not null
#  comment      :text          
#  active       :boolean       not null
#  started_at   :datetime      
#  stopped_at   :datetime      
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class ProductComponent < ActiveRecord::Base

  attr_readonly :company_id, :quantity, :content_id, :package_id, :name, :comment
  belongs_to :company
  belongs_to :product
  belongs_to :component, :class_name=>Product.to_s
  belongs_to :location, :class_name=>StockLocation.to_s

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
  end

  def before_update
    self.stopped_at = Time.now
    ProductComponent.create!(self.attributes.merge({:started_at=>self.stopped_at, :stopped_at=>nil, :active=>true, :company_id=>self.company_id})) if self.active
    self.active = false
    true
  end
  
  def check_quantities(params, production_quantity)
    total = 0
    for p in params[self.id.to_s]
      total += p[1].to_d
    end
    value = (total == (self.quantity*production_quantity))
  end
  
#   def stocks_move_create(params, production_id)
#     for p in params
#       if p[1] > 0
#         StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>p[1], :location_id=>p[0], :product_id=>self.component_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>false, :origin_type=>Production.to_s, :origin_id=>production_id)
#       end
#     end

#   end

end
