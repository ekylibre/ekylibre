# frozen_string_literal: true

class BankStatementClassifierService
  attr_reader :log_result

  def self.call(*args)
    new(*args).call
  end

  def initialize(bank_statement_ids: )
    @bank_statement = BankStatement.find(bank_statement_ids)
    @bank_statement_items = @bank_statement.items
    @log_result = {}
  end

  def call
    # build data to send to Mistral
    data = @bank_statement_items.map{|i| "#{i.id.to_s} - #{i.name}"}.join(',')
    # call Mistral Ner service
    c = Clients::Mistral::Ner.new
    result = c.extract_metadata_from_bank_statements(data)
    puts result.inspect.yellow
    return result[:error] if result[:error].present?

    @log_result[:items_classified] = 0
    @bank_statement_items.each do |bs_item|
      matching_item = result[:entities].find {|item| item[:id] == bs_item.id.to_s }
      next unless matching_item.present?

      # find payment_mode and link it to bs_item
      if matching_item[:payment_mode].present? && bs_item.transaction_nature.blank?
        # set payment_mode to bs_item
        bs_item.update!(transaction_nature: matching_item[:payment_mode])
      end

      # find or create entity and link it to bs_item
      if matching_item[:name].present? && bs_item.entity.blank?
        # find or create entity
        entity = Entity.where('full_name ILIKE ?', matching_item[:name].strip).first
        unless entity
          entity = Entity.new(last_name: matching_item[:name].strip, full_name: matching_item[:name].strip, active: true)
          if matching_item[:nature] == "organisation"
            entity.nature = :organization
          else
            entity.nature = :contact
          end
          if bs_item.balance > 0
            entity.supplier = true
          else
            entity.client = true
          end
          entity.save!
        end
        # set entity to bs_item
        bs_item.update!(entity_id: entity.id)
        if matching_item[:role].present? && entity.present? && entity.description.blank?
          entity.update!(description: matching_item[:role])
        end
        @log_result[:items_classified] += 1
      end
    end
    @log_result
  end
end
