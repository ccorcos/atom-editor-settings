# AutoMdLinksView = require './markdown-helpers-view'
request = require('request')

module.exports =
  activate: (state) ->
    atom.workspaceView.command "markdown-helpers:convert-link", => @convert(new GoogleWebConvertor())
    atom.workspaceView.command "markdown-helpers:convert-image", => @convert(new GoogleImageConvertor())

  convert: (convertor) ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    text = selection.getText()

    return unless text

    callback = (text) => @updateSelection(text)

    convertor.convert(text, callback)

  updateSelection: (text) ->
    editor = atom.workspace.activePaneItem
    selection = editor.getSelection()
    selection.insertText(text)


class GoogleWebConvertor
    url: 'http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q='

    format: (text, link) -> "[#{text}](#{link})"

    convert: (text, callback) ->
        handler = (error, response, body) =>
            @handleResponse(body, callback)

        request.get({url: @url + text, json:true}, handler)

    handleResponse: (json, callback) ->
      text = json.responseData.results[0].titleNoFormatting
      link = json.responseData.results[0].unescapedUrl

      callback(@format(text, link))

  class GoogleImageConvertor extends GoogleWebConvertor
      url: 'http://ajax.googleapis.com/ajax/services/search/images?v=1.0&q='

      format: (text, link) ->  "![#{text}](#{link})"
