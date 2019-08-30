const {environment} = require('@rails/webpacker')

const legacyConfig = require('./legacy')

environment.config.merge(legacyConfig)

const MomentLocalesPlugin = require('moment-locales-webpack-plugin');

environment.plugins.append('MomentPlugin', new MomentLocalesPlugin({localesToKeep: ['ar', 'de', 'en', 'es', 'fr', 'it', 'ja', 'pt', 'zh-cn']}))

module.exports = environment
