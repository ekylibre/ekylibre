require 'rails/info'
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
    flash[:error] = tc(:unknown_action, :value=>request.url.inspect)
    redirect_to :action=>:index
  end
  
  def about_us
    File.open("#{RAILS_ROOT}/VERSION") {|f| @version = f.read.split(',')}
    @properties = Rails::Info.properties
    @properties.reverse!
    @properties.insert(0, ["Ekylibre version", @version.reverse.join(' / ')])
  end

end
