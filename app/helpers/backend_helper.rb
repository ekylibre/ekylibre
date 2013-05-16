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

module BackendHelper

  def bar_chart(values, options = {})
    render :partial => "backend/charts/bar_chart", :locals => {:values => values}
  end

  def pie_chart(values, options = {})
    render :partial => "backend/charts/pie_chart", :locals => {:values => values}
  end

  # Angles are in degrees (not in radians)
  def pie_piece_path(x, y, radius, angle_start, angle_stop)
    # M 320,240 L 414.96396989003193,208.66560320151174 A 100,100,0,0,1, 361.91765204166643,330.7904755319289Z
    angle = angle_stop - angle_start
    path = "M#{x},#{y}"
    path << "L#{x + radius.to_f*Math.cos(angle_start*Math::PI/180.0)},#{y + radius.to_f*Math.sin(angle_start*Math::PI/180.0)}"
    path << "A#{radius},#{radius},#{angle_start},"
    path << (angle > 180 ? "1" : "0") + ","
    path << "1,"
    path << "#{x + radius.to_f*Math.cos(angle_stop*Math::PI/180.0)},#{y + radius.to_f*Math.sin(angle_stop*Math::PI/180.0)}"
    path << "Z"
    return path
  end


  def root_models
    Ekylibre.references.keys.collect{|a| [::I18n.t("activerecord.models.#{a.to_s.singularize}"), a.to_s.singularize]}.sort{|a,b| a[0].ascii <=> b[0].ascii}
  end

  def navigation_tag
    session[:last_page] ||= {}
    render :partial => "layouts/navigation"
  end

end
