{WorkspaceView} = require 'atom'
MarkdownHelpers = require '../lib/markdown-helpers'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "MarkdownHelpers", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('markdown-helpers')

  describe "when the markdown-helpers:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.markdown-helpers')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'markdown-helpers:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.markdown-helpers')).toExist()
        atom.workspaceView.trigger 'markdown-helpers:toggle'
        expect(atom.workspaceView.find('.markdown-helpers')).not.toExist()
