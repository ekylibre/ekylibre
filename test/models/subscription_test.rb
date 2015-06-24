# = Informations
#
# == License
#
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: subscriptions
#
#  address_id        :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  description       :text
#  first_number      :integer
#  id                :integer          not null, primary key
#  last_number       :integer
#  lock_version      :integer          default(0), not null
#  nature_id         :integer
#  number            :string
#  product_nature_id :integer
#  quantity          :decimal(19, 4)
#  sale_id           :integer
#  sale_item_id      :integer
#  started_at        :datetime
#  stopped_at        :datetime
#  subscriber_id     :integer
#  suspended         :boolean          default(FALSE), not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#


require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  # Add tests here...
end
