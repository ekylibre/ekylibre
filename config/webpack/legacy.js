module.exports = {
  output: {
    // Makes exports from entry packs available to global scope, e.g.
    library: ['Packs', '[name]'],
    libraryTarget: 'var'
  }
}