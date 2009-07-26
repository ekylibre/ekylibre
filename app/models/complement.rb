# == Schema Information
#
# Table name: complements
#
#  active       :boolean       default(TRUE), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  decimal_max  :decimal(16, 4 
#  decimal_min  :decimal(16, 4 
#  id           :integer       not null, primary key
#  length_max   :integer       
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nature       :string(8)     not null
#  position     :integer       
#  required     :boolean       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
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
