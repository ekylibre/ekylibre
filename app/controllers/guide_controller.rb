class GuideController < ApplicationController
 
  def index
  end

  def welcome
    redirect_to :action=>:index
  end

  def about_us
  end

end
