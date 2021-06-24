module Ekylibre
  class Extension
    class << self
      # Insert the css file to the plugins.scss tmp file.
      # The plugins.scss file is inserted to all.scss.
      def insert_css_file(extension_name)
        Ekylibre.themes.each do |theme|
          stylesheet = "// This files contains #{theme} theme addons from plugins\n\n"
          stylesheet << "@import \"#{extension_name}\";\n"

          file_path = "themes/#{theme}/plugins.scss"
          write_asset_tmp_file('theme-addons', file_path, stylesheet)
        end
      end

      # Insert the js file to the plugins.js.coffee tmp file.
      # The plugins.js.coffee file is inserted to application.js.
      def insert_js_file(extension_name)
        script = "# This files contains JS addons from plugins\n"
        script << "#= require #{extension_name}\n"

        file_path = 'plugins.js.coffee'
        write_asset_tmp_file('javascript-addons', file_path, script)
      end

      private

        def write_asset_tmp_file(folder, file_path, file_content)
          base_dir = Rails.root.join('tmp', 'plugins', folder)
          Rails.application.config.assets.paths << base_dir.to_s

          file = base_dir.join(file_path)

          FileUtils.mkdir_p file.dirname
          File.write(file, file_content)
        end
    end
  end
end
