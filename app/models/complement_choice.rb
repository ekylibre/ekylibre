# == Schema Information
#
# Table name: complement_choices
#
#  company_id    :integer       not null
#  complement_id :integer       not null
#  created_at    :datetime      not null
#  creator_id    :integer       
#  id            :integer       not null, primary key
#  lock_version  :integer       default(0), not null
#  name          :string(255)   not null
#  position      :integer       
#  updated_at    :datetime      not null
#  updater_id    :integer       
#  value         :string(255)   not null
#

class ComplementChoice < ActiveRecord::Base
  belongs_to :company
  belongs_to :complement
  has_many :data, :class_name=>ComplementDatum.to_s
  acts_as_list :scope=>:complement_id

  def to_s
    self.name
  end

end
