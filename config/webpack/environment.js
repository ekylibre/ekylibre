const {environment} = require('@rails/webpacker')
const typescript = require('./loaders/typescript')
const webpack = require('webpack')
const dotenv = require('./dotenv');

dotenv.loadEnv();

const legacyConfig = require('./legacy')

environment.config.merge(legacyConfig)

const MomentLocalesPlugin = require('moment-locales-webpack-plugin');

environment.plugins.insert('Environment', new webpack.EnvironmentPlugin(process.env))
environment.plugins.append('MomentPlugin', new MomentLocalesPlugin({localesToKeep: ['ar', 'de', 'en', 'es', 'fr', 'it', 'ja', 'pt', 'zh-cn']}))

environment.loaders.prepend('typescript', typescript)

module.exports = environment
