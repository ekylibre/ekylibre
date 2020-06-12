# frozen_string_literal: true

module PanierLocal
  class Base < ActiveExchanger::Base
    class UniqueResultExpectedError < StandardError; end

    # @return [Import]
    def import_resource
      @import_resource ||= Import.find(options[:import_id])
    end

    def account_normalizer
      @account_normalier ||= Accountancy::AccountNumberNormalizer.build
    end

    def unwrap_one(name, error_many: nil, error_none: nil, exact: false, &block)
      results = block.call
      size = results.size

      if size > 1
        message = if error_many.nil?
                    "Expected only one #{name}, got #{size}"
                  elsif error_many.respond_to?(:call)
                    error_many.call(size: size)
                  else
                    error_many
                  end

        raise UniqueResultExpectedError, message
      elsif exact && size == 0
        message = if error_none.nil?
                    "Expected only one #{name}, got none"
                  elsif error_none.respond_to?(:call)
                    error_none.call
                  else
                    error_none
                  end

        raise UniqueResultExpectedError, message
      else
        results.first
      end
    end

    # @return [String]
    def client_account_radix
      @client_account_radix ||= Preference.value(:client_account_radix).presence || '411'
    end

    # @return [User]
    def responsible
      import_resource.creator
    end

    # @param [String] account_number
    # @return [Account, nil]
    def find_account_by_provider(account_number)
      unwrap_one('account') do
        Account.of_provider_vendor(:panier_local)
               .of_provider_data(:account_number, account_number)
      end
    end

    # @param [String] code
    # @return [Entity, nil]
    def find_entity_by_provider(code)
      unwrap_one('entity') { Entity.of_provider_vendor(:panier_local).of_provider_data(:entity_code, code) }
    end

    # @param [String] entity_name
    # @param [String] account_number
    # @param [String] entity_code
    # @return [Entity]
    def find_or_create_entity(entity_name, account_number, entity_code)
      Maybe(find_entity_by_provider(entity_code))
        .recover { find_entity_by_account_number_or_create(entity_name, account_number, entity_code) }
        .or_raise
    end

    # @param [String] entity_name
    # @param [String] account_number
    # @param [String] entity_code
    # @return [Entity]
    def find_entity_by_account_number_or_create(entity_name, account_number, entity_code)
      account = Maybe(find_account_by_provider(account_number))
                  .recover { Account.find_by(number: account_normalizer.normalize!(account_number)) }
                  .recover { create_entity_account(entity_name, account_number) }
                  .or_raise

      Maybe(find_entity_by_client_account(account))
        .recover { Entity.create!(
          active: true,
          client: true,
          client_account_id: account.id,
          codes: { 'panier_local' => entity_code },
          last_name: entity_name.mb_chars.capitalize,
          nature: :organization,
          provider: provider_value(entity_code: entity_code)
        ) }
        .or_raise
    end

    # @param [String] entity_name
    # @param [String] account_number
    # @return [Account]
    def create_entity_account(entity_name, account_number)
      clean = account_normalizer.normalize!(account_number)

      auxiliary_number = clean[3..-1]
      if auxiliary_number.match(/\A0*\z/).present?
        raise StandardError.new("Can't create account. Number provided can't be a radical class")
      end

      attributes = {
        number: clean,
        name: entity_name,
        centralizing_account_name: 'clients',
        nature: 'auxiliary',
        auxiliary_number: auxiliary_number,
        provider: provider_value(account_number: account_number)
      }

      Account.create!(**attributes)
    end

    # @param [Account] account
    # @return [Entity, nil]
    def find_entity_by_client_account(account)
      unwrap_one('entity') { Entity.joins(:client_account).where(accounts: { number: account.number }) }
    end

    protected

      def provider_value(**data)
        { vendor: provider_vendor, name: provider_name, id: import_resource.id, data: data }
      end

      def provider_name
        raise StandardError, "Unimplemented!"
      end

      def provider_vendor
        :panier_local
      end

      def tl(*unit, **options)
        I18n.t("exchanger.panier_local.#{provider_name}.#{unit.map(&:to_s).join('.')}", **options)
      end
  end
end