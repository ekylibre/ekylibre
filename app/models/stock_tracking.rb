# == Schema Information
#
# Table name: stock_trackings
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  serial       :string(255)   
#  active       :boolean       default(TRUE), not null
#  begun_at     :datetime      not null
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class StockTracking < ActiveRecord::Base
  belongs_to :company
  has_many :stock_moves
end
