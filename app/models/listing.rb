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

  #validates_format_of :query, :with=>/\s*SELECT\s+[^\;]*/i

  def root_model_name
    ::I18n.t("activerecord.models."+self.root_model.underscore)
  end

  def after_create
    # self.nodes.create!(:nature=>"string", :label=>"racine", :name=>self.root_model, :company_id=>self.company_id)
  end

  def root
    self.nodes.find_by_parent_id(nil)||self.nodes.create!(:label=>self.root_model_name, :name=>self.root_model, :nature=>"root")
  end

end
