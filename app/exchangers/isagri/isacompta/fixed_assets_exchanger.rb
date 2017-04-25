module Isagri
  module Isacompta
    class FixedAssetsExchanger < ActiveExchanger::Base
      # Check fixed assets
      def check
        valid = true
        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: true, col_sep: ';', encoding: detection[:encoding])
        w.count = rows.size

        # status to map
        depreciation_method_transcode = {
          'Linéaire' => :linear,
          'Non amortissable' => :none,
          'Dégressif' => :regressive
        }

        # get default allocation and expenses account
        exchange_allocation_account = Account.find_or_import_from_nomenclature(:fixed_asset_depreciations) # 28
        exchange_expenses_account = Account.find_or_import_from_nomenclature(:depreciations_inputations_expenses) # 68

        unless exchange_allocation_account && exchange_expenses_account
          w.error 'No way to have exchange accounts to build fixed asset'
          valid = false
        end

        rows.each_with_index do |row, index|
          line_number = index + 2
          prompt = "L#{line_number.to_s.yellow}"

          r = {
            asset_account: row[0].blank? ? nil : row[0].to_s,
            number: row[1].blank? ? '' : row[1].to_s,
            name: row[2].blank? ? nil : row[2].to_s,
            purchase_on: row[4].blank? ? nil : Date.strptime(row[4].to_s, '%d/%m/%Y'),
            purchase_amount: row[5].blank? ? nil : row[5].tr(',', '.').to_d,
            depreciation_method: row[6].blank? ? nil : depreciation_method_transcode[row[6].to_s.strip],
            in_use_on: row[7].blank? ? nil : Date.strptime(row[7].to_s, '%d/%m/%Y'),
            asset_amount: row[8].blank? ? nil : row[8].tr(',', '.').to_d,
            duration_in_year: row[9].blank? ? nil : row[9].to_i,
            depreciation_rate: row[10].blank? ? nil : row[10].tr(',', '.').to_f,
            asset_sale_method: row[11].blank? ? nil : row[11].to_s,
            net_value: row[20].blank? ? nil : row[20].tr(',', '.').to_d
          }.to_struct

          unless r.asset_account
            w.error "No asset account exist in file on #{prompt}"
            valid = false
          end

          unless r.name
            w.error "No name exist in file on #{prompt}"
            valid = false
          end

          unless r.purchase_on
            w.error "No purchase_on date exist in file on #{prompt}"
            valid = false
          end

          unless r.purchase_amount
            w.error "No purchase amount date exist in file on #{prompt}"
            valid = false
          end

          unless r.depreciation_method
            w.error "No depreciation method date exist in file on #{prompt}. You must have one of the following ('Linéaire', 'Non amortissable', 'Dégressif')"
            valid = false
          end

          unless r.duration_in_year
            w.error "No valid duration exist in file on #{prompt}"
            valid = false
          end

          # check asset account must exist in DB
          next unless r.asset_account && r.name
          exchange_asset_account_name = r.number + ' | ' + r.name
          exchange_asset_account = Account.find_or_create_by_number(r.asset_account, name: exchange_asset_account_name)
          unless exchange_asset_account
            w.error "No way to have matching asset account in DB or Nomenclature (#{r.asset_account.inspect}) to build fixed asset on #{prompt}"
            valid = false
          end
        end
      end

      # Create or updates fixed assets
      def import
        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: true, col_sep: ';', encoding: detection[:encoding])
        w.count = rows.size
        currency_preference = Preference[:currency]

        # status to map
        depreciation_method_transcode = {
          'Linéaire' => :linear,
          'Non amortissable' => :none,
          'Dégressif' => :regressive
        }

        # get default allocation and expenses account
        exchange_allocation_account = Account.find_or_import_from_nomenclature(:fixed_asset_depreciations) # 28
        exchange_expenses_account = Account.find_or_import_from_nomenclature(:depreciations_inputations_expenses) # 68

        rows.each_with_index do |row, index|
          line_number = index + 2
          prompt = "L#{line_number.to_s.yellow} | "

          r = {
            asset_account: row[0].blank? ? nil : row[0].to_s,
            number: row[1].blank? ? '' : row[1].to_s.strip,
            name: row[2].blank? ? nil : row[2].to_s.strip,
            purchase_on: row[4].blank? ? nil : Date.strptime(row[4].to_s, '%d/%m/%Y'),
            purchase_amount: row[5].blank? ? nil : row[5].tr(',', '.').to_d,
            depreciation_method: row[6].blank? ? nil : depreciation_method_transcode[row[6].to_s.strip],
            in_use_on: row[7].blank? ? nil : Date.strptime(row[7].to_s, '%d/%m/%Y'),
            asset_amount: row[8].blank? ? nil : row[8].tr(',', '.').to_d,
            duration_in_year: row[9].blank? ? nil : row[9].to_i,
            depreciation_rate: row[10].blank? ? nil : row[10].tr(',', '.').to_f,
            asset_sale_method: row[11].blank? ? nil : row[11].to_s,
            net_value: row[20].blank? ? nil : row[20].tr(',', '.').to_d
          }.to_struct

          description = r.number + ' | ' + r.name + ' | ' + r.purchase_on.to_s + ' | ' + r.net_value.to_s

          # get or create asset account
          if r.asset_account && r.name
            exchange_asset_account_name = r.number + ' | ' + r.name
            exchange_asset_account = Account.find_or_create_by_number(r.asset_account, name: exchange_asset_account_name)
            w.info prompt + "exchange asset account : #{exchange_asset_account.label.inspect.red}"
          end

          computed_name = r.number + ' | ' + r.name

          # Check existing asset (name && in_use date && asset_amount)
          asset = FixedAsset.find_by(name: computed_name) if computed_name
          # Create asset
          if asset
            if asset.updateable?
              asset.description = description
              asset.started_on = r.in_use_on
              asset.stopped_on = r.in_use_on + r.duration_in_year.years
              asset.depreciable_amount = r.asset_amount
              asset.depreciation_method = r.depreciation_method
              asset.depreciation_percentage = r.depreciation_rate
              asset.asset_account = exchange_asset_account
              asset.allocation_account = exchange_allocation_account
              asset.expenses_account = exchange_expenses_account
              asset.save!
              w.info prompt + "Fixed asset updated : #{asset.name.inspect.yellow}"
            else
              w.info prompt + "Fixed asset are not updateable : #{asset.name.inspect.red}"
            end
          else
            asset_attributes = {
              name: computed_name,
              currency: currency_preference,
              description: description,
              started_on: r.in_use_on,
              stopped_on: r.in_use_on + r.duration_in_year.years,
              depreciable_amount: r.asset_amount,
              depreciation_method: r.depreciation_method,
              depreciation_period: :yearly,
              depreciation_percentage: r.depreciation_rate,
              journal: Journal.find_by(nature: :various),
              asset_account: exchange_asset_account,
              allocation_account: exchange_allocation_account,
              expenses_account: exchange_expenses_account
            }
            w.info prompt + "asset attributes : #{asset_attributes.inspect.green}"
            asset = FixedAsset.create!(asset_attributes)
            w.info prompt + "Fixed asset created : #{asset.name.inspect.green}"
            # Update asset
          end

          w.check_point
        end
      end
    end
  end
end
