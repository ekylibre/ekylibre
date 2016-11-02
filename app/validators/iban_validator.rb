class IbanValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :invalid) unless valid_iban?(value)
  end

  private

  def valid_iban?(iban)
    iban = iban.to_s
    return false unless iban.length > 4 && iban.length <= 34
    str = iban[4..iban.length] + iban[0..1] + '00'

    # Test the iban key
    str.each_char do |c|
      str.gsub!(c, c.to_i(36).to_s) if c =~ /\D/
    end
    iban_key = 98 - (str.to_i.modulo 97)
    (iban_key.to_i == iban[2..3].to_i)
  end
end
