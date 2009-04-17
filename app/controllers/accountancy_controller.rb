class AccountancyController < ApplicationController
  include ActionView::Helpers::FormOptionsHelper
  
  dyta(:journals, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :closed_on
    t.action :journals_update, :image=>:update
    t.action :journals_delete, :method=>:post, :image=>:delete, :confirm=>:are_you_sure
    t.action :journals_close
    t.action :entries_consult, :image=>:table
    t.procedure :create, :action=>:journals_create
  end
  
  dyta(:accounts, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :number
    t.column :name
    t.action :accounts_update, :image=>:update
    t.action :accounts_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :create, :action=>:accounts_create
  end
  
  dyta(:bank_accounts, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :iban_label
    t.action :bank_accounts_update, :image=>:update
    t.action :bank_accounts_delete, :method=>:post, :image=>:delete, :confirm=>:are_you_sure
    t.action :statements_point    
    t.procedure :create, :action=>:bank_accounts_create
  end
  
  dyta(:bank_account_statements, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :started_on
    t.column :stopped_on
    t.column :number
    t.action :statements_update, :image=>:update
    t.action :statements_delete, :method=>:post, :image=>:delete, :confirm=>:are_you_sure
    t.action :statements_display
    t.procedure :create, :action=>:statements_create
  end
  
  dyta(:entries, :conditions=>:entries_conditions, :joins=>"INNER JOIN journal_records r ON r.id = entries.record_id INNER JOIN journal_periods p ON p.id=r.period_id") do |t|
    t.column :number, :label=>"Numéro", :through=>:record
    t.column :created_on, :label=>"Crée le", :through=>:record
    t.column :printed_on, :label=>"Saisie le", :through=>:record
    t.column :name
    t.column :number, :label=>"Compte" , :through=>:account
    t.column :debit
    t.column :credit
  end
  
  dyta(:financialyears, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :code
    t.column :closed
    t.column :started_on
    t.column :stopped_on
    t.action :financialyears_update, :image=>:update
    t.action :financialyears_delete, :method=>:post, :image=>:delete, :confirm=>:are_you_sure
    t.procedure :create, :action=>:financialyears_create
  end

  dyli(:account_search, :attributes=>[:number, :name], :conditions=>{:company_id=>['@current_company.id']}, :model=>:account)


  #
  def index
    
  end

  # lists all the bank_accounts with the mainly characteristics. 
  def bank_accounts
    bank_accounts_list params
  end

  # this method creates a bank_account with a form.
  def bank_accounts_create
    access :bank_accounts
    if request.post? 
      #puts 'param:'+params[:bank_account].to_s 
      @bank_account = BankAccount.new(params[:bank_account])
      @bank_account.company_id = @current_company.id
      #puts 'BA:'+@bank_account.inspect
      redirect_to_back if @bank_account.save
    else
      @bank_account = BankAccount.new
      @valid_account = @current_company.accounts.empty?
      @valid_journal = @current_company.journals.empty?  
    end
    render_form
  end

  # this method updates a bank_account with a form.
  def bank_accounts_update
    access :bank_accounts
    @bank_account = BankAccount.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      if @bank_account.update_attributes(params[:bank_account])
        redirect_to :action => "bank_accounts"
      end
    end
    render_form
  end
  
  # this method deletes a bank_account.
  def bank_accounts_delete
    if request.post? or request.delete?
      @bank_account = BankAccount.find_by_id_and_company_id(params[:id], @current_company.id)  
      if @bank_account.statements.size > 0
        @bank_account.update_attribute(:deleted, true)
      else
        BankAccount.delete @bank_account
      end
    end
    redirect_to :action => "bank_accounts"
  end

  # lists all the accounts with the credit, the debit and the balance for each of them.
  def accounts
    accounts_list 'sort'=>"number", 'dir'=>'asc'
  end
  
  
  # this action creates an account with a form.
  def accounts_create
    access :accounts
    if request.post?
      @account = Account.new(params[:account])
      @account.company_id = @current_company.id
      redirect_to_back if @account.save
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
      params[:account].delete :number
      redirect_to_back if @account.update_attributes(params[:account])
    end
    @title = {:value=>@account.label}
    render_form
  end


  # this action deletes or hides an existing account.
  def accounts_delete
    if request.post? or request.delete?
      @account = Account.find_by_id_and_company_id(params[:id], @current_company.id)  
      Account.destroy(@account.id) unless @account.entries.size > 0 or @account.balances.size > 0
    end
    redirect_to_current
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

  PRINTS=[[:balance,{:partial=>"date_to_date",:ex=>"ex"}],
          [:general_ledger,{:partial=>"date_to_date"}],
          [:journal_by_id,{:partial=>"by_journal"}],
          [:journal,{:partial=>"date_to_date"}]]
  #[:balance_sheet,{:partial=>"by_financial_year"}],
  #[:income_statements,{:partial=>"by_financial_year"}]]
  
  def document_prepare
    @prints = PRINTS
    if request.post?
      session[:mode] = params[:print][:mode]
      redirect_to :action=>:document_print
    end
  end
  
  def document_print
    for print in PRINTS
      @print = print if print[0].to_s == session[:mode]
    end
    @partial = 'print_'+@print[1][:partial]
    @begin = Date.today.year.to_s+"-"+"01-01"
    @end = Date.today.year.to_s+"-12-31"
    if request.post? 
      if session[:mode] == "income_statements"
        @financialyear = Financialyear.find_by_id_and_company_id(params[:printed][:id], @current_company.id)
        params[:printed][:name] = @financialyear.code
        params[:printed][:from] = @financialyear.started_on
        params[:printed][:to] = @financialyear.stopped_on
      end
      params[:printed][:name] = Journal.find_by_id_and_company_id(params[:printed][:name], @current_company.id).name if session[:mode] == "journal_by_id"
      params[:printed][:current_company] = @current_company.id
      params[:printed][:siren] = @current_company.siren.to_s
      params[:printed][:company_name] = @current_company.name.to_s
      render(:xil=>"#{RAILS_ROOT}/app/views/prints/#{@print[0].to_s}.xml",:locals=>params[:printed])
    end
    #params[:printed][:from] = Date.today
    @title = {:value=>t("views.#{self.controller_name}.document_prepare.#{@print[0].to_s}")}
  end

  def order_sale
    #render(:xil=>"#{RAILS_ROOT}/app/views/prints/sale_order.xml",:locals=>params[:printed])
    render(:xil=>"#{RAILS_ROOT}/app/views/prints/sale_order.xml",:key=>params[:id])
    ##
  end
  
  # this method finds the journal with the matching id and the company_id.
  def journals_find
    @find_journals = @current_company.journals #Journal.find(:all,:conditions=>["company_id = ?", @current_company.id])
    render :partial => 'journals_find'
  end
  
  # this method finds the currency with the matching id and the company_id.
  def currencies_find
    @find_currencies = @current_company.currencies #Currency.find(:all,:conditions=>["company_id = ?", @current_company.id])
    render :partial => 'currencies_find'
  end
  

  # this method finds the account with the matching number and the company_id.
  def accounts_find
    if request.xhr?
      @search = params[:account].gsub('*','%')
      @accounts = @current_company.accounts.find(:all,:conditions=>["number LIKE ?", @search])
      render :partial => 'accounts_find'
    else
      redirect_to_back
    end
  end
  

  # lists all the bank_accounts with the mainly characteristics. 
  def financialyears
    financialyears_list params
  end
  
  # this action creates a financialyear with a form.
  def financialyears_create
    access :financialyears
    
    if request.post? 
      @financialyear = Financialyear.new(params[:financialyear])
      @financialyear.company_id = @current_company.id
      redirect_to_back if @financialyear.save
    else
      @financialyear = Financialyear.new
      f = @current_company.financialyears.find(:first, :order=>"stopped_on DESC")
      
      @financialyear.started_on = f.stopped_on+1.day unless f.nil?
      @financialyear.started_on ||= Date.today
      @financialyear.stopped_on = (@financialyear.started_on+1.year-1.day).end_of_month
      @financialyear.written_on = (@financialyear.stopped_on+6.months).end_of_month
      @financialyear.code = @financialyear.started_on.year.to_s
      @financialyear.code += '/'+@financialyear.stopped_on.year.to_s if @financialyear.started_on.year!=@financialyear.stopped_on.year
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

      Financialyear.destroy @financialyear unless @financialyear.periods.size > 0 
    end
    redirect_to :action => "financialyears"
  end
  
  # This method allows to close the financialyear.
  def financialyears_close
    access :financialyears
    @financialyears = Financialyear.find(:all, :conditions => {:company_id => @current_company.id, :closed => false})
    if @financialyears.empty? 
      flash[:message]=tc(:create_financialyear_before_close)
      redirect_to :action => :financialyears_create
    end
    @financialyear = Financialyear.find :first
    if request.post?
      @financialyear= Financialyear.find_by_id_and_company_id(params[:financialyear][:id], @current_company.id)  
      
      if @financialyear.close(params[:financialyear][:stopped_on])
        redirect_to session[:history][1]
      end
    else
      if @financialyear
        @financialyear_periods = []
        d = @financialyear.started_on
        while (d+1).end_of_month < @financialyear.stopped_on
          d=(d+1).end_of_month
          @financialyear_periods << d.to_s(:attributes)
        end
      end
    end
  end
  
  # 
  def financialyears_periods
    @financialyear_periods=[]
    
    @financialyear = Financialyear.find(params[:financialyear_select])
    
    d = @financialyear.started_on
    
    while (d+1).end_of_month < @financialyear.stopped_on
      d=(d+1).end_of_month
      @financialyear_periods << d.to_s(:attributes)
    end
    render :text => options_for_select(@financialyear_periods)
  end


  #
  def entries_conditions(options)
    conditions = ["entries.company_id=?", @current_company.id]
    unless session[:journal_period][:journal_id].blank?
      journal = @current_company.journals.find(:first, :conditions=>{:id=>session[:journal_period][:journal_id]})
      if journal
        conditions[0] += " AND p.journal_id=?"
        conditions << journal.id
      end
    end
    unless session[:journal_period][:financialyear_id].blank?
      financialyear = @current_company.financialyears.find(:first, :conditions=>{:id=>session[:journal_period][:financialyear_id]||0})
      if financialyear
        conditions[0] += " AND p.financialyear_id=?"
        conditions << financialyear.id
      end
    end
    conditions
  end


  # this action displays all entries stored in the journal. 
  def entries_consult
    session[:journal_period] ||= {}
    session[:journal_period][:journal_id] = params[:id] if params[:id]
    @journal_period = JournalPeriod.new(:journal_id=>params[:id])
    @journals = @current_company.journals
    @financialyears = @current_company.financialyears
    if request.post?
      session[:journal_period] = params[:journal_period]
    end
    entries_list
  end
  

  # this action has not specific view.
  def params_entries
    if request.post?
      session[:entries] ||= {}
      session[:entries][:journal] = params[:journal_id]
      session[:entries][:financialyear] = params[:financialyear_id]
      session[:entries][:records_number] = params[:number]
      redirect_to :action => :entries
    end
  end
  
  # This method allows to enter the accountancy records with a form.
  def entries
    session[:entries] ||= {}
    session[:entries][:records_number] ||= 5
    @records=[]
    @journal = find_and_check(:journal, session[:entries][:journal]) if session[:entries][:journal]
    @financialyear = find_and_check(:financialyear, session[:entries][:financialyear]) if session[:entries][:financialyear]

    @valid = (not @journal.nil? and not @financialyear.nil?)

    @journals = @current_company.journals.find(:all, :order=>:name)
    @financialyears = @current_company.financialyears.find(:all, :conditions => {:closed => false}, :order=>:code)
    
    unless @financialyears.size>0
      flash[:message] = tc('messages.need_financialyear_to_record_entries')
      redirect_to :action=>:financialyears_create
      return
    end

    unless @journals.size>0
      flash[:message] = tc('messages.need_journal_to_record_entries')
      redirect_to :action=>:journals_create
      return
    end
    
    if @valid
      @record = JournalRecord.new
      if request.post?
        # session[:entries][:account_number] = params[:account][:search].split(',')[0]
        @period = @journal.periods.find(:first, :conditions=>['company_id = ? AND financialyear_id = ? AND CAST(? AS DATE) BETWEEN started_on AND stopped_on', @current_company.id, @financialyear.id, params[:record][:created_on] ])
        if @period.nil?
          @period = @journal.periods.create(:company_id=>@current_company.id, :financialyear_id=>@financialyear.id, :started_on=>params[:record][:created_on]) 
          #raise Exception.new({:company_id=>@current_company, :financialyear_id=>@financialyear, :started_on=>params[:record][:created_on]}.inspect)
          #raise Exception.new(@period.inspect)
          @period.save
        end
        
        @record = JournalRecord.find(:first,:conditions=>{:period_id => @period.id, :number => params[:record][:number]})
        @record = @period.records.build(params[:record].merge({:period_id=>@period.id, :company_id=>@current_company.id, :journal_id=>@journal.id})) if @record.nil?
        
        @entry = @current_company.entries.build(params[:entry])
        
        if @record.save
          @entry.record_id = @record.id
          @entry.currency_id = @journal.currency_id
          if @entry.save
            @record.reload
            @entry  = Entry.new
            # session[:entries][:account_number] = ''
          end
        end
  #      raise Exception.new('>>>>>>>>>>>>>>>>>>>>>>>>>>>                  : '+@record.errors.inspect)
     

      elsif request.delete?
        @entry = Entry.find_by_id_and_company_id(params[:id], @current_company.id)  
        if @entry.close?
          flash[:message]=tc(:messages, :need_unclosed_entry_to_delete)
        else
          Entry.delete(@entry)
        end
        @entry = Entry.new 
      else
        @entry = Entry.new 
      end
     
      #  raise Exception.new('>>>>>>>>>>>>>>>>>>>>>>>>>>>voila: '+@record.errors.inspect)
      #      periods = @journal.periods.find(:all,:conditions=>['financialyear_id=?',session[:entries][:financialyear]])
      #      periods.each do |period|
      #        @records += @journal.last_records(period, session[:entries][:records_number].to_i)
      #      end  
      @records = @journal.records.find(:all, :order=>"created_on DESC", :limit=>session[:entries][:records_number].to_i)
     
      #   raise Exception.new('>>>>>>>>>>>>>>>>>>>>>>>>>>>oui: '+@record.errors.inspect)
      
      # raise Exception.new('oui: '+@record.errors.inspect)
      #unless @record.errors
      #raise Exception.new('oui')
      
      @record = @journal.records.find(:first, :conditions => ["debit!=credit OR (debit=0 AND credit=0)"], :order=>:id) if @record.balanced or @record.new_record?
      #  puts('>>>>>>>>>>>>>>>>>>>>>>>>>>>oui2: '+@record.errors.inspect)
      # raise Exception.new('>>>>>>>>>>>>>>>>>>>>>>>>>>>oui2: '+@record.errors.inspect)
      unless @record.nil?
        #raise Exception.new('oui')
        if (@record.balance > 0) 
          @entry.currency_credit=@record.balance.abs 
        else
          @entry.currency_debit=@record.balance.abs  
        end
      end
      
      @record = JournalRecord.new(params[:record]) if @record.nil?
      #raise Exception.new('ouif: '+@record.errors.inspect)
      if @record.new_record? and not @record.errors
        @record.number = @records.size>0 ? @records.first.number.succ : 1
        @record.created_on ||= @record.printed_on ||= Date.today
        #raise Exception.new('ouif2: '+@record.errors.inspect)
      end
      #end
      # raise Exception.new('oui')
      # @record.errors.add_to_base('kmk')
      # raise Exception.new('ouifi: '+@record.inspect+' :  '+@record.errors.inspect+'<< et >> '+@entry.inspect+' :  '+@entry.errors.inspect)
      
      render :action => "entries.rjs" if request.xhr?
    
    end
    
  end

  # this method updates an entry with a form.
  def entries_update
    access :entries
    @entry = Entry.find_by_id_and_company_id(params[:id], @current_company.id)  
    
    if request.post? or request.put?
      @entry.update_attributes(params[:entry]) 
      redirect_to :action => "entries" 
    end
    render_form
  end

  # this method deletes an entry with a form.
  def entries_delete
    
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
      redirect_to_back if @journal.save
    else
      @journal = Journal.new
      @journal.nature = Journal.natures[0][1]
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
        flash[:message]=tc(:messages, :need_empty_journal_to_delete)
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
    @journals= @current_company.journals 
    if @journals.empty?
      flash[:message]=tc(:create_journal_before_close)
      redirect_to :action => :journals_create
    end
    if params[:id]  
      @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id) 
    else
      @journal = Journal.find :first
    end
    if @journal
      d = @journal.closed_on
      while (d+1).end_of_month < Date.today
        d=(d+1).end_of_month
        @journal_periods << d.to_s(:attributes)
      end
    end
    if request.post?
      @journal = Journal.find_by_id_and_company_id(params[:journal][:id], @current_company.id)
      
      if @journal.nil?
        flash[:error] = tc(:unavailable_journal)
      end  
      
      if @journal.close(params[:journal][:closed_on])
        redirect_to_back
      end
    end
  end

  # This method allows to build the table of the periods.
  def journals_periods
    @journal_periods=[]
    @journal = Journal.find(params[:journal_select])
    d = @journal.closed_on
    while (d+1).end_of_month < Date.today
      d=(d+1).end_of_month
      @journal_periods << d.to_s(:attributes)
    end
    render :text => options_for_select(@journal_periods) 
  end

  # lists all the statements in details for a precise account.
  def statements  
    bank_account_statements_list params
    @valid = @current_company.bank_accounts.empty?
  end

  # This method creates a statement.
  def statements_create
    access :statements
    @bank_accounts = @current_company.bank_accounts  
    if request.post?
      @statement = BankAccountStatement.new(params[:statement])
      @statement.bank_account_id = params[:statement][:bank_account_id]
      @statement.company_id = @current_company.id
      if BankAccount.find_by_id_and_company_id(params[:statement][:bank_account_id], @current_company.id).account.entries.find(:all, :conditions => "statement_id is NULL").size.zero?
        flash[:message]=tc('messages.no_entries_pointable_for_bank_account')
      else  
        redirect_to :action => "statements_point", :id => @statement.id if @statement.save
      end
    else
      @statement = BankAccountStatement.new
    end
    render_form 
  end


  # This method updates a statement.
  def statements_update
    access :statements
    @bank_accounts = BankAccount.find(:all,:conditions=>"company_id = "+@current_company.id.to_s)  
    @statement = BankAccountStatement.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      @statement.update_attributes(params[:statement]) 
      redirect_to :action => "statements_point", :id => @statement.id if @statement.save 
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


  # This method displays the list of entries recording to the bank account for the given statement.
  def statements_point
    session[:statement] = params[:id]  if request.get? 
    @bank_account_statement=BankAccountStatement.find(session[:statement])
    @bank_account=BankAccount.find(@bank_account_statement.bank_account_id)
    
    @entries=@current_company.entries.find(:all, :conditions => {:account_id => @bank_account.account_id, :editable => true}, :joins => "INNER JOIN journal_records j ON j.id = entries.record_id", :order => "statement_id DESC")

    if request.xhr?
      
      @entry=Entry.find(params[:id]) 

      if @entry.statement_id.eql? session[:statement].to_i
        
        @entry.update_attribute("statement_id", nil)
        @bank_account_statement.credit -= @entry.debit
        @bank_account_statement.debit  -= @entry.credit
        @bank_account_statement.save
        
      elsif @entry.statement_id.nil?
        @entry.update_attribute("statement_id", session[:statement])
        @bank_account_statement.credit += @entry.debit
        @bank_account_statement.debit  += @entry.credit
        @bank_account_statement.save
        
      else
        @entry.statement.debit  -= @entry.credit
        @entry.statement.credit -= @entry.debit
        @entry.statement.save
        @entry.update_attribute("statement_id", nil)
      end
      
      render :action => "statements.rjs" 
      
    end
    @title = {:value => @bank_account_statement.number}
  end

  # displays in details the statement choosen with its mainly characteristics.
  def statements_display
    @bank_account_statement = BankAccountStatement.find(params[:id])
  end

end


