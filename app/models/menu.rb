# == Schema Information
# Schema version: 20080808080808
#
# Table name: menus
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  label        :text

class Menu < ActiveRecord::Base

  has_many :menu_items

end 
