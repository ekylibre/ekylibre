class ValidateDraftJournalEntriesService
  def initialize(entries)
    @entries = entries
  end

  def validate_all
    JournalEntry.transaction do
      ApplicationRecord.connection.execute('LOCK journal_entries IN ACCESS EXCLUSIVE MODE')
      @entries.update_all(state: :confirmed, validated_at: Time.zone.now)
      JournalEntryItem.where(entry_id: @entries).update_all(state: :confirmed)
    end
  end
end
