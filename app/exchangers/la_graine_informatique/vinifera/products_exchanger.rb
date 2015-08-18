# coding: utf-8
class LaGraineInformatique::Vinifera::ProductsExchanger < ActiveExchanger::Base
  def import
    rows = CSV.read(file, headers: true, encoding: 'cp1252', col_sep: ';')
    w.count = rows.count

    # FILE STRUCTURE
    # 0 CATEGORY
    # 43 (pdtpxv01) - first sale price
    # to
    # 72 (pdtpxv30) - 30th sale price


    rows.each do |row|
      r = {
          price: 
          for r in [row[43]..row[72]]
            if r and r.to_d != 0.0
              price_#{r.index}: r.to_d
            end
          end
      }.to_struct




      w.check_point
    end
  end  
end
