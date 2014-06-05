# encoding: utf-8
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier
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

class Api::V1::BaseController < ActionController::Base
  before_action :check_format!
  # acts_as_token_authentication_handler_for User

  after_action do
    response.headers["X-Ekylibre-Media-Type"] = "ekylibre.v1"
    # response.headers["Access-Control-Allow-Origin"] = "*"
  end

  hide_action :check_format!
  def check_format!
    if request.format != :json
      render status: :not_acceptable, json: {message: "The request must be JSON"}
      return false
    end
  end

end
