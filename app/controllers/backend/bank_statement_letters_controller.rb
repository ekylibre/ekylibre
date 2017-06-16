module Backend
  # Handles bank reconciliation lettering.
  class BankStatementLettersController < Backend::BaseController
    def create
      return unless find_bank_statement

      bank_items     = BankStatementItem.where(id: params[:bank_statement_items])
      journal_items  = JournalEntryItem.where(id: params[:journal_entry_items])

      new_letter = @bank_statement.letter_items(bank_items, journal_items)
      return head(:bad_request) unless new_letter

      respond_to do |format|
        format.json {  render json: { letter: new_letter } }
      end
    end

    def destroy
      return unless find_bank_statement

      letter = params[:id]
      JournalEntryItem
        .pointed_by(@bank_statement)
        .where(bank_statement_letter: letter)
        .update_all(bank_statement_letter: nil, bank_statement_id: nil)
      @bank_statement
        .items
        .where(letter: letter)
        .update_all(letter: nil)

      respond_to do |format|
        format.json {  render json: { letter: letter } }
      end
    end

    private

    def find_bank_statement
      @bank_statement = BankStatement.find_by(id: params[:bank_statement_id])
      @bank_statement || (head(:bad_request) && nil)
    end
  end
end
