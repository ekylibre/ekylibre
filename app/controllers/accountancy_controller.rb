class AccountancyController < ApplicationController
  #  # groups all the accounts corresponding to a transaction of sale.
  #   ACCOUNTS_OF_SALES={:sale=>70, :tva_collected=>4457, :customer=>[411, 413, 4191], :bank=>[511, 512], :cash=>53 , 
  #     :others=>[654, 661, 665] }
  
  #   # groups all the accounts corresponding to a transaction of purchase.
  #   ACCOUNTS_OF_PURCHASES={:purchase=>[60, 61, 62, 635], :tva_deductible=>[4452, 4456], :supplier=>[401, 403, 4091], 
  #     :bank=>512, :others=>765 }


include ActionView::Helpers::FormOptionsHelper

  
  dyta(:journals, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :closed_on
    t.action :journals_update, :image=>:edit
    t.action :journals_delete, :method=>:post
    t.action :journals_close
    t.procedure :create, :action=>:journals_create
  end
 
  dyta(:accounts, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :number
    t.column :name
    t.column :label
    t.action :accounts_update, :image=>:edit
    t.action :accounts_delete, :method=>:post
    t.action :accounts_letter
    t.procedure :create, :action=>:accounts_create
  end
 
  dyta(:bank_accounts, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :bank_code
    t.column :agency_code
    t.column :number
    t.column :iban
    t.column :iban_text
    t.action :bank_accounts_update, :image=>:edit
    t.action :bank_accounts_delete, :method=>:post
    t.procedure :create, :action=>:bank_accounts_create
  end

  dyta(:bank_account_statements, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :started_on
    t.column :stopped_on
    t.column :number
    t.action :statements_update, :image=>:edit
    t.action :statements_delete, :method=>:post
    t.procedure :create, :action=>:statements_create
  end

   dyta(:entries, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :debit
    t.column :credit
    t.column :letter
    t.column :currency_rate
    t.action :statements_point, :method=>:post
  end

   dyta(:financialyears, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :code
    t.column :closed
    t.column :started_on
    t.column :stopped_on
    t.action :financialyears_update, :image=>:edit
    t.action :financialyears_delete, :method=>:post
    t.procedure :create, :action=>:financialyears_create
  end


  # displays all the traitments concerning accountancy.
  def index
    @bank_accounts = @current_company.bank_accounts 
    @journals = @current_company.journals  
    @financialyears = @current_company.financialyears
  end

  # lists all the bank_accounts with the mainly characteristics. 
  def bank_accounts
    bank_accounts_list params
  end

  # this method creates a bank_account with a form.
  def bank_accounts_create
    access :bank_accounts
    if request.post? 
      @bank_account = BankAccount.new(params[:bank_account])
      @bank_account.company_id = @current_company.id
      redirect_to :action => "bank_accounts" if @bank_account.save
    else
      @bank_account = BankAccount.new
    end
    render_form
  end

  # this method updates a bank_account with a form.
  def bank_accounts_update
   access :bank_accounts
    @bank_account = BankAccount.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      @bank_account.update_attributes(params[:bank_account])
      redirect_to :action => "bank_accounts"
    end
    render_form
  end
  
  # this method deletes a bank_account.
  def bank_accounts_delete
    if request.post? or request.delete?
      @bank_account = BankAccount.find_by_id_and_company_id(params[:id], @current_company.id)  
      if @bank_account.account.entries.size > 0
        @bank_account.update_attribute(:deleted, true)
      else
        BankAccount.delete @bank_account
      end
    end
    redirect_to :action => "bank_accounts"
  end

  # lists all the accounts with the credit, the debit and the balance for each of them.
  def accounts
    accounts_list params
  end
  
  # this action has not specific view.
  def params_entries
    session[:journal] = params[:journal][:id]
    session[:records_number] = params[:number]
    redirect_to :action => "entries" 
  end

  # this action creates an account with a form.
  def accounts_create
    access :accounts
    if request.post?
      @account = Account.new(params[:account])
      @account.company_id = @current_company.id
      redirect_to :action => "accounts" if @account.save
    else
      @account = Account.new
    end
    render_form
  end

  # this action updates an existing account with a form.
  def accounts_update
    access :accounts
    @account = Account.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      @account.update_attributes(params[:account])
      redirect_to :action => "accounts"
    end
    render_form
  end


  # this action deletes or hides an existing account.
  def accounts_delete
    if request.post? or request.delete?
      @account = Account.find_by_id_and_company_id(params[:id], @current_company.id)  
      #if @account.usable
      #  @account.update_attribute(:deleted, true)
      #else
      
      Account.destroy @account unless @account.entries.size > 0 or @account.balances.size > 0
      #end
    end
    redirect_to :action => "accounts"
  end
 

  #
  def accounts_letter_launch
     @accounts = Account.find(:all, :conditions => {:company_id => @current_company.id})
  end


  #
  def accounts_letter
    if request.xhr?
    
    else
      @entries = Entry.find(:all, :conditions => ['company_id = ? AND account_id = ? AND letter is NULL', @current_company.id, params[:id] ])
    end
  end

  def document_prepare
    @company = @current_company
    if request.post?
      case params[:mode] 
      when  "balance_sheet"
        session[:mode] = "balance_sheet"
        session[:print] = params[:print_balance_sheet][:id]
      when "balance"
        session[:mode] = "balance"
        session[:print]= params[:print_balance]
      end
      redirect_to :action=>:document_print
    end
  end
  
  def document_print
    @company = @current_company
    case session[:mode] 
    when "balance_sheet"
      @id = session[:print][:id]
    when "balance"
      @begin = session[:print][:from]
      @end = session[:print][:to]
      @code = session[:print][:code]
      @year_from = session[:print][:from]
      session[:print][:date] = true
      # raise Exception.new @year_from.inspect
      # params[:print][:year_begin] = Date.new(year,01,01)
     # params[:test][:year_end] = Date.new(year,12,31)
      session[:print][:current_company] = @current_company.id.to_s
    end
    if request.post?
      render(:xil=>'/home/thibaud/ekylibre2/trunk/ekylibre/app/balance.xml',:locals=>session[:print])
    end
  end
  
  # ths method allows to print.
  def print
    render :action => 'print'
  end
  
  # this method finds the journal with the matching id and the company_id.
  def journals_find
    @find_journals = @current_company.journals
    render :partial => 'journals_find'
  end
  
  # this method finds the currency with the matching id and the company_id.
  def currencies_find
    @find_currencies = @current_company.currencies
    render :partial => 'currencies_find'
  end
  

  # this method finds the account with the matching number and the company_id.
  def accounts_find
    @search = params[:account].gsub('*','%')
    @find_accounts = Account.find(:all,:conditions=>["company_id = ? AND number LIKE ?", @current_company.id, @search])
    render :partial => 'accounts_find'
  end

  # lists all the financialyears.
  def financialyears
    financialyears_list params
  end


  # this action creates a financialyear with a form.
  def financialyears_create
    access :financialyears
    if request.post?
      @financialyear = Financialyear.new(params[:financialyear])
      @financialyear.company_id = @current_company.id
      redirect_to session[:history][2] if @financialyear.save
    else
      @financialyear = Financialyear.new
    end
    render_form
  end

  
  # this action updates a financialyear with a form.
  def financialyears_update
    access :financialyears
    @financialyear = Financialyear.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      redirect_to :action => "financialyears"  if @financialyear.update_attributes(params[:financialyear])
    end
    render_form
  end
  
  
  # this action deletes a financialyear.
  def financialyears_delete
    if request.post? or request.delete?
      @financialyear = Financialyear.find_by_id_and_company_id(params[:id], @current_company.id)  
      Financialyear.destroy @financialyear unless @financialyear.journal_periods.size > 0 
    end
    redirect_to :action => "financialyears"
  end
  

  # This method allows to close the financialyear.
  def financialyears_close
    access :financialyears
    @financialyears = Financialyear.find(:all, :conditions => {:company_id => @current_company.id, :closed => false})
    redirect_to :action => "index" if @financialyears.empty?
   
    @financialyear = Financialyear.find :first
    
    @financialyear_periods = []

    d = @financialyear.started_on
    e = @financialyear.stopped_on
    while d.end_of_month < e
      @financialyear_periods << d.to_s(:attributes)
      d=(d+1).end_of_month
    end
      

    if request.post?
      @financialyear = Financialyear.find_by_id_and_company_id(params[:financialyear][:id], @current_company.id)
      @financialyear.close(Date.today)
      redirect_to :action => "index"
    end 
  end

  
  #
  def financialyears_periods
    @financialyear_periods=[]
    
    @financialyear = Financialyear.find(params[:financialyear_select])
    
    d = @financialyear.started_on
    e = @financialyear.stopped_on
    while d.end_of_month < e
      @financialyear_periods << d.to_s(:attributes)
      d=(d+1).end_of_month
    end
    
    render :text =>options_for_select(@financialyear_periods)
  end


  # This method allows to enter the accountancy records with a form.
  def entries
    session[:records_number] = 5 if session[:records_number].nil?
    journals_list(params) if request.get?
    @records = []
    @record  = JournalRecord.new
    @entry   = Entry.new
    unless session[:journal].nil?
      if request.post?
        @financialyear = Financialyear.find_by_company_id(@current_company.id)
        redirect_to :action => "financialyears_create" unless @financialyear 
        # puts 'a:'+@current_company.inspect
        @record = Journal.find(session[:journal]).create_record(params[:record])
        #puts 'record:'+@record.inspect
        account = Account.find(:first, :conditions=>{:number => params[:account][:number], :company_id => @current_company.id})
        currency = Currency.find(:first, :conditions=>["company_id = ?", @current_company.id])
        @entry = Entry.new(params[:entry].merge({:account_id => account.id, :record_id => @record.id, 
                                                     :currency_id => currency.id, :company_id => @current_company.id}))
        
         
        # @aff = ''
        #         unless @entry.errors.nil?
        #           @entry.errors.each do |attr, msg|
        #             @aff += msg
        #           end
        #         else
        #           @aff += "enregistrement effectué !"
        #         end


        #raise Exception.new 'controller : ' +.errors.inspect.to_s
        @entry.save
        @record.reload        
      end

      @records = Journal.find(session[:journal]).last_records(session[:records_number].to_i)
      @record = JournalRecord.find(:first, :conditions => ["journal_id=? and debit!=credit",session[:journal]], :order=>:id) if @record.balanced
      @record = JournalRecord.new if @record.nil?
      @entry = Entry.new
    end

    if @record.new_record? # or (request.post? and @record.balanced)
      @record.number = @records.size>0 ? @records.first.number.succ : 1
      @record.created_on = @record.printed_on = Date.today
    end

    render :action => "entries.rjs" if request.xhr?    
  end
  

  # lists all the transactions established on the accounts, sorted by date.
  def journals
    journals_list params
  end

  #this method creates a journal with a form. 
  def journals_create
    access :journals
    if request.post?
      @journal = Journal.new(params[:journal])
      @journal.company_id = @current_company.id
      redirect_to :action => "journals" if @journal.save
    else
      @journal = Journal.new
    end
    render_form
  end

 #this method updates a journal with a form. 
  def journals_update
    access :journals
    @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id)  
    
    if request.post? or request.put?
      @journal.update_attributes(params[:journal]) 
      redirect_to :action => "journals" 
    end
    render_form
  end

  # this action deletes or hides an existing journal.
  def journals_delete
    if request.post? or request.delete?
      @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id)  
      if @journal.periods.size > 0
        @journal.update_attribute(:deleted, true)
      else
        Journal.delete(@journal)
      end
    end
    redirect_to :action => "journals"
  end
 

   # This method allows to close the journal.
  def journals_close
    access :journals
   
    @journal_periods = []
    if request.get?
     
      if params[:id]  
        @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id) 
        @journals = @current_company.journals 
      else
        @journals = @current_company.journals 
        redirect_to :action => "index" if @journals.empty?
        @journal=Journal.find :first
      end
     
      if @journal
        d = @journal.closed_on
        while (d+1).end_of_month < Date.today
          d=(d+1).end_of_month
          @journal_periods << d.to_s(:attributes)
        end
      end
      
    elsif request.post?
        
      @journal = Journal.find_by_id_and_company_id(params[:journal][:id], @current_company.id) # if params[:journal][:id]
     
      #if @journal.nil?
       # flash[:error] = lc(:unavailable_journal)
       # redirect_to :back
      #end
      
       @journal.close(params[:journal][:closed_on])
         # redirect_to :action => "journals"
      redirect_to session[:history][2]
      #render :inline => "modifie"
      #end
       
    end
   
  end
  
  #
  def journals_periods
    @journal_periods=[]
    
    @journal = Journal.find(params[:journal_select])
   
    d = @journal.closed_on
    while (d+1).end_of_month < Date.today
      d=(d+1).end_of_month
      @journal_periods << d.to_s(:attributes)
    end
    render :text =>options_for_select(@journal_periods)
  end

  #
  def print
    render :action => 'print'
  end
  
  # This method prints the balance.
  def print_balance_sheet
    render :action => 'print_balance_sheet'
    if request.post?
      render(:xil=>'/home/thibaud/ekylibre2/trunk/ekylibre/app/test.xml')
    end  
  end
  
  #
  def print_journal
    render :action => 'print_journal'
    if request.post?
      render(:xil=>'/home/thibaud/ekylibre2/trunk/ekylibre/app/journal.xml')
    end
  end
  
  #
  def print_balance
    #raise Exception.new  " test"
    render :action => 'print_balance'
    #raise Exception.new date + " test"
    #raise Exception.new @current_company.id
    # raise Exception.new [:test][:current_company]
    if request.post?
      date = params[:test][:date]
      year = date.to_i
      params[:test][:year_begin] = Date.new(year,01,01)
      params[:test][:year_end] = Date.new(year,12,31)
      params[:test][:current_company] = @current_company.id.to_s
      #raise Exception.new params[:test][:financial_id].class.to_s
      render(:xil=>'/home/thibaud/ekylibre2/trunk/ekylibre/app/balance.xml',:locals=>params[:test])
    end
  end
  

  # lists all the statements in details for a precise account.
  def statements  
    bank_account_statements_list params if request.get?
    session[:bank_account] = params[:id] 
  end


  # This method creates a statement.
  def statements_create
    access :statements
    
    if request.post?
      @statement = BankAccountStatement.new(params[:statement])
      @statement.bank_account_id = session[:bank_account]
      @statement.company_id = @current_company.id
      redirect_to :action => "statements_point", :id => @statement.id if @statement.save
    else
      @statement = BankAccountStatement.new
    end
   render_form 
  end

    
  # This method updates a statement.
  def statements_update
    access :statements
    @statement = BankAccountStatement.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      @statement.update_attributes(params[:statement]) 
      redirect_to :action => "statements" 
    end
    render_form
  end
 

  # This method deletes a statement.
  def statements_delete
    if request.post? or request.delete?
        @statement = BankAccountStatement.find_by_id_and_company_id(params[:id], @current_company.id)  
        BankAccountStatement.delete @statement
        redirect_to :action=>"statements"
    end
  end

  
  # This method displays the list of entries recording to the accountancing account associated to the bank account.
  def statements_point
    session[:statement] = params[:id]  if request.get? 
  
    @bank_account=BankAccount.find(session[:bank_account])
    @entries=Entry.find(:all, :conditions => {:account_id => @bank_account.account_id, :company_id => @current_company.id}, :order => "id ASC")   
     @bank_account_statement=BankAccountStatement.find(session[:statement])

    
    if request.xhr?
      entry=Entry.find(params[:id]) 
      unless  entry.statement_id
        entry.update_attribute("statement_id", session[:statement])
        @bank_account_statement.credit += entry.debit
        @bank_account_statement.debit  += entry.credit
        @bank_account_statement.save
      end
      render :action => "statements.rjs" 
    end


  end
   
    


end


