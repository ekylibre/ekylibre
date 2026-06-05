# frozen_string_literal: true

module Phytosanitary
  module Register
    module Exporters
      class JsonExporter < Base
        def call
          JSON.pretty_generate(
            meta: meta_hash,
            entries: @payload.entries.to_a.map { |e| entry_hash(e) }
          )
        end
      end
    end
  end
end
