# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  headers      :string
#  id           :integer          not null, primary key
#  ip           :string
#  lock_version :integer          default(0), not null
#  nature       :string
#  request_id   :integer
#  ssl          :string
#  status       :string
#  type         :string
#  updated_at   :datetime         not null
#  updater_id   :integer
#  url          :string
#  verb         :string
#
class CallResponse < CallMessage
  belongs_to :request, class_name: 'CallRequest'
  delegate :method, :ip, :url, to: :request

  # Create a CallResponse from an ActionResponse
  def self.create_from_response!(response, request)
    create!(
      nature: :outgoing, # Because we come from a controller here.
      status: response.status,
      headers: response.headers,
      body: response.body,
      format: response.content_type,
      request: request
    )
  end

  def self.create_from_net_response!(response, request)
    create!(
      nature: :incoming, # Because we are receiving an answer.
      status: response.code,
      headers: response.to_hash,
      body: response.body,
      format: response.content_type,
      request: request
    )
  end

  def self.create_from_savon_httpi_response!(response, request)
    create!(
      nature: :incoming, # Receiving an answer in protocol.
      status: response.code,
      headers: response.headers,
      body: response.raw_body,
      format: response.headers.split(';').first,
      request: request
    )
  end
end
