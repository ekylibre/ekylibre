# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier
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

module Backend::ThemeHelper
  DEFAULT = {
    colors: ['#2f7ed8', '#0d233a', '#8bbc21', '#910000', '#1aadce', '#492970',
             '#f28f43', '#77a1e5', '#c42525', '#a6c96a'],
    font: {
      family: "'Open Sans', sans-serif",
      size: '14px'
    }
  }.freeze

  def theme_config
    DEFAULT
  end

  def theme_colors
    theme_config[:colors]
  end

  def theme_font_family
    theme_config[:font][:family]
  end

  def theme_font_size
    theme_config[:font][:size]
  end
end
