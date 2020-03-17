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
# == Table: synchronization_operations
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  finished_at     :datetime
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  notification_id :integer
#  operation_name  :string           not null
#  originator_id   :integer
#  originator_type :string
#  request         :jsonb
#  response        :jsonb
#  state           :string           not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class SynchronizationOperation < Ekylibre::Record::Base
  enumerize :state, in: %i[undone in_progress errored aborted finished], predicates: true, default: :undone
  enumerize :operation_name, in: %i[get_inventory authenticate get_urls], predicates: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :finished_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :operation_name, :state, presence: true
  validates :originator_type, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  has_many :calls, as: :source
  belongs_to :notification

  delegate :human_message, to: :notification, allow_nil: true

  belongs_to :originator, polymorphic: true

  has_many :targets, class_name: 'Animal', foreign_key: :originator_id, inverse_of: :originator

  scope :of_product, ->(product) { joins(:originator).where('originator_id IS NOT NULL AND originator.product_id = ?', product.id) }

  scope :operation, lambda { |name, options = {}|
    options[:state] ||= :finished
    order(created_at: :desc).where(operation_name: name, state: options[:state])
  }

  def notify(message, interpolations = {}, options = {})
    if creator
      creator.notify(message, interpolations.merge(operation_name: "enumerize.synchronization_operation.operation_name.#{operation_name}".t), options.merge(target: self))
    end
  end

  class << self
    def run(operation, options = {})
      so = create!(operation_name: operation, state: :undone)
      Ekylibre::Hook.publish operation, options.merge(synchronization_operation_id: so.id)
    end
  end
end
