class SetValidatedAtValueOnForwardJournalEntry < ActiveRecord::Migration[4.2]
  def up
    execute <<~SQL
      UPDATE journal_entries je
      SET validated_at = je.printed_on
      FROM journals j
      WHERE je.journal_id = j.id
      AND j.nature = 'forward'
      AND je.validated_at IS NULL
      AND je.state != 'draft'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE journal_entries je
      SET validated_at = NULL
      FROM journals j
      WHERE je.journal_id = j.id
      AND j.nature = 'forward'
      AND je.validated_at = je.printed_on
      AND je.state != 'draft'
    SQL
  end
end
