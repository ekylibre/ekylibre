# == Schema Information
#
# Table name: journal_records
#
#  closed           :boolean       
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  created_on       :date          not null
#  creator_id       :integer       
#  credit           :decimal(16, 2 default(0.0), not null
#  debit            :decimal(16, 2 default(0.0), not null
#  financialyear_id :integer       
#  id               :integer       not null, primary key
#  journal_id       :integer       not null
#  lock_version     :integer       default(0), not null
#  number           :string(255)   not null
#  position         :integer       not null
#  printed_on       :date          not null
#  resource_id      :integer       
#  resource_type    :string(255)   
#  status           :string(1)     default("A"), not null
#  updated_at       :datetime      not null
#  updater_id       :integer       
#

class JournalRecord < ActiveRecord::Base
  belongs_to :company
  belongs_to :journal
  belongs_to :financialyear, :class_name=>Financialyear.name
  belongs_to :resource, :polymorphic=>true
  has_many :entries, :foreign_key=>:record_id, :dependent=>:destroy 
  acts_as_list :scope=>:financialyear

  validates_format_of :number, :with => /^[\dA-Z][\dA-Z]*$/
  validates_length_of :number, :is =>  4

  #
  def before_validation
    self.debit = self.entries.sum(:debit)
    self.credit = self.entries.sum(:credit)
    unless self.number
      record = self.company.journal_records.find(:last, :conditions => ["EXTRACT(MONTH FROM created_on)=? AND financialyear_id=? AND journal_id=?", self.created_on.month, self.financialyear_id, self.journal_id], :order=>:number)
      if record
        self.number = record.number.succ
      else
        self.number = '1'
      end
    end
    self.number = self.number.rjust(4, "0")
    
  end 
  
  #
  def validate
    errors.add :number, tc(:error_format_number) unless self.number=~/^[\dA-Z][\dA-Z]*$/
    errors.add :printed_on, tc(:error_printed_date) if self.printed_on > self.created_on
    if self.financialyear
      errors.add :created_on, tc(:error_created_date_current_financialyear) if self.created_on < self.financialyear.started_on or self.created_on > self.financialyear.stopped_on
    end
    if self.journal
      errors.add :created_on, tc(:error_closed_journal, [self.journal.closed_on.to_formatted_s]) if self.created_on < self.journal.closed_on 
    end
  end
  
  # this method computes the debit and the credit of the record.
  def refresh
    self.save
  end
  
  #determines if the record is balanced or not.
  def balanced
    self.debit == self.credit and self.debit != 0
  end

  #determines the difference between the debit and the credit from the record.
  def balance
    self.debit - self.credit 
  end

  # this method allows to lock the record.
  def close
    self.update_attribute(:closed, true)
    if self.entries.size > 0
      self.entries.each do |entrie|
        entrie.close
      end
    end
  end

  #this method tests if all the entries matching to the record does not edited in draft mode.
  def normalized
    return (not self.entries.exists?(:draft=>true))
  end

  # Adds an entry with the minimum informations. It computes debit and credit withe the "amount".
  # If the amount is negative, the amount is put in the other column (debit or credit). Example: 
  #   record.add_debit("blabla", account, -65) # will put +65 in +credit+ column
  def add_debit(name, account, amount, options={})
    add(name, account, amount, options)
  end

  def add_credit(name, account, amount, options={})
    add(name, account, amount, options.merge(:credit=>true))
  end

  private

  def add(name, account, amount, options={})
    return if amount == 0
    attributes = options.merge(:name=>name)
    attributes[:account] = account.is_a?(Integer) ? account : account.id
    attributes[:currency_id] = self.journal.currency_id
    credit = options.delete(:credit) ? true : false
    credit = not credit if amount < 0
    if credit
      attributes[:currency_credit] = amount
      attributes[:currency_debit]  = 0.0
    else
      attributes[:currency_credit] = 0.0
      attributes[:currency_debit]  = amount
    end
    record.entries.create!(attributes)
  end

  
end
