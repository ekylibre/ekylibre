class AccountancyController < ApplicationController
  #  # groups all the accounts corresponding to a transaction of sale.
  #   ACCOUNTS_OF_SALES={:sale=>70, :tva_collected=>4457, :customer=>[411, 413, 4191], :bank=>[511, 512], :cash=>53 , 
  #     :others=>[654, 661, 665] }
  
  #   # groups all the accounts corresponding to a transaction of purchase.
  #   ACCOUNTS_OF_PURCHASES={:purchase=>[60, 61, 62, 635], :tva_deductible=>[4452, 4456], :supplier=>[401, 403, 4091], 
  #     :bank=>512, :others=>765 }
  
  dyta(:journals, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :closed_on
    t.column :name, :through=>:nature
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
    t.procedure :create, :action=>:statements_new
  end

   dyta(:entries, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :debit
    t.column :credit
    t.column :letter
    t.column :currency_rate
    t.action :statements_point, :method=>:post
  end


  #
  def index
  
  end


  # displays the accoutancing operations.
  def operations
    @bank_accounts = BankAccount.find(:all,:conditions=>"company_id = "+@current_company.id.to_s)  
    @journals = Journal.find(:all, :conditions => {:company_id => @current_company.id})
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


  #
  def print
    render :action => 'print'
  end
  
  # this method finds the journal with the matching id and the company_id.
  def find_journals
    @find_journals = Journal.find(:all,:conditions=>["company_id = ?", @current_company.id])
    render :partial => 'find_journals'
  end
  
  # this method finds the currency with the matching id and the company_id.
  def find_currencies
    @find_currencies = Currency.find(:all,:conditions=>["company_id = ?", @current_company.id])
    render :partial => 'find_currencies'
  end
  

  # this method finds the account with the matching number and the company_id.
  def find_accounts
    @search = params[:account].gsub('*','%')
    @find_accounts = Account.find(:all,:conditions=>["company_id = ? AND number LIKE ?", @current_company.id, @search])
    render :partial => 'find_accounts'
  end
  
  # this method is used to load datas such as accounts, financialyears ... 
  def load_data
   # creation of a financial year.
   # @current_company.accounts.create!(:number=>'6', :name=>'charge', :label=>'charge', :parent_id=>1)
   # @current_company.accounts.create!(:number=>'7', :name=>'produit', :label=>'produit', :parent_id=>2)
   # @current_company.accounts.create!(:number=>'71', :name=>'produit', :label=>'produit1', :parent_id=>2)
    @current_company.financialyears.create!(:code=>'1A2',
                                            :started_on=>Date.civil(2009,01,01), 
                                            :stopped_on=>Date.civil(2009,12,31), 
                                            :written_on=>Date.civil(2009,12,12) )
    @current_company.currencies.create!(:name=>'europeenne', :code=>'Eur', :format=>'euros')

    redirect_to :action => "entries"
  end
 
 
  #
  def entries
    session[:records_number] = 5 if session[:records_number].nil?
    journals_list(params) if request.get?
    @records = []
    @record = JournalRecord.new
    @entry = Entry.new
    unless session[:journal].nil?
      if request.post?
        @record = Journal.find(session[:journal]).create_record(params[:record])
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
  
  # this method converts a date into a new date with a specific format or a string into a date.
  # def convert_date(date)
#     if date.is_a? Date
#       return date.strftime("%e-%m-%Y") 
#     else 
#       d=date.split('-') 
#      # raise Exception.new d.inspect
#       return Date.civil(d[0].to_i,d[1].to_i,d[2].to_i) 
#     end
#   end
  
  
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
     @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id)  
     if request.post?
       @journal.close(params[:journal][:closed_on])
       redirect_to :action => "journals"
     end
     @journal_periods = []
     d = @journal.closed_on
     while (d+1).end_of_month < Date.today
       d=(d+1).end_of_month
       @journal_periods << d
     end
   end
     

  # This method allows to close the financialyear.
  def financialyears_close
    access :financialyears
    #  @financialyear= Financialyear.find_by_id_and_company_id(params[:financialyear][:id], @current_company.id)  
   @financialyears = Financialyear.find(:all, :conditions => {:company_id => @current_company.id, :closed => false})
    if request.post?
      @financialyear.close(Date.today)

    else
      @financialyear= Financialyear.find_by_id_and_company_id(params[:financialyear][:id], @current_company.id)  
      @financialyear_periods = []
      d = @financialyear.started_on
      while (d+1).end_of_month < @financialyear.stopped_on
        d=(d+1).end_of_month
        @financialyear_periods << d
      end
    end
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
  def statements_new
    access :statements
    
    if request.post?
      @statement = BankAccountStatement.new(params[:statement])
      @statement.bank_account_id = session[:bank_account]
      @statement.company_id = @current_company.id
      redirect_to :action => "statements_point" if @statement.save
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
   # if request.get?
    @bank_account = BankAccount.find(session[:bank_account])
    #puts 'ba:'+@bank_account.account_id.to_s
    @entries = Entry.find(:all, :conditions => {:account_id => @bank_account.account_id, :company_id => @current_company.id})  
    puts 'e:'+@entries.inspect
    #entries_list params
   #else
    if request.post?
      params[:entry].each do |id| 
        @bank_account.account.entries << id
      end
    end
    #end
  end
 

  
  
end


