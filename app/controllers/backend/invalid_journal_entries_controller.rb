module Backend
  class InvalidJournalEntriesController < Backend::BaseController
    def index; end

    def delete_all
      JournalEntry.where.not(balance: 0.0).destroy_all
      redirect_to controller: :journals, action: :index
    end
  end
end
