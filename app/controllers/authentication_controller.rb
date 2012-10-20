# encoding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier
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

class AuthenticationController < BaseController
  layout "authentication"

  # TODO Run callback for future uses?

  def initialize_session(user)
    reset_session
    session[:expiration]   = 3600*5
    session[:history]      = []
    session[:last_page]    = {}
    session[:last_query]   = Time.now.to_i
    session[:rights]       = user.rights.to_s.split(" ").collect{|x| x.to_sym}.freeze
    session[:side]         = true
    session[:view_mode]    = user.preference("interface.general.view_mode", "printable", :string).value
    session[:user_id]      = user.id
    # Loads modules preferences
    session[:modules]      = {}
    show_modules = "interface.show_modules."
    for preference in user.preferences.where("name LIKE ?", "#{show_modules}%")
      session[:modules][preference.name[show_modules.length..-1]] = preference.value
    end
    # Build and cache customized menu for all the session
    session[:menus] = ActiveSupport::OrderedHash.new
    for menu, submenus in Ekylibre.menus
      fsubmenus = ActiveSupport::OrderedHash.new
      for submenu, menuitems in submenus
        fmenuitems = menuitems.collect do |url|
          if user.authorization(url[:controller], url[:action], session[:rights]).nil?
            url.merge(:url=>url_for(url))
          else
            nil
          end
        end.compact
        fsubmenus[submenu] = fmenuitems unless fmenuitems.size.zero?
      end
      session[:menus][menu] = fsubmenus unless fsubmenus.keys.size.zero?
    end
  end

end
