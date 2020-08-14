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
# == Table: registered_seeds
#
#  complete_name :jsonb
#  name          :jsonb
#  number        :integer          not null, primary key
#  specie        :string           not null
#
class RegisteredSeed < ActiveRecord::Base
  include Lexiconable
  self.id_column = :number
  self.name_column = "name->>'fra'"

  delegate :unit, to: :class

  def articles
    Article.where(reference_id: id, reference_type: self.class.name.underscore)
  end

  def chemical?
    false
  end

  def source_nature
    :seed
  end

  def to_article
    unless Article.find_by(name: proper_name)
      Article.new(reference_type: self.class.name.underscore, reference_id: id, name: proper_name, nature: :seed, species: specie, unit: unit)
    end
  end

  def proper_name
    n = Nomen::Variety.find(specie.to_sym)
    if n
      n.human_name + '-' + name[Preference[:language]]
    else
      name['fra']
    end
  end

  class << self
    def matching(query = '')
      matches = Array(query).map do |match|
        sanitize_sql_array(["(lower(unaccent(complete_name->>'fra')) ILIKE lower(unaccent(?)))", "%#{match}%"])
      end
      if matches.compact.present?
        condition = '(' + matches.join(' OR ') + ')'
        return where(condition).order(condition + ' DESC')
      else
        return all
      end
    end

    def unit
      Nomen::Unit['kilogram']
    end
  end
end
