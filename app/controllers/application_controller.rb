# == License
# Ekylibre - Simple agricultural ERP
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

  before_action :set_raven_context if ENV['SENTRY_DSN']

  skip_before_action :verify_authenticity_token, if: :session_controller?

  before_action :set_theme
  before_action :set_locale
  before_action :set_time_zone
  before_action :set_mailer_host
  before_action :check_browser

  rescue_from PG::UndefinedTable, Apartment::TenantNotFound, with: :configure_application

  hide_action :current_theme, :current_theme=, :human_action_name, :authorized?

  attr_accessor :current_theme

  # Permits to redirect
  hide_action :after_sign_in_path_for
  def after_sign_in_path_for(resource)
    if Ekylibre::Plugin.redirect_after_login?
      path = Ekylibre::Plugin.after_login_path(resource)
    end
    path || super
  end

  hide_action :session_controller?
  def session_controller?
    controller_name == 'sessions' && action_name == 'create'
  end

  def self.human_action_name(action, options = {})
    options = {} unless options.is_a?(Hash)
    root = 'actions.' + controller_path + '.'
    action = action.to_s
    options[:default] ||= []
    if action == 'create' && !options[:default].include?((root + 'new').to_sym)
      options[:default] << (root + 'new').to_sym
    elsif action == 'update' && !options[:default].include?((root + 'edit').to_sym)
      options[:default] << (root + 'edit').to_sym
    elsif action == 'update_many' && !options[:default].include?((root + 'edit_many').to_sym)
      options[:default] << (root + 'edit_many').to_sym
    end
    klass = superclass
    while klass != ApplicationController
      default = "actions.#{klass.controller_path}.#{action}".to_sym
      options[:default] << default unless options[:default].include?(default)
      klass = klass.superclass
    end
    ::I18n.translate(root + action, options)
  end

  helper_method :human_action_name
  def human_action_name
    self.class.human_action_name(action_name.to_s, @title)
  end

  def authorized?(url_options = {})
    return true if url_options == '#' || current_user.administrator?
    if url_options.is_a?(Hash)
      url_options[:controller] ||= controller_path
      url_options[:action] ||= action_name
    elsif url_options.is_a?(String) && url_options.match(/\#/)
      action = url_options.split('#')
      url_options = { controller: action[0].to_sym, action: action[1].to_sym }
    else
      raise ArgumentError, 'Invalid URL: ' + url_options.inspect
    end
    unless url_options[:controller] =~ /\/\w+/
      namespace = controller_path.gsub(/\/\w+$/, '')
      if namespace.present?
        url_options[:controller] = "/#{namespace}/#{url_options[:controller]}"
      end
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

  def notify(message, options = {}, nature = :information, mode = :next)
    options[:default] ||= []
    options[:default] = [options[:default]] unless options[:default].is_a?(Array)
    options[:default] << message.to_s.humanize
    options[:scope] = 'notifications.messages'
    nature = nature.to_s
    notistore = (mode == :now ? flash.now : flash)
    notistore[:notifications] = {} unless notistore[:notifications].is_a? Hash
    notistore[:notifications][nature] = [] unless notistore[:notifications][nature].is_a? Array
    notistore[:notifications][nature] << (message.is_a?(String) ? message : message.to_s.t(options))
  end

  def notify_error(message, options = {})
    notify(message, options, :error)
  end

  def notify_warning(message, options = {})
    notify(message, options, :warning)
  end

  def notify_success(message, options = {})
    notify(message, options, :success)
  end

  def notify_now(message, options = {})
    notify(message, options, :information, :now)
  end

  def notify_error_now(message, options = {})
    notify(message, options, :error, :now)
  end

  def notify_warning_now(message, options = {})
    notify(message, options, :warning, :now)
  end

  def notify_success_now(message, options = {})
    notify(message, options, :success, :now)
  end

  def has_notifications?(nature = nil)
    return false unless flash[:notifications].is_a? Hash
    if nature.nil?
      for nature, messages in flash[:notifications]
        return true if messages.any?
      end
    elsif flash[:notifications][nature].is_a?(Array)
      return true if flash[:notifications][nature].any?
    end
    false
  end

  def set_theme
    @current_theme = 'tekyla'
  end

  # Initialize locale with params[:locale] or HTTP_ACCEPT_LANGUAGE
  def set_locale
    if current_user && I18n.available_locales.include?(current_user.language.to_sym)
      I18n.locale = current_user.language
    else
      session[:locale] = params[:locale] if params[:locale]
      if session[:locale].blank?
        if locale = http_accept_language.compatible_language_from(Ekylibre.http_languages.keys)
          session[:locale] = Ekylibre.http_languages[locale]
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
  end

  # Change the time zone from the given params or reuse session variable
  def set_time_zone
    session[:time_zone] = params[:time_zone] if params[:time_zone]
    session[:time_zone] ||= 'UTC'
    Time.zone = session[:time_zone]
  end

  # Sets mailer host on each request to ensure to get the valid domain
  def set_mailer_host
    ActionMailer::Base.default_url_options = { host: request.host_with_port }
  end

  def check_browser
    browser = Browser.new(ua: request.headers['HTTP_USER_AGENT'], accept_language: request.headers['HTTP_ACCEPT_LANGUAGE'])
    notify_warning_now :incompatible_browser if browser.ie?
  end

  def configure_application(exception)
    title = exception.class.name.underscore.t(scope: 'exceptions')
    render '/public/configure_application', layout: 'exception', locals: { title: title, message: exception.message, class_name: exception.class.name }, status: 500
  end

  def set_raven_context
    if current_user
      Raven.user_context(id: current_user.id) # or anything else in session
    end
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
