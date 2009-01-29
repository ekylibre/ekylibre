# == Schema Information
# Schema version: 20081111111111
#
# Table name: entities
#
#  id           :integer       not null, primary key
#  nature_id    :integer       not null
#  language_id  :integer       not null
#  code         :string(255)   not null
#  name         :string(255)   not null
#  first_name   :string(255)   
#  full_name    :string(255)   not null
#  active       :boolean       default(TRUE), not null
#  born_on      :date          
#  dead_on      :date          
#  ean13        :string(13)    
#  soundex      :string(4)     
#  website      :string(255)   
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Entity < ActiveRecord::Base
  #has_many :contact
  def before_validation
    self.soundex = self.name.soundex2
    self.first_name.to_s!.strip!
    self.name.to_s!.strip!
    unless self.nature.nil?
      self.first_name = '' unless self.nature.physical
    end
    self.full_name = (self.name.to_s+" "+self.first_name.to_s).strip

    self.code = self.full_name.codeize if self.code.blank?
    while Entity.find(:first, ["company_id=? AND code=? AND id!=?",self.company_id, self.code,self.id||0])
      self.code.succ!
    end


    #self.active = false  unless self.dead_on.blank?
  end


end 
