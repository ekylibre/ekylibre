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
  def params_entries
    session[:journal] = params[:journal][:id]
    session[:records_number] = params[:number]
    redirect_to :action => "entries" 
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
  def convert_date(date)
    if date.is_a? Date
      return date.strftime("%e-%m-%Y") 
    else 
      d=date.split('-') 
     # raise Exception.new d.inspect
      return Date.civil(d[0].to_i,d[1].to_i,d[2].to_i) 
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
    render :action => 'print_balance_sheet'
    if request.post?
      render_xil('/home/thibaud/ekylibre2/trunk/ekylibre/app/test.xml')
    end  
  end
  
  def print_journal
    render :action => 'print_journal'
    if request.post?
      render_xil('/home/thibaud/ekylibre2/trunk/ekylibre/app/journal.xml')
    end
  end
  
  def print_balance
    #raise Exception.new  " test"
    render :action => 'print_balance'
    #raise Exception.new date + " test"
    #raise Exception.new @current_company.id
    # raise Exception.new [:test][:current_company]
    if request.post?
      params[:test][:current_company] = @current_company.id
      render_xil('/home/thibaud/ekylibre2/trunk/ekylibre/app/balance.xml',:locals=>params[:test])
    end
  end
  

end


