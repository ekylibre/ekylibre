const { environment } = require('@rails/webpacker')

const legacyConfig = require('./legacy')

environment.config.merge(legacyConfig)

module.exports = environment
