class NormalizePercentagesAndRates < ActiveRecord::Migration
  RATES = {
    :entities => :reduction_rate,
    :sale_natures => :downpayment_rate,
    :subscription_natures => :reduction_rate
  }.to_a.freeze
  PERCENTS = {
    :users => :reduction_percent,
    :incoming_payment_modes => :commission_percent,
    :sale_lines => :reduction_percent
  }.to_a.freeze

  def up
    # TODO : remove discount_rate ?
    for table, column in RATES
      execute("UPDATE #{quoted_table_name(table)} SET #{column} = 100 * #{column}")
      change_column table, column, :decimal, :precision => 19, :scale => 4
      rename_column table, column, column.to_s.gsub(/_rate$/, "_percentage").to_sym
    end
    for table, column in PERCENTS
      rename_column table, column, column.to_s.gsub(/_percent$/, "_percentage").to_sym
    end

    rename_column :users, :reduction_percentage, :maximal_grantable_reduction_percentage

    change_column :taxes, :nature, :string, :limit => 16
    execute "UPDATE #{quoted_table_name(:taxes)} SET nature = 'percentage' WHERE nature = 'percent'"

    # rename_column :users, :username, :user_name
  end

  def down
    # rename_column :users, :user_name, :username

    execute "UPDATE #{quoted_table_name(:taxes)} SET nature = 'percent' WHERE nature = 'percentage'"
    change_column :taxes, :nature, :string, :limit => 8

    rename_column :users, :maximal_grantable_reduction_percentage, :maximum_grantable_reduction_percentage

    for table, column in PERCENTS.reverse
      rename_column table, column.to_s.gsub(/_percent$/, "_percentage").to_sym, column
    end
    for table, column in RATES.reverse
      rename_column table, column.to_s.gsub(/_rate$/, "_percentage").to_sym, column
      change_column table, column, :decimal, :precision => 19, :scale => 10
      execute("UPDATE #{quoted_table_name(table)} SET #{column} = #{column} / 100")
    end
  end
end
