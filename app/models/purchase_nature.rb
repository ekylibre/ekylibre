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
# == Table: purchase_natures
#
#  active       :boolean          default(TRUE), not null
#  by_default   :boolean          default(FALSE), not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  id           :integer          not null, primary key
#  journal_id   :integer          not null
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class PurchaseNature < Ekylibre::Record::Base
  belongs_to :journal
  has_many :purchases, foreign_key: :nature_id, dependent: :restrict_with_exception

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :by_default, inclusion: { in: [true, false] }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :journal, presence: true
  # ]VALIDATORS]
  validates :name, uniqueness: true

  delegate :currency, to: :journal

  selects_among_all

  scope :actives, -> { where(active: true) }

  def with_accounting?
    ActiveSupport::Deprecation.warn "All purchase_natures are with accounting = true"
    true
  end

  def journal_currency
    ActiveSupport::Deprecation.warn 'journal_currency is deprecated, directly use `currency` or `journal.currency`'
    currency
  end

  def payslip?
    ActiveSupport::Deprecation.warn "No purchase_natures are payslips"
    false
  end

  class << self
    # Load default purchase nature
    def load_defaults(**_options)
      nature = :purchases
      currency = Preference[:currency]
      journal = Journal.find_by(nature: nature, currency: currency)
      journal ||= Journal.create!(name: "enumerize.journal.nature.#{nature}".t,
                                  nature: nature.to_s, currency: currency,
                                  closed_on: Date.new(1899, 12, 31).end_of_month)
      unless find_by(name: PurchaseNature.tc('default.name'))
        create!(
          name: PurchaseNature.tc('default.name'),
          active: true,
          journal: journal
        )
      end
    end
  end
end
