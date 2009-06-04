# == Schema Information
# Schema version: 20090520140946
#
# Table name: taxes
#
#  id                   :integer       not null, primary key
#  name                 :string(255)   not null
#  group_name           :string(255)   not null
#  included             :boolean       not null
#  reductible           :boolean       default(TRUE), not null
#  nature               :string(8)     not null
#  amount               :decimal(16, 4 default(0.0), not null
#  description          :text          
#  account_collected_id :integer       
#  account_paid_id      :integer       
#  company_id           :integer       not null
#  created_at           :datetime      not null
#  updated_at           :datetime      not null
#  created_by           :integer       
#  updated_by           :integer       
#  lock_version         :integer       default(0), not null
#

class Tax < ActiveRecord::Base
  belongs_to :company
  belongs_to :account_collected, :class_name=>Account.to_s
  belongs_to :account_paid, :class_name=>Account.to_s
  has_many :prices

  attr_readonly :amount, :nature, :company_id

  def validate
    errors.add(:amount, tc(:amount_must_be_included_between_0_and_1)) if (self.amount < 0 || self.amount > 1) && self.nature=="percent"
  end

  def before_destroy
    Tax.create!(self.attributes.merge({:deleted=>true, :name=>self.name+" ", :company_id=>self.company_id})) 
  end
  
  def compute(amount)
    case self.nature.to_sym
    when :percent
      amount*self.amount
    when :amount
      self.amount
    else
      raise Exception.new("Unknown tax nature : "+self.nature.inspect.to_s)
    end
  end

  def self.natures
     [:percent, :amount].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def text_nature
    tc('natures.'+self.nature.to_s)
  end
  
end
