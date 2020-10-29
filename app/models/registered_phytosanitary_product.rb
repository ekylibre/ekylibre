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
# == Table: registered_phytosanitary_products
#
#  active_compounds             Array<:text>
#  allowed_mentions             :jsonb
#  firm_name                    :string
#  france_maaid                 :string           not null
#  id                           :integer          not null, primary key
#  in_field_reentry_delay       :interval
#  mix_category_codes           Array<:integer>
#  name                         :string           not null
#  natures                      Array<:text>
#  operator_protection_mentions :text
#  other_names                  Array<:text>
#  product_type                 :string
#  record_checksum              :integer
#  reference_name               :string           not null
#  restricted_mentions          :string
#  started_on                   :date
#  state                        :string           not null
#  stopped_on                   :date
#
class RegisteredPhytosanitaryProduct < ActiveRecord::Base
  extend Enumerize
  include HasInterval
  include Lexiconable
  include ScopeIntrospection
  include Searchable

  has_many :phrases, class_name: 'RegisteredPhytosanitaryPhrase', foreign_key: :product_id, dependent: :restrict_with_exception
  has_many :risks, class_name: 'RegisteredPhytosanitaryRisk', foreign_key: :product_id, dependent: :restrict_with_exception
  has_many :usages, class_name: 'RegisteredPhytosanitaryUsage', foreign_key: :product_id, dependent: :restrict_with_exception

  enumerize :state, in: %w[authorized inherited withdrawn], predicates: true
  has_interval :in_field_reentry_delay
  search_on :name, :firm_name, :france_maaid

  delegate :unit, to: :class

  def phytosanitary_product
    self
  end

  def chemical?
    true
  end

  def source_nature
    :chemical
  end

  def state
    if product_type == 'PCP'
      RegisteredPhytosanitaryProduct.find(france_maaid).state
    else
      super
    end
  end

  def allowed_mentions
    if product_type == 'PCP'
      RegisteredPhytosanitaryProduct.find(france_maaid).allowed_mentions
    else
      super
    end
  end

  def usages
    if product_type == 'PCP'
      RegisteredPhytosanitaryProduct.find(france_maaid).usages
    else
      super
    end
  end

  def risks
    if product_type == 'PCP'
      RegisteredPhytosanitaryProduct.find(france_maaid).risks
    else
      super
    end
  end

  def phrases
    if product_type == 'PCP'
      RegisteredPhytosanitaryProduct.find(france_maaid).phrases
    else
      super
    end
  end

  def mix_category_codes
    super || []
  end

  # @return [Array<String>]
  def natures
    super || []
  end

  def proper_name
    [natures.first, name, france_maaid, firm_name].compact.join(' - ')
  end

  def label_method
    "#{france_maaid} - #{name.capitalize}"
  end

  def decorated_reentry_delay
    decorate.in_field_reentry_delay
  end

  def allowed_for_organic_farming?
    allowed_mentions.present? && allowed_mentions.keys.include?('organic_usage')
  end

  class << self
    def unit
      Nomen::Unit['liter']
    end
  end
end
