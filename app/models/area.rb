# == Schema Information
#
# Table name: areas
#
#  id           :integer       not null, primary key
#  postcode     :string(255)   not null
#  name         :string(255)   not null
#  city_id      :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  creator_id   :integer       
#  updater_id   :integer       
#  lock_version :integer       default(0), not null
#

class Area < ActiveRecord::Base
  belongs_to :company
  belongs_to :city
  has_many :contacts
  validates_format_of :postcode, :with=>/\d{5}/
  attr_readonly :company_id

  def before_validation
    self.name = self.postcode.upper
  end

end


