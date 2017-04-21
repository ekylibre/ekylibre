require 'test_helper'

class NomenTest < ActiveSupport::TestCase
  setup do
    I18n.locale = ENV['LOCALE']
  end

  Nomen.each do |nomenclature|
    test "#{nomenclature.name} translations unicity" do
      translations = nomenclature.list.map(&:human_name)
      unique_translations = translations.uniq
      count = (translations.size - unique_translations.size)
      assert count.zero?, "#{count} translations are repeated for different items: " + unique_translations.select { |t| translations.count { |l| l == t } > 1 }.sort.to_sentence(locale: :eng)
    end
  end

  test 'working_sets expression' do
    invalids = []
    Nomen::WorkingSet.list.each do |item|
      begin
        WorkingSet.to_sql(item.expression)
      rescue WorkingSet::SyntaxError => e
        invalids << { item: item, exception: e }
      end
    end
    details = invalids.map do |invalid|
      item = invalid[:item]
      exception = invalid[:exception]
      "#{item.name.to_s.yellow}:\n" \
      "  expression: #{item.expression.inspect}\n" \
      "  exception: #{exception.message}"
    end.join("\n")

    assert invalids.empty?, "#{invalids.count} working sets have invalid syntax:\n" + details.dig
  end

  test 'product_natures abilities' do
    invalids = []
    Nomen::ProductNature.list.each do |item|
      begin
        WorkingSet::AbilityArray.load(item.abilities).check!
      rescue Exception => e
        invalids << { item: item, exception: e }
      end
    end
    details = invalids.map do |invalid|
      item = invalid[:item]
      exception = invalid[:exception]
      "#{item.name.to_s.yellow}:\n" \
      "  expression: #{item.abilities.inspect}\n" \
      "  exception: #{exception.message}"
    end.join("\n")

    assert invalids.empty?, "#{invalids.count} product nature have invalid abilities:\n" + details.dig
  end

  test 'product_nature_variants indicators' do
    invalids = []
    Nomen::ProductNatureVariant.find_each do |item|
      if item.frozen_indicators_values.to_s.present?
        item.frozen_indicators_values.to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
            .collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each do |i|
          indicator_name = i.first.strip.downcase.to_sym
          nature = Nomen::ProductNature.find(item.nature)
          unless nature.frozen_indicators.include? indicator_name
            invalids << { item: item, exception: "Indicator :#{indicator_name} is not one of '#{item.name}' nature '#{item.nature}'" }
          end
        end
      end
    end
    details = invalids.map do |invalid|
      item = invalid[:item]
      exception = invalid[:exception]
      "#{item.name.to_s.yellow}:\n" \
      "  expression: #{item.abilities.inspect}\n" \
      "  exception: #{exception.message}"
    end.join("\n")

    assert invalids.empty?, "#{invalids.count} product nature have invalid abilities:\n" + details.dig
  end
end
