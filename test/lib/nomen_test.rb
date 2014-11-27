# encoding: UTF-8
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

end
