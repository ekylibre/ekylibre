# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: associates
#
#

class Associate < ApplicationRecord
  include Attachable
  include Customizable

  enumerize :associate_nature, in: %i[owner usufructuary bare_owner], default: :owner, predicates: true
  belongs_to :associate_account, class_name: 'Account'
  belongs_to :entity
  has_many :main_journal_entry_items, through: :associate_account, source: :journal_entry_items

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :currency, presence: true, length: { maximum: 500 }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :share_quantity, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :share_unit_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :stopped_on, timeliness: { on_or_after: ->(associate) { associate.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  validates :entity, presence: true
  # ]VALIDATORS]

  delegate :name, to: :entity, prefix: true

  before_validation do
    self.started_on ||= Date.today
    self.currency ||= Preference[:currency]
  end

  def balance(fy = nil)
    if fy.nil?
      main_journal_entry_items.sum('real_credit - real_debit') || 0.0
    else
      main_journal_entry_items.of_unclosure_journal.where(financial_year: fy).sum('real_credit - real_debit') || 0.0
    end
  end

  def percentage_on_company
    total = self.class.where(associate_nature: %w[owner bare_owner]).map { |a| a.share_unit_amount * a.share_quantity}.compact.sum
    if self.associate_nature != :usufructuary
      (100 * (self.share_unit_amount * self.share_quantity).to_d / total.to_d).round(2)
    else
      nil
    end
  end
end
