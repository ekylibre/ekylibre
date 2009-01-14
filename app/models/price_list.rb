# == Schema Information
# Schema version: 20081127140043
#
# Table name: price_lists
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  started_on   :date          not null
#  stopped_on   :date          
#  deleted      :boolean       not null
#  comment      :text          
#  currency_id  :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class PriceList < ActiveRecord::Base
end
