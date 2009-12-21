# == Schema Information
#
# Table name: shapes
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  master       :boolean       default(TRUE), not null
#  name         :string(255)   not null
#  number       :string(255)   
#  parent_id    :integer       
#  polygon      :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Shape < ActiveRecord::Base
  acts_as_tree
  attr_readonly :company_id
  belongs_to :company
  has_many :operations, :class_name=>ShapeOperation.name
  has_many :shapes
  # acts_as_measure :area

  def before_validation
    self.master = false if self.master.nil?
    self.polygon ||= "[NotUsed]"
  end

end
