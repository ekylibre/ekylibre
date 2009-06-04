# == Schema Information
# Schema version: 20090520140946
#
# Table name: units
#
#  id           :integer       not null, primary key
#  name         :string(8)     not null
#  label        :string(255)   not null
#  base         :string(255)   not null
#  quantity     :decimal(, )   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Unit < ActiveRecord::Base
  belongs_to :company
  has_many :products

  DEFAULT_UNITS = {
    :u=> {:base=>'u',  :quantity=>1},
    :kg=>{:base=>'g',  :quantity=>1000},
    :t=> {:base=>'g',  :quantity=>1000000},
    :m=> {:base=>'m',  :quantity=>1},
    :km=>{:base=>'m',  :quantity=>1000},
    :ha=>{:base=>'m2', :quantity=>10000},
    :a=> {:base=>'m2', :quantity=>100},
    :ca=>{:base=>'m2', :quantity=>1},
    :l=> {:base=>'m3', :quantity=>0.001},
    :hl=>{:base=>'m3', :quantity=>0.1},
    :m3=>{:base=>'m3', :quantity=>1}
  }

  def self.default_units
    DEFAULT_UNITS
  end


end
