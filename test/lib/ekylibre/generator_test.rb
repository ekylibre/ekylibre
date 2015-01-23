# encoding: UTF-8
require 'test_helper'

class Ekylibre::GeneratorTest < ActiveSupport::TestCase

  setup do
  end

  test "creation 2 ways transcoding files for bos taurus nomenclature" do

    tr = Ekylibre::Tele::Idele::Generator.new
    tr.bos_taurus

  end

  #test "import sex from typeSexe xsd" do
  #  tr = Ekylibre::Tele::Idele::Generator.new
  #  tr.sexes
  #end

  #test "creation transcoding file for countries" do
  #  tr = Ekylibre::Tele::Idele::Generator.new
  #  tr.countries
  #end

  #test "creation transcoding file for birth conditions" do
  #  tr = Ekylibre::Tele::Idele::Generator.new
  #  tr.mammalia_birth_conditions
  #end

end
