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
# == Table: fixed_asset_depreciations
#
#  accountable        :boolean          default(FALSE), not null
#  accounted_at       :datetime
#  amount             :decimal(19, 4)   not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  depreciable_amount :decimal(19, 4)
#  depreciated_amount :decimal(19, 4)
#  financial_year_id  :integer
#  fixed_asset_id     :integer          not null
#  id                 :integer          not null, primary key
#  journal_entry_id   :integer
#  lock_version       :integer          default(0), not null
#  locked             :boolean          default(FALSE), not null
#  position           :integer
#  started_on         :date             not null
#  stopped_on         :date             not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#
class FixedAssetDepreciation < Ekylibre::Record::Base
  acts_as_list scope: :fixed_asset
  belongs_to :fixed_asset
  belongs_to :financial_year
  belongs_to :journal_entry, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accountable, :locked, inclusion: { in: [true, false] }
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :depreciable_amount, :depreciated_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(fixed_asset_depreciation) { fixed_asset_depreciation.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :fixed_asset, presence: true
  # ]VALIDATORS]
  delegate :currency, :number, to: :fixed_asset

  scope :with_active_asset, -> { joins(:fixed_asset).where(locked: false, fixed_assets: { state: :in_use }) }
  scope :not_accountable, -> { where(accountable: false) }
  scope :not_locked, -> { where(locked: false) }
  scope :up_to, ->(date) { where('fixed_asset_depreciations.stopped_on <= ?', date) }

  scope :with_active_asset_up_to, lambda { |date|
    joins(:fixed_asset)
      .where('fixed_asset_depreciations.accountable = false AND fixed_asset_depreciations.locked = false AND fixed_asset_depreciations.stopped_on <= ? AND fixed_assets.state = ?', date, :in_use)
  }

  sums :fixed_asset, :depreciations, amount: :depreciated_amount

  bookkeep

  protect(on: :destroy) do
    journal_entry.present? && !journal_entry.draft?
  end

  after_initialize do
    next if persisted?

    self.locked ||= false
  end

  before_validation do
    if fixed_asset
      self.depreciated_amount = fixed_asset.depreciations.where('stopped_on < ?', started_on).sum(:amount) + amount
      self.depreciable_amount = fixed_asset.depreciable_amount - depreciated_amount
    end
  end

  validate do
    # A start day must be the depreciation start or a financial year start
    if financial_year &&
      fixed_asset&.started_on &&
      started_on != fixed_asset.started_on &&
      started_on != financial_year.started_on &&
      started_on != started_on.beginning_of_month
      errors.add(:started_on, :invalid_start_date, start: fixed_asset.started_on)
    end
  end

  def has_journal_entry?
    !journal_entry.nil?
  end

  # Returns the duration of the depreciation
  def duration
    FixedAsset.duration(started_on, stopped_on, mode: fixed_asset.depreciation_method.to_sym)
  end
end
