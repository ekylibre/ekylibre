class CreateCashIndicators < ActiveRecord::Migration[5.0]
  def change

    create_table :economic_cash_indicators do |t|
      t.string :context, index: true
      t.string :context_color
      t.references :activity, index: true
      t.references :activity_budget, index: true
      t.references :activity_budget_item, index: true
      t.references :worker_contract, index: true
      t.references :loan, index: true
      t.references :campaign, index: true
      t.references :product_nature_variant, index: true
      t.date :used_on, index: true
      t.date :paid_on, index: true
      t.string :direction, index: true
      t.string :nature, index: true
      t.string :origin, index: true
      t.decimal :pretax_amount
      t.decimal :amount
      t.stamps
    end

  end
end
