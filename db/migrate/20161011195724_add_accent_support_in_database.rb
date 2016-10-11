class AddAccentSupportInDatabase < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        enable_extension  'unaccent'
      end

      dir.down do
        disable_extension 'unaccent'
      end
    end
  end
end
