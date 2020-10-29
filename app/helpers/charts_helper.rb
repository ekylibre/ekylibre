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
  OPTIONS = %i[colors credits exporting labels legend loading navigation pane plot_options series subtitle title tooltip x_axis y_axis].each_with_object({}) do |name, hash|
    hash[name] = name.to_s.tr('_', '-') # camelize(:lower)
    hash
  end.freeze

  TYPES = %i[line spline area area_spline column bar pie scatter area_range area_spline_range column_range waterfall].each_with_object({}) do |name, hash|
    hash[name] = name.to_s.delete('_')
    hash
  end.freeze

  COLORS = {
    aliceblue: '#F0F8FF',
    antiquewhite: '#FAEBD7',
    aqua: '#00FFFF',
    aquamarine: '#7FFFD4',
    azure: '#F0FFFF',
    beige: '#F5F5DC',
    bisque: '#FFE4C4',
    black: '#000000',
    blanchedalmond: '#FFEBCD',
    blue: '#0000FF',
    blueviolet: '#8A2BE2',
    brown: '#A52A2A',
    burlywood: '#DEB887',
    cadetblue: '#5F9EA0',
    chartreuse: '#7FFF00',
    chocolate: '#D2691E',
    coral: '#FF7F50',
    cornflowerblue: '#6495ED',
    cornsilk: '#FFF8DC',
    crimson: '#DC143C',
    cyan: '#00FFFF',
    darkblue: '#00008B',
    darkcyan: '#008B8B',
    darkgoldenrod: '#B8860B',
    darkgray: '#A9A9A9',
    darkgrey: '#A9A9A9',
    darkgreen: '#006400',
    darkkhaki: '#BDB76B',
    darkmagenta: '#8B008B',
    darkolivegreen: '#556B2F',
    darkorange: '#FF8C00',
    darkorchid: '#9932CC',
    darkred: '#8B0000',
    darksalmon: '#E9967A',
    darkseagreen: '#8FBC8F',
    darkslateblue: '#483D8B',
    darkslategray: '#2F4F4F',
    darkslategrey: '#2F4F4F',
    darkturquoise: '#00CED1',
    darkviolet: '#9400D3',
    deeppink: '#FF1493',
    deepskyblue: '#00BFFF',
    dimgray: '#696969',
    dimgrey: '#696969',
    dodgerblue: '#1E90FF',
    firebrick: '#B22222',
    floralwhite: '#FFFAF0',
    forestgreen: '#228B22',
    fuchsia: '#FF00FF',
    gainsboro: '#DCDCDC',
    ghostwhite: '#F8F8FF',
    gold: '#FFD700',
    goldenrod: '#DAA520',
    gray: '#808080',
    grey: '#808080',
    green: '#008000',
    greenyellow: '#ADFF2F',
    honeydew: '#F0FFF0',
    hotpink: '#FF69B4',
    indianred: '#CD5C5C',
    indigo: '#4B0082',
    ivory: '#FFFFF0',
    khaki: '#F0E68C',
    lavender: '#E6E6FA',
    lavenderblush: '#FFF0F5',
    lawngreen: '#7CFC00',
    lemonchiffon: '#FFFACD',
    lightblue: '#ADD8E6',
    lightcoral: '#F08080',
    lightcyan: '#E0FFFF',
    lightgoldenrodyellow: '#FAFAD2',
    lightgray: '#D3D3D3',
    lightgrey: '#D3D3D3',
    lightgreen: '#90EE90',
    lightpink: '#FFB6C1',
    lightsalmon: '#FFA07A',
    lightseagreen: '#20B2AA',
    lightskyblue: '#87CEFA',
    lightslategray: '#778899',
    lightslategrey: '#778899',
    lightsteelblue: '#B0C4DE',
    lightyellow: '#FFFFE0',
    lime: '#00FF00',
    limegreen: '#32CD32',
    linen: '#FAF0E6',
    magenta: '#FF00FF',
    maroon: '#800000',
    mediumaquamarine: '#66CDAA',
    mediumblue: '#0000CD',
    mediumorchid: '#BA55D3',
    mediumpurple: '#9370DB',
    mediumseagreen: '#3CB371',
    mediumslateblue: '#7B68EE',
    mediumspringgreen: '#00FA9A',
    mediumturquoise: '#48D1CC',
    mediumvioletred: '#C71585',
    midnightblue: '#191970',
    mintcream: '#F5FFFA',
    mistyrose: '#FFE4E1',
    moccasin: '#FFE4B5',
    navajowhite: '#FFDEAD',
    navy: '#000080',
    oldlace: '#FDF5E6',
    olive: '#808000',
    olivedrab: '#6B8E23',
    orange: '#FFA500',
    orangered: '#FF4500',
    orchid: '#DA70D6',
    palegoldenrod: '#EEE8AA',
    palegreen: '#98FB98',
    paleturquoise: '#AFEEEE',
    palevioletred: '#DB7093',
    papayawhip: '#FFEFD5',
    peachpuff: '#FFDAB9',
    peru: '#CD853F',
    pink: '#FFC0CB',
    plum: '#DDA0DD',
    powderblue: '#B0E0E6',
    purple: '#800080',
    rebeccapurple: '#663399',
    red: '#FF0000',
    rosybrown: '#BC8F8F',
    royalblue: '#4169E1',
    saddlebrown: '#8B4513',
    salmon: '#FA8072',
    sandybrown: '#F4A460',
    seagreen: '#2E8B57',
    seashell: '#FFF5EE',
    sienna: '#A0522D',
    silver: '#C0C0C0',
    skyblue: '#87CEEB',
    slateblue: '#6A5ACD',
    slategray: '#708090',
    slategrey: '#708090',
    snow: '#FFFAFA',
    springgreen: '#00FF7F',
    steelblue: '#4682B4',
    tan: '#D2B48C',
    teal: '#008080',
    thistle: '#D8BFD8',
    tomato: '#FF6347',
    turquoise: '#40E0D0',
    violet: '#EE82EE',
    wheat: '#F5DEB3',
    white: '#FFFFFF',
    whitesmoke: '#F5F5F5',
    yellow: '#FFFF00',
    yellowgreen: '#9ACD32'
  }.freeze

  def lightness(color)
    color = COLORS[color.downcase.to_sym] unless color.to_s =~ /\A\#[a-fA-F0-9]{6}\z/
    color ||= '#777777'
    r = color[1..2].to_i(16)
    g = color[3..4].to_i(16)
    b = color[5..6].to_i(16)
    0.299 * r + 0.587 * g + 0.114 * b
  end

  def contrasted_color(color)
    if lightness(color) > 160
      '#333333'
    else
      '#FFFFFF'
    end
  end

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

  TYPES.each do |type, absolute_type|
    define_method "#{type}_highcharts" do |series, options = {}, html_options = {}|
      options[:chart] ||= {}
      options[:chart][:type] = absolute_type
      options[:chart][:style] ||= {}
      options[:chart][:style][:font_family] ||= theme_font_family
      options[:chart][:style][:font_size]   ||= theme_font_size
      options[:colors] ||= theme_colors
      if options[:title].is_a?(String)
        options[:title] = {text: options[:title].dup}
      end
      if options[:subtitle].is_a?(String)
        options[:subtitle] = {text: options[:subtitle].dup}
      end
      series = [series] unless series.is_a?(Array)
      options[:series] = series
      OPTIONS.each do |name, _absolute_name|
        if %i[legend credits].include?(name)
          if options.has_key?(name.to_sym)
            options[name.to_sym] = { enabled: true } if options[name.to_sym].is_a?(TrueClass)
          end
        end
        options[name.to_sym][:enabled] = true if options[name.to_sym].is_a?(Hash) and !options[name.to_sym].has_key?(:enabled)
      end
      html_options[:data] ||= {}
      html_options[:data][:highcharts] = options.jsonize_keys.to_json
      return content_tag(:div, nil, html_options)
    end
  end

  def normalize_serie(values, x_values, default = 0.0)
    x_values.map do |x|
      (values[x] || default).to_s.to_f
    end
  end

  # Permit to produce pie or gauge
  # Values are represented relatively to all
  #   engine:     Engine for rendering. c3 by default.
  def distribution_chart(_options = {})
    raise NotImplemented
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
    raise NotImplemented
  end

  def formate_and_translate(categories)
    categories.map { |category| category.l(format: "%b %Y") }
  end
end
