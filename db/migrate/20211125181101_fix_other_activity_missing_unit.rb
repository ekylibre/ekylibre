class FixOtherActivityMissingUnit < ActiveRecord::Migration[5.0]
  def change
    update_view :economic_indicators, version: 4, revert_to_version: 3, materialized: true
  end
end
