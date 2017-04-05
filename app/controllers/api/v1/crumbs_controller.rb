# encoding: utf-8

# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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

module Api
  module V1
    class CrumbsController < Api::V1::BaseController
      def index
        render json: current_user.crumbs, status: :ok
      end

      def create
        crumb = Crumb.new(permitted_params)
        crumb.user = current_user
        if crumb.save
          render json: { id: crumb.id }, status: :created
        else
          render json: crumb.errors, status: :unprocessable_entity
        end
      end

      protected

      def permitted_params
        super.permit(:nature, :geolocation, :read_at, :accuracy, :device_uid, metadata: %i[procedure_nature name scanned_code quantity unit])
      end
    end
  end
end
