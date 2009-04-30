# == Schema Information
# Schema version: 20090410102120
#
# Table name: stock_locations
#
#  id               :integer       not null, primary key
#  name             :string(255)   not null
#  x                :string(255)   
#  y                :string(255)   
#  z                :string(255)   
#  comment          :text          
#  parent_id        :integer       
#  account_id       :integer       not null
#  establishment_id :integer       
#  contact_id       :integer       
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  updated_at       :datetime      not null
#  created_by       :integer       
#  updated_by       :integer       
#  lock_version     :integer       default(0), not null
#

class StockLocation < ActiveRecord::Base
  belongs_to :account
  belongs_to :company
  belongs_to :contact
  belongs_to :establishment
  has_many :product_stocks
  has_many :purchase_order_lines
  has_many :sale_order_lines
  has_many :stock_locations
  has_many :stock_moves
  has_many :stock_transfers

  acts_as_tree
end
