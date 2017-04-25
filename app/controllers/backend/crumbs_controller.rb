# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Sebastien Gauvrit, Brice Texier
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

module Backend
  class CrumbsController < Backend::BaseController
    manage_restfully only: %i[update destroy]

    def index
      @worked_on = if params[:worked_on].blank?
                     current_user.unconverted_crumb_days.first
                   else
                     params[:worked_on].to_date
                   end
    end

    # Creates an intervention from crumb and redirects to an edit form for
    # the newly created intervention.
    def convert
      return unless crumb = find_and_check
      intervention_path = crumb.intervention_path
      begin
        if intervention = intervention_path.convert!(params.slice(:procedure_name, :working_width))
          redirect_to edit_backend_intervention_path(intervention)
        elsif current_user.unconverted_crumb_days.any?
          redirect_to backend_crumbs_path(worked_on: params[:worked_on])
        else
          redirect_to backend_interventions_path
        end
      rescue StandardError => e
        notify_error(e.message)
        redirect_to backend_crumbs_path(worked_on: params[:worked_on])
      end
    end
  end
end
