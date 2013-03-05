# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2013 Brice Texier
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

module Backend::HelpHelper

  def find_article(name)
    if Ekylibre.helps[I18n.locale]
      if Ekylibre.helps[I18n.locale].has_key?(name.to_s)
        return name.to_s
      else
        index = name.to_s.gsub(/\-\w+$/, '-index')
        return index if Ekylibre.helps[I18n.locale].has_key?(index)
      end
    end
    return nil
  end


  def article_exist?(name)
    return !find_article(name).nil?
  end

  def search_article(article = nil)
    session[:help_history] = [] unless session[:help_history].is_a? [].class
    article ||= "#{self.absolute_controller_name}-#{self.action_name}"
    file = nil
    for locale in [I18n.locale, I18n.default_locale]
      for f, attrs in Ekylibre.helps
        next if attrs[:locale].to_s != locale.to_s
        file_name = [article, article.split("-")[0].to_s+"-index"].detect{|name| attrs[:name]==name}
        file = f and break unless file_name.blank?
      end
      break unless file.nil?
    end
    if file and session[:side] and article != session[:help_history].last
      session[:help_history] << file
    end
    file ||= article.to_sym
    return file
  end


  def article(name, options = {})
    return unless file = find_article(name)
    content = nil
    File.open(Ekylibre.helps[I18n.locale][file][:file], 'rb:UTF-8'){|f| content = f.read}
    content = content.split(/\n/)[1..-1].join("\n") if options.delete(:without_title)
    content = wikize(content.to_s, options)
    return content
  end


  #   name = name.to_s
  #   content = ''
  #   file_name, locale = '', nil
  #   for locale in [I18n.locale, I18n.default_locale]
  #     help_dir = Rails.root.join("config", "locales", locale.to_s, "help")
  #     file_name = [name, name.split("-")[0].to_s << "-index"].detect do |pattern|
  #       File.exists? help_dir.join(pattern << ".txt")
  #     end
  #     break unless file_name.blank?
  #   end
  #   file_text = Rails.root.join("config", "locales", locale.to_s, "help", file_name.to_s << ".txt")
  #   if File.exists?(file_text)
  #     File.open(file_text, 'r') do |file|
  #       content = file.read
  #     end
  #     content = wikize(content, options)
  #   end
  #   return content
  # end


end
