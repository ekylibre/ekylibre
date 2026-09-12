# frozen_string_literal: true

class BankStatementClassifierService
  attr_reader :log_result

  def self.classify_from_data(*args, **options)
    new(*args, **options).classify_from_data
  end

  def self.call(*args, **options)
    new(*args, **options).classify_from_ia
  end

  def initialize(bank_statement_ids: )
    @bank_statement = BankStatement.find(bank_statement_ids)
    @bank_statement_items = @bank_statement.items.where(entity_id: nil).reorder(:transfered_on).limit(100)
    @log_result = {}
  end

  def classify_from_data
    @bank_statement_items.each do |bs_item|
      similar_items = BankStatementItem.where.not(entity_id: nil).where("similarity(unaccent(name), unaccent(?)) >= 0.8", bs_item.name).reorder(:transfered_on)
      if similar_items.present?
        reference_item = similar_items.last
        if reference_item.transaction_nature.present?
          bs_item.update!(entity_id: reference_item.entity_id, transaction_nature: reference_item.transaction_nature)
        else
          bs_item.update!(entity_id: reference_item.entity_id)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("BankStatementClassifierService#classify_from_data: skipping bank_statement_item ##{bs_item.id} (#{e.message})")
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
