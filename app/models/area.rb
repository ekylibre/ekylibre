class Area < ActiveRecord::Base
  belongs_to :city
  has_many :contacts

  validates_format_of :postcode, :with=>/\d{5}/

end
