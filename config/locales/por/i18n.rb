# coding: utf-8
{ :por => {
    :i18n => {
      :dir => 'ltr',
      :iso2 => 'pt',
      :name => 'Português',
      :plural => {
        :keys => [:one, :other],
        :rule => lambda { |n| n<2 ? :one : :other }
      }
    },
    :date => {
      :order => [:day, :month, :year]
    }
  }
}
