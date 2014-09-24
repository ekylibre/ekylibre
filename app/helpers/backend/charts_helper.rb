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

module Backend::ChartsHelper

  OPTIONS = [:colors, :credits, :exporting, :labels, :legend, :loading, :navigation, :pane, :plot_options, :series, :subtitle, :title, :tooltip, :x_axis, :y_axis].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '-') # camelize(:lower)
    hash
  end.freeze

  TYPES = [:line, :spline, :area, :area_spline, :column, :bar, :pie, :scatter, :area_range, :area_spline_range, :column_range, :waterfall].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '')
    hash
  end.freeze

  def ligthen(color, rate)
    r, g, b = color[1..2].to_i(16), color[3..4].to_i(16), color[5..6].to_i(16)
    r *= (1+rate)
    g *= (1+rate)
    b *= (1+rate)
    r = 255 if r > 255
    g = 255 if g > 255
    b = 255 if b > 255
    return '#' + r.to_i.to_s(16).rjust(2, '0') + g.to_i.to_s(16).rjust(2, '0') + b.to_i.to_s(16).rjust(2, '0')
  end

  for type, absolute_type in TYPES
    code  = "def #{type}_chart(series, options = {}, html_options = {})\n"
    code << "  options[:chart] ||= {}\n"
    code << "  options[:chart][:type] = '#{absolute_type}'\n"
    code << "  options[:chart][:style] ||= {}\n"
    code << "  options[:chart][:style][:font_family] ||= theme_font_family\n"
    code << "  options[:chart][:style][:font_size]   ||= theme_font_size\n"
    code << "  options[:colors] ||= theme_colors\n"
    code << "  if options[:title].is_a?(String)\n"
    code << "    options[:title] = {text: options[:title].dup}\n"
    code << "  end\n"
    code << "  if options[:subtitle].is_a?(String)\n"
    code << "    options[:subtitle] = {text: options[:subtitle].dup}\n"
    code << "  end\n"
    code << "  series = [series] unless series.is_a?(Array)\n"
    code << "  options[:series] = series\n"
    for name, absolute_name in OPTIONS
      if [:legend, :credits].include?(name)
        code << "  if options.has_key?(:#{name})\n"
        code << "    options[:#{name}] = {enabled: true} if options[:#{name}].is_a?(TrueClass)\n"
        code << "  end\n"
      end
    end
    code << "  html_options[:data] ||= {}\n"
    code << "  html_options[:data][:chart] = options.jsonize_keys.to_json\n"
    code << "  return content_tag(:div, nil, html_options)\n"
    code << "end\n"
    # code.split("\n").each_with_index{|x, i| puts((i+1).to_s.rjust(4)+": "+x)}
    eval(code)
  end


  def normalize_serie(values, x_values, default = 0.0)
     data = []
     for x in x_values
       data << (values[x] || default).to_s.to_f
     end
     return data
  end

end
