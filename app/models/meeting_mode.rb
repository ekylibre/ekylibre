class MeetingMode < ActiveRecord::Base
  
  belongs_to :company
  has_many :meetings

  attr_readonly :company_id, :name

  
  def before_validation_on_create
    self.active = true
  end

  def before_update
    MeetingMode.create!(self.attributes.merge({:active=>true, :company_id=>self.company_id})) if self.active
    self.active = false
    true
  end

end
