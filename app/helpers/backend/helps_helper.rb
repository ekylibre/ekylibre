# coding: utf-8

# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
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

module Backend
  module HelpsHelper
    def find_article(name)
      if Ekylibre.helps[I18n.locale]
        kontroller, aktion = name.to_s.split('-')[0..1]
        possibilities = [name]
        possibilities << kontroller + '-edit' if aktion == 'update'
        possibilities << kontroller + '-new' if %w[create update edit].include?(aktion)
        possibilities << kontroller + '-index'
        return possibilities.detect do |p|
          Ekylibre.helps[I18n.locale].key?(p)
        end
      end
      nil
    end

    def article_exist?(name)
      !find_article(name).nil?
    end

    def article(name, options = {})
      return unless file = find_article(name)
      content = nil
      File.open(Ekylibre.helps[I18n.locale][file][:file], 'rb:UTF-8') { |f| content = f.read }
      content = content.split(/\n/)[1..-1].join("\n") if options.delete(:without_title)
      content = wikize(content.to_s, options)
      content
    end

    def help_shown?
      Preference[:use_contextual_help] &&
        !current_user.preference('interface.helps.collapsed', true, :boolean).value
    end

    # Open an help file and returns corresponding HTML
    def help(file)
      f = File.open(file, 'rb:UTF-8')
      content = f.read
      f.close
      wikize(content)
    end

    # Transforms text to HTML like in wikis.
    def wikize(content, options = {})
      # AJAX fails with XHTML entities because there is no DOCTYPE in AJAX response

      # French rules
      content.gsub!(/[\,\s]+(\.{3,}|…)/, '...')
      content.gsub!('...', '&#8230;')
      content.gsub!(/(\w)(\?|\:)([\s$])/, '\1~\2\3')
      content.gsub!(/(\w+)[\ \~]+(\?|\:)/, '\1~\2')

      content.gsub!(/\~/, '&#160;')

      content.gsub!(/^\ \ \*\ +(.*)\ *$/, '<ul><li>\1</li></ul>')
      content.gsub!(/<\/ul>\n<ul>/, '')
      content.gsub!(/^\ \ \-\ +(.*)\ *$/, '<ol><li>\1</li></ol>')
      content.gsub!(/<\/ol>\n<ol>/, '')
      content.gsub!(/^\ \ \?\ +(.*)\ *$/, '<dl><dt>\1</dt></dl>')
      content.gsub!(/^\ \ \!\ +(.*)\ *$/, '<dl><dd>\1</dd></dl>')
      content.gsub!(/<\/dl>\n<dl>/, '')

      content.gsub!(/^>>>\ +(.*)\ *$/, '<p class="notice">\1</p>')
      content.gsub!(/<\/p>\n<p class="notice">/, '<br/>')
      content.gsub!(/^!!!\ +(.*)\ *$/, '<p class="warning">\1</p>')
      content.gsub!(/<\/p>\n<p class="warning">/, '<br/>')

      content.gsub!(/\{\{\ *[^\}\|]+\ *(\|[^\}]+)?\}\}/) do |data|
        data = data.squeeze(' ')[2..-3].split('|')
        align = { '  ' => 'center', ' x' => 'right', 'x ' => 'left', 'xx' => '' }[(data[0][0..0] + data[0][-1..-1]).gsub(/[^\ ]/, 'x')]
        title = data[1] || data[0].split(/[\:\\\/]+/)[-1].humanize
        src = data[0].strip
        if src =~ /^icon:/
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
        url = options[:url].merge(controller: "/#{url[0]}", action: (url[1] || :index))
        # TODO: clean authorization system
        surl = url_for(url) # Permit to test URL
        (options[:no_link] || !authorized?(url) ? link[1] : link_to(link[1].html_safe, surl))
      end

      options[:method] = :get
      content = content.gsub(/\[\[[\w\-]+\|[^\]]*\]\]/) do |link|
        link = link[2..-3].split('|')
        url = url_for(options[:url].merge(id: link[0]))
        link_to(link[1].html_safe, url, { :remote => true, 'data-type' => :html }.merge(options)) # REMOTE
      end

      content = content.gsub(/\[\[[\w\-]+\]\]/) do |link|
        link = link[2..-3]
        url = url_for(options[:url].merge(id: link))
        link_to(link.html_safe, url, { :remote => true, 'data-type' => :html }.merge(options)) # REMOTE
      end

      (1..6).each do |x|
        n = 7 - x
        content.gsub!(/^\s*\={#{n}}\s*([^\=]+)\s*\=*/, "<h#{x}>\\1</h#{x}>")
      end
      content.gsub!(/\<h1\>.*\<\/h1\>/, '')

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

      content.html_safe
    end
  end
end
