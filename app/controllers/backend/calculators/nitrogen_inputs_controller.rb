# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
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

class Backend::Calculators::NitrogenInputsController < BackendController

  def show
    redirect_to action: :edit
  end

  def edit
    if @campaign = Campaign.find_by(id: params[:campaign_id])
      @zones = Calculus::NitrogenInputs::Zone.of_campaign(@campaign)
    end
  end

  def update
    @campaign = Campaign.find(params[:campaign_id])
    Calculus::NitrogenInputs::Zone.calculate!(@campaign, params[:zones])
    notify_now(:new_values_are_calculated)
    @zones = Calculus::NitrogenInputs::Zone.of_campaign(@campaign)
    render action: :edit
  end

end
