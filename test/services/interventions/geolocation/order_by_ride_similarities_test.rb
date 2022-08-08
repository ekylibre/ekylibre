require 'test_helper'

module Interventions
  module Geolocation
    class OrderByRideSimilaritiesTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      setup do
        @objects = @interventions_similarity_scores_double = [
          { intervention: 1, total_score: 10, date_score: -4 },
          { intervention: 2, total_score: 1, date_score: -8 },
          { intervention: 3, total_score: 1, date_score: -2 }
        ].map(&:to_struct)
      end

      test 'Filters and orders interventions' do
        intervention_ordered = OrderByRideSimilarities.call(interventions_similarity_scores: @interventions_similarity_scores_double)
        assert_equal( 2, intervention_ordered.count)
        assert_equal([1, 3], intervention_ordered )
      end
    end
  end
end
