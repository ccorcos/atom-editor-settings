{allowUnsafeEval} = require 'loophole'
Js2Coffee = allowUnsafeEval -> require('js2coffee');

RangeFinder = require './range-finder'

module.exports =
  activate: ->
    atom.workspaceView.command 'js2coffee:toggle', '.editor', =>
      editor = atom.workspaceView.getActivePaneItem()
      @convert(editor)

  convert: (editor) ->
    ranges = RangeFinder.rangesFor(editor)
    ranges.forEach (range) =>
      jsContent = editor.getTextInBufferRange(range)
      try
        coffeeContent = Js2Coffee.build(jsContent, {indent: editor.getTabText()});
        editor.setTextInBufferRange(range, coffeeContent)
      catch e
        console.error("invalid javascript")
