# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
  class TrialBalancesController < Backend::BaseController
    def show
      @balance = Journal.trial_balance(params) if params[:period]
    end

    def export
      return unless params[:period]
      balance = Journal.trial_balance(params)
      respond_to do |format|
        format.html
        format.ods do
          send_data(
              trial_balance_to_ods_export(balance).bytes,
              filename: "[#{Time.zone.now.l}] #{Journal.model_name.human}.ods".underscore
          )
        end
      end
    end

    def trial_balance_to_ods_export(balance)
      require 'odf/spreadsheet'
      output = ODF::Spreadsheet.new
      output.instance_eval do
        office_style :important, family: :cell do
          property :text, 'font-weight': :bold, 'font-size': '11px'
        end
        office_style :bold, family: :cell do
          property :text, 'font-weight': :bold
        end

      end
      output
    end

  end
end
