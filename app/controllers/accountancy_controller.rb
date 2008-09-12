class AccountancyController < ApplicationController

  def accounts
    @accounts = @current_company.accounts
  end
  
  def entries
  end

  def journals
  end
end
