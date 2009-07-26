# == Schema Information
#
# Table name: listings
#
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  query        :text          
#  root_model   :string(255)   not null
#  story        :text          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Listing < ActiveRecord::Base
  belongs_to :company
  has_many :nodes, :class_name=>ListingNode.name
  attr_readonly :company_id
  
  def root_model_name
    ::I18n.t("activerecord.models."+self.root_model.underscore)
  end

end
