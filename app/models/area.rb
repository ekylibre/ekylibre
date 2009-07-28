# == Schema Information
#
# Table name: areas
#
#  city         :string(255)   
#  city_name    :string(255)   
#  code         :string(255)   
#  company_id   :integer       not null
#  country      :string(2)     default("??")
#  created_at   :datetime      not null
#  creator_id   :integer       
#  district_id  :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  postcode     :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Area < ActiveRecord::Base
  belongs_to :company
  belongs_to :district
  has_many :contacts

  attr_readonly :company_id

  def before_validation
    return false unless self.company
    self.name = self.name.gsub(/\s+/,' ').strip.upper
    words = self.name.to_s.split(' ')
    start = words[0].to_s.ascii.length<=3 ? 2 : 1
    self.postcode, self.city, self.city_name = '', '', ''
    if words and words.size>0
      self.postcode = words[0..start-1].join(" ")
      self.city = words[start..-1].join(" ").upper
      self.city_name = self.city
      if self.city_name.match(/cedex/i)
        self.city_name = self.city_name.split(/\scedex/i)[0].strip 
      end
    end
  end

end


