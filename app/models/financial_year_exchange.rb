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
# == Table: financial_year_exchanges
#
#  closed_at                :datetime
#  created_at               :datetime         not null
#  creator_id               :integer
#  financial_year_id        :integer          not null
#  id                       :integer          not null, primary key
#  import_file_content_type :string
#  import_file_file_name    :string
#  import_file_file_size    :integer
#  import_file_updated_at   :datetime
#  lock_version             :integer          default(0), not null
#  public_token             :string
#  public_token_expired_at  :datetime
#  started_on               :date             not null
#  stopped_on               :date             not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#
class FinancialYearExchange < Ekylibre::Record::Base
  belongs_to :financial_year
  has_many :journal_entries, dependent: :nullify
  has_one :accountant, through: :financial_year
  has_attached_file :import_file, path: ':tenant/:class/:id/:style.:extension'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed_at, :import_file_updated_at, :public_token_expired_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :import_file_content_type, :import_file_file_name, length: { maximum: 500 }, allow_blank: true
  validates :import_file_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :public_token, uniqueness: true, length: { maximum: 500 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(financial_year_exchange) { financial_year_exchange.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :financial_year, presence: true
  # ]VALIDATORS]
  validates :stopped_on, presence: true, timeliness: { on_or_before: ->(exchange) { exchange.financial_year_stopped_on || (Time.zone.today + 50.years) }, type: :date }
  do_not_validate_attachment_file_type :import_file

  scope :opened, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  class << self
    def for_public_token(public_token)
      find_by!('public_token = ? AND public_token_expired_at >= ?', public_token, Time.zone.today)
    end
  end

  after_initialize :set_initial_values, if: :initializeable?
  before_validation :set_started_on, on: :create
  before_create :close_journal_entries
  after_create :set_journal_entries_financial_year_exchange

  def opened?
    !closed_at
  end

  def close!
    self.closed_at = Time.zone.now
    save!
  end

  def accountant_email
    return unless financial_year && financial_year.accountant
    address = financial_year.accountant.default_email_address
    address && address.coordinate
  end

  def accountant_email?
    accountant_email.present?
  end

  def generate_public_token!
    set_public_token_and_expiration
    save!
  end

  private

  delegate :stopped_on, to: :financial_year, prefix: true, allow_nil: true

  def initializeable?
    new_record?
  end

  def set_initial_values
    if stopped_on.blank? && financial_year
      self.stopped_on = [Date.yesterday, financial_year.stopped_on].min
    end
  end

  def set_started_on
    self.started_on = compute_started_on unless started_on
  end

  def set_public_token_and_expiration
    self.public_token = SecureRandom.urlsafe_base64(32)
    self.public_token_expired_at = Time.zone.today + 1.month
  end

  def close_journal_entries
    JournalEntryItem.where(entry: related_journal_entries).update_all(state: 'closed')
    related_journal_entries.update_all(state: 'closed')
    # related_journal_entries.where(state: :draft).find_each(&:confirm)
    # related_journal_entries.where(state: :confirmed).find_each(&:close)
  end

  def set_journal_entries_financial_year_exchange
    related_journal_entries.update_all financial_year_exchange_id: id
  end

  def related_journal_entries
    JournalEntry.joins(:journal).where(printed_on: started_on..stopped_on).where('journals.accountant_id IS NULL OR journals.accountant_id != ?', financial_year.accountant_id)
  end

  def compute_started_on
    return unless financial_year
    previous_exchange_stopped_on = financial_year.exchanges.limit(1).where('stopped_on < ?', stopped_on).reorder(stopped_on: :desc).pluck(:stopped_on).first
    previous_exchange_stopped_on || financial_year.started_on
  end
end
