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
# == Table: integrations
#
#  ciphered_parameters    :jsonb
#  created_at             :datetime         not null
#  creator_id             :integer
#  data                   :jsonb
#  id                     :integer          not null, primary key
#  initialization_vectors :jsonb
#  lock_version           :integer          default(0), not null
#  nature                 :string           not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

# Integration model is here to save connection parameters in (encrypted) store
# to keep them reusable when necessary.
class Integration < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :nature, presence: true, uniqueness: true, length: { maximum: 500 }
  # ]VALIDATORS]
  delegate :authentication_mode, :check_connection, :integration_name, to: :integration_type
  composed_of :parameters,
              class_name: 'ActionIntegration::Parameters',
              mapping: [%w[ciphered_parameters ciphered], %w[initialization_vectors ivs]],
              converter: proc { |parameters| ActionIntegration::Parameters.cipher(parameters) }

  validate do
    next unless ciphered_parameters_changed?
    next unless integration_type
    next unless authentication_mode == :check
    check_connection attributes do |c|
      c.redirect do
        errors.add(:parameters, :check_redirected)
      end
      c.error do
        errors.add(:parameters, :check_errored)
      end
    end
  end

  before_validation do
    self.initialization_vectors = parameters.ivs
    self.ciphered_parameters = parameters.ciphered
  end

  before_destroy do
    ActionIntegration::Base.find_integration(nature).on_logout(trigger: true)
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

  def name
    nature.to_s.camelize
  end

  def update_data(new_data)
    update(data: data.merge(new_data))
  end

  class << self
    def active?(name)
      find_by(nature: name).present?
    end
  end
end
