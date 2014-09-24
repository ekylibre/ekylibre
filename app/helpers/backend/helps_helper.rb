# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

module Backend::HelpsHelper

  def find_article(name)
    if Ekylibre.helps[I18n.locale]
      kontroller, aktion = name.to_s.split("-")[0..1]
      possibilities = [name]
      possibilities << kontroller + "-edit" if aktion == "update"
      possibilities << kontroller + "-new" if ["create", "update", "edit"].include?(aktion)
      possibilities << kontroller + "-index"
      return possibilities.detect do |p|
        Ekylibre.helps[I18n.locale].has_key?(p)
      end
    end
    return nil
  end


  def article_exist?(name)
    return !find_article(name).nil?
  end

  # def search_article(article = nil)
  #   session[:help_history] = [] unless session[:help_history].is_a? [].class
  #   article ||= "#{controller.controller_path}-#{self.action_name}"
  #   file = nil
  #   for locale in [I18n.locale, I18n.default_locale]
  #     for f, attrs in Ekylibre.helps
  #       next if attrs[:locale].to_s != locale.to_s
  #       kontroller, aktion = article.to_s.split("-")[0..1]
  #       possibilities = [article]
  #       possibilities << kontroller + "-edit" if action == "update"
  #       possibilities << kontroller + "-new" if ["create", "update", "edit"].include?(action)
  #       possibilities << kontroller + "-index"
  #       file_name = possibilities.detect{|name| attrs[:name]==name}
  #       file = f and break unless file_name.blank?
  #     end
  #     break unless file.nil?
  #   end
  #   if file and session[:side] and article != session[:help_history].last
  #     session[:help_history] << file
  #   end
  #   file ||= article.to_sym
  #   return file
  # end


  def article(name, options = {})
    return unless file = find_article(name)
    content = nil
    File.open(Ekylibre.helps[I18n.locale][file][:file], 'rb:UTF-8'){|f| content = f.read}
    content = content.split(/\n/)[1..-1].join("\n") if options.delete(:without_title)
    content = wikize(content.to_s, options)
    return content
  end

  def help_shown?
    !current_user.preference("interface.helps.collapsed", false, :boolean).value
  end


  # Open an help file and returns corresponding HTML
  def help(file)
    f = File.open(file, "rb:UTF-8")
    content = f.read
    f.close
    return wikize(content)
  end

  # Transforms text to HTML like in wikis.
  def wikize(content, options = {})
    # AJAX fails with XHTML entities because there is no DOCTYPE in AJAX response

    # French rules
    content.gsub!(/[\,\s]+(\.{3,}|…)/ , '...')
    content.gsub!('...' , '&#8230;')
    content.gsub!(/(\w)(\?|\:)([\s$])/ , '\1~\2\3' )
    content.gsub!(/(\w+)[\ \~]+(\?|\:)/ , '\1~\2' )


    content.gsub!(/\~/ , '&#160;')

    content.gsub!(/^\ \ \*\ +(.*)\ *$/ , '<ul><li>\1</li></ul>')
    content.gsub!(/<\/ul>\n<ul>/ , '')
    content.gsub!(/^\ \ \-\ +(.*)\ *$/ , '<ol><li>\1</li></ol>')
    content.gsub!(/<\/ol>\n<ol>/ , '')
    content.gsub!(/^\ \ \?\ +(.*)\ *$/ , '<dl><dt>\1</dt></dl>')
    content.gsub!(/^\ \ \!\ +(.*)\ *$/ , '<dl><dd>\1</dd></dl>')
    content.gsub!(/<\/dl>\n<dl>/ , '')

    content.gsub!(/^>>>\ +(.*)\ *$/ , '<p class="notice">\1</p>')
    content.gsub!(/<\/p>\n<p class="notice">/ , '<br/>')
    content.gsub!(/^!!!\ +(.*)\ *$/ , '<p class="warning">\1</p>')
    content.gsub!(/<\/p>\n<p class="warning">/ , '<br/>')

    content.gsub!(/\{\{\ *[^\}\|]+\ *(\|[^\}]+)?\}\}/) do |data|
      data = data.squeeze(' ')[2..-3].split('|')
      align = {'  ' => 'center', ' x' => 'right', 'x ' => 'left', 'xx' => ''}[(data[0][0..0] + data[0][-1..-1]).gsub(/[^\ ]/,'x')]
      title = data[1]||data[0].split(/[\:\\\/]+/)[-1].humanize
      src = data[0].strip
      if src.match(/^icon:/)
        icon_name = src.split(':')[1]
        "<i class='icon icon-#{icon_name}'></i>"
      else
        src = image_path(src)
        '<img class="md md-' + align + '" alt="' + title + '" title="' + title + '" src="' + src + '"/>'
      end
    end


    options[:url] ||= {}
    content = content.gsub(/\[\[>[^\|]+\|[^\]]*\]\]/) do |link|
      link = link[3..-3].split('|')
      url = link[0].split(/[\#\?\&]+/)
      url = options[:url].merge(:controller => url[0], :action => (url[1]||:index))
      # TODO clean authorization system
      surl = url_for(url) # Permit to test URL
      (options[:no_link] || !authorized?(url) ? link[1] : link_to(link[1].html_safe, surl))
    end

    options[:method] = :get
    content = content.gsub(/\[\[[\w\-]+\|[^\]]*\]\]/) do |link|
      link = link[2..-3].split('|')
      url = url_for(options[:url].merge(:id => link[0]))
      link_to(link[1].html_safe, url, {:remote => true, "data-type" => :html}.merge(options)) # REMOTE
    end

    content = content.gsub(/\[\[[\w\-]+\]\]/) do |link|
      link = link[2..-3]
      url = url_for(options[:url].merge(:id => link))
      link_to(link.html_safe, url, {:remote => true, "data-type" => :html}.merge(options)) # REMOTE
    end

    for x in 1..6
      n = 7-x
      content.gsub!(/^\s*\={#{n}}\s*([^\=]+)\s*\=*/, "<h#{x}>\\1</h#{x}>")
    end
    content.gsub!(/\<h1\>.*\<\/h1\>/, "")

    content.gsub!(/^\ \ (.*\w+.*)$/, '  <pre>\1</pre>')

    content.gsub!(/([^\:])\/\/([^\s][^\/]+)\/\//, '\1<em>\2</em>')
    content.gsub!(/\'\'([^\s][^\']+)\'\'/, '<code>\1</code>')
    content.gsub!(/(^)([^\s\<][^\s].*)($)/, '<p>\2</p>') unless options[:without_paragraph]
    content.gsub!(/^\s*(\<a.*)\s*$/, '<p>\1</p>')

    content.gsub!(/\*\*([^\s\*]+)\*\*/, '<strong>\1</strong>')
    content.gsub!(/\*\*([^\s\*][^\*]*[^\s\*])\*\*/, '<strong>\1</strong>')
    content.gsub!(/(^|[^\*])\*([^\*]|$)/, '\1&lowast;\2')
    content.gsub!("</p>\n<p>", "\n")

    content.strip!

    #raise StandardError.new content
    return content.html_safe
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
