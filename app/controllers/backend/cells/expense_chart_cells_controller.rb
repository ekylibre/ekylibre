# -*- coding: utf-8 -*-
class Backend::Cells::ExpenseChartCellsController < Backend::CellsController

  def show
      @chart = LazyHighCharts::HighChart.new('pie') do |f|
      f.chart({:defaultSeriesType=>"pie" , :margin=> [50, 200, 60, 170]} )
      series = {
               :type=> 'pie',
               :name=> 'Browser share',
               :data=> [
                  ['Firefox',   45.0],
                  ['IE',       26.8],
                  {
                     :name=> 'Chrome',
                     :y=> 12.8,
                     :sliced=> true,
                     :selected=> true
                  },
                  ['Safari',    8.5],
                  ['Opera',     6.2],
                  ['Others',   0.7]
               ]
      }
      f.series(series)
      f.options[:title][:text] = "TEST"
      f.legend(:layout=> 'vertical',:style=> {:left=> 'auto', :bottom=> 'auto',:right=> '10px',:top=> '10px'})
      f.plot_options(:pie=>{
        :allowPointSelect=>true,
        :cursor=>"pointer" ,
        :dataLabels=>{
          :enabled=>true,
          :color=>"black",
          :style=>{
            :font=>"13px OpenSans, Verdana, sans-serif"
          }
        }
      })
    end
  end




end
