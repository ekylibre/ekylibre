# == Schema Information
#
# Table name: taxes
#
#  id                   :integer       not null, primary key
#  name                 :string(255)   not null
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
#  deleted              :boolean       not null
#

class Tax < ActiveRecord::Base
  belongs_to :company
  belongs_to :account_collected, :class_name=>Account.to_s
  belongs_to :account_paid, :class_name=>Account.to_s
  has_many :prices

  attr_readonly :amount, :nature, :company_id

  def before_validation
    
    if self.account_collected_id.nil?
      if self.amount == 0.0210
        account = Account.find_by_company_id_and_number(self.company_id, "445711") || Account.create!(:company_id=>self.company_id, :number=>"445711", :name=>self.name) 
      elsif self.amount == 0.0550
        account = Account.find_by_company_id_and_number(self.company_id, "445712") || Account.create!(:company_id=>self.company_id, :number=>"445712", :name=>self.name) 
      elsif self.amount == 0.1960
        account = Account.find_by_company_id_and_number(self.company_id, "445713") || Account.create!(:company_id=>self.company_id, :number=>"445713", :name=>self.name)
      else
        tax = Tax.find(:first, :conditions=>["company_id = ? and amount = ? and account_collected_id IS NOT NULL", self.company_id, self.amount])
        last = self.company.accounts.find(:first, :conditions=>["number like ?",'4457%'], :order=>"created_at desc")
        account = tax.nil? ? Account.create!(:company_id=>self.company_id, :number=>last.number.succ, :name=>self.name) : tax.account
      end
      self.account_collected_id = account.id
    end
  end


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
