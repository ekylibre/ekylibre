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
# == Table: affairs
#
#  accounted_at           :datetime
#  cash_session_id        :integer
#  closed                 :boolean          default(FALSE), not null
#  closed_at              :datetime
#  created_at             :datetime         not null
#  creator_id             :integer
#  credit                 :decimal(19, 4)   default(0.0), not null
#  currency               :string           not null
#  dead_line_at           :datetime
#  deals_count            :integer          default(0), not null
#  debit                  :decimal(19, 4)   default(0.0), not null
#  description            :text
#  id                     :integer          not null, primary key
#  journal_entry_id       :integer
#  letter                 :string
#  lock_version           :integer          default(0), not null
#  name                   :string
#  number                 :string
#  origin                 :string
#  pretax_amount          :decimal(19, 4)   default(0.0)
#  probability_percentage :decimal(19, 4)   default(0.0)
#  responsible_id         :integer
#  state                  :string
#  third_id               :integer          not null
#  type                   :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#

class SaleOpportunity < SaleAffair
  include Commentable
  include Versionable
  attr_readonly :currency
  refers_to :origin, class_name: 'OpportunityOrigin'
  belongs_to :client, class_name: 'Entity', foreign_key: :third_id
  has_many :tasks
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]
  validates :client, :responsible, presence: true
  validates :probability_percentage, numericality: { in: 0..100 }

  state_machine :state, initial: :prospecting do
    state :prospecting
    state :qualification
    state :value_proposition
    state :price_quote
    state :negociation
    state :won
    state :lost

    event :prospect do
      transition all => :prospecting
      # transition :prospecting => :qualification
      # transition :value_proposition => :qualification
    end

    event :qualify do
      transition all => :qualification
      # transition :prospecting => :qualification
      # transition :value_proposition => :qualification
    end

    event :evaluate do
      transition all => :value_proposition
      # transition :qualification => :value_proposition
      # transition :price_quote => :value_proposition
    end

    event :quote do
      transition all => :price_quote
      # transition :value_proposition => :price_quote
      # transition :negociation => :price_quote
    end

    event :negociate do
      transition all => :negociation
      # transition :price_quote => :negociation
      # transition :won => :negociation
      # transition :lost => :negociation
    end

    event :win do
      transition all => :won
      #  transition :negociation => :won
    end

    event :lose do
      transition all => :lost
      # transition :prospecting => :lost
      # transition :qualification => :lost
      # transition :value_proposition => :lost
      # transition :price_quote => :lost
      # transition :negociation => :lost
    end
  end

  before_validation(on: :create) do
    self.state ||= :prospecting
    self.currency ||= Preference[:currency]
  end

  def status
    if lost?
      :stop
    elsif won?
      :go
    else
      :caution
    end
  end

  # Returns timeleft in seconds of the sale opportunities
  def timeleft(at = Time.zone.now)
    return nil if dead_line_at.nil? || dead_line_at <= at
    (dead_line_at - at)
  end

  def human_status
    I18n.t("tooltips.models.sale_opportunity.#{state}")
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(self.state.to_sym).human_name
  end

  # Returns age in seconds of the sale opportunities
  def age(at = Time.zone.now)
    return nil if created_at.nil?
    (at - created_at)
  end
end
