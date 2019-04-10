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
# == Table: call_messages
#
#  body         :text
#  call_id      :integer
#  created_at   :datetime         not null
#  creator_id   :integer
#  format       :string
#  headers      :text
#  id           :integer          not null, primary key
#  ip_address   :string
#  lock_version :integer          default(0), not null
#  nature       :string           not null
#  request_id   :integer
#  ssl          :string
#  status       :string
#  type         :string
#  updated_at   :datetime         not null
#  updater_id   :integer
#  url          :string
#  verb         :string
#

# Class representing any message linked to APIs in DB, whether ours or others.
class CallMessage < Ekylibre::Record::Base
  belongs_to :operation, class_name: 'Call', foreign_key: :call_id
  enumerize :nature, in: %i[incoming outgoing], predicates: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :body, :headers, length: { maximum: 500_000 }, allow_blank: true
  validates :format, :ip_address, :ssl, :status, :url, :verb, length: { maximum: 500 }, allow_blank: true
  validates :nature, presence: true
  # ]VALIDATORS]
end
