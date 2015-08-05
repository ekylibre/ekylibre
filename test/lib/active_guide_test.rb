require 'test_helper'

class ActiveGuideTest < ActiveSupport::TestCase
  test 'sample guide' do
    # guide = ActiveGuide::Base.new :test_guide do
    class TestGuide < ActiveGuide::Base
      result :penalty
      before do
        variables.penalty = 0
        variables.b = 54
      end
      group :toto do
        group :tests_1 do
          test :thing_1_quality, proc { variables.a = 5 }
          test :thing_2_quality, proc { rand(100) > 60 }
          test :thing_3_quality, proc { FinancialYear.any? }
          test :thing_4_quality do
            validate do
              rand > 0.5
            end
            after do
              variables.penalty += 5 unless answer
            end
          end
        end
        group :tests_2 do
          test :thing_5_quality do
            subtest :thin_a, proc { true }
            subtest :thin_b, proc { rand(100) > 30 }
            subtest :thin_c, proc { Account.any? }
            after do
              variables.penalty += 3 unless answer
            end
          end
          question :something_to_ask
          test :thing_6, proc { variables.any? }
        end
      end
    end

    TestGuide.run(verbose: false)
  end
end
