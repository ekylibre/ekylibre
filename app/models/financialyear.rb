# == Schema Information
#
# Table name: financialyears
#
#  closed       :boolean       not null
#  code         :string(12)    not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Financialyear < ActiveRecord::Base
  belongs_to :company

  has_many :account_balances, :class_name=>"AccountBalance", :foreign_key=>:financialyear_id

  has_many :records,  :class_name=>"JournalRecord"

  validates_presence_of :started_on, :stopped_on

  #
  def before_validation
    self.stopped_on = self.started_on+1.year if self.stopped_on.blank? and self.started_on
    self.stopped_on = self.stopped_on.end_of_month unless self.stopped_on.blank?
    if self.started_on
      self.code = self.started_on.year.to_s
      self.code += "/"+self.stopped_on.year.to_s if self.started_on.year!=self.stopped_on.year
      self.code += "EX"
    end
    self.code.upper!
    if self.company
      while self.company.financialyears.count(:conditions=>["code=? AND id!=?",self.code, self.id||0]) > 0 do
        self.code.succ!
      end
    end
  end

  #
  def validate
    unless self.stopped_on.blank? 
      errors.add_to_base tc(:error_stopped2_financialyear) unless self.stopped_on == self.stopped_on.end_of_month
      errors.add_to_base tc(:error_period_financialyear) unless self.started_on < self.stopped_on
    end
  
  end
  
  # tests if the financialyear can be closed.
  def closable?
    records = self.records
    if records.size > 0
      records.each do |record|
        return false unless record.balanced
        #   return false unless record.closed
      end
    end
    return true
    #else
    #  return false
  end

    # When a financial year is closed, all the matching journals are closed too. 
  def close(date)
    if self.closable?
      self.company.journals.find(:all, :conditions => ["closed_on < ?", date]).each do |journal|
        journal.close(date)
      end
      self.update_attributes(:stopped_on => date, :closed => true)
    end
  end

  # this method returns the previous financialyear.
 # def previous(company)
  def previous
    #return Financialyear.find(:last, :conditions => ["company_id = ? AND stopped_on < ?", company, self.started_on], :order => "stopped_on ASC")
    return Financialyear.find(:last, :conditions => ["company_id = ? AND stopped_on < ?", self.company_id, self.started_on], :order => "stopped_on ASC")
  end
 
   # this method returns the next financialyear.
  def next(company)
    return Financialyear.find(:first, :conditions => ["company_id = ? AND started_on = ?", company, self.stopped_on+1], :order => "started_on ASC")
  end
 
  def balance(accounts_number)
    unless accounts_number.nil?
      not_in_query, in_query, accounts_to_substract = [], [], []

      if accounts_number.include?(",")
        
        if accounts_number.include?("-")
          accounts_number.split(",").each{|a| accounts_to_substract << a.strip.gsub(/^\-/,'') if a.match(/\-/)}
          accounts_to_substract.each do |a|
            in_query << "accounts.number LIKE '#{a.upcase}%'"
          end
          balance_to_substract = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit , sum(account_balances.local_debit) as sum_debit FROM account_balances LEFT JOIN accounts ON (accounts.id = account_balances.account_id  AND account_balances.financialyear_id = #{self.id}) WHERE #{in_query.join(' OR ')} AND account_balances.company_id = #{self.company_id}")
        end
        
        in_query.clear
        accounts = accounts_number.split(",").each{|a| a.strip!}
        accounts.each do |a|
          if a.match(/^\^/)
            not_in_query << "accounts.number NOT LIKE '#{a.gsub!(/^\^/,'').upcase}%'"
          elsif not a.match(/^\-/)
            in_query << "accounts.number LIKE '#{a.upcase}%'"
          end
        end
        not_in_query = not_in_query.empty? ? "" : "AND "+not_in_query.join(" OR ")
        balance = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit , sum(account_balances.local_debit) as sum_debit FROM account_balances LEFT JOIN accounts ON (accounts.id = account_balances.account_id  AND account_balances.financialyear_id = #{self.id}) WHERE #{in_query.join(' OR ')} #{not_in_query} AND account_balances.company_id = #{self.company_id}")
      else
        balance = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit, sum(account_balances.local_debit) as sum_debit FROM account_balances LEFT JOIN accounts ON (accounts.id = account_balances.account_id  AND account_balances.financialyear_id = #{self.id}) WHERE accounts.number LIKE '#{accounts_number.strip.upcase}%' AND account_balances.company_id = #{self.company_id}")
      end
    end
    #puts accounts_number.include?("-").inspect+balance[0].inspect+"!!!!!!!!!!!!!"+balance_to_substract.inspect
    #raise Exception.new balance_to_substract[0]["sum_credit"].to_d.inspect
    if accounts_number.include?("-")
      return ( (balance[0]["sum_debit"].to_f - balance[0]["sum_credit"].to_f) - (balance_to_substract[0]["sum_debit"].to_f - balance_to_substract[0]["sum_credit"].to_f) )
    else
      return (balance[0]["sum_debit"].to_f - balance[0]["sum_credit"].to_f)
    end
  end

  def compute_balances
    ## entries.all group_by account_id =>refresh account_balance corresponding
    results = ActiveRecord::Base.connection.select_all("SELECT account_id, sum(entries.debit) as sum_debit, sum(entries.credit) as sum_credit FROM entries LEFT JOIN journal_records as jr ON jr.id = entries.record_id AND jr.financialyear_id = #{self.id} WHERE entries.company_id =  #{self.company_id} AND draft is false GROUP BY account_id")
    results.each do |result|
      if account_balance = self.company.account_balances.find_by_financialyear_id_and_account_id(self.id, result["account_id"].to_i)
        account_balance.update_attributes!(:local_credit=>result["sum_credit"].to_d, :local_debit=>result["sum_debit"].to_d)
      else
        self.company.account_balances.create!(:financialyear_id=>self.id, :account_id=>result["account_id"].to_i, :local_credit=>result["sum_credit"].to_d, :local_debit=>result["sum_debit"].to_d)
      end
    end
  end
  
 

end
