class AccountancyController < ApplicationController

  def accounts
    @accounts = @current_company.accounts
  end
  
  def entries
  end

  def journals
    @journals = @current_company.journals
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

end
