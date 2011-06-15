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

class CompaniesController < ApplicationController


  
  def register
    if request.post?
      @my_company = Company.new(params[:my_company])
      @user = User.new(params[:user].merge(:company_id=>0, :role_id=>0, :language=>'fra'))

      if defined?(Ekylibre::DONT_REGISTER)
        hash = Digest::SHA256.hexdigest(params[:register_password].to_s)
        redirect_to :action=>:login unless defined?(Ekylibre::DONT_REGISTER_PASSWORD)
        redirect_to :action=>:login if hash!=Ekylibre::DONT_REGISTER_PASSWORD
        return
      end
      
      # Test validity
      return unless @my_company.valid? and @user.valid?

      @my_company, @user = Company.create_with_data(params[:my_company], params[:user], params[:demo])
      if @my_company.id and @user.id
        init_session(@user)
        redirect_to :controller=>:dashboards, :action=>:welcome, :company=>@my_company.code
      end      
    else
      reset_session
      if params[:my_company]
        redirect_to :company=>nil, :locale=>params[:locale]
        return
      end
      @my_company = Company.new
      @user = User.new
    end
  end

end
