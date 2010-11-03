# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
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

class StoreController < ActionController::Base # ApplicationController

  before_filter :analyze

  def index
  end

  protected

  def analyze()
    @current_company = Company.find_by_code(params[:company])
    unless @current_company
      # notify(:unknown_company, :error) unless params[:company].blank?
      render :file=>Rails.root.join("public", "404.html"), :status=>404, :layout=>false
    end    
  end

end
