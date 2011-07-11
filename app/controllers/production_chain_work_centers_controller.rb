# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

class ProductionChainWorkCentersController < ApplicationController
  manage_restfully :production_chain_id=>"params[:production_chain_id]", :nature=>"(params[:nature]||'input')"
  manage_restfully_list

  # Displays details of one production chain work center selected with +params[:id]+
  def show
    return unless @production_chain_work_center = find_and_check(:production_chain_work_center)
    t3e @production_chain_work_center.attributes
  end

  def play
  end

end
