# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier
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

class Backend::BeehivesController < BackendController

  # Save beehive config in preferences
  def update
    children = params["children"].sort do |a,b|
      a[0] <=> b[0]
    end.map do |box|
      next unless box.second["children"]
      cells = box.second["children"].symbolize_keys.sort do |a,b|
        a[0] <=> b[0]
      end.map do |cell|
        cell.second.symbolize_keys
      end.compact
      cells.any? ? { type: box.second["type"], children: cells } : nil
    end.compact
    current_user.prefer!("beehive.#{params[:id]}", {type: "root", children: children}.deep_stringify_keys.to_yaml)
    head :ok
  end


  def reset
    if preference = current_user.preferences.find_by(name: "beehive.#{params[:id]}")
      preference.destroy!
    end
    head :ok
  end

end
