# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
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
# ##### END LICENSE BLOCK #####

module RelationsHelper

  def condition_label(condition)
    if condition.match(/^generic/)
      klass, attribute = condition.split(/\-/)[1].classify.constantize, condition.split(/\-/)[2]
      return I18n.t("views.relations.entities_export.conditions.filter_on_attribute_of_class", :attribute=>klass.human_attribute_name(attribute), :class=>klass.human_name)
    else
      return I18n.t("views.relations.entities_export.conditions.#{condition}")
    end
  end

end
