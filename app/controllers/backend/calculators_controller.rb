# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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
class Backend::CalculatorsController < BackendController

  LIST = {
    # nitrogen_inputs: {controller: "backend/calculators/nitrogen_inputs", action: :show},
    manure_management_plans: {controller: "backend/manure_management_plans", action: :index}
  }

  def index
    # Dir.chdir(Rails.root.join("app", "controllers", "backend", "calculators")) do
    #   @calculators = Dir.glob("*.rb").collect do |basename|
    #     basename.gsub(/_controller.rb\z/, "")
    #   end
    # end
    @calculators = LIST
  end

end
