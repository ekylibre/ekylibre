# == Schema Information
#
# Table name: bank_account_statements
#
#  id              :integer       not null, primary key
#  bank_account_id :integer       not null
#  started_on      :date          not null
#  stopped_on      :date          not null
#  intermediate    :boolean       not null
#  number          :string(255)   not null
#  debit           :decimal(16, 2 default(0.0), not null
#  credit          :decimal(16, 2 default(0.0), not null
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  updated_at      :datetime      not null
#  created_by      :integer       
#  updated_by      :integer       
#  lock_version    :integer       default(0), not null
#

class BankAccountStatement < ActiveRecord::Base
  belongs_to :bank_account
  belongs_to :company

  has_many :entries, :class_name=>"Entry", :foreign_key=>:intermediate_id
  has_many :entries, :class_name=>"Entry", :foreign_key=>:statement_id

  before_destroy :statement_entry

  # A bank account statement has to contain all the planned records.
  def validate    
    errors.add_to_base lc(:error_period_statement) if self.started_on >= self.stopped_on
  end

  #
  def statement_entry
    if self.entries.size > 0
      self.entries.each do |entry|
        entry.update_attribute(:statement_id, nil)
      end
    end
  end

end
