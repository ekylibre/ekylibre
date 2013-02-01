# encoding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier
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

class Authentication::SessionsController < ::Devise::SessionsController

  # def new
  #   if session[:user_id]
  #     reset_session
  #     redirect_to :action=>:new, :redirect=>params[:redirect]
  #     return
  #   end
  #   ActiveRecord::SessionStore::Session.delete_all(["updated_at <= ?", Date.today-1.month])
  # end

  # def create
  #   if user = Entity.authenticate(params[:name], params[:password])
  #     initialize_session(user)
  #     session[:locale] = params[:locale].to_sym unless params[:locale].blank?
  #     unless session[:user_id].blank?
  #       redirect_to params[:redirect] || root_url
  #       return
  #     end
  #   else
  #     notify_error_now(:no_authenticated)
  #   end
  #   render :action => :new
  # end

  # def destroy
  #   reset_session
  #   redirect_to root_url
  # end

  # Permits to renew the session if expired
  def renew
    if request.post?
      if user = Entity.authenticate(params[:name], params[:password])
        session[:last_query] = Time.now.to_i # Reactivate session
        # render :json=>{:dialog=>params[:dialog]}
        head :ok, :x_return_code=>"granted"
        return
      else
        @no_authenticated = true
        response.headers["X-Return-Code"] = "denied"
        notify_error_now(:no_authenticated)
      end
    end
    render :renew, :layout=>false
  end



  # TODO Run callback for future uses?

  # def initialize_session(user)
  #   reset_session
  #   session[:expiration]   = 3600*5
  #   session[:history]      = []
  #   session[:last_page]    = {}
  #   session[:last_query]   = Time.now.to_i
  #   session[:rights]       = user.rights.to_s.split(" ").collect{|x| x.to_sym}.freeze
  #   session[:side]         = true
  #   session[:view_mode]    = user.preference("interface.general.view_mode", "printable", :string).value
  #   session[:user_id]      = user.id
  #   # Loads modules preferences
  #   # session[:modules]      = {}
  #   # show_modules = "interface.show_modules."
  #   # for preference in user.preferences.where("name LIKE ?", "#{show_modules}%")
  #   #   session[:modules][preference.name[show_modules.length..-1]] = preference.value
  #   # end

  #   # Build and cache customized menu for all the session
  #   # TODO: Adds filter method to restrain menu to usable

  #   # session[:menu] = Ekylibre.menu # .filter_with(authorized_actions)

  #   # session[:menus] = ActiveSupport::OrderedHash.new
  #   # for menu, submenus in Ekylibre.menus
  #   #   fsubmenus = ActiveSupport::OrderedHash.new
  #   #   for submenu, menuitems in submenus
  #   #     fmenuitems = menuitems.collect do |url|
  #   #       if true # user.authorization(url[:controller], url[:action], session[:rights]).nil?
  #   #         url.merge(:url=>url_for(url))
  #   #       else
  #   #         nil
  #   #       end
  #   #     end.compact
  #   #     fsubmenus[submenu] = fmenuitems unless fmenuitems.size.zero?
  #   #   end
  #   #   session[:menus][menu] = fsubmenus unless fsubmenus.keys.size.zero?
  #   # end
  # end


end
