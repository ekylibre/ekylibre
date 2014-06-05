# == License
# Ekylibre - Simple agricultural ERP
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

module Backend::FormHelper
  
  def indicator_field_tag(*args)
    options = args.extract_options!
    name = args.shift
    indicator = args.shift
    value = args.shift
    datatype = indicator.datatype
    if datatype == :boolean
      hidden_field_tag(name, "0") + check_box_tag(name, "1", value)
    elsif datatype == :measure
      content_tag(:div, class: "input-append") do
        text_field_tag("#{name}[value]", (value ? value.to_d : nil)) +
          select_tag("#{name}[unit]", options_for_select(Measure.siblings(indicator.unit).collect{|u| [Nomen::Units[u].human_name, u]}, (value ? value.unit : indicator.unit)))
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
