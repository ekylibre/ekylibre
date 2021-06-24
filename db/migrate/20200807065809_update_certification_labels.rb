class UpdateCertificationLabels < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        # change indicator certification_label to text instead of nomen choices (because provide by Lexicon now)
        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_datatype = 'string',
          string_value = choice_value
          WHERE indicator_name = 'certification_label' AND indicator_datatype = 'choice'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_datatype = 'string',
          string_value = choice_value
          WHERE indicator_name = 'certification_label' AND indicator_datatype = 'choice'
        SQL
      end
      
      dir.down do
        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_datatype = 'choice',
          choice_value = string_value
          WHERE indicator_name = 'certification_label' AND indicator_datatype = 'string'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_datatype = 'choice',
          choice_value = string_value
          WHERE indicator_name = 'certification_label' AND indicator_datatype = 'string'
        SQL
      end
    end
  end
end
