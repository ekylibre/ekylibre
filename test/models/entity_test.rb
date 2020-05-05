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
# == Table: entities
#
#  active                       :boolean          default(TRUE), not null
#  activity_code                :string
#  authorized_payments_count    :integer
#  bank_account_holder_name     :string
#  bank_identifier_code         :string
#  born_at                      :datetime
#  client                       :boolean          default(FALSE), not null
#  client_account_id            :integer
#  codes                        :jsonb
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  currency                     :string           not null
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  deliveries_conditions        :string
#  description                  :text
#  employee                     :boolean          default(FALSE), not null
#  employee_account_id          :integer
#  first_financial_year_ends_on :date
#  first_met_at                 :datetime
#  first_name                   :string
#  full_name                    :string           not null
#  iban                         :string
#  id                           :integer          not null, primary key
#  language                     :string           not null
#  last_name                    :string           not null
#  legal_position_code          :string
#  lock_version                 :integer          default(0), not null
#  locked                       :boolean          default(FALSE), not null
#  meeting_origin               :string
#  nature                       :string           not null
#  number                       :string
#  of_company                   :boolean          default(FALSE), not null
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer
#  picture_updated_at           :datetime
#  proposer_id                  :integer
#  prospect                     :boolean          default(FALSE), not null
#  provider                     :jsonb
#  reminder_submissive          :boolean          default(FALSE), not null
#  responsible_id               :integer
#  siret_number                 :string
#  supplier                     :boolean          default(FALSE), not null
#  supplier_account_id          :integer
#  supplier_payment_delay       :string
#  supplier_payment_mode_id     :integer
#  title                        :string
#  transporter                  :boolean          default(FALSE), not null
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  vat_number                   :string
#  vat_subjected                :boolean          default(TRUE), not null
#

require 'test_helper'

class EntityTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'nature' do
    entity = Entity.create(nature: :zarb)
    assert entity.errors.include?(:nature), 'Entity must not accept invalid nature'
    entity = Entity.create(nature: :contact)
    assert !entity.errors.include?(:nature), 'Entity must accept contact nature'
    entity = Entity.create(nature: :organization)
    assert !entity.errors.include?(:nature), 'Entity must accept organization nature'
  end

  test 'have a number' do
    accountant = build(:entity, number: '')
    assert accountant.valid?
  end

  test 'has many booked journals' do
    accountant = create(:entity, :accountant, :with_booked_journals)
    refute accountant.booked_journals.empty?
  end

  test 'does not have financial year with opened exchange without financial year' do
    accountant = create(:entity, :accountant)
    refute accountant.financial_year_with_opened_exchange?
  end

  test 'has financial year with opened exchange' do
    accountant = accountant_with_financial_year_and_opened_exchange
    assert accountant.financial_year_with_opened_exchange?
  end

  test 'cannot destroy when it has financial year with opened exchange' do
    accountant = accountant_with_financial_year_and_opened_exchange
    assert_raises { accountant.destroy }
  end

  test 'merge' do
    observation_count = 0
    main = Entity.normal.first
    observation_count += main.observations.count
    double = Entity.normal.where(id: EntityAddress.where.not(entity_id: main.id).select(:entity_id)).first
    observation_count += double.observations.count
    main.merge_with(double)
    assert_nil Entity.find_by(id: double.id)
    assert observation_count, main.observations.count
    # TODO: Check addresses, attributes, custom fields, and observations
  end

  test 'merge with author' do
    observation_count = 0
    main = Entity.normal.first
    observation_count += main.observations.count
    double = Entity.normal.where(id: EntityAddress.where.not(entity_id: main.id).select(:entity_id)).first
    observation_count += double.observations.count
    main.merge_with(double, author: User.first)
    assert_nil Entity.find_by(id: double.id)
    assert observation_count + 1, main.observations.count
    # TODO: Check addresses, attributes, custom fields, and observations
  end

  test 'can only have valid siret numbers or none at all' do
    company = Entity.normal.find_by(country: 'fr')
    company.siret_number = nil
    assert company.valid?
    company.siret_number = '1234' # Too short
    assert !company.valid?
    company.siret_number = '12345678901011' # Right length but invalid
    assert !company.valid?
    company.siret_number = '123455555544444444' # Valid but too long
    assert !company.valid?
    company.siret_number = '80853428300037' # Valid
    assert company.valid?
  end

  def accountant_with_financial_year_and_opened_exchange
    accountant = create(:entity, :accountant)
    financial_year = FinancialYear.last
    financial_year.update_attribute :accountant_id, accountant.id
    create(:financial_year_exchange, :opened, financial_year: financial_year)
    accountant
  end

  test 'is_france true if country fr' do
    e = Entity.new
    e.country = 'fr'

    assert e.in_france?
  end

  test 'is_france false if other country' do
    e = Entity.new
    e.country = 'de'

    refute e.in_france?
  end

  test 'do not validate siret if entity not in france' do
    e = Entity.new
    e.country = 'de'
    e.siret_number=42

    refute e.tap(&:valid?).errors.key? :siret_number
  end

  test 'automatic employee account creation ventilates based on entity_id' do
    e = Entity.create! last_name: "Dummy"

    e.update! employee: true

    assert_equal "421#{e.id.to_s.rjust(5, '0')}", e.employee_account.number
  end
end
