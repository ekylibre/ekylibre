module ActionIntegration
  class Parameters
    attr_accessor :ivs, :ciphered

    delegate :keys, :values, to: :values

    def initialize(ciphered, ivs)
      @ciphered = ciphered || {}
      @ivs = ivs || {}
      @values = {}
      @cipher = OpenSSL::Cipher::AES256.new(:CBC)

      @cipher.decrypt

      @cipher.key = Base64.urlsafe_decode64(ActionIntegration.config.cipher_key)

      @ciphered.map do |name, value|
        @cipher.iv = Parameters.decode(@ivs[name])
        @values[name] = @cipher.update(Parameters.decode(value)) + @cipher.final
      end

      self
    end

    def self.cipher(parameters)
      new_parameters = Parameters.new(nil, nil)

      parameters.each do |name, value|
        new_parameters[name] = value
      end

      new_parameters
    end

    def [](name)
      @values[name]
    end

    def []=(name, new_val)
      @cipher.encrypt

      @cipher.key = Base64.urlsafe_decode64(ActionIntegration.config.cipher_key).force_encoding 'UTF-8'

      iv = @cipher.random_iv
      @ivs[name] = Parameters.encode(iv)
      @ciphered[name] = Parameters.encode(@cipher.update(new_val) + @cipher.final)
      @values[name] = new_val
    end

    private

    def self.encode(value)
      Base64.encode64(value)
    end

    def self.decode(value)
      Base64.decode64(value)
    end
  end
end
