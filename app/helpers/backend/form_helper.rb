# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2015 Brice Texier
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

module Backend::FormHelper
  # Date field tag override default formize date_field_tag helper to
  # simplify use for now
  def date_field_tag(name, value = nil, html_options = {})
    html_options[:value] = value
    html_options[:size] ||= 10
    html_options[:type] = :date
    html_options[:name] = name
    tag(:input, html_options)
  end

  # Date field tag override default formize date_field_tag helper to
  # simplify use for now
  def datetime_field_tag(name, value = nil, html_options = {})
    html_options[:size] ||= 16
    html_options[:lang] ||= 'i18n.iso2'.t
    html_options[:type] = :datetime
    html_options[:name] = name
    html_options[:value] = value || params[name]
    tag(:input, html_options)
  end

  def field_tag(*args)
    options = args.extract_options!
    name = args.shift || options[:name]
    datatype = args.shift || options[:datatype]
    value = args.shift || options[:value]
    if datatype == :boolean
      hidden_field_tag(name, '0') + check_box_tag(name, '1', value)
    elsif datatype == :measure
      unless unit = options[:unit] || (value ? value.unit : nil)
        fail StandardError, 'Need unit'
      end
      content_tag(:div, class: 'input-append') do
        text_field_tag("#{name}[value]", (value ? value.to_d : nil)) +
          select_tag("#{name}[unit]", options_for_select(Measure.siblings(unit).collect { |u| [Nomen::Units[u].human_name, u] }, (value ? value.unit : unit)))
      end
    elsif [:string, :integer, :decimal].include? datatype
      text_field_tag(name, value)
    elsif datatype == :choice
      choices = options[:choices] || []
      select_tag(name, options_for_select(choices, value))
    elsif datatype == :chart_of_accounts
      select_tag(name, options_for_select(Nomen::ChartsOfAccounts.selection, value))
    elsif nomenclature = Nomen[datatype.to_s.pluralize]
      select_tag(name, options_for_select(nomenclature.selection, value))
    else
      return "[EmptyField #{name.inspect}]"
    end
  end

  def indicator_field_tag(*args)
    options = args.extract_options!
    name = args.shift
    indicator = args.shift
    value = args.shift
    datatype = indicator.datatype
    if datatype == :boolean
      hidden_field_tag(name, '0') + check_box_tag(name, '1', value)
    elsif datatype == :measure
      content_tag(:div, class: 'input-append') do
        text_field_tag("#{name}[value]", (value ? value.to_d : nil)) +
          select_tag("#{name}[unit]", options_for_select(Measure.siblings(indicator.unit).collect { |u| [Nomen::Units[u].human_name, u] }, (value ? value.unit : indicator.unit)))
      end
    elsif [:string, :integer, :decimal].include? datatype
      text_field_tag(name, value)
    elsif datatype == :choice
      select_tag(name, options_for_select(indicator.selection(:choices), value))
    else
      return indicator.name.upcase
    end
  end
end
