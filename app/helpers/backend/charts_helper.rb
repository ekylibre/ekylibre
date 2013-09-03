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

module Backend::ChartsHelper

  OPTIONS = [:colors, :credits, :exporting, :labels, :legend, :loading, :navigation, :pane, :plot_options, :series, :subtitle, :title, :tooltip, :x_axis, :y_axis].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '-') # camelize(:lower)
    hash
  end.freeze

  TYPES = [:line, :spline, :area, :area_spline, :column, :bar, :pie, :scatter, :area_range, :area_spline_range, :column_range].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '')
    hash
  end.freeze

  for type, absolute_type in TYPES
    code  = "def #{type}_chart(series, options = {}, html_options = {})\n"
    code << "  options[:type] = '#{absolute_type}'\n"
    code << "  if options[:title].is_a?(String)\n"
    code << "    options[:title] = {text: options[:title].dup}\n"
    code << "  end\n"
    code << "  if options[:subtitle].is_a?(String)\n"
    code << "    options[:subtitle] = {text: options[:subtitle].dup}\n"
    code << "  end\n"
    for name, absolute_name in OPTIONS
      code << "  if options.has_key?(:#{name})\n"
      if [:legend, :credits].include?(name)
        code << "    options[:#{name}][:enabled] ||= true\n"
      end
      code << "    html_options['data-highchart-#{absolute_name}'] = options.delete(:#{name}).jsonize_keys.to_json\n"
      code << "  end\n"
    end
    code << "  series = [series] unless series.is_a?(Array)\n"
    code << "  html_options['data-highchart-series'] = series.map(&:jsonize_keys).to_json\n"
    code << "  html_options['data-highchart'] = options.jsonize_keys.to_json\n"
    code << "  return content_tag(:div, nil, html_options)\n"
    code << "end\n"
    # code.split("\n").each_with_index{|x, i| puts((i+1).to_s.rjust(4)+": "+x)}
    eval(code)
  end

end

class ::Hash

  def jsonize_keys
    return self.deep_transform_keys do |key|
      key.to_s.camelize(:lower)
    end
  end

end
