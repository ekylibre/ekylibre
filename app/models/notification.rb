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
# == Table: notifications
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  interpolations :json
#  level          :string           not null
#  lock_version   :integer          default(0), not null
#  message        :string           not null
#  read_at        :datetime
#  recipient_id   :integer          not null
#  target_id      :integer
#  target_type    :string
#  target_url     :string
#  updated_at     :datetime         not null
#  updater_id     :integer
#

# Column message expect a string which is more an ID. It permits to be i18nized.
# Notifications are used to inform users asynchronously.
class Notification < Ekylibre::Record::Base
  enumerize :level, in: %i[information success warning error], default: :information
  belongs_to :recipient, class_name: 'User'
  belongs_to :target, polymorphic: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :level, :recipient, presence: true
  validates :message, presence: true, length: { maximum: 500 }
  validates :read_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :target_type, :target_url, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]

  def read!
    update_attributes!(read_at: Time.zone.now)
  end

  def human_message
    "notifications.messages.#{message}".t(interpolations.symbolize_keys.merge(default: message.humanize))
  end
end
