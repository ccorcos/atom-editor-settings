_ = require 'underscore'
spawn = require("child_process").spawn
exec = require("child_process").exec
DDPClient = require 'ddp'
path = require 'path'
fs = require 'fs'
byline = require 'byline'
moment = require 'moment'
readline = require 'readline'
{$$, BufferedNodeProcess, SelectListView} = require 'atom'

module.exports =
class OrbitView extends SelectListView
  ddpPackages: null 
  installedMeteorPackages: []

  initialize: (serializeState) ->
    super

    @addClass('overlay from-top')
    atom.workspaceView.command "orbit:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()


  getPackages: ->
    ddpclient = new DDPClient(
      host: "atmosphere.meteor.com"
      port: "80"
      auto_reconnect: true
      auto_reconnect_timer: 500
      use_ejson: true # default is false
      use_ssl: false #connect to SSL server,
      use_ssl_strict: true #Set to false if you have root ca trouble.
      maintain_collections: true #Set to false to maintain your own collections.
    )

    ddpclient.connect (error) =>
      if error
        console.log "DDP connection error!"
        return

      ddpclient.subscribe "packageMetadata", [], =>

        pItems = []

        _.each ddpclient.collections.packages, ((p)->
          pItems.push
            name: p.name
            updatedAt: moment(p.updatedAt).fromNow()
            isInstalled: _.contains @installedMeteorPackages, p.name
        ), this
        pItems.sort (a, b)->
          return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        @setItems(pItems)
        @ddpPackages = pItems
        return

      return

  getInstalledMeteorPackages: (cb) ->
    # TODO: Shouldn't have to reset array and open ddp connection every time
    @installedMeteorPackages = []
    pPath = path.join(atom.project.getPath(), '.meteor/packages')

    fs.exists pPath, (exists)=>
      if exists
        pckgReg = /^[a-z, A-Z]/
        stream = fs.createReadStream(pPath)
        stream = byline.createStream(stream)
        stream.on 'data', (line)=>
          line = line.toString()
          if pckgReg.exec(line)
            @installedMeteorPackages.push line

        stream.on 'end', (line)=>
          cb()


  attach: ->

    if @ddpPackages?
      @getInstalledMeteorPackages ()=>
        @setItems(@ddpPackages) 
    else 
      @getInstalledMeteorPackages ()=>
        @getPackages()

    atom.workspaceView.append(this)
    @focusFilterEditor()

  viewForItem: (item) ->
    statusClass = if _.contains @installedMeteorPackages, item.name then 'status status-added icon icon-diff-added' else ''
    $$ ->
      @li class: 'two-lines', =>
        @div class: statusClass, ''
        @div class: 'primary-line icon icon-file-text', item.name
        @div class: 'secondary-line no-icon', item.updatedAt 

  toggle: ->
    if @hasParent()
      @cancel()
    else
      @attach()

  # TODO: 
  updatePackages: (item, addOrRemove) ->
    isInstalledOrNot = (if addOrRemove == "add" then true else false)
    name = item.name
    match = _.find @ddpPackages, (i) ->
      return i.name == name

    if match?
      match.isInstalled = isInstalledOrNot

    if isInstalledOrNot
      @installedMeteorPackages.push item.name
    else
      @installedMeteorPackages.splice( @installedMeteorPackages.indexOf( item.name ), 1 )

      

  meteorProcess: (item, addOrRemove) ->
    meteorPath = atom.config.get('orbit.MeteorPath')  
    cmd = meteorPath + " " + addOrRemove + " " + item.name

    options =
      cwd: atom.project.getPath()

    child = exec(cmd, options, (error, stdout, stderr) =>

      # TODO: needs to be re-thinked
      @updatePackages(item, addOrRemove)
      @getInstalledMeteorPackages () =>
        # console.log "getInstalledMeteorPackages called"
      return
    )


  mrtProcess: (item, addOrRemove) ->
    mrtPath = atom.config.get('orbit.mrtPath')
  
    options = 
      cwd: atom.project.getPath()
    
    options.env = Object.create(process.env)  unless options.env?

    options.env["ATOM_SHELL_INTERNAL_RUN_AS_NODE"] = 1
    node = (if process.platform is "darwin" then path.resolve(process.resourcesPath, "..", "Frameworks", "Atom Helper.app", "Contents", "MacOS", "Atom Helper") else process.execPath)

    mrt = spawn(node, [
      mrtPath
      addOrRemove
      item.name
    ], options )

    readline.createInterface(
      input: mrt.stdout
      terminal: false
    ).on "line", (line) =>
      re1 = ".*?" # Non-greedy match on filler
      re2 = "(http:\\/\\/meteor\\.com)" # HTTP URL 1
      p = new RegExp(re1 + re2, ["i"])
      if p.exec(line)
        @meteorProcess(item, addOrRemove)
      return

    mrt.on "exit", (data) =>
      @meteorProcess(item, addOrRemove)
      return

    mrt.stderr.on "data", (data) ->
      console.log "error: " + data.toString()
      return

  @::getFilterKey = ->
    return "name"

  confirmed: (item) ->
    console.log "confirmed"
    addOrRemove = (if item.isInstalled then "remove" else "add")
    @mrtProcess item, addOrRemove
    @cancel()