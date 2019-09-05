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
  class SalesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions cancel: :redirected_get,
                               contacts: :index_xhr,
                               except: %i[generate_parcel update]

    test 'should redirect to 404 if wrong nature' do
      sale = sales(:sales_001)
      get :show, id: sale.id, nature: 'pouet', format: 'pdf'
      assert_response :not_found
    end

    %i[estimate order invoice].each do |nature|
      test "should switch to Jasper if sales #{nature} document template exists" do
        sale = sales(:sales_001)
        class << @controller
          attr_accessor :called
          def create_response
            @called = true
            head 200
          end
        end
        get :show, id: sale.id, nature: nature, format: :pdf
        assert @controller.called
      end
    end
  end
end
