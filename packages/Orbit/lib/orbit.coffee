OrbitView = require './orbit-view'

console.log "nothing done yet"

module.exports =

  mrtPath: null
  meteorPath: null
  boundObservers: false

  defaultConfig:
    'orbit.mrtPath': '/usr/local/bin/mrt',
    'orbit.MeteorPath': '/usr/local/bin/meteor'

  loadSettings: ->
    if not @boundObservers
      for config_key, default_val of @defaultConfig
        atom.config.observe(config_key, {}, @loadSettings)
      @boundObservers = true

    console.log "Loading config"

    for config_key, default_val of @defaultConfig
      unless atom.config.get(config_key)
        atom.config.set(config_key, default_val)

    @mrtPath = atom.config.get('orbit.mrtPath')
    @meteorPath = atom.config.get('orbit.MeteorPath')

  activate: (state) ->
    @loadSettings()
    console.log "activating"
    @orbitView = new OrbitView(state.orbitViewState)

  deactivate: ->
    @orbitView.destroy()

  serialize: ->
    orbitViewState: @orbitView.serialize()
