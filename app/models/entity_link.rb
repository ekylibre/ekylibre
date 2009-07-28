# == Schema Information
#
# Table name: entity_links
#
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  entity1_id   :integer       not null
#  entity2_id   :integer       not null
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  nature_id    :integer       not null
#  started_on   :date          
#  stopped_on   :date          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class EntityLink < ActiveRecord::Base
  belongs_to :company
  belongs_to :entity1, :class_name=>Entity.name
  belongs_to :entity2, :class_name=>Entity.name
  belongs_to :nature, :class_name=>EntityLinkNature.name

  attr_readonly :company_id

  def after_create
    self.started_on = Date.today
    self.save
  end


end
