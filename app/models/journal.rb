# == Schema Information
# Schema version: 20090407073247
#
# Table name: journals
#
#  id             :integer       not null, primary key
#  nature         :string(16)    not null
#  name           :string(255)   not null
#  code           :string(4)     not null
#  deleted        :boolean       not null
#  currency_id    :integer       not null
#  counterpart_id :integer       
#  closed_on      :date          default(Thu, 31 Dec 1970), not null
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class Journal < ActiveRecord::Base
  belongs_to :company
  belongs_to :currency
  belongs_to :counterpart, :class_name=>"Account"
 #  belongs_to :account, :class_name=>"Account", :foreign_key=>:counterpart_id 
  
  has_many :bank_accounts
  has_many :periods, :class_name=>"JournalPeriod", :foreign_key=>:journal_id
  has_many :records, :class_name=>"JournalRecord", :foreign_key=>:journal_id

  #   before_create :journal_nature
  before_destroy :empty?


  # groups all the accounts corresponding to a transaction of sale.
  ACCOUNTS_OF_SALES = {:sale=>70, :tva_collected=>4457, :customer=>[411, 413, 4191], :bank=>[511, 512], :cash=>53, 
    :others=>[654, 661, 665] }  
  
  # groups all the accounts corresponding to a transaction of purchase.
  ACCOUNTS_OF_PURCHASES = {:purchase=>[60, 61, 62, 635], :tva_deductible=>[4452, 4456], :supplier=>[401, 403, 4091], 
    :bank=>512, :others=>765 }
  
  #
  def before_validation
    if self.closed_on.nil?
      self.closed_on = Date.civil(1970,1,1) 
      if self.company
        f = self.company.financialyears.find(:first, :order=>:started_on)
        self.closed_on = f.started_on-1.day unless f.nil?
      end
    end
  end

  #
  def validate
  end

  # tests if the period contains records.
  def empty?
    return self.periods.size <= 0
  end

  # this method closes a journal.
  def close(date)
    self.periods.each do |period|
      unless period.balanced
        errors.add_to_base lc(:error_unbalanced_period_journal)
        return false 
      end
    end
    
    self.update_attribute(:closed_on, date)
    self.periods.each do |period|
      period.close(date)
    end
    return true
  end

  
  # this method creates a period with a record.
  def create_record(financialyear, values = {})
    period = self.periods.find(:first, :conditions=>['company_id = ? AND financialyear_id = ? AND ?::date BETWEEN started_on AND stopped_on', self.company_id, financialyear, values[:created_on] ])
    period = self.periods.create!(:company_id=>self.company_id, :financialyear_id=> financialyear, :started_on=>values[:created_on]) if period.nil?
    record = JournalRecord.find(:first,:conditions=>{:period_id => period.id, :number => values[:number]}) 
    record = JournalRecord.create!(values.merge({:period_id=>period.id, :company_id=>self.company_id, :journal_id=>self.id})) if record.nil?
    return record
  end

  
  # this method searches the last records according to a number.  
  def last_records(period, number_record=:all)
    period.records.find(:all, :order => "lpad(number,20,'0') DESC", :limit => number_record)
  end


  #
  def journal(period)
   # if the type of journal (purchase, sale, bank, cash ...) is precised. Otherwise, it deals with a standard journal. 
    case self.name
    when "purchases"
      ACCOUNTS_OF_PURCHASES.each_value do |account|
        accounts += Account.find(:first, :conditions=>{:number=>"LIKE '?%'" + account}).number
      end
    when "sales"
      ACCOUNTS_OF_SALES.each_value do |account|
        accounts += Account.find(:first, :conditions=>{:number=>"LIKE '?%'"+ account}).number
      end
    else
      accounts += Account.find(:all).number
    end
    
    results = Hash.new
    
    records = JournalRecord.find(:all,:conditions=>{:period_id=>period.id})
    records.each do |record|
      results[record.created_on.to_sym] = Hash.new
      result = results[results.created_on.to_sym]
      entries = Entry.find(:all, :conditions=>{:record_id=>record.id})
      entries.each do |entrie|
        if accounts.include? entrie.account.number
          result[entrie.account.number.to_sym] = { :name => entrie.account.name, :debit => entrie.debit,
            :credit => entrie.credit, :solde => entrie.solde }
        end
      end
      results[record.created_on.to_sym] = result  unless result.empty? 
    end
  end

  # this method returns an array .
  def self.natures
    [:sale, :purchase, :bank, :various].collect{|x| [tc('natures.'+x.to_s), x] }
  end



end

