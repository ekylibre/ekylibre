# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: affairs
#
#  accounted_at     :datetime
#  closed           :boolean          not null
#  closed_at        :datetime
#  created_at       :datetime         not null
#  creator_id       :integer
#  credit           :decimal(19, 4)   default(0.0), not null
#  currency         :string(3)        not null
#  deals_count      :integer          default(0), not null
#  debit            :decimal(19, 4)   default(0.0), not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  number           :string(255)      not null
#  originator_id    :integer          not null
#  originator_type  :string(255)      not null
#  third_id         :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#
require 'test_helper'

class AffairTest < ActiveSupport::TestCase

  # check that every model that can be affairable
  def test_affairables
    for type in Affair::AFFAIRABLE_TYPES
      model = type.constantize
      assert model.respond_to?(:deal_third), "Model #{type} cannot be used with affairs"
    end
  end

  # def test_attachment
  #   affair = affairs(:affairs_003)
  #   deals = [incoming_payments(:incoming_payments_001), sales(:sales_001)]
  #   for deal in deals
  #     affair.attach(deal)
  #   end
  #   assert_equal (deals.size + 1), affair.deals_count, "The deals count is invalid"
  # end

end
