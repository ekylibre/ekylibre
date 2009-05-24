# = Definitions of the length dimension units
#
# Author:: Kenta Murata
# Copyright:: Copyright (C) 2008 Kenta Murata
# License:: LGPL version 3.0
 
require 'measure'
 
class Measure
  {
    :m => :meter,
    :km => :kilo_meter,
    :cm => :centi_meter,
    :mm => :milli_meter,
    :um => :micro_meter,
    :nm => :nano_meter,
    :in => :inch,
    :ft => :feet,
    :yd => :yard,
  }.each do |a, u|
    def_unit u, :length unless has_unit? u
    def_alias a, u
  end
 
  def_conversion :m, :cm => 100, :mm => 1000, :um => 1000000, :nm => 1000000000
  def_conversion :km, :m => 1000
  def_conversion :cm, :mm => 10
  def_conversion :mm, :um => 1000
  def_conversion :um, :nm => 1000
  def_conversion :in, :m => 0.254, :cm => 2.54, :mm => 25.4
  def_conversion :ft, :in => 12
  def_conversion :yd, :in => 36, :ft => 3
 
  # for Physics
 
  {
    :aa => :angstrom,
    :AU => :astronomical_unit,
    :au => :astronomical_unit,
    :ly => :light_year,
  }.each do |a, u|
    def_unit u, :length unless has_unit? u
    def_alias a, u
  end
 
  def_conversion :m, :angstrom => 10000000000
  def_conversion :AU, :m => 149_597_870_691
  def_conversion :light_year, :m => 9_460_730_472_580_800
 
  # for DTP
 
  {
    :pt => :point,
    :didot_point => :point,
    :dp => :didot_point,
    :bp => :big_point,
    :pc => :pica,
  }.each do |a, u|
    def_unit u, :length unless has_unit? u
    def_alias a, u
  end
 
  def_conversion :in, :pt => 72.27, :bp => 72.0
  def_conversion :pc, :pt => 12
end
