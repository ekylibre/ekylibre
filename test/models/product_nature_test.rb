# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
# == Table: product_natures
#
#  abilities_list            :text
#  active                    :boolean          default(FALSE), not null
#  category_id               :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  derivative_of             :string
#  derivatives_list          :text
#  description               :text
#  evolvable                 :boolean          default(FALSE), not null
#  frozen_indicators_list    :text
#  id                        :integer          not null, primary key
#  linkage_points_list       :text
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  number                    :string           not null
#  picture_content_type      :string
#  picture_file_name         :string
#  picture_file_size         :integer
#  picture_updated_at        :datetime
#  population_counting       :string           not null
#  reference_name            :string
#  subscribing               :boolean          default(FALSE), not null
#  subscription_days_count   :integer          default(0), not null
#  subscription_months_count :integer          default(0), not null
#  subscription_nature_id    :integer
#  subscription_years_count  :integer          default(0), not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  variable_indicators_list  :text
#  variety                   :string           not null
#
require 'test_helper'

class ProductNatureTest < ActiveSupport::TestCase
  test_model_actions
  test 'working sets scope' do
    Nomen::WorkingSet.list.each do |item|
      assert ProductNature.of_working_set(item.name).count >= 0
    end
  end

  test 'working sets expression' do
    expressions = ProductNature.all.map do |n|
      expr = "is #{n.variety}"
      expr << " and derives from #{n.derivative_of}" if n.derivative_of?
      if n.abilities_list.any?
        begin
          n.abilities_list.check!
        rescue WorkingSet::InvalidExpression => e
          puts "Invalid abilities list: #{e.message}".red
          next
        end
        expr << ' and (' + n.abilities_list.map { |a| "can #{a}" }.join(' and ') + ')'
      end
      expr
    end.compact.uniq
    assert_operator expressions.count, :>, 10, 'More than 10 expressions are expected in product natures'
    expressions.each do |expression|
      scope_count = ProductNature.of_expression(expression).count
      direct_count = ProductNature.select { |n| n.of_expression(expression) }.count
      assert_operator scope_count, :>, 0
      assert_operator direct_count, :>, 0
      assert_equal scope_count, direct_count, "Expression '#{expression}' doesn't permit to find same natures (scope: #{scope_count} [#{ProductNature.of_expression(expression).pluck(:id).to_sentence}], direct: #{direct_count}  [#{ProductNature.select { |n| n.of_expression(expression) }.map(&:id).to_sentence}])"
    end
  end

  test 'flattened nomenclature' do
    assert ProductNature.flattened_nomenclature
    assert ProductNature.flattened_nomenclature.respond_to?(:any?)
    assert ProductNature.flattened_nomenclature.any?
    assert ProductNature.items_of_expression('is vitis').any?
    assert ProductNature.items_of_expression('is vitis or is bos_taurus').any?
    assert ProductNature.items_of_expression('can store(plant)').any?
  end
end
