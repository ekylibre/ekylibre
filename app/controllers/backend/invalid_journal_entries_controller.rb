module Backend
  class InvalidJournalEntriesController < Backend::BaseController
    def index
      @invalid_entries = JournalEntry.where.not(balance: 0.0).order(:printed_on)
      @invalid_entries_count = @invalid_entries.count
      @invalid_entries = @invalid_entries.page(params[:page]).per(2)
    end

    def delete_all
      JournalEntry.where.not(balance: 0.0).destroy_all
      redirect_to controller: :journals, action: :index
    end
  end
end
