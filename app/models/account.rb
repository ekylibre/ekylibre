# == Schema Information
# Schema version: 20081127140043
#
# Table name: accounts
#
#  id           :integer       not null, primary key
#  number       :string(16)    not null
#  alpha        :string(16)    
#  name         :string(208)   not null
#  label        :string(255)   not null
#  usable       :boolean       not null
#  groupable    :boolean       not null
#  keep_entries :boolean       not null
#  transferable :boolean       not null
#  letterable   :boolean       not null
#  pointable    :boolean       not null
#  is_debit     :boolean       not null
#  last_letter  :string(8)     
#  comment      :text          
#  delay_id     :integer       
#  entity_id    :integer       
#  parent_id    :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Account < ActiveRecord::Base
 validates_format_of :number, :with=>/[0-9]+/i
 
after_create :parent
before_destroy :sub


  # This method allows to create the parent accounts if it is necessary.
  #def before_validation
  def parent
    number=self.number.to_s
    number=self.number.to_s[0..number.size-2] if number.size > 1
    account=Account.find_by_number(number)
    unless account
      @new_account=Account.create!(:number=>number, :name=>"Account", :label=>"A", :company_id=>self.company_id) 
      self.update_attribute(:parent_id, @new_account.id)
    else
      self.update_attribute(:parent_id,account.id)
    end
  end

  # This method allows to delete all the sub-accounts.
  def sub
   puts 'yesyjkj'
    accounts = Account.find(:all, :conditions => "number LIKE '"+self.number.to_s+"%'", :order=> "number DESC")

    accounts.each do |account|
      Account.delete account
    end
  end

end

