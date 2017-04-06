module Backend
  class RegularizationsController < Backend::BaseController
    manage_restfully except: %i[index show new edit update], identifier: :id

    def create
      journal_entry = JournalEntry.find(params[:journal_entry_id])
      affair = Affair.find(params[:affair_id])
      Regularization.create!(journal_entry: journal_entry, affair: affair)
      redirect_to params[:redirect] || { controller: :affairs, action: :show, id: affair }
    end

    def show
      return unless @regularization = find_and_check
      redirect_to controller: :journal_entries, action: :show, id: @regularization.journal_entry.id
    end
  end
end
