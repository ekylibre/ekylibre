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
      KramdownToHtmlService.call(content: content)
    end

    def help_shown?
      !current_user.preference('interface.helps.collapsed', true, :boolean).value
    end

    # Open an help file and returns corresponding HTML
    def help(file)
      f = File.open(file, 'rb:UTF-8')
      content = f.read
      f.close
      KramdownToHtmlService.call(content: content)
    end

    # Open an help file and returns corresponding PDF
    def pdf(file)
      f = File.open(file, 'rb:UTF-8')
      content = f.read
      f.close
      KramdownToHtmlService.pdf(content: content)
    end
  end
end
