class GuideController < ApplicationController
  # layout :application

  def index
    @title = {:user=>@current_user.label}
    @entities = @current_company.entities
    @deliveries = @current_company.deliveries.find(:all,:conditions=>{:moved_on=>nil})
    @purchases = @current_company.purchase_orders.find(:all, :conditions=>{:moved_on=>nil})
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
