# encoding: utf-8
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_theme
  before_action :set_locale
  before_action :set_time_zone

  rescue_from PG::UndefinedTable, Apartment::SchemaNotFound, with: :configure_application

  hide_action :current_theme, :current_theme=, :human_action_name, :authorized?

  attr_accessor :current_theme


  # # Permits to redirect
  # def after_sign_in_path_for(resource)
  #   backend_root_url(:locale => params[:locale])
  # end

  def self.human_name
    raise "DEPRECATED"
    ::I18n.translate("controllers." + self.controller_path)
  end

  def self.human_action_name(action, options = {})
    options = {} unless options.is_a?(Hash)
    root, action = "actions." + self.controller_path + ".", action.to_s
    options[:default] ||= []
    if action == "create" and !options[:default].include? (root + "new").to_sym
      options[:default] << (root + "new").to_sym
    elsif action == "update" and !options[:default].include? (root + "edit").to_sym
      options[:default] << (root + "edit").to_sym
    end
    klass = self.superclass
    while klass != ApplicationController do
      default = "actions.#{klass.controller_path}.#{action}".to_sym
      options[:default] << default unless options[:default].include?(default)
      klass = klass.superclass
    end
    return ::I18n.translate(root + action, options)
  end

  def human_action_name
    return self.class.human_action_name(action_name, @title)
  end

  def authorized?(url_options = {})
    return true if url_options == "#" or current_user.administrator?
    if url_options.is_a?(Hash)
      url_options[:controller] ||= self.controller_path
      url_options[:action] ||= :index
    elsif url_options.is_a?(String) and url_options.match(/\#/)
      action = url_options.split("#")
      url_options = {:controller => action[0].to_sym, :action => action[1].to_sym}
    else
      raise ArgumentError, "Invalid URL: " + url_options.inspect
    end
    if current_user
      return current_user.can_access?(url_options)
      # if url_options[:controller].blank? or url_options[:action].blank?
      #   raise ArgumentError, "Uncheckable URL: " + url_options.inspect
      # end
      # return current_user.authorization(url_options[:controller], url_options[:action], session[:rights]).nil?
    else
      true
    end
  end

  protected

  def set_theme
    @current_theme = 'tekyla'
  end

  # Initialize locale with params[:locale] or HTTP_ACCEPT_LANGUAGE
  def set_locale
    session[:locale] = params[:locale] if params[:locale]
    if session[:locale].blank?
      if locale = http_accept_language.compatible_language_from(Ekylibre::HTTP_LANGUAGES.keys)
        session[:locale] = Ekylibre::HTTP_LANGUAGES[locale]
      end
    else
      session[:locale] = nil unless ::I18n.available_locales.include?(session[:locale].to_sym)
    end
    if ::I18n.available_locales.include?(Preference[:language])
      session[:locale] ||= Preference[:language]
    end
    session[:locale] ||= I18n.default_locale
    I18n.locale = session[:locale]
  end

  # Change the time zone from the given params or reuse session variable
  def set_time_zone
    if params[:time_zone]
      session[:time_zone] = params[:time_zone]
    end
    session[:time_zone] ||= "UTC"
    Time.zone = session[:time_zone]
  end


  def configure_application(exception)
    title = exception.class.name.underscore.t(scope: "exceptions")
    render "/public/configure_application", layout: "exception", locals: {title: title, message: exception.message, class_name: exception.class.name}, status: 500
  end

end
