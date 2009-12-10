# == Schema Information
#
# Table name: entity_categories
#
#  code         :string(8)     
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  default      :boolean       not null
#  deleted      :boolean       not null
#  description  :text          
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class EntityCategory < ActiveRecord::Base

  belongs_to :company
  has_many :entities, :foreign_key=>:category
  has_many :prices, :foreign_key=>:category

  attr_readonly :company_id

  def before_validation
    self.code = self.name.codeize if self.code.blank?
    self.code = self.code[0..7]

    EntityCategory.update_all({:default=>false}, ["company_id=? AND id!=?", self.company_id, self.id||0]) if self.default
  end
 

  def before_destroy
    EntityCategory.create!(self.attributes.merge({:deleted=>true, :code=>self.code.to_s+" ", :company_id=>self.company_id})) 
  end
  
end
