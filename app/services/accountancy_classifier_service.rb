# frozen_string_literal: true

class AccountancyClassifierService
  attr_reader :log_result

  def self.classify_from_data(*args, **options)
    new(*args, **options).classify_from_data
  end

  def self.call(*args, **options)
    new(*args, **options).classify_from_ia
  end

  def initialize(journal_entry_item_ids: )
    @jei = JournalEntryItem.where(id: journal_entry_item_ids).where("activity_budget_id IS NULL").reorder(:printed_on)
    @log_result = {}
  end

  def classify_from_data
    @jei.each do |item|
      similar_items = JournalEntryItem.where("account_id = ? AND activity_budget_id IS NOT NULL AND similarity(LOWER(unaccent(name)), LOWER(unaccent(?))) >= 0.8", item.account_id, item.name).reorder(:printed_on)
      if similar_items.present?
        reference_item = similar_items.last
        item.update!(activity_budget_id: reference_item.activity_budget_id)
      end
    end
  end

  # La reconnaissance d'entités s'appuyait sur `Clients::Mistral::Ner`, retiré
  # de lib/clients : elle doit désormais passer par un service Python distinct,
  # qui reste à brancher. La méthode lève plutôt que de renvoyer un résultat
  # vide, qui se confondrait avec un « rien à classer ».
  def classify_from_ia
    raise NotImplementedError.new("Clients::Mistral a été retiré : brancher le service de reconnaissance d'entités avant d'appeler #classify_from_ia")
  end
end
