module FileSizeHelper
  def converted_file_size(file_size)
    size_ko = 1000.to_f
    size_mo = (size_ko * size_ko).to_f
    size_go = (size_mo * size_ko).to_f
    size_terra = (size_go * size_ko).to_f

    if !file_size.nil? && file_size.to_d > 0
      if file_size.to_i < size_mo
        "#{(file_size.to_i/size_ko).round(2)} Ko"
      elsif file_size.to_i < size_go
        "#{(file_size.to_i/size_mo).round(2)} Mo"
      elsif file_size.to_i < size_terra
        "#{(file_size.to_i/size_go).round(2)} Go"
      end
    else
      "-"
    end
  end
end
