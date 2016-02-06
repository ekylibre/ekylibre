module Nomen
  module Migrator
    class Model
      def self.run(migration)
        up = []
        dn = []
        migration.each_action do |action|
          if action.is_a?(Nomen::Migration::Actions::ItemChange) && action.new_name?
            up << "# #{action.human_name}"
            Nomen::Migrator.each_reflection(nomenclature: action.nomenclature) do |n|
              up << "execute \"UPDATE #{n.model.table_name} SET #{n.foreign_key}='#{action.new_name}' WHERE #{n.foreign_key}='#{action.name}'\""
              dn << "execute \"UPDATE #{n.model.table_name} SET #{n.foreign_key}='#{action.name}' WHERE #{n.foreign_key}='#{action.new_name}'\""
            end
            dn << "# Reverse: #{action.human_name}"
          elsif action.is_a?(Nomen::Migration::Actions::ItemMerging)
            up << "# #{action.human_name}"
            Nomen::Migrator.each_reflection(nomenclature: action.nomenclature) do |n|
              up << "execute \"UPDATE #{n.model.table_name} SET #{n.foreign_key}='#{action.into}' WHERE #{n.foreign_key}='#{action.name}'\""
              dn << "# Cannot unmerge '#{action.name}' from '#{action.into}' in #{n.model.table_name}##{n.foreign_key}"
            end
            dn << "# Reverse: #{action.human_name}"
          elsif !action.is_a?(Nomen::Migration::Actions::Base)
            raise "Cannot handle: #{action.inspect}"
          end
        end
        name = migration.name.gsub(/\s+/, '_').classify
        code = "# Migration generated with nomenclature migration ##{migration.number}\n"
        code << "class #{name} < ActiveRecord::Migration\n"
        if up.any?
          code << "  def up\n"
          code << up.join("\n").dig(2)
          code << "  end\n\n"
        end
        if dn.any?
          code << "  def down\n"
          code << dn.reverse.join("\n").dig(2)
          code << "  end\n"
        end
        code << "end\n"
        if up.any? && dn.any?
          now = Time.zone.now.strftime('%Y%m%d%H%M%S')
          migration_name = "#{now}_#{name.underscore}"
          puts "Write migration db/migrate/#{migration_name}.rb".yellow
          File.write(Rails.root.join('db', 'migrate', "#{migration_name}.rb"), code)
          sleep(1)
        end
      end
    end
  end
end
