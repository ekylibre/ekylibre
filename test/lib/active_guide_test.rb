require 'test_helper'

class ActiveGuideTest < ActiveSupport::TestCase

  test "sample guide" do
    guide = ActiveGuide::Base.new :test_guide do
      result :penalty
      before do
        variables.penalty = 0
        variables.b = 54
      end
      group :toto do
        group :tests_1 do
          test :thing_1_quality, Proc.new { variables.a = 5 }
          test :thing_2_quality, Proc.new { rand(100) > 60 }
          test :thing_3_quality, Proc.new { FinancialYear.any? }
          test :thing_4_quality do
            validate do
              rand > 0.5
            end
            after do
              unless answer
                variables.penalty += 5
              end
            end
          end
        end
        group :tests_2 do
          test :thing_5_quality do
            subtest :thin_a, Proc.new { true }
            subtest :thin_b, Proc.new { rand(100) > 30 }
            subtest :thin_c, Proc.new { Account.any? }
            after do
              unless answer
                variables.penalty += 3
              end
            end
          end
          question :something_to_ask
          test :thing_6, Proc.new { variables.any? }
        end
      end
    end

    guide.run(verbose: false)
  end


end
