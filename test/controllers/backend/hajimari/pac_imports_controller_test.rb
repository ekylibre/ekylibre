require 'test_helper'

class Backend::Hajimari::PacImportsControllerTest < ActionController::TestCase

  def setup
    @pac_file = File.read(Rails.root.join('test','fixtures', 'files', 'pac_file'))
  end

  test "should parse pac file" do
    hashed = {}
    hashed = Hash.from_xml(@pac_file)
    hashed.deep_symbolize_keys!
    assert_not_empty hashed
    assert_equal 'GAEC DUPONT', hashed[:producteurs][:producteur][:demandeur][:identification_societe][:exploitation]

  end

end