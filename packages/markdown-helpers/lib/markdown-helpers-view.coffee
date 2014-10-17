{View} = require 'atom'

module.exports =
class MarkdownHelpersView extends View
  @content: ->
    @div class: 'markdown-helpers overlay from-top', =>
      @div "The package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "markdown-helpers:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "MarkdownHelpersView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
