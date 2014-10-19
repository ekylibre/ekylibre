# encoding: utf-8
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2014 Sébastien Gauvrit, Brice Texier
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

class Backend::CrumbsController < BackendController
  manage_restfully only: [:update, :destroy]

  def index
    unless params[:worked_on].blank?
      @worked_on = params[:worked_on].to_date
    else
      @worked_on = current_user.unconverted_crumb_days.first
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
    rescue Exception => e
      notify_error(e.message)
      redirect_to backend_crumbs_path
    end
  end

end
