class EntityCategory < ActiveRecord::Base

  belongs_to :company
  has_many :entities, :foreign_key=>:category

  def before_validation
    EntityCategory.update_all({:default=>false}, ["company_id=? AND id!=?", self.company_id, self.id||0]) if self.default
  end


  def before_destroy
    EntityCategory.create!(self.attributes.merge({:deleted=>true, :company_id=>self.company_id})) 
  end
  
end
