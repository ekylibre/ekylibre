# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
# == Table: product_labellings
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  label_id     :integer          not null
#  lock_version :integer          default(0), not null
#  product_id   :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ProductLabelling < Ekylibre::Record::Base
  include Labellable
  belongs_to :product, inverse_of: :labellings
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :label, :product, presence: true
  # ]VALIDATORS]
end
