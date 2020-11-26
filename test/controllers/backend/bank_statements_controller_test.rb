# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

require 'test_helper'
module Backend
  class BankStatementsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions new: { cash_id: 1 },
                               create: { bank_statement: { cash_id: 1 } },
                               # reconciliation: :get_and_post, # TODO: Re-activate this test
                               index: :redirected_get,
                               except: %i[letter unletter reconciliation] # TODO: Re-activate those tests

    test 'import_cfonb post works' do
      create :cash, iban: 'FR8314508000309837485442I87'
      post(:import_cfonb, upload: uploaded_file("import_cfonb.csv"))
      assert_redirected_to("/backend/bank-statements/#{assigns(:bank_statement).id}")
    end

    private

      # @param [String] file_path
      # @return [Rack::Test::UploadedFile]
      def uploaded_file(file_path)
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixture-files/accountancy/cfonb", file_path).open)
      end
  end
end
