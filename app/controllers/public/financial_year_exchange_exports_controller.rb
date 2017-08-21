# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier
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

module Public
  class FinancialYearExchangeExportsController < BaseController
    def show
      @exchange = find_exchange
    end

    def csv
      @exchange = find_exchange
      export = FinancialYearExchangeExport.new(@exchange)
      export.export('csv') do |file, name|
        send_data File.read(file), filename: name
      end
    end

    private

    def find_exchange
      public_token = params[:id]
      FinancialYearExchange.for_public_token(public_token)
    end
  end
end
