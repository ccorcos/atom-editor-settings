{CompositeDisposable, Disposable} = require 'event-kit'
MinimapGitDiffBinding = require './minimap-git-diff-binding'

class MinimapGitDiff

  bindings: {}
  pluginActive: false
  constructor: ->
    @subscriptions = new CompositeDisposable

  isActive: -> @pluginActive
  activate: (state) ->
    @gitDiff = atom.packages.getLoadedPackage('git-diff')
    @minimap = atom.packages.getLoadedPackage('minimap')

    return @deactivate() unless @gitDiff? and @minimap?

    @minimapModule = require @minimap.path

    return @deactivate() unless @minimapModule.versionMatch('3.x')
    @minimapModule.registerPlugin 'git-diff', this

  deactivate: ->
    binding.destroy() for id,binding of @bindings
    @bindings = {}
    @gitDiff = null
    @minimap = null
    @minimapModule = null

  activatePlugin: ->
    return if @pluginActive

    @activateBinding()
    @pluginActive = true

    @subscriptions.add @minimapModule.onDidActivate @activateBinding
    @subscriptions.add @minimapModule.onDidDeactivate @destroyBindings

  deactivatePlugin: ->
    return unless @pluginActive

    @pluginActive = false
    @subscriptions.dispose()
    @destroyBindings()

  activateBinding: =>
    @createBindings() if atom.project.getRepo()?

    @subscriptions.add @asDisposable atom.project.on 'path-changed', =>
      if atom.project.getRepo()?
        @createBindings()
      else
        @destroyBindings()

  createBindings: =>
    @minimapModule.eachMinimapView ({view}) =>
      editorView = view.editorView
      editor = view.editor

      return unless editor?

      id = editor.id
      binding = new MinimapGitDiffBinding editorView, @gitDiff, view
      @bindings[id] = binding

      binding.activate()

  destroyBindings: =>
    binding.destroy() for id,binding of @bindings
    @bindings = {}

  asDisposable: (subscription) -> new Disposable -> subscription.off()

module.exports = new MinimapGitDiff
