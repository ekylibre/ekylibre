# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier, David Joulin
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
require 'procedo'

module Backend
  class ActivityTacticsController < Backend::BaseController
    manage_restfully except: :index

    unroll
    def procedures_name
      data = {}
      check_value(Procedo.procedures_of_main_category(params[:name]).sort { |a, b| a.human_name <=> b.human_name }).each do |procedure_name|
        data[procedure_name.name] = procedure_name.human_name
      end
      render json: data
    end

    def actions
      data = {}
      check_value(Procedo.find(params[:name]).optional_actions_selection).each do |action|
        data[action[1]] = action[0]
      end
      render json: data
    end

    private

    def check_value(data)
      unless data
        head :not_found
        return
      end
      data
    end
  end
end
