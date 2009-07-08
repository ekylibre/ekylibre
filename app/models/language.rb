# == Schema Information
#
# Table name: languages
#
#  id          :integer       not null, primary key
#  name        :string(255)   not null
#  native_name :string(255)   not null
#  iso2        :string(2)     not null
#  iso3        :string(3)     not null
#  company_id  :integer       
#

class Language < ActiveRecord::Base
  has_many :entities
  belongs_to :company
  attr_protected :company_id
end
