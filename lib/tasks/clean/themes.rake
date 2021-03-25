namespace :clean do
  desc 'Re-links themes'
  task :themes do
    assets_dir = Rails.root.join('app', 'assets')
    themes_dir = Rails.root.join('app', 'themes')
    Dir.glob(themes_dir.join('*')).each do |theme_path|
      theme_dir = Pathname.new(theme_path)
      theme = theme_dir.basename.to_s
      %w[fonts images stylesheets javascripts].each do |dir|
        next unless theme_dir.join(dir).exist?

        FileUtils.mkdir_p(assets_dir.join(dir, 'themes'))
        # raise [theme_dir.join(dir), assets_dir.join(dir, "themes", theme).relative_path_from(theme_dir.join(dir))].inspect
        Dir.chdir(assets_dir.join(dir, 'themes')) do
          FileUtils.rm_f(theme)
          FileUtils.ln_sf(theme_dir.join(dir).relative_path_from(assets_dir.join(dir, 'themes')), theme)
        end
      end
    end
  end
end
