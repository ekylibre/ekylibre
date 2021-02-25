# frozen_string_literal: true

module Depreciable
  extend ActiveSupport::Concern

  private

    def split_depreciation!(depreciation, date)
      total_amount = depreciation.amount
      period = Accountancy::Period.new(depreciation.started_on, depreciation.stopped_on)
      before, after = period.split date

      depreciation.update! stopped_on: before.stop,
                           amount: resource.round(total_amount * before.days / period.days)

      resource.depreciations.create! position: depreciation.position + 1,
                                     amount: total_amount - depreciation.amount,
                                     started_on: after.start,
                                     stopped_on: after.stop
    end

    def depreciations_valid?(date)
      active = resource.depreciation_on date
      active.nil? || resource.depreciations.following(active).all? { |d| !d.has_journal_entry? }
    end
end
