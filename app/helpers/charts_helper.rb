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

module ChartsHelper
  OPTIONS = [:colors, :credits, :exporting, :labels, :legend, :loading, :navigation, :pane, :plot_options, :series, :subtitle, :title, :tooltip, :x_axis, :y_axis].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '-') # camelize(:lower)
    hash
  end.freeze

  TYPES = [:line, :spline, :area, :area_spline, :column, :bar, :pie, :scatter, :area_range, :area_spline_range, :column_range, :waterfall].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '')
    hash
  end.freeze

  def ligthen(color, rate)
    r = color[1..2].to_i(16)
    g = color[3..4].to_i(16)
    b = color[5..6].to_i(16)
    r *= (1 + rate)
    g *= (1 + rate)
    b *= (1 + rate)
    r = 255 if r > 255
    g = 255 if g > 255
    b = 255 if b > 255
    '#' + r.to_i.to_s(16).rjust(2, '0') + g.to_i.to_s(16).rjust(2, '0') + b.to_i.to_s(16).rjust(2, '0')
  end

  for type, absolute_type in TYPES
    code  = "def #{type}_highcharts(series, options = {}, html_options = {})\n"
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
      code << "  options[:#{name}][:enabled] = true if options[:#{name}].is_a?(Hash) and !options[:#{name}].has_key?(:enabled)\n"
    end
    code << "  html_options[:data] ||= {}\n"
    code << "  html_options[:data][:highcharts] = options.jsonize_keys.to_json\n"
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
    data
  end

  # Permit to produce pie or gauge
  # Values are represented relatively to all
  #   engine:     Engine for rendering. c3 by default.
  def distribution_chart(_options = {})
    fail NotImplemented
  end

  # Permits to draw a nonlinear chart (line, spline)
  # Values are represented with given abscissa for each value
  #   :abscissa
  #   :ordinates
  #   engine:     Engine for rendering. c3 by default.
  def category_chart(options = {})
    html_options = options.slice!(:series, :abscissa, :ordinates, :engine)
    options[:type] = :nonlinear
    # TODO: Check options validity
    html_options[:class] ||= 'chart'
    html_options.deep_merge!(data: { chart: options.to_json })
    content_tag(:div, nil, html_options)
  end

  # Permits to draw a linear chart (line, spline, bar)
  # Values are represented with regular interval
  #   series:    (Array of) Hash for series
  #     name:       ID
  #     values:     Array of numeric values
  #     label:      Label for the legend
  #     ordinate:   Name of the used ordinate
  #     type:       One of: line, spline, bar
  #     area:       Boolean
  #     style:      Styles
  #   abscissa:   X axis details
  #     label:      Label for the X axis
  #     values:     Array of labels used for indexes
  #   ordinates: (Array of) Hash for Y axes
  #     name:       ID
  #     label:      Name of the Y axis
  #   engine:     Engine for rendering. c3 by default.
  def cartesian_chart(options = {})
    html_options = options.slice!(:series, :abscissa, :ordinates, :engine)
    options[:type] = :time
    # TODO: Check options validity
    options[:series] = [options[:series]] unless options[:series].is_a?(Array)
    options[:series].each do |serie|
      serie[:values].each do |coordinates|
        coordinates[0] = coordinates[0].utc.l(format: '%Y-%m-%dT%H:%M:%S')
      end
    end
    html_options[:class] ||= 'chart'
    html_options.deep_merge!(data: { chart: options.to_json })
    content_tag(:div, nil, html_options)
  end

  # Permit to produce pie or gauge
  # Values are represented relatively to all
  #   engine:     Engine for rendering. c3 by default.
  def tree_distribution_chart(_options = {})
    fail NotImplemented
  end
end
