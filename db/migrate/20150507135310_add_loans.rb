class AddLoans < ActiveRecord::Migration

  def change

    create_table :loans do |t|
      t.references :lender,   null: false, index: true
      t.string     :name,     null: false
      t.references :cash,     null: false, index: true
      t.string     :currency, null: false
      t.decimal    :amount,               precision: 19, scale: 4, null: false
      # Annually
      t.decimal    :interest_percentage,  precision: 19, scale: 4, null: false
      t.decimal    :insurance_percentage, precision: 19, scale: 4, null: false
      t.date       :started_on,             null: false
      t.integer    :repayment_duration,     null: false
      t.string     :repayment_period,       null: false
      t.string     :repayment_method,       null: false
      t.integer    :shift_duration,         null: false, default: 0
      t.string     :shift_method
      t.references :journal_entry,         index: true
      t.datetime   :accounted_at
      t.stamps
    end

    create_table :loan_repayments do |t|
      t.references :loan,             null: false, index: true
      t.integer    :position,         null: false
      t.decimal    :amount,           null: false, precision: 19, scale: 4
      t.decimal    :base_amount,      null: false, precision: 19, scale: 4
      t.decimal    :interest_amount,  null: false, precision: 19, scale: 4
      t.decimal    :insurance_amount, null: false, precision: 19, scale: 4
      t.decimal    :remaining_amount, null: false, precision: 19, scale: 4
      t.date       :due_on,           null: false
      t.references :journal_entry,         index: true
      t.datetime   :accounted_at
      t.stamps
    end

  end


end
