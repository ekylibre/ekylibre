# == Schema Information
#
# Table name: listings
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  root_model   :string(255)   not null
#  query        :text          
#  comment      :text          
#  story        :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  creator_id   :integer       
#  updater_id   :integer       
#  lock_version :integer       default(0), not null
#

class Listing < ActiveRecord::Base
  belongs_to :company
  has_many :nodes, :class_name=>ListingNode.name
  attr_readonly :company_id
  
  def root_model_name
    ::I18n.t("activerecord.models."+self.root_model.underscore)
  end

end
