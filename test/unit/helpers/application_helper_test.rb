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

require 'test_helper'
class ApplicationHelperTest < ActionView::TestCase

  context 'Help controller' do
    setup do
    end


    for file in Dir.glob(Rails.root.join("config", "locales", "*", "help", "*.txt"))
      File.open(file, "rb") do |f|
        source = f.read
        should "'wikize' '#{file.gsub(Rails.root.to_s, '.')}'" do
          assert_nothing_raised() do
            wikize(source, :url=>{:controller=>:help, :action=>:show})
            # render :inline=>"<%=wikize(@source)-%>"
          end
        end
      end
    end

  end

end
