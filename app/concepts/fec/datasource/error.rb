# frozen_string_literal: true

module FEC
  module Datasource
    class Error < FEC::Datasource::Base

      # Datas returned are the same that in FEC::Datasource::Exporter file but as ActiveRecord instead of hash
      def perform
        JournalEntry.where(journal: @journals)
                    .between(@started_on, @stopped_on)
                    .with_compliance_errors('fec', 'journal_entries')
      end
    end
  end
end
