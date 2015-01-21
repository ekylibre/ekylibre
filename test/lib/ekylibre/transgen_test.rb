# encoding: UTF-8
require 'test_helper'

class Ekylibre::TransgenTest < ActiveSupport::TestCase

  setup do
  end

  #test "import race code from idele csv" do

  #  tr = Ekylibre::Tele::Idele::Transgen.new
  #  tr.bos_taurus

  #end

  test "import sex from typeSexe xsd" do
    tr = Ekylibre::Tele::Idele::Transgen.new
    tr.sexes
  end

end
