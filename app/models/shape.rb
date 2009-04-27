class Shape < ActiveRecord::Base

  belongs_to :company
  has_many :shape_operations
  has_many :shapes

  acts_as_tree

end
