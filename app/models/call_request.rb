# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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

# Represents a Request in DB.
class CallRequest < CallMessage
  has_many :responses, class_name: 'CallResponse', foreign_key: :request_id

  def self.create_from_request!(request)
    # We were hitting the char limit on the weird requests Rails does to test controllers.
    url = Rails.env.test? ? request.host : request.original_url[0...500]
    create!(
      nature: :incoming, # Because we are in one of our own controllers here.
      headers: request.headers,
      body: request.body,
      ip_address: request.ip,
      url: url,
      format: request.format,
      verb: request.method,
      ssl: request.ssl?
    )
  end

  def self.create_from_net_request!(http, request, format)
    create!(
      nature: :outgoing, # We are hitting up someone.
      headers: request.to_hash,
      body: request.body,
      url: http.address + request.path,
      format: format,
      verb: request.method,
      ssl: http.use_ssl?
    )
  end

  def self.create_from_savon_httpi_request!(req, format)
    create!(
      nature: :outgoing, # We are hitting up someone.
      headers: req.headers,
      body: req.body,
      url: req.url,
      format: format,
      verb: :POST,
      ssl: req.ssl?
    )
  end

  def last_response
    responses.order(:created_at).last
  end
end
