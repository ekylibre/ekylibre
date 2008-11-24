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
  end
  
  def entries
    entries = Entrie.find(:all)
    entries.each do |entrie|
    end    
  end
    
  
  # lists all the transactions established on the accounts, sorted by date.
  def journals
    
    begin
      journals = JournalPeriod.find(:all, :conditions=>["started_on = ?", params[:period] ])
      
      journals.each do |j|
        journal = Journal.find(:first, :conditions=>["id = ? AND nature_id = ?", j.id, params[:type_journal] ])
        journal_id = j.id
        end
      
    rescue
      raise Exception.new("No records matching has been found in the database.")
    end
    
    Journal.journal(journal_id, params[:type_journal], params[:period])

  end
  #    journals_list params
  #    @journals = @current_company.journals



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
