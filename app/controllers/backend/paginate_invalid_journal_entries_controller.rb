module Backend
  class PaginateInvalidJournalEntriesController < Backend::BaseController
    def index
      @current_page = params[:page].to_i
      @invalid_entries = JournalEntry.where.not(balance: 0.0).order(:printed_on)
      @invalid_entries_count = @invalid_entries.count
      @invalid_entries = @invalid_entries.page(@current_page).per(2)
    end
  end
end
