class GuideController < ApplicationController
 
  def index
    @title = {:user=>@current_user.label}
  end

  def welcome
    redirect_to :action=>:index
  end

  def unknown_action
    flash[:error] = tc(:unknown_action)
    redirect_to :action=>:index
  end
  
  def about_us
  end

end
