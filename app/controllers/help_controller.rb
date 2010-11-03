# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class HelpController < ApplicationController
  include ActionView::Helpers::TagHelper
     
  def close   
    session[:help]=false
    session[:help_history] = []
    @current_user.preference("interface.help.opened", true, :boolean).set session[:help]
    render :text=>''
  end
  
  def search
    help_search(params[:article])
    @current_user.preference("interface.help.opened", true, :boolean).set session[:help]
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
   
