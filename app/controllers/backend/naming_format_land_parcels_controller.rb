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

module Backend
  class NamingFormatLandParcelsController < NamingFormatsController
    def build_example
      return render json: { example: I18n.t('labels.example', value: '') } if params[:fields_values].nil?

      build_example_interactor = NamingFormats::LandParcels::BuildExampleInteractor
                                 .call(params)

      render json: { example: I18n.t('labels.example', value: build_example_interactor.example) } if build_example_interactor.success?
      render json: { example: build_example_interactor.error } if build_example_interactor.fail?
    end

    def index
      super
    end

    def update
      @naming_format.update(valid_permitted_params)

      if params[:update_records].to_bool
        NamingFormats::LandParcels::ChangeLandParcelsNamesInteractor
          .call
      end

      redirect_to backend_naming_formats_path
    end

    private

    def permitted_params
      params
        .require(:naming_format_land_parcel)
        .permit(fields_attributes: %i[
                  id
                  field_name
                  _destroy
                ])
    end

    def valid_permitted_params
      permitted_params
        .tap do |param|

        param[:fields_attributes]
          .values
          .select { |value| value[:id].nil? }
          .each { |value| value[:type] = NamingFormatFieldLandParcel.to_s }
      end
    end
  end
end
