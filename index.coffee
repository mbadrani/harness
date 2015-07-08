webdriverio = require 'webdriverio'
fs = require 'fs'
path = require 'path'
{helpers} = require 'test-stack-helpers'
config = require './config'

dependencies =
  exit: (client, done) -> client.end done
  explicitWaitMs: config.explicitWaitMs
  errors: require './libs/errors'

{TestStackError} = dependencies.errors

loadCustomConfigFile = ->
  if fs.existsSync config.customConfigFile
    for k, v of require config.customConfigFile
      config[k] = v 

loadCapabilities = (capability) ->
  originPathToCapabilities = "#{config.capabilitiesPath}/#{capability}.coffee"
  return require originPathToCapabilities if fs.existsSync originPathToCapabilities

  customPathToCapabilities = "#{config.customCapabilitiesPath}/#{capability}.coffee"
  return require customPathToCapabilities if fs.existsSync customPathToCapabilities

  throw new TestStackError """
  Capability #{capability} not found in paths 
  #{originPathToCapabilities} or #{customPathToCapabilities}
  """


setup = (capability) ->
  loadCustomConfigFile()
  capabilities = loadCapabilities capability
  capabilities['waitforTimeout'] = config.explicitWaitMs

  client = webdriverio.remote capabilities
  client.on 'error', (e) ->
    client.options.waitforTimeout = 500

  for helper in helpers
    for nameOfHelper, fn of helper
      client[nameOfHelper] = fn

  if config.pageObjectsPath?
    if fs.existsSync config.pageObjectsPath
      for po in fs.readdirSync config.pageObjectsPath
        client[path.basename po, '.coffee'] = require(config.pageObjectsPath+'/'+path.basename(po, '.coffee')) client, dependencies


  dependencies.client = client

  return dependencies

module.exports = {
  setup
}