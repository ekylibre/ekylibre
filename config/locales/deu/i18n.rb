{ deu: {
  i18n: {
    dir: 'ltr',
    iso2: 'de',
    name: 'Deutsch',
    plural: {
      keys: %i[one other],
      rule: ->(n) { n == 1 ? :one : :other }
    }
  },
  date: {
    order: %i[day month year]
  }
} }
