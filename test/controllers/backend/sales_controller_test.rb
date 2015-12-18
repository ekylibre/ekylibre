# -*- coding: utf-8 -*-
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
  class SalesControllerTest < ActionController::TestCase
    test_restfully_all_actions cancel: :redirected_get, contacts: :index_xhr, except: :generate_parcel

    test 'should print an invoice' do
      sale = sales(:sales_001)
      assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
      template = DocumentTemplate.of_nature(:sales_invoice).first
      assert template, 'No template found for sales_invoice'
      assert_nothing_raised do # "Template #{template.inspect} doesn't seems to work"
        get :show, id: sale.id, format: :pdf, key: sale.number, template: template.id
      end
      assert_response :success
    end
  end
end
