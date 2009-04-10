# == Schema Information
# Schema version: 20090410102120
#
# Table name: complements
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  nature       :string(8)     not null
#  position     :integer       
#  active       :boolean       default(TRUE), not null
#  required     :boolean       not null
#  length_max   :integer       
#  decimal_min  :decimal(16, 4 
#  decimal_max  :decimal(16, 4 
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Complement < ActiveRecord::Base
  belongs_to :company
  has_many :choices, :class_name=>ComplementChoice.to_s
  has_many :data, :class_name=>ComplementDatum.to_s
  acts_as_list

  attr_readonly :company_id, :nature

  NATURES = ['string', 'decimal', 'boolean', 'date', 'datetime', 'choice']
   
  def self.natures
    NATURES.collect{|x| [tc('natures.'+x), x] }
  end

  def nature_label   
    tc('natures.'+self.nature)
  end

  def choices_count
    self.choices.count
  end

  def sort_choices
    choices = self.choices.find(:all, :order=>:name)
    for x in 0..choices.size-1
      choices[x]['position'] = x+1
      choices[x].save!#(false)
    end
  end

end
