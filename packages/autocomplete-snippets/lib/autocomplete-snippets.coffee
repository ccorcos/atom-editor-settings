_ = require "underscore-plus"
{ProviderPackageFactory} = require "autocomplete-plus"
SnippetsProvider = require "./snippets-provider"

module.exports =
  editorSubscription: null
  providers: []
  autocomplete: null

  ###
   * Registers a SnippetProvider for each editor view
  ###
  activate: ->
    atom.packages.activatePackage("autocomplete-plus")
      .then (pkg) =>
        @autocomplete = pkg.mainModule
        @registerProviders()

  ###
   * Registers a SnippetProvider for each editor view
  ###
  registerProviders: ->
    @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
      if editorView.attached and not editorView.mini
        provider = new SnippetsProvider editorView

        @autocomplete.registerProviderForEditorView provider, editorView

        @providers.push provider

  ###
   * Cleans everything up, unregisters all SnippetProvider instances
  ###
  deactivate: ->
    @editorSubscription?.off()
    @editorSubscription = null

    @providers.forEach (provider) =>
      @autocomplete.unregisterProvider provider

    @providers = []
