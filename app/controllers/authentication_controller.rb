# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
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

require "digest/sha2"

class AuthenticationController < ApplicationController

  before_filter :companize

  def index
    redirect_to :action=>:login
  end
  
  def login
    ActiveRecord::SessionStore::Session.delete_all(["updated_at <= ?", Date.today-1.month])
    if request.post?
      if user = User.authenticate(params[:name], params[:password], @current_company)
        init_session(user)
        unless session[:user_id].blank?
          # redirect_to (session[:last_url]||{:controller=>:company, :action=>:index}).merge(:company=>params[:company])
          redirect_to params[:url]||{:controller=>:company, :action=>:index, :company=>user.company.code}
        end
      elsif User.count(:conditions=>{:name=>params[:name]}) > 1
        @users = User.find(:all, :conditions=>{:name=>params[:name]}, :joins=>"JOIN #{Company.table_name} AS companies ON (companies.id=company_id)",  :order=>"companies.name")
        notify(:need_company_code_to_login, :warning, :now)
      else
        notify(:no_authenticated, :error, :now)
      end
    else
      if params[:locale].blank?
        if request.env["HTTP_ACCEPT_LANGUAGE"].blank?
          params[:locale] = ::I18n.default_locale
        else
          codes = {}
          for l in ::I18n.active_locales
            codes[::I18n.translate("i18n.iso2", :locale=>l).to_s] = l
          end
          params[:locale] = codes[request.env["HTTP_ACCEPT_LANGUAGE"].to_s.split(/[\,\;]+/).select{|x| !x.match(/^q\=/)}.detect{|x| codes[x[0..1]]}[0..1]]
        end
      end
      ::I18n.locale = params[:locale]
      session[:side] = false
      session[:help] = false
    end
  end

  def relogin
    if request.post?
      if user = User.authenticate(params[:name], params[:password], @current_company)
        session[:last_query] = Time.now.to_i # Reactivate session
        render :json=>{:dialog=>params[:dialog]}
        return
      else
        @no_authenticated = true
        notify(:no_authenticated, :error, :now)
      end
    end
    render :action=>:relogin, :layout=>false
  end

  def register
    if request.post?
      @company = Company.new(params[:company])
      @user = User.new(params[:user].merge(:company_id=>0, :role_id=>0, :language=>'fra'))

      if defined?(Ekylibre::DONT_REGISTER)
        hash = Digest::SHA256.hexdigest(params[:register_password].to_s)
        redirect_to :action=>:login unless defined?(Ekylibre::DONT_REGISTER_PASSWORD)
        redirect_to :action=>:login if hash!=Ekylibre::DONT_REGISTER_PASSWORD
        return
      end
      
      # Test validity
      return unless @company.valid? and @user.valid?

      @company, @user = Company.create_with_data(params[:company], params[:user], params[:demo])
      if @company.id and @user.id
        init_session(@user)
        redirect_to :controller=>:company, :action=>:welcome, :company=>@company.code
      end      
    else
      reset_session
      if params[:company]
        redirect_to :company=>nil 
        return
      end
      @company = Company.new
      @user = User.new
    end
  end
  
  def logout
    session[:user_id] = nil    
    session[:last_controller] = nil
    session[:last_action] = nil
    reset_session
    redirect_to :action=>:login, :company=>params[:company]
  end
  

  protected
  
  def init_session(user)
    session[:expiration]   = 3600*5
    session[:help]         = user.preference("interface.help.opened", true, :boolean).value
    session[:help_history] = []
    session[:history]      = []
    session[:last_page]    = {}
    session[:last_query]   = Time.now.to_i
    session[:rights]       = user.rights.to_s.split(" ").collect{|x| x.to_sym}
    session[:side]         = true
    session[:user_id]      = user.id
  end

  def companize()
    if params[:company].is_a? String
      @current_company = Company.find_by_code(params[:company])
      unless @current_company
        notify(:unknown_company, :error) unless params[:company].blank?
        redirect_to :action=>:login, :company=>nil
      end
    end
  end

end
