# == Schema Information
# Schema version: 20081111111111
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
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class StockTracking < ActiveRecord::Base
end
