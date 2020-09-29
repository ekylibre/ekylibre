module Ekylibre
  class FixedAssetsExchanger < ActiveExchanger::Base
    category :accountancy
    vendor :ekylibre

    # Imports fixed assets into fixed assets DB
    # filename example : IMMOB.CSV
    # separator is ';' with headers and encoding is UTF-8
    # Columns are:
    #  0 - A: number
    #  1 - B: name
    #  2 - C: description
    #  3 - D: sale_account_number
    #  4 - E: depreciable_amount
    #  5 - F: currency
    #  6 - G: depreciation_method #need_transcode
    #  7 - H: started_on
    #  8 - I: depreciation_period #need_transcode
    #  9 - J: depreciation_percentage
    #  10 - K: depreciation_fiscal_coefficient #if depreciation_method is regressive
    #  11 - L: journal_code
    #  12 - M: journal_name
    #  13 - N: asset_account_number.
    #  14 - O: asset_account_name
    #  15 - P: special_imputation_asset_account_number.
    #  16 - Q: special_imputation_asset_account_name
    #  17 - R: allocation_account_number
    #  18 - S: allocation_account_name
    #  19 - T: expenses_account_number
    #  20 - U: expenses_account_name
    #  21 - V: state
    #  22 - W: accounted_on # when state is waiting
    #  23 - X : waiting_account_number # when state is waiting
    #  24 - Y - waiting_account_name # when state is waiting
    #  25 - Z - ceded_on #  when scrap or sold
    #  26 - AA - purchase_id # when scrap or sold

    NORMALIZATION_CONFIG = [
      { col: 0, name: :number, type: :string, constraint: :not_nil },
      { col: 1, name: :name, type: :string, constraint: :not_nil },
      { col: 2, name: :description, type: :string },
      { col: 3, name: :sale_account_number, type: :string },
      { col: 4, name: :depreciable_amount, type: :float, constraint: :greater_or_equal_to_zero },
      { col: 5, name: :currency, type: :string },
      { col: 6, name: :depreciation_method, type: :string, constraint: :not_nil },
      { col: 7, name: :started_on, type: :date, constraint: :not_nil },
      { col: 8, name: :depreciation_period, type: :string },
      { col: 9, name: :depreciation_percentage, type: :float, constraint: :greater_or_equal_to_zero },
      { col: 10, name: :depreciation_fiscal_coefficient, type: :float },
      { col: 11, name: :journal_code, type: :string },
      { col: 12, name: :journal_name, type: :string },
      { col: 13, name: :asset_account_number, type: :string, constraint: :not_nil },
      { col: 14, name: :asset_account_name, type: :string, constraint: :not_nil },
      { col: 15, name: :special_imputation_asset_account_number, type: :string },
      { col: 16, name: :special_imputation_asset_account_name, type: :string },
      { col: 17, name: :allocation_account_number, type: :string },
      { col: 18, name: :allocation_account_name, type: :string },
      { col: 19, name: :expenses_account_number, type: :string },
      { col: 20, name: :expenses_account_name, type: :string },
      { col: 21, name: :state, type: :string, constraint: :not_nil },
      { col: 22, name: :accounted_on, type: :date },
      { col: 23, name: :waiting_account_number, type: :string },
      { col: 24, name: :waiting_account_name, type: :string },
      { col: 25, name: :ceded_on, type: :date },
      { col: 26, name: :product_work_number, type: :string }
    ].freeze

    # state to map
    STATES = {
      'En Service' => :in_use,
      'Brouillon' => :draft,
      'En attente' => :waiting,
      'Vendue' => :sold,
      'Mise au rebut' => :scrapped
    }.freeze

    # period to map
    DEPRECIATION_PERIODS = {
      'Mensuelle' => :monthly,
      'Trimestrielle' => :quarterly,
      'Annuelle' => :yearly
    }.freeze

    # depreciation method to map
    DEPRECIATION_METHODS = {
      'Linéaire' => :linear,
      'Aucune' => :none,
      'Dégressive' => :regressive
    }.freeze

    # accounts to check
    ACCOUNT_NUMBER_PROPERTIES = %w[asset_account special_imputation_asset_account allocation_account expenses_account waiting_account].freeze

    def check
      rows, errors = parse_file(file)
      w.count = rows.size

      valid = errors.all?(&:empty?)
      if valid == false
        w.error "The file is invalid: #{errors}"
        return false
      end

      rows.each_with_index do |row, index|
        line_number = index + 2
        # w.check_point

        # check correct states method
        if row.state.present? && STATES[row.state].nil?
          w.error "Errors on state : #{row.state} in line : #{line_number} - #{valid}".red
          valid = false
        end

        # check correct depreciation method
        if row.depreciation_method.present? && DEPRECIATION_METHODS[row.depreciation_method].nil?
          w.error "Errors on depreciation_method : #{row.depreciation_method} in line : #{line_number} - #{valid}".red
          valid = false
        end

        # check correct depreciation period
        if row.depreciation_period.present? && DEPRECIATION_PERIODS[row.depreciation_period].nil?
          w.error "Errors on depreciation_period : #{row.depreciation_period} in line : #{line_number} - #{valid}".red
          valid = false
        end

        # check depreciation_period present if row.depreciation_method != none
        if row.depreciation_method.present? && DEPRECIATION_METHODS[row.depreciation_method] != :none && !row.depreciation_period.present?
          w.error "Missing depreciation_period in line : #{line_number} - #{valid}".red
          valid = false
        end

        # check depreciation_percentage present if row.depreciation_method != none
        if row.depreciation_method.present? && DEPRECIATION_METHODS[row.depreciation_method] != :none && row.depreciation_percentage == 0.0
          w.error "Missing depreciation_percentage in line : #{line_number} - #{valid}".red
          valid = false
        end

        # check accounts present if row.depreciation_method != none
        if row.depreciation_method.present? && DEPRECIATION_METHODS[row.depreciation_method] != :none && (!row.allocation_account_number.present? || !row.expenses_account_number.present?)
          w.error "Missing expenses or allocation accounts number in line : #{line_number} - #{valid}".red
          valid = false
        end

        # check depreciation_fiscal_coefficient present if row.depreciation_method == regressive
        if row.depreciation_method.present? && DEPRECIATION_METHODS[row.depreciation_method] == :regressive && !row.depreciation_fiscal_coefficient.present?
          w.error "Missing depreciation_fiscal_coefficient in line : #{line_number} - #{valid}".red
          valid = false
        end

        # check asset account must exist in DB
        ACCOUNT_NUMBER_PROPERTIES.each do |property|
          if row.send(property + '_number').present?
            account = find_or_create_account(row.send(property + '_number'), row.send(property + '_name'))
            if account.nil?
              w.error "No way to have matching asset account in DB or Nomenclature (#{row.send(property + '_number')}) to build fixed asset in line : #{line_number}"
              valid = false
            end
          end
        end

        # check journal if present in file
        if row.journal_code.present?
          journal = find_or_create_journal(row.journal_code, row.journal_name, 'fixed_assets')
          unless journal
            w.error "No way to find or create a journal with  (#{row.journal_code}) in line : #{line_number} - #{valid}"
            valid = false
          end
        end

        w.info "#{line_number} - #{valid}".green

      end
      w.info "End validation : #{valid}".yellow
      valid
    end

    def import
      rows, _errors = parse_file(file)
      w.count = rows.size
      currency_preference = Preference[:currency]

      # find default_journal for fixed_assets
      default_journal = Journal.find_by_nature('fixed_assets')
      default_journal ||= Journal.create!(name: "enumerize.journal.nature.fixed_assets".t, nature: 'fixed_assets', currency: currency_preference, closed_on: Date.new(1899, 12, 31).end_of_month)

      rows.each_with_index do |row, index|
        line_number = index + 2
        w.info "Fixed asset started : #{row.number} | #{row.name.inspect.yellow}"
        journal = find_or_create_journal(row.journal_code, row.journal_name, 'fixed_assets')

        # add general asset attributes
        asset_attributes = {
          name: row.name,
          currency: currency_preference,
          description: row.description,
          started_on: row.started_on,
          depreciable_amount: row.depreciable_amount,
          depreciation_method: DEPRECIATION_METHODS[row.depreciation_method].to_s,
          journal: (journal.presence || default_journal),
          asset_account: find_or_create_account(row.asset_account_number),
          state: STATES[row.state].to_s,
          provider: provider_value(number: row.number)
        }

        # add asset attributes for depreciables assets
        if DEPRECIATION_METHODS[row.depreciation_method] != :none
          asset_attributes[:depreciation_period] = DEPRECIATION_PERIODS[row.depreciation_period].to_s
          asset_attributes[:depreciation_percentage] = row.depreciation_percentage
          asset_attributes[:allocation_account] = find_or_create_account(row.allocation_account_number)
          asset_attributes[:expenses_account] = find_or_create_account(row.expenses_account_number)
        end

        # add asset depreciation_fiscal_coefficient for regressive depreciables case
        if DEPRECIATION_METHODS[row.depreciation_method] == :regressive
          asset_attributes[:depreciation_fiscal_coefficient] = row.depreciation_fiscal_coefficient
        end

        # add asset attributes for waiting assets
        if STATES[row.state] == :waiting
          asset_attributes[:waiting_account] = find_or_create_account(row.waiting_account_number)
        end

        # Check existing asset (name && started_on && depreciable_amount)
        asset = find_fixed_asset_by_provider(row.number)

        # Link asset to product if exist
        if row.product_work_number.present?
          product = Product.find_by(work_number: row.product_work_number.strip)
          product ||= Product.find_by(id: row.product_work_number.to_i)
          if product
            asset_attributes[:product_id] = product.id
          end
        end

        # Update, Nothing or Create asset
        if asset && asset.updateable?
          asset.update!(asset_attributes)
          w.info "Fixed asset updated : #{asset.name.inspect.yellow}"
        elsif asset && !asset.updateable?
          w.info "Fixed asset are not updateable : #{asset.name.inspect.red}"
        else
          asset = FixedAsset.create!(asset_attributes)
          w.info "Fixed asset created : #{asset.name.inspect.green}"
        end
      end
    end

    private

      # @return [Accountancy::AccountNumberNormalizer]
      def number_normalizer
        @number_normalizer ||= Accountancy::AccountNumberNormalizer.build
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def find_or_create_account(acc_number, acc_name = nil)
        Maybe(find_or_create_account_by_number(acc_number, acc_name))
          .or_raise
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def find_or_create_account_by_number(acc_number, acc_name = nil)
        normalized = account_normalizer.normalize!(acc_number)

        Maybe(Account.find_by(number: normalized))
          .recover { create_account(acc_number, normalized, acc_name) }
          .or_raise
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def create_account(acc_number, acc_number_normalized, acc_name = nil)
        attrs = {
          name: acc_name,
          number: acc_number_normalized,
          provider: provider_value(account_number: acc_number)
        }
        Account.create!(attrs)
      end

      # @param [String] jou_code
      # @param [String] jou_name
      # @param [Symbol] jou_nature
      # @return [Journal]
      def find_or_create_journal(jou_code, jou_name, jou_nature)
        Maybe(find_journal_by_provider(jou_code))
          .recover { find_journal_by_name_or_code(jou_code, jou_name, jou_nature) }
          .recover { create_journal(jou_code, jou_name, jou_nature) }
          .or_raise
      end

      # @param [String] code
      # @param [String] name
      # @param [Symbol] nature
      # @return [Journal]
      def create_journal(code, name, nature)
        Journal.create!(name: name, code: code, nature: nature, provider: provider_value(journal_code: code))
      end

      # @param [String]
      # @return [Journal, nil]
      def find_journal_by_provider(code)
        unwrap_one('journal') do
          Journal.of_provider_name(self.class.vendor, provider_name)
                 .of_provider_data(:journal_code, code)
        end
      end

      # @param [String]
      # @return [Journal, nil]
      def find_journal_by_name_or_code(jou_code, jou_name, jou_nature)
        if jou_code.present? && jou_name.present? && jou_nature.present?
          journal = Journal.find_by(code: jou_code, nature: jou_nature, name: jou_name)
        elsif jou_code.present? && jou_nature.present?
          journal = Journal.find_by(code: jou_code, nature: jou_nature)
        end
      end

      # @param [String]
      # @return [FixedAsset, nil]
      def find_fixed_asset_by_provider(code)
        unwrap_one('fixed_asset') do
          FixedAsset.of_provider_name(self.class.vendor, provider_name)
                 .of_provider_data(:number, code)
        end
      end

    protected

      def unwrap_one(name, exact: false, &block)
        results = block.call
        size = results.size
        if size > 1
          raise UniqueResultExpectedError.new("Expected only one #{name}, got #{size}")
        elsif exact && size == 0
          raise UniqueResultExpectedError.new("Expected only one #{name}, got none")
        else
          results.first
        end
      end

      # @return [Accountancy::AccountNumberNormalizer]
      def account_normalizer
        @account_normalizer ||= Accountancy::AccountNumberNormalizer.build
      end

      # @return [Import]
      def import_resource
        @import_resource ||= Import.find(options[:import_id])
      end

      def provider_value(**data)
        { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: data }
      end

      def provider_name
        :fixed_assets
      end

      def parse_file(file)
        rows = ActiveExchanger::CsvReader.new(col_sep: ';').read(file)
        parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

        parser.normalize(rows)
      end

  end
end
