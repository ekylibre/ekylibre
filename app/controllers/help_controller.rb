class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper
     
  def close   
    session[:help]=false
    session[:help_history] = []
    render :text=>''
  end
  
  def search
    help_search(params[:article])
    render :partial=>'search'
  end

  def previous
    s = session[:help_history].size
    if s>1
      @article = session[:help_history][s-2]
      session[:help_history].delete_at(s-1)
    else
      @article = session[:help_history][0]
    end    
    render :partial=>'search'
  end

  def side
    session[:side] = false if session[:side].nil?
    session[:side] = !session[:side] # (params[:operation]=='open')
    render :text=>''
  end

end
   
