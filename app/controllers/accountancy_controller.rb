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
    @accounts = @current_company.accounts
  end
  
  def entries
  end

  def journals
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
