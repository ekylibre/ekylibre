# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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
  class ExportsController < Backend::BaseController
    respond_to :pdf, :odt, :ods, :docx, :xlsx, :xml, :json, :html, :csv
    HIDDEN_AGGREGATORS = [ "fr_pcg82_balance_sheet",
                           "fr_pcg82_profit_and_loss_statement",
                           "fr_pcga_balance_sheet",
                           "fr_pcga_profit_and_loss_statement",
                           "vat_register",
                           "income_statement"]


    def index
      # FIXME: It should not be necessary to do that
      DocumentTemplate.load_defaults unless DocumentTemplate.any?
      @aggregators = helpers.export_categories.each_with_object({}) do |export_category, hash|
        hash[export_category] = (Aggeratio.of_category(export_category.name) - HIDDEN_AGGREGATORS.map { |agg| Aggeratio[agg] })
      end
    end

    def show
      unless klass = Aggeratio[params[:id]]
        notify_error :aggeratio_not_found
        redirect_to action: :index
        return
      end

      klass.parameters.each do |parameter|
        next if parameter.record_list?
        value_preference = "exports.#{klass.name}.parameters.#{parameter.name}.value"
        value = current_user.preference(value_preference, parameter.default).value
        params[parameter.name] ||= value
        current_user.prefer!(value_preference, params[parameter.name])
      end

      @aggregator = klass.new(params)
      aggregator_parameters = @aggregator.class.parameters.map(&:name).uniq
      t3e name: klass.human_name
      if params[:format] == 'pdf'
        ExportJob.perform_later(JSON(params), current_user.id)
        notify_success(:document_in_preparation)
        redirect_to :back
      else
        if (aggregator_parameters - params.keys).empty?
          notify(:information_success_print)
          @btn_class = 'btn-primary'
        end
        respond_with @aggregator
      end
    end
  end
end
