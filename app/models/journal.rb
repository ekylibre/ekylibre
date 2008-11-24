# == Schema Information
# Schema version: 20080819191919
#
# Table name: journals
#
#  id             :integer       not null, primary key
#  nature_id      :integer       not null
#  name           :string(255)   not null
#  code           :string(4)     not null
#  counterpart_id :integer       
#  closed_on      :date          not null
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class Journal < ActiveRecord::Base


  def self.
  begin
        journal_nature = Journal.find(:first, :conditions=>["id = ? AND nature_id = ?", params[:id], params[:type_journal]])
      rescue
        raise Exception.new("No records matching has been found in the database.")
      end
      
      name_nature_journal = JournalNature.find(journal_nature.id).name
      
      # if the type of journal (purchase, sale, bank, cash ...) is precised. Otherwise, it deals with a standard journal. 
      case params[:type_journal]
      when "purchases"
        ACCOUNTS_OF_PURCHASES.each_value do |account|
          accounts +=  Account.find(:first, :conditions=>["number LIKE '?%'", account]).number
        end
      
      when "sales"
        ACCOUNTS_OF_SALES.each_value do |account|
          accounts +=  Account.find(:first, :conditions=>["number LIKE '?%'", account]).number
        end
      
      else
        accounts +=  Account.find(:all).number
      end

 C'est une méthode ici ?

  @results = Hash.new

  periods = JournalPeriod.find(:all,:conditions=>["journal_id = ?", params[id]])
  periods.each do |period| 
    @results[period.started_on.to_sym] = Hash.new
    result=@results[period.started_on.to_sym]
    
    records = JournalRecord.find(:all,:conditions=>["period_id = ?", period.id])
    records.each do |record|
      created_on = record.created_on.to_sym
      result[created_on] = Hash.new
      result2 = result[created_on]
      entries = Entry.find(:all,:conditions=>["record_id = ?", record.id])
      entries.each do |entrie|
        account = Account.find(entrie.account_id)
        if accounts.include? account.number
          result2[account.number.to_sym] = Hash.new
          result2[account.number.to_sym][:debit] = entrie.debit
          result2[account.number.to_sym][:credit] = entrie.credit
          result2[account.number.to_sym][:solde] = entrie.solde
          result2[account.number.to_sym][:name] = account.name
        end
      end

      if result2.empty?
        result.delete record.created_on.to_sym 
      else
        result[record.created_on.to_sym] = result2 
      end
      
    end
    @results[period.started_on.to_sym] = result
  end
  #    journals_list params
  #    @journals = @current_company.journals





end

