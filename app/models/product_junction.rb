# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: product_junctions
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string
#  started_at      :datetime
#  stopped_at      :datetime
#  tool_id         :integer
#  type            :string
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductJunction < Ekylibre::Record::Base
  include Taskable
  belongs_to :tool, class_name: 'Product'
  has_many :ways, class_name: 'ProductJunctionWay', inverse_of: :junction, foreign_key: :junction_id, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  # ]VALIDATORS]
  validates_presence_of :started_at, :stopped_at

  before_validation do
    self.started_at ||= Time.now
    self.stopped_at ||= self.started_at
  end

  class << self
    def has_way(name, *args)
      options = args.extract_options!
      options[:nature] ||= :continuity
      code = ''
      code << "has_one :#{name}_way, -> { where(role: '#{name}') }, class_name: 'ProductJunctionWay', foreign_key: :junction_id, inverse_of: :junction\n"
      code << "has_one :#{name}, through: :#{name}_way, source: :road\n"

      code << "accepts_nested_attributes_for :#{name}_way\n"

      code << "def create_#{name}!(road)\n"
      code << "  self.ways.create!(road: road, role: '#{name}',  nature: :#{options[:nature]})\n"
      code << "end\n"

      code << "def self.#{name}_options\n"
      code << "  {nature: :#{options[:nature]}}\n"
      code << "end\n"

      class_eval(code)
    end

    def has_finish(name, *args)
      options = args.extract_options!
      options[:nature] = :finish
      has_way(name, *args, options)
    end

    def has_start(name, *args)
      options = args.extract_options!
      options[:nature] = :start
      has_way(name, *args, options)
    end
  end
end
