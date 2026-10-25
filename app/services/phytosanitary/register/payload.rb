# frozen_string_literal: true

module Phytosanitary
  module Register
    Payload = Struct.new(
      :holder_siret,
      :holder_name,
      :campaign_name,
      :period_from,
      :period_to,
      :generated_at,
      :entries,
      keyword_init: true
    ) do
      def empty?
        entries.nil? || entries.empty?
      end

      def size
        entries.to_a.size
      end

      def freeze
        entries.each(&:freeze) if entries
        entries.freeze if entries
        super
      end
    end
  end
end
