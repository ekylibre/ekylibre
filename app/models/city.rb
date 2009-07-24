# == Schema Information
#
# Table name: cities
#
#  id             :integer       not null, primary key
#  insee_cdc      :string(1)     
#  insee_cheflieu :string(1)     
#  insee_reg      :string(2)     
#  insee_dep      :string(3)     
#  insee_com      :string(3)     
#  insee_ar       :string(1)     
#  insee_ct       :string(2)     
#  insee_tncc     :string(1)     
#  insee_artmaj   :string(5)     
#  insee_ncc      :string(70)    
#  insee_artmin   :string(5)     
#  insee_nccenr   :string(70)    
#  name           :string(255)   not null
#  district_id    :integer       not null
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class City < ActiveRecord::Base
  belongs_to :company
  belongs_to :district
  has_many :areas

  attr_readonly :company_id
  #validates_format_of :insee_ar, :with=>/\d/
  #validates_format_of :insee_ct, :with=>/\d{2}/
  #validates_format_of :insee_reg, :with=>/\d{2}/
  #validates_format_of :insee_com, :with=>/\d{3}/
 
  def city_name
    self.name
  end

end
