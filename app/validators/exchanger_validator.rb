class ExchangerValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :invalid) unless is_valid_exchanger? record, value
  end

  private

    def is_valid_exchanger?(record, value)
      transformer = options.fetch(:transform, nil)
      if transformer
        value = transformer.is_a?(Symbol) ? record.send(transformer, value) : transformer.call(record, value)
      end

      ActiveExchanger::Base.find_by value
    end
end
