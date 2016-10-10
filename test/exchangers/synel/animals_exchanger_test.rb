require 'test_helper'

module Synel
  class AnimalsExchangerTest < ::ActiveExchanger::TestCase
    test 'import' do
      ::ActiveExchanger::Base.import(:synel_animals, fixture_files_path.join('imports', 'synel_animals.csv'))
    end
  end
end
