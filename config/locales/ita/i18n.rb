{
  ita: {
    i18n: {
      dir: 'ltr',
      iso2: 'it',
      name: 'Italiano',
      plural: {
        keys: %i[one other],
        rule: ->(n) { n == 1 ? :one : :other }
      }
    },
    date: {
      order: %i[day month year] # ?
    }
  }
}
