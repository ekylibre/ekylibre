class AccountancyController < ApplicationController

  # groups all the accounts corresponding to a transaction of sale.
  ACCOUNTS_OF_SALES={:sale=>70, :tva_collected=>4457, :customer=>[411, 413, 4191], :bank=>[511, 512], :cash=>53 , 
    :others=>[654, 661, 665] }
  
  # groups all the accounts corresponding to a transaction of purchase.
  ACCOUNTS_OF_PURCHASES={:purchase=>[60, 61, 62, 635], :tva_deductible=>[4452, 4456], :supplier=>[401, 403, 4091], 
    :bank=>512, :others=>765 }

  


  dyta(:journals, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    #  dyta(:journals, :conditions=>["company_id=? and ?",['@current_company.id'], 'toto"tot']) do |t|
    t.column :name
    t.column :code
    t.column :name, :through=>:nature
    t.action :journals_edit, :image=>:edit
    t.procedure :create, :action=>:journals_create
  end

  # lists all the accounts with the credit, the debit and the balance for each of them.
  def accounts
    accounts = Account.find(:all)
    @results = Hash.new
    
    accounts.each do |account|
      entries = Entry.find_by_id(account.id)
      @results[account.name.to_sym] = Hash.new
      @results[account.name.to_sym][:number] = account.number
      result = @results[account.name.to_sym]
      entries.each do |entrie|
        result[:debit] += entrie.debit
        result[:credit] += entrie.credit
      end
      result[:solde] = result[:debit] - result[:credit]
      @results[account.name.to_sym] = result
    end
    
    @accounts = @current_company.accounts
  end
  
  
  
  def entries
    entries = Entrie.find(:all)
    entries.each do |entrie|
      
  end

  # lists all the transactions established on the accounts, sorted by date.
  def journals
    
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
    end
    
  when "sales"
    ACCOUNTS_OF_SALES.each_value do |account|
      accounts +=  Account.find(:first, :conditions=>["number LIKE '?%'", account]).number
    end
  end
else
  accounts +=  Account.find(:all).number
end


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
