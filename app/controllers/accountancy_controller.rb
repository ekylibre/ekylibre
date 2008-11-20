class AccountancyController < ApplicationController

  dyta(:journals, :conditions=>{:company_id=>['@current_company.id']}) do |t|
#  dyta(:journals, :conditions=>["company_id=? and ?",['@current_company.id'], 'toto"tot']) do |t|
    t.column :name
    t.column :code
    t.column :name, :through=>:nature
    t.action :journals_edit, :image=>:edit
    t.procedure :create, :action=>:journals_create
  end


  def accounts
    accounts = Account.find(:all)
    results = Hash.new
    
    accounts.each do |account|
      entries = Entry.find_by_id(account.id)
      results[account.name.to_sym] = Hash.new
      result = results[account.name.to_sym]
      entries.each do |entrie|
        result[:debit] += entrie[debit]
        result[:credit] += entrie[credit]
      end
      result[:solde] = result[:debit] - result[:credit]
     results[account.name.to_sym] = result
    end
    
    @accounts = @current_company.accounts
  end
  

      
  def entries
  end


  def journals
    nature_id = Journal.find_by_nature_id(params[id]) 
    nature_journal = JournalNature.find_by_name(nature_id)
    results = Hash.new
    
    periods = JournalPeriod.find(:all,:conditions=>["journal_id = ?", params[id]])
    periods.each do |period| 
      results[period.started_on.to_sym] = Hash.new
      result=results[period.started_on.to_sym]

      records = JournalRecord.find(:all,:conditions=>["period_id = ?", period[id]])
      records.each do |record|
        result[record.id.to_sym] = Hash.new
        result = result[record.id.to_sym]
        result[:save_on] = record[created_on]
        entries = Entry.find(:all,:conditions=>["record_id = ?", record[id]])
        entries.each do |entrie|
          result[entrie.account_id.to_sym] = Hash.new
          result[entrie.account_id.to_sym][:debit] = entrie[debit]
          result[entrie.account_id.to_sym][:credit] = entrie[credit]
          result[entrie.account_id.to_sym][:solde] = entrie[solde]
          account = Account.find(entrie.account_id)
          result[entrie.account_id.to_sym][:number] = account[number]
          result[entrie.account_id.to_sym][:name] = account[name]
        end
        results[period.started_on.to_sym] = results
      end
    end
    journals_list params
#    @journals = @current_company.journals
  end

  def journals_create
    access :journals
    if request.post?
      @journal = Journal.new(params[:journal])
      @journal.company_id = session[:company_id]
      redirect_to_back if @journal.save
    else
      @journal = Journal.new
    end
    render_form
  end

  def toto
    render :text=>"C'est OK, ça marche !"
  end

end
