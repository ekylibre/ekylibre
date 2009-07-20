# == Schema Information
#
# Table name: complement_choices
#
#  id            :integer       not null, primary key
#  complement_id :integer       not null
#  name          :string(255)   not null
#  value         :string(255)   not null
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  lock_version  :integer       default(0), not null
#  position      :integer       
#  creator_id    :integer       
#  updater_id    :integer       
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
