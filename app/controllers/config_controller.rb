class ConfigController < ApplicationController

  def company
    @company = @current_company
    @establishments = @company.establishments
    @departments = @company.departments
    @users = @company.users
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
  
  def users_create
    access :users
    if request.post?
      @user = User.new(params[:article])
      @user.company_id = session[:company_id]
      redirect_to session[:url][1] if @user.save
    else
      @user = User.new
    end
    render_form
 	end

end
