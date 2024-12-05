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
# == Table: email_templates
#  by_default   :boolean          not null, default(false)
#  body         :text             not null
#  created_at   :datetime         not null
#  creator_id   :integer(4)
#  format       :string
#  handler      :string
#  id           :integer(4)       not null, primary key
#  language     :string
#  locale       :string
#  lock_version :integer(4)       default(0), not null
#  name         :string           not null
#  nature       :string
#  path         :string
#  partial      :boolean          not null, default(false)
#  updated_at   :datetime         not null
#  updater_id   :integer(4)
#

class EmailTemplate < ApplicationRecord
  refers_to :nature, class_name: 'DocumentNature'
  refers_to :language
  store_templates

  validates :nature, inclusion: { in: nature.values }

  before_validation do
    self.format ||= "html"
    self.handler ||= "liquid"
    self.locale ||= nil
    self.language ||= Preference[:language]
  end

  class << self
    # Loads in DB all default email templates depending to the locales
    def load_defaults(options = {})
      locale = (options[:locale] || Preference[:language] || I18n.locale)

      mail_template_file = Rails.root.join('config', 'locales', locale.to_s, 'email_templates.yml')
      mail_template = (mail_template_file.exist? ? YAML.load_file(mail_template_file) : {}).deep_symbolize_keys.freeze

      ApplicationRecord.transaction do
        destroy_all
        mail_template[locale.to_sym][:email_templates].each do |_k, v|
          create!(name: v[:name],
                  nature: v[:nature],
                  locale: locale,
                  path: v[:path],
                  format: v[:format],
                  handler: v[:handler],
                  by_default: v[:by_default],
                  body: v[:body],
                  metadata: v[:metadata])
        end
      end
      true
    end
  end
end
