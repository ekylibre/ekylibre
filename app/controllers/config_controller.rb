class ConfigController < ApplicationController

  def company
    @company = @current_company
    @establishments = @company.establishments
  end

  def company_edit
    @company = @current_company
    if request.post?
      if @company.update_attributes(params[:company])
        redirect_to :action=>:company
      end
    end
  end

  def user
    render :text=>@current_user.name, :layout=>true
  end

  

end
