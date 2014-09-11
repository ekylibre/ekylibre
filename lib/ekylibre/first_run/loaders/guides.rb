Ekylibre::FirstRun.add_loader :guides do |first_run|

  file = first_run.path("alamano", "guides.csv")
  if file.exist?
    first_run.count :guides do |w|
      CSV.foreach(file, headers: true) do |row|
        unless guide = Guide.find_by(name: row[0])
          guide = Guide.create!(name: row[0], nature: row[1], active: true)
        end
        (0..(3 + rand(2))).to_a.reverse.each do |i|
          guide.run!(Time.now - (i * 3600 * 24 * (25 + rand(15))) - rand(3600 * 24 * 4))
          w.check_point
        end
      end
    end
  end

end
