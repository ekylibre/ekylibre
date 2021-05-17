# frozen_string_literal: true

# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class AnalyticSequencesController < Backend::BaseController
    manage_restfully only: %i[new create edit update]

    def index
      @analytic_sequences = AnalyticSequence.all.includes(:segments).references(:segments)
      if FinancialYearExchange.where(transmit_isacompta_analytic_codes: true).exists?
        @analytic_sequences_grid = initialize_grid(@analytic_sequences)
        empty_analytic_codes.each do |segment|
          notify_warning(:fill_analytic_codes_of_your_segments.tl(segment: segment))
        end
      else
        notify(:activate_transmit_analytic_codes.tl)
      end
    end

    private

      def empty_analytic_codes
        segments = @analytic_sequences.map do |sequence|
          sequence.segments.map(&:name)
        end.flatten.compact.uniq

        segments.map do |segment|
          if segment.singularize.classify.constantize.where(isacompta_analytic_code: nil).exists?
            segment.text.downcase
          end
        end
      end
  end
end
