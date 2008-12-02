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

  dyta(:accounts, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :number
    t.column :name
  end

  dyta(:entries, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :number, :through=>:record
    t.column :created_at, :through=>:record
    t.column :printed_on, :through=>:record
    t.column :name, :through=>:account
    t.column :number, :through=>:account
    t.column :debit
    t.column :credit
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
    #entries_list params
    @entries = Entry.find(:all)

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

end
