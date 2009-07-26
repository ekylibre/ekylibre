# == Schema Information
#
# Table name: entity_natures
#
#  abbreviation :string(255)   not null
#  active       :boolean       default(TRUE), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          
#  id           :integer       not null, primary key
#  in_name      :boolean       default(TRUE), not null
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  physical     :boolean       not null
#  title        :string(255)   
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class EntityNature < ActiveRecord::Base
  belongs_to :company
  has_many :entities, :foreign_key=>:nature_id 


  def before_validation
    self.in_name = false if self.physical
    if self.physical
      self.title = self.abbreviation if self.title.blank?
    else
      self.title = ''
    end
  end



end
