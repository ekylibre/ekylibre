# == Schema Information
#
# Table name: entity_categories
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  description  :text          
#  default      :boolean       not null
#  deleted      :boolean       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#  code         :string(8)     
#

class EntityCategory < ActiveRecord::Base

  belongs_to :company
  has_many :entities, :foreign_key=>:category
  has_many :prices, :foreign_key=>:category

  def before_validation
    self.code = self.name.codeize if self.code.blank?
    self.code = self.code[0..7]

    EntityCategory.update_all({:default=>false}, ["company_id=? AND id!=?", self.company_id, self.id||0]) if self.default
  end


  def before_destroy
    EntityCategory.create!(self.attributes.merge({:deleted=>true, :code=>self.code.to_s+" ", :company_id=>self.company_id})) 
  end
  
end
