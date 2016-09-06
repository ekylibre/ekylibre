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
# == Table: integrations
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  nature       :string
#  parameters   :jsonb
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Integration < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :nature, uniqueness: true, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  delegate :auth_type, :check_connection, :integration_name, to: :integration_type
  before_destroy do
    ActionIntegration::Base.find_integration(nature).on_logout(trigger: true)
  end
  validate do
    check_connection self do |c|
      c.redirect do
        errors.add(:parameters, :check_redirected)
      end
      c.error do
        errors.add(:parameters, :check_errored)
      end
    end
  end

  after_save do
    Ekylibre::Hook.publish "#{nature}_check_successful"
  end

  def integration_type
    ActionIntegration::Base.find_integration(nature)
  end

  def parameter_keys
    integration_type.parameters
  end
end
