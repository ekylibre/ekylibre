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
    manage_restfully only: [:update, :destroy]

    def index
      @worked_on = unless params[:worked_on].blank?
                     params[:worked_on].to_date
                   else
                     current_user.unconverted_crumb_days.first
                   end
    end

    # Creates an intervention from crumb and redirects to an edit form for
    # the newly created intervention.
    def convert
      return unless crumb = find_and_check
      begin
        if intervention = crumb.convert!(params.slice(:procedure_name, :support_id, :actors_ids, :relevance, :limit, :history, :provisional, :max_arity))
          redirect_to edit_backend_intervention_path(intervention)
        elsif current_user.unconverted_crumb_days.any?
          redirect_to backend_crumbs_path(worked_on: params[:worked_on])
        else
          redirect_to backend_interventions_path
        end
      rescue StandardError => e
        notify_error(e.message)
        redirect_to backend_crumbs_path
      end
    end
  end
end
