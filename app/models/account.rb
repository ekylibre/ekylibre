# == Schema Information
# Schema version: 20090311124450
#
# Table name: accounts
#
#  id           :integer       not null, primary key
#  number       :string(16)    not null
#  alpha        :string(16)    
#  name         :string(208)   not null
#  label        :string(255)   not null
#  deleted      :boolean       not null
#  usable       :boolean       not null
#  groupable    :boolean       not null
#  keep_entries :boolean       not null
#  transferable :boolean       not null
#  letterable   :boolean       not null
#  pointable    :boolean       not null
#  is_debit     :boolean       not null
#  last_letter  :string(8)     
#  comment      :text          
#  parent_id    :integer       default(0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Account < ActiveRecord::Base
  validates_format_of :number, :with=>/[0-9]+/i
  acts_as_tree

  # This method allows to create the parent accounts if it is necessary.
  def before_validation
    self.label = self.number.to_s+' - '+self.name.to_s
    self.parent_id = 0 if self.parent_id.blank?
  end

  def after_save
    if self.number.size>1
      old_parent_id = self.parent_id
      account = Account.find_by_company_id_and_number(self.company_id, self.number.to_s[0..-2])
      unless account
        account = Account.create!(:number=>self.number.to_s[0..-2], :name=>tc("default_account_name", :number=>self.number.to_s[0..-2]), :company_id=>self.company_id)
      end
      self.update_attribute(:parent_id, account.id) if account.id!=old_parent_id
    end
  end

  # This method allows to delete an account only if it has any sub-accounts.
  def after_destroy
    #raise Exception.new self.childrenz.inspect
    raise Exception.new(tc('error_account_children')) if self.children.size>0
  end

  def parent
    Account.find_by_id(self.parent_id)
  end
  
  def childrenz
    Account.find_all_by_parent_id(self.id)||{}
  end

end

