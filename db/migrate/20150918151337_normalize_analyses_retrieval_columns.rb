class NormalizeAnalysesRetrievalColumns < ActiveRecord::Migration[4.2]
  def change
    rename_column :analyses, :state, :retrieval_status
    rename_column :analyses, :error_explanation, :retrieval_message
  end
end
