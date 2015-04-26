require 'test_helper'

class NomenTest < ActiveSupport::TestCase

  setup do
    # All document template should be loaded already
    # DocumentTemplate.load_defaults
    I18n.locale = ENV["LOCALE"]
  end


  Nomen.each do |nomenclature|

    test "#{nomenclature.name} translations unicity" do
      translations = nomenclature.list.map(&:human_name)
      unique_translations = translations.uniq
      count = (translations.size - unique_translations.size)
      assert count.zero?, "#{count} translations are repeated for different items: " + unique_translations.select{|t| translations.select{|l| l == t }.size > 1}.sort.to_sentence(locale: :eng)
    end

  end

  test "working_sets expression" do
    invalids = []
    Nomen::WorkingSets.list.each do |item|
      begin
        WorkingSet.to_sql(item.expression)
      rescue WorkingSet::SyntaxError => e
        invalids << {item: item, exception: e}
      end
    end
    details = invalids.map do |invalid|
      item = invalid[:item]
      exception = invalid[:exception]
      "#{item.name.to_s.yellow}:\n" +
        "  expression: #{item.expression.inspect}\n" +
        "  exception: #{exception.message}"
    end.join("\n")

    assert invalids.empty?, "#{invalids.count} working sets have invalid syntax:\n" + details.dig
  end

end
