# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

class CompaniesController < AdminController

  def register
    if request.post?
      language = (params[:locale].blank? ? I18n.locale||I18n.default_locale : params[:locale])
      @my_company = Company.new(params[:my_company].merge(:language=>language.to_s))
      @user = User.new(params[:user].merge(:company_id=>0, :role_id=>0, :language=>language.to_s))

      if defined?(Ekylibre::DONT_REGISTER)
        hash = Digest::SHA256.hexdigest(params[:register_password].to_s)
        redirect_to_login unless defined?(Ekylibre::DONT_REGISTER_PASSWORD)
        redirect_to_login if hash!=Ekylibre::DONT_REGISTER_PASSWORD
        return
      end
      
      
      # Test validity
      @user.valid? # Perform validations
      return unless @my_company.valid? and @user.errors.to_hash.delete_if{|a,e| [:company, :role].include?(a)}.keys.empty?

      @my_company, @user = Company.create_with_data(params[:my_company], params[:user], params[:demo])
      if @my_company.id and @user.id
        initialize_session(@user)
        redirect_to :controller=>:dashboards, :action=>:welcome
      end      
    else
      if session[:user_id]
        reset_session
        redirect_to :action=>:register
        return
      end
      if params[:my_company]
        redirect_to :company=>nil, :locale=>params[:locale]
        return
      end
      @my_company = Company.new(:currency=>'EUR')
      @user = User.new
    end
  end

end
