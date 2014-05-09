# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013-2014 Brice Texier, David Joulin
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

require 'test_helper'

class Backend::AffairsControllerTest < ActionController::TestCase
  test_restfully_all_actions  select: {mode: :show, params: {third_id: identify(:legal_entities_001), deal_type: "sale"}}, attach: {mode: :touch, params: {deal_id: identify(:sales_001), deal_type: "sale"}}, detach: {mode: :destroy, params: {deal_id: identify(:sales_001), deal_type: "sale"}}

  test "should not attach invalid deal" do
    affair = affairs(:affairs_001)
    assert affair.valid?, "Affair 001 must be valid"
    post :attach, {id: affair.id}
    assert_response :error, "Error expected with no given deal"
  end

  test "should not detach invalid deal" do
    affair = affairs(:affairs_001)
    assert affair.valid?, "Affair 001 must be valid"
    post :detach, {id: affair.id}
    assert_response :error, "Error expected with no given deal"
  end

end
