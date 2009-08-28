# == Schema Information
#
# Table name: document_natures
#
#  code         :string(255)   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  family       :string(255)   
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  to_archive   :boolean       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class DocumentNature < ActiveRecord::Base
  belongs_to :company
  has_many :templates, :class_name=>DocumentTemplate.name, :foreign_key=>:nature_id

  @@families = [:company, :relations, :accountancy, :management, :resources, :production]

  def self.families
    @@families.collect{|x| [tc('families.'+x.to_s), x.to_s]}
  end

  def family_label
    tc('families.'+self.family) if self.family
  end


  def destroyable?
    true
  end
  
end
