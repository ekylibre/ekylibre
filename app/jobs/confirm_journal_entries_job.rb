class ConfirmJournalEntriesJob < ActiveJob::Base
  queue_as :default

  def perform(journal_ids, user)
    journal_entries = JournalEntry.where(id: journal_ids)
    undone = 0
    begin
      for entry in journal_entries
        entry.confirm if entry.can_confirm?
        undone += 1 if entry.draft?
      end
      notification = user.notifications.build(notification_params(true, journal_entries.size - undone, nil))
    rescue Exception => e
      notification = user.notifications.build(notification_params(false, nil, e.message))
    end
    notification.save
  end

  private

  def notification_params(message, number, error)
    {
      message: message ? :draft_journal_entries_have_been_validated : :exception_raised,
      level: message ? :success : :error,
      target_type: 'JournalEntry',
      interpolations: {
        count: number,
        error_message: error
      }
    }
  end
end
