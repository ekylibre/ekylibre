require 'test_helper'

class Backend::Hajimari::CapImportsControllerTest < ActionController::TestCase

  def setup
    @cap_file = File.read(Rails.root.join('test','fixtures', 'files', 'cap_file'))
  end

  test "should parse cap file" do
    hashed = {}
    hashed = Hash.from_xml(@cap_file)
    hashed.deep_symbolize_keys!
    assert_not_empty hashed
    assert_equal 'GAEC DUPONT', hashed[:producteurs][:producteur][:demandeur][:identification_societe][:exploitation]

  end

end