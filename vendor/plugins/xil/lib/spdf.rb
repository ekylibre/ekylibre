require 'bigdecimal'
require 'zlib'

class Spdf
  VERSION = '0.1'
  PDF_VERSION = "1.3"
  LAYOUTS = {
    :single=>'/SinglePage',
    :continuous=>'/OneColumn',
    :two_left=>'/TwoColumnLeft',
    :two_right=>'/TwoColumnRight'
  }

  ZOOMS = {
    :page=>"/Fit",
    :width=>"/FitH null",
    :height=>"/FitV null"
  }

  CHAR_WIDTHS =  {
    'courier'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
    'courierB'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
    'courierI'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
    'courierBI'=>[600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600,600],
    'helvetica'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500],
    'helveticaB'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556],
    'helveticaI'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500],
    'helveticaBI'=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556],
    'times'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 408, 500, 500, 833, 778, 180, 333, 333, 500, 564, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 564, 564, 564, 444, 921, 722, 667, 667, 722, 611, 556, 722, 722, 333, 389, 722, 611, 889, 722, 722, 556, 722, 667, 556, 611, 722, 722, 944, 722, 722, 611, 333, 278, 333, 469, 500, 333, 444, 500, 444, 500, 444, 333, 500, 500, 278, 278, 500, 278, 778, 500, 500, 500, 500, 333, 389, 278, 500, 500, 722, 500, 500, 444, 480, 200, 480, 541, 350, 500, 350, 333, 500, 444, 1000, 500, 500, 333, 1000, 556, 333, 889, 350, 611, 350, 350, 333, 333, 444, 444, 350, 500, 1000, 333, 980, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 200, 500, 333, 760, 276, 500, 564, 333, 760, 333, 400, 564, 300, 300, 333, 500, 453, 250, 333, 300, 310, 500, 750, 750, 750, 444, 722, 722, 722, 722, 722, 722, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 722, 722, 722, 722, 722, 722, 564, 722, 722, 722, 722, 722, 722, 556, 500, 444, 444, 444, 444, 444, 444, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 564, 500, 500, 500, 500, 500, 500, 500, 500],
    'timesB'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 555, 500, 500, 1000, 833, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 930, 722, 667, 722, 722, 667, 611, 778, 778, 389, 500, 778, 667, 944, 722, 778, 611, 778, 722, 556, 667, 722, 722, 1000, 722, 722, 667, 333, 278, 333, 581, 500, 333, 500, 556, 444, 556, 444, 333, 500, 556, 278, 333, 556, 278, 833, 556, 500, 556, 556, 444, 389, 333, 556, 500, 722, 500, 500, 444, 394, 220, 394, 520, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 1000, 350, 667, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 220, 500, 333, 747, 300, 500, 570, 333, 747, 333, 400, 570, 300, 300, 333, 556, 540, 250, 333, 300, 330, 500, 750, 750, 750, 500, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 778, 778, 778, 778, 778, 570, 778, 722, 722, 722, 722, 722, 611, 556, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 500, 556, 500],
    'timesI'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 420, 500, 500, 833, 778, 214, 333, 333, 500, 675, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 675, 675, 675, 500, 920, 611, 611, 667, 722, 611, 611, 722, 722, 333, 444, 667, 556, 833, 667, 722, 611, 722, 611, 500, 556, 722, 611, 833, 611, 556, 556, 389, 278, 389, 422, 500, 333, 500, 500, 444, 500, 444, 278, 500, 500, 278, 278, 444, 278, 722, 500, 500, 500, 500, 389, 389, 278, 500, 444, 667, 444, 444, 389, 400, 275, 400, 541, 350, 500, 350, 333, 500, 556, 889, 500, 500, 333, 1000, 500, 333, 944, 350, 556, 350, 350, 333, 333, 556, 556, 350, 500, 889, 333, 980, 389, 333, 667, 350, 389, 556, 250, 389, 500, 500, 500, 500, 275, 500, 333, 760, 276, 500, 675, 333, 760, 333, 400, 675, 300, 300, 333, 500, 523, 250, 333, 300, 310, 500, 750, 750, 750, 500, 611, 611, 611, 611, 611, 611, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 667, 722, 722, 722, 722, 722, 675, 722, 722, 722, 722, 722, 556, 611, 500, 500, 500, 500, 500, 500, 500, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 675, 500, 500, 500, 500, 500, 444, 500, 444],
    'timesBI'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 389, 555, 500, 500, 833, 778, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 832, 667, 667, 667, 722, 667, 667, 722, 778, 389, 500, 667, 611, 889, 722, 722, 611, 722, 667, 556, 611, 722, 667, 889, 667, 611, 611, 333, 278, 333, 570, 500, 333, 500, 500, 444, 500, 444, 333, 500, 556, 278, 278, 500, 278, 778, 556, 500, 500, 500, 389, 389, 278, 556, 444, 667, 500, 444, 389, 348, 220, 348, 570, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 944, 350, 611, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 389, 611, 250, 389, 500, 500, 500, 500, 220, 500, 333, 747, 266, 500, 606, 333, 747, 333, 400, 570, 300, 300, 333, 576, 500, 250, 333, 300, 300, 500, 750, 750, 750, 500, 667, 667, 667, 667, 667, 667, 944, 667, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 722, 722, 722, 722, 722, 570, 722, 722, 722, 722, 722, 611, 611, 500, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 444, 500, 444],
    'symbol'=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 713, 500, 549, 833, 778, 439, 333, 333, 500, 549, 250, 549, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 549, 549, 549, 444, 549, 722, 667, 722, 612, 611, 763, 603, 722, 333, 631, 722, 686, 889, 722, 722, 768, 741, 556, 592, 611, 690, 439, 768, 645, 795, 611, 333, 863, 333, 658, 500, 500, 631, 549, 549, 494, 439, 521, 411, 603, 329, 603, 549, 549, 576, 521, 549, 549, 521, 549, 603, 439, 576, 713, 686, 493, 686, 494, 480, 200, 480, 549, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 750, 620, 247, 549, 167, 713, 500, 753, 753, 753, 753, 1042, 987, 603, 987, 603, 400, 549, 411, 549, 549, 713, 494, 460, 549, 549, 549, 549, 1000, 603, 1000, 658, 823, 686, 795, 987, 768, 768, 823, 768, 768, 713, 713, 713, 713, 713, 713, 713, 768, 713, 790, 790, 890, 823, 549, 250, 713, 603, 603, 1042, 987, 603, 987, 603, 494, 329, 790, 790, 786, 713, 384, 384, 384, 384, 384, 384, 494, 494, 494, 494, 0, 329, 274, 686, 686, 686, 384, 384, 384, 384, 384, 384, 494, 494, 494, 0],
    'zapfdingbats'=>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 278, 974, 961, 974, 980, 719, 789, 790, 791, 690, 960, 939, 549, 855, 911, 933, 911, 945, 974, 755, 846, 762, 761, 571, 677, 763, 760, 759, 754, 494, 552, 537, 577, 692, 786, 788, 788, 790, 793, 794, 816, 823, 789, 841, 823, 833, 816, 831, 923, 744, 723, 749, 790, 792, 695, 776, 768, 792, 759, 707, 708, 682, 701, 826, 815, 789, 789, 707, 687, 696, 689, 786, 787, 713, 791, 785, 791, 873, 761, 762, 762, 759, 759, 892, 892, 788, 784, 438, 138, 277, 415, 392, 392, 668, 668, 0, 390, 390, 317, 317, 276, 276, 509, 509, 410, 410, 234, 234, 334, 334, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 732, 544, 544, 910, 667, 760, 760, 776, 595, 694, 626, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 894, 838, 1016, 458, 748, 924, 748, 918, 927, 928, 928, 834, 873, 828, 924, 924, 917, 930, 931, 463, 883, 836, 836, 867, 867, 696, 696, 874, 0, 874, 760, 946, 771, 865, 771, 888, 967, 888, 831, 873, 927, 970, 918, 0]
  }

  attr_accessor :title, :keywords, :creator, :author, :subject, :zoom, :layout
  attr_reader :fonts, :available_fonts

  def initialize
    @pages = []
    @page = -1
    @aliases = {}
    @fonts = {}
    @images = {}
    @producer = self.class.to_s+' '+VERSION
    
    @available_fonts={
      'courier'               => {:type=>:core, :base=>'Courier', :encoding=>'/WinAnsiEncoding'},
      'courier-bold'          => {:type=>:core, :base=>'Courier-Bold', :encoding=>'/WinAnsiEncoding'},
      'courier-italic'        => {:type=>:core, :base=>'Courier-Oblique', :encoding=>'/WinAnsiEncoding'},
      'courier-bold-italic'   => {:type=>:core, :base=>'Courier-BoldOblique', :encoding=>'/WinAnsiEncoding'},
      'helvetica'             => {:type=>:core, :base=>'Helvetica', :encoding=>'/WinAnsiEncoding'},
      'helvetica-bold'        => {:type=>:core, :base=>'Helvetica-Bold', :encoding=>'/WinAnsiEncoding'},
      'helvetica-italic'      => {:type=>:core, :base=>'Helvetica-Oblique', :encoding=>'/WinAnsiEncoding'},
      'helvetica-bold-italic' => {:type=>:core, :base=>'Helvetica-BoldOblique', :encoding=>'/WinAnsiEncoding'},
      'times'                 => {:type=>:core, :base=>'Times-Roman', :encoding=>'/WinAnsiEncoding'},
      'times-bold'            => {:type=>:core, :base=>'Times-Bold', :encoding=>'/WinAnsiEncoding'},
      'times-italic'          => {:type=>:core, :base=>'Times-Italic', :encoding=>'/WinAnsiEncoding'},
      'times-bold-italic'     => {:type=>:core, :base=>'Times-BoldItalic', :encoding=>'/WinAnsiEncoding'},
      'symbol'                => {:type=>:core, :base=>'Symbol'},
      'zapfdingbats'          => {:type=>:core, :base=>'ZapfDingbats'}
    }
  end

  def new_page(format=[])
    error('Parameter format must be an array') unless format.is_a? Array
    format[0] ||= 1000.0
    error('Parameter format can only contains numeric values') unless [Integer, Float, BigDecimal].include? format[0].class
    format[1] ||= format[0]*1.414
    @pages ||= []
    @page = @pages.size
    @pages << {:format=>format, :items=>[]}
  end

  def alias(key, value)
    @aliases[key] = value
  end

  def image(file, params={}, page=nil)
    if @images[file].nil?
      error("File does not exists (#{file.inspect})") unless File.exists? file
      error("JPG only please (NOT #{file.inspect})") unless file.split('.')[-1] == 'jpg'
      @images[file] = { :width=>56, :height=>45, 
        :color_space=>'/DeviceRGB', :bits_per_component=>8, 
        :filter=>'/DCTDecode', :file=>file }
    end
    params[:image] = file
    @pages[page||@page][:items] << {:nature=>:image, :params=>params}
  end

  def line(params={}, page=nil)
    @pages[page||@page][:items] << {:nature=>:line, :params=>params}
  end

  def box(params={}, page=nil)
    params[:font] ||= {}
    params[:font][:family] ||= 'Times'
    params[:font][:bold] ||= false
    params[:font][:italic] ||= false
    get_font(params[:font][:family], params[:font][:bold], params[:font][:italic])
    @pages[page||@page][:items] << {:nature=>:box, :params=>params}
  end

  def text(content, x, y, params={}, page=nil)
    params[:text] = content
    params[:x] = x
    params[:y] = y
    box(params, page)
  end

  def generate(options={})
    yield self if block_given?
    @compress = false
    open('/tmp/test.pdf','wb') do |f|
      f.write(build)
    end
  end

  def error(message, nature=nil)
    raise Exception.new("#{self.class.to_s} error: #{message}")
  end


  private


  def build
    @objects = [0]
    @objects_count = 0
    @now = Time.now
    # Resources
    resources_object = build_resources
    # Pages
    pages_object, first_page_object = build_pages(resources_object)
    # build_resources
    # Info
    info_object = build_info
    # Catalog
    root_object = build_catalog(pages_object, first_page_object)

    # Building of the complete document
    pdf = "%PDF-#{PDF_VERSION}\n\n"
    xref  = "xref\n"
    xref += "0 #{(@objects_count+1).to_s}\n"
    xref += "0000000000 65535 f \n"
    for i in 1..@objects_count
      xref += sprintf('%010d 00000 n ', pdf.length)+"\n"
      pdf += i.to_s+" 0 obj\n"
      pdf += @objects[i]
      pdf += "endobj\n\n"      
    end
    length = pdf.length
    pdf += xref
    pdf += "trailer\n"
    trailer = [['Size', (@objects_count+1).to_s], ['Root', root_object.to_s+' 0 R']]
    trailer << ['Info', info_object.to_s+' 0 R'] unless info_object.nil?
    pdf += dictionary(trailer)
    pdf += "startxref\n"
    pdf += length.to_s+"\n"
    pdf += "%%EOF\n"
    pdf
  end


  def build_fonts_0
    # $nf=$this->n;
    for diff in @diffs
      # Encodings
      new_object
      out('<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences ['+diff+']>>')
      out('endobj')
    end

    #     @FontFiles.each do |file, info|
    #       # Font file embedding
    #       newobj
    #       @FontFiles[file]['n'] = @n

    #       if self.class.const_defined? 'FPDF_FONTPATH' then
    #         if FPDF_FONTPATH[-1,1] == '/' then
    #           file = FPDF_FONTPATH + file
    #         else
    #           file = FPDF_FONTPATH + '/' + file
    #         end
    #       end

    #       size = File.size(file)
    #       unless File.exists?(file)
    #         Error('Font file not found')
    #       end

    #       out('<</Length ' + size.to_s)

    #       if file[-2, 2] == '.z' then
    #         out('/Filter /FlateDecode')
    #       end
    #       out('/Length1 ' + info['length1'])
    #       out('/Length2 ' + info['length2'] + ' /Length3 0') if info['length2']
    #       out('>>')
    #       open(file, 'rb') do |f|
    #         putstream(f.read())
    #       end
    #       out('endobj')
    #     end

    file = 0
    @fonts.each do |k, font|
      # Font objects
      @fonts[k]['n']=@objects_count+1
      type=font['type']
      name=font['name']
      if type=='core'
        # Standard font
        new_object
        out('<</Type /Font')
        out('/BaseFont /'+name)
        out('/Subtype /Type1')
        if name!='Symbol' and name!='ZapfDingbats'
          out('/Encoding /WinAnsiEncoding')
        end
        out('>>')
        out('endobj')
      elsif type=='Type1' or type=='TrueType'
        # Additional Type1 or TrueType font
        new_object
        out('<</Type /Font')
        out('/BaseFont /'+name)
        out('/Subtype /'+type)
        out('/FirstChar 32 /LastChar 255')
        out('/Widths '+(@objects_count+1).to_s+' 0 R')
        out('/FontDescriptor '+(@objects_count+2).to_s+' 0 R')
        if font['enc'] and font['enc'] != ''
          unless font['diff'].nil?
            out('/Encoding '+(nf+font['diff']).to_s+' 0 R')
          else
            out('/Encoding /WinAnsiEncoding')
          end
        end
        out('>>')
        out('endobj')
        # Widths
        new_object
        cw=font['cw']
        s='['
        32.upto(255) do |i|
          s << cw[i].to_s+' '
        end
        out(s+']')
        out('endobj')
        # Descriptor
        new_object
        s='<</Type /FontDescriptor /FontName /'+name
        font['desc'].each do |k, v|
          s << ' /'+k+' '+v
        end
        file=font['file']
        if file
          s << ' /FontFile'+(type=='Type1' ? '' : '2')+' '+
            @font_files[file]['n'].to_s+' 0 R'
        end
        out(s+'>>')
        out('endobj')
      else
        # Allow for additional types
        mtd='build_'+type.downcase
        unless self.respond_to?(mtd)
          self.error('Unsupported font type: '+type)
        end
        self.send(mtd, font)
      end
    end
  end




  def build_images_0
    filter=(@compress) ? '/Filter /FlateDecode ' : ''
    @images.each do |file, info|
      new_object
      @images[file]['n']=@objects_count
      out('<</Type /XObject')
      out('/Subtype /Image')
      out('/Width '+info['w'].to_s)
      out('/Height '+info['h'].to_s)
      if info['cs']=='Indexed'
        out("/ColorSpace [/Indexed /DeviceRGB #{info['pal'].length/3-1} #{(@objects_count+1)} 0 R]")
      else
        out('/ColorSpace /'+info['cs'])
        if info['cs']=='DeviceCMYK'
          out('/Decode [1 0 1 0 1 0 1 0]')
        end
      end
      out('/BitsPerComponent '+info['bpc'].to_s)
      out('/Filter /'+info['f']) if info['f']
      unless info['parms'].nil?
        out(info['parms'])
      end
      if info['trns'] and info['trns'].kind_of?(Array)
        trns=''
        info['trns'].length.times do |i|
          trns=trns+info['trns'][i].to_s+' '+info['trns'][i].to_s+' '
        end
        out('/Mask ['+trns+']')
      end
      out('/Length '+info['data'].length.to_s+'>>')
      build_stream(info['data'])
      @images[file]['data']=nil
      out('endobj')
      # Palette
      new_stream_object(info['pal']) if info['cs']=='Indexed'
    end
  end


  # END Resources

  def build_info
    info = []
    info << ['Producer', textstring(@producer)] unless @producer.nil?
    info << ['Title', textstring(@title)] unless @title.nil?
    info << ['Subject', textstring(@subject)] unless @subject.nil?
    info << ['Author', textstring(@author)] unless @author.nil?
    info << ['Keywords', textstring(@keywords)] unless @keywords.nil?
    info << ['Creator', textstring(@creator)] unless @creator.nil?
    info << ['CreationDate', textstring('D:'+@now.strftime("%Y%m%d%H%M%S%z"))]
    info << ['ModDate', textstring('D:'+@now.strftime("%Y%m%d%H%M%S%z"))]
    new_object(info)
  end

  def build_catalog(pages_object, first_page=nil)
    catalog = [['Type', '/Catalog'],
               ['Pages', "#{pages_object.to_s} 0 R"]]
    if first_page and not zoom.nil?
      zoom = if @zoom.is_a? Symbol
               ZOOMS[@zoom]
             elsif [Float, Integer].include? @zoom.class
               "/XYZ null null #{(@zoom/100).to_s}"
             end||ZOOMS[:page]
      catalog << ['OpenAction', "[#{first_page} 0 R #{zoom}]"]
    end
    catalog << ['PageLayout', LAYOUTS[@layout]||LAYOUTS[:coutinuous]] unless @layout.nil?
    new_object(catalog)
  end

  # Build the pages, page, content objects
  def build_pages(resources_object)
    pages_count = @pages.size
    pages = []
    pages_object = new_object    
    for page in @pages
      # Page content
      contents_object = new_stream_object(build_page(page))
      # Page
      pages << new_object([['Type', '/Page'],
                           ['Parent', "#{pages_object} 0 R"], # Required
                           ['MediaBox', sprintf('[0 0 %.2f %.2f]', page[:format][0], page[:format][1])], # Required
                           ['Resources', resources_object.to_s+' 0 R'], # Required
                           ['Contents', contents_object.to_s+' 0 R']])
    end
    # Pages root (No parent for root /Pages)
    pages_root = new_object([['Type', '/Pages'],
                             ['Kids', '['+pages.collect{|i| i.to_s+' 0 R'}.join(' ')+']'],
                             ['Count',pages.size.to_s]], pages_object)
    return pages_root, pages[0]
  end


  def build_page(page)
    # Beginning of page
    code = ''
    # Set line cap style to square
    #code += "2 J\n"
    # Set line width
    #    code += sprintf('%.2f w',5)
    # Set font
    # Items of page
    page_width  = page[:format][0]
    page_height = page[:format][1]
    for item in page[:items]
      params = item[:params]
      if item[:nature]==:box
        text = params[:text]
        if text
          font = get_font(params[:font][:family], params[:font][:bold], params[:font][:italic])
          size = params[:font][:size]||12
          x = params[:x]||0
          y = page_height-0.7*size-(params[:y]||0)
          code += "BT /#{font[:name]} #{size} Tf #{x} #{y} Td #{textstring(text)} Tj ET\n"
        end
      elsif item[:nature]==:image
        code += sprintf('q %.2f 0 0 %.2f %.2f %.2f cm /'+@images[item[:params][:image]][:name]+' Do Q', 100, 100, 100, 100)
      end
    end

    return code
  end


  def build_resources
    # Build fonts objects
    fonts = []
    for key, font in @fonts
      dict = [['Type', '/Font'],
              ['Name', '/'+font[:name]]]
      if font[:type] == :core
        dict << ['Subtype', '/Type1']
        dict << ['BaseFont', '/'+font[:base]]
        dict << ['Encoding', font[:encoding]] if font[:encoding]
      else
        error("Unsupported type of font: #{font[:type].inspect}")
      end
      fonts << [font[:name], new_object(dict).to_s+' 0 R']
    end

    # Build images objects
    images = []
    for key, image in @images
      f = open(image[:file], 'rb')
      data = f.read
      f.close
      object = new_object do |lines|
        lines << dictionary([['Type', '/XObject'], ['Subtype', '/Image'],
                             ['Width', image[:width]], ['Height', image[:height]],
                             ['ColorSpace', image[:color_space]],
                             ['BitsPerComponent', image[:bits_per_component]],
                             ['Filter', image[:filter]], ['Length', data.length]])
        lines << new_stream(data)
      end
      image[:name] = 'I'+images.size.to_s
      images << [image[:name], object.to_s+' 0 R']
    end

    # Resource object
    resources = [['ProcSet', '[/PDF /Text /ImageB /ImageC /ImageI]']]
    resources << ['Font', fonts]
    resources << ['XObject', images]
    new_object(resources)
  end


  def new_object(data=nil, object_number=nil)
    if object_number.nil?
      @objects_count += 1
      object_number = @objects_count
      @objects[object_number] = ''
    end
    if block_given?
      lines = []
      yield(lines)
      @objects[object_number] += lines.join("\n")+"\n"
    elsif not data.nil?
      @objects[object_number] += (data.is_a?(Array) ? dictionary(data) : data)+"\n"
    end
    object_number
  end

  def new_stream_object(stream)
    filter = ''
    if @compress
      filter = '/Filter /FlateDecode '
      stream = Zlib::Deflate.deflate(stream)
    end
    new_object do |lines|
      lines << "\<\<"+filter+'/Length '+stream.length.to_s+"\>\>"
      lines << new_stream(stream)
    end
  end

  def new_stream(stream)
    "stream\n"+stream+"\nendstream"
  end

  def dictionary(dict=[], depth=0)
    raise Exception.new('Only Array type are accepted as dictionary type ('+dict.class.to_s+')') unless dict.is_a? Array
    eol = (dict.size>1 and not @compress)
    code  = "\<\<"
    code += "\n" if eol
    for key, value in dict
      code += "  "*depth+'/'+key.to_s+' '
      code += value.is_a?(Array) ? dictionary(value, depth+1) : value.to_s
      code += "\n" if eol
    end
    code += "  "*depth+"\>\>"
    code
  end

  def get_font(family_name='Times', bold=false, italic=false)
    label = family_name.downcase+(bold ? '-bold' : '')+(italic ? '-italic' : '')
    font = @fonts[label]
    if font.nil?
      font = @available_fonts[label]
      error("Unavailable font: #{label}") if font.nil?
      font[:name] = 'F'+(@fonts.size+1).to_s
      @fonts[label] = font
    end
    font
  end

  # Escape special characters
  def escape(string)
    string.gsub('\\','\\\\').gsub('(','\\(').gsub(')','\\)').gsub("\r",'\\r')
  end

  # Format a text string
  def textstring(string)
    '('+escape(string.to_s)+')'
  end

end




pdf = Spdf.new
pdf.new_page([595.28, 841.89])
pdf.title = 'Enfin un moteur PDF lisible'
pdf.box(:text=>'Hello World!')
pdf.text('Hello World! Test pour Spdf', 100, 625, :font=>{:family=>'Symbol', :size=>16})
pdf.text('Hello World! Deuxième', 100, 600, :font=>{:family=>'Courier', :bold=>true, :size=>16})
pdf.image('sample2.jpg')
pdf.new_page([1200.0,300.0])
pdf.text('Hello World! Encore une mission reussie pour Spdf', 200, 200, :font=>{:family=>'Courier', :size=>16})
puts pdf.fonts.inspect
pdf.image('sample2.jpg')
pdf.generate
