class UpdateReferenceNumberForExistingJournalEntries < ActiveRecord::Migration
  def change
    execute "UPDATE journal_entries AS je
               SET reference_number = CASE je.resource_type
                                      WHEN 'Sale' THEN s.number
                                      WHEN 'Purchase' THEN p.reference_number
                                      END
             FROM purchases AS p, sales AS s
             WHERE je.reference_number IS NULL
               AND ((je.resource_id = s.id AND je.resource_type = 'Sale')
                 OR (je.resource_id = p.id AND je.resource_type = 'Purchase'))"
  end
end
