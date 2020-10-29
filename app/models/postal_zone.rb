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
# == Table: postal_zones
#
#  city         :string
#  city_name    :string
#  code         :string
#  country      :string           not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  district_id  :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  postal_code  :string           not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

class PostalZone < Ekylibre::Record::Base
  refers_to :country
  belongs_to :district
  has_many :mail_addresses, class_name: 'EntityAddress', foreign_key: :mail_postal_zone_id
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :city, :city_name, :code, length: { maximum: 500 }, allow_blank: true
  validates :country, presence: true
  validates :name, :postal_code, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :country, length: { allow_nil: true, maximum: 2 }

  before_validation do
    self.name = name.gsub(/\s+/, ' ').strip if name
    words = name.to_s.split(' ')
    start = (words[0].to_s.ascii.length <= 3 ? 2 : 1)
    self.postal_code = ''
    self.city = ''
    self.city_name = ''
    if words.present?
      self.postal_code = (words[0..start - 1] || []).join(' ')
      self.city = (words[start..-1] || []).join(' ')
      self.city_name = city
      if city_name =~ /cedex/i
        self.city_name = city_name.split(/\scedex/i)[0].strip
      end
    end
  end

  def self.exportable_columns
    content_columns.delete_if { |c| !%i[city postal_code].include?(c.name.to_sym) }
  end
end
