class AccountancyController < ApplicationController
  #  # groups all the accounts corresponding to a transaction of sale.
  #   ACCOUNTS_OF_SALES={:sale=>70, :tva_collected=>4457, :customer=>[411, 413, 4191], :bank=>[511, 512], :cash=>53 , 
  #     :others=>[654, 661, 665] }
  
  #   # groups all the accounts corresponding to a transaction of purchase.
  #   ACCOUNTS_OF_PURCHASES={:purchase=>[60, 61, 62, 635], :tva_deductible=>[4452, 4456], :supplier=>[401, 403, 4091], 
  #     :bank=>512, :others=>765 }
  

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
    accounts_list params
  end
  
  # this action has not specific view.
  def journal_entries
    session[:journal] = params[:journal][:id]
    redirect_to :action => "entries" 
  end

  def entries
    journals_list params
    @entries = Entry.find(:all)
    #record = JournalRecord.find(:last, :order => "number ASC")
    
    #if record
    #  @number = record.number.succ
    #else
    #  @number = 1
    #end
    
  end


  def find_accounts
    @search=params[:account].gsub('*','%')
    @find_accounts = Account.find(:all,:conditions=>["company_id = ? AND number LIKE ?", @current_company.id, @search])
    render :partial => 'find_accounts'
    
  end
  
    
  def load_data
   # creation of a financial year.
    @current_company.accounts.create!(:number=>'6', :name=>'charge', :label=>'charge', :parent_id=>1)
    @current_company.accounts.create!(:number=>'7', :name=>'produit', :label=>'produit', :parent_id=>2)
    @current_company.accounts.create!(:number=>'71', :name=>'produit', :label=>'produit1', :parent_id=>2)
    @current_company.financialyears.create!(:code=>'1A2',
                                            :started_on=>Date.civil(2008,01,01), 
                                            :stopped_on=>Date.civil(2008,12,31), 
                                            :written_on=>Date.civil(2008,12,12) )
    @current_company.currencies.create!(:name=>'europeenne', :code=>'Eur', :format=>'euros')

    redirect_to :action => "entries"
  end
 
 
  def entries_create
    if request.post?
      @record = Journal.find(session[:journal]).create_record(params[:record])
      account = Account.find_by_number(params[:account][:number])
      currency = Currency.find(:first, :conditions=>["company_id = ?", @current_company.id])
      
      @entry = Entry.create!(params[:entry].merge({:account_id => account.id, :record_id => @record.id, 
                                :currency_id => currency.id, :company_id => @current_company.id}))
      @record.reload
      
      @entries = Entry.find(:all, :conditions =>["company_id = ?", @current_company.id])
             
      if request.xhr?
        render :action => "entries_create"
      else
        raise Exception.new "blabla"
        render :action => "entries"
      end
    
    else
      @entry = Entry.new
    end
    
  end


  # lists all the transactions established on the accounts, sorted by date.
  def journals
    #    begin
    #      period = JournalPeriod.find(:first, :conditions=>["started_on = ? AND stopped_on = ?", params[:period][0], params[:period][1] ])
    #    rescue
    #      raise Exception.new("No records matching has been found in the database.")
    #    end    
    #    period.journal.journal(period)
    journals_list params
  
  #    journals_list params
  #    @journals = @current_company.journals
  end

  def journals_create
    access :journals
    if request.post?
      @journal = Journal.new(params[:journal])
      @journal.company_id = @current_company.id
      redirect_to_back if @journal.save
    else
      @journal = Journal.new
    end
    render_form
  end

  def print
    render :action => 'print'
  end
  
  
  def print_balance_sheet
    render_xil('/home/thibaud/ekylibre/trunk/ekylibre/app/test.xml')
    render :action => 'print_balance_sheet'
    
  end
  


end


