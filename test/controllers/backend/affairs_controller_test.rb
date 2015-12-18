# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013-2014 Brice Texier, David Joulin
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
  class AffairsControllerTest < ActionController::TestCase
    test_restfully_all_actions do |o|
      o.select mode: :show,    params: { third_id: identify(:entities_001), deal_type: 'sale' }
      o.attach mode: :touch,   params: { deal_id:  identify(:sales_001), deal_type: 'sale' }
      o.detach mode: :destroy, params: { deal_id:  6, deal_type: 'purchase', id: 15 }
      o.finish id: 20
    end

    test 'should not attach invalid deal' do
      affair = affairs(:affairs_001)
      assert affair.valid?, 'Affair 001 must be valid'
      post :attach, id: affair.id
      assert (flash['notifications'] && flash['notifications']['error'].any?), "Error expected with no given deal (got #{flash.inspect})"
    end

    test 'should not detach invalid deal' do
      affair = affairs(:affairs_001)
      assert affair.valid?, 'Affair 001 must be valid'
      post :detach, id: affair.id
      assert (flash['notifications'] && flash['notifications']['error'].any?), "Error expected with no given deal (got #{flash.inspect})"
    end
  end
end
