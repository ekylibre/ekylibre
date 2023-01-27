# frozen_string_literal: true

module Interventions
  module Geolocation
    class OrderByRideSimilarities
      DATE_MIN_SCORE = -7

      def self.call(*args)
        new(*args).call
      end

      def initialize(interventions_similarity_scores:)
        @interventions_similarity_scores = interventions_similarity_scores
      end

      def call
        interventions_similarity_scores
          .reject{ |intervention_similarity_score| intervention_similarity_score.date_score < DATE_MIN_SCORE }
          .sort_by!(&:total_score)
          .reverse!
          .map(&:intervention)
      end

      private
        attr_reader :interventions_similarity_scores
    end
  end
end
