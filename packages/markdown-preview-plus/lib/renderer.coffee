path = require 'path'
_ = require 'underscore-plus'
cheerio = require 'cheerio'
Highlights = require 'highlights'
{$} = require 'atom'
roaster = null # Defer until used
{scopeForFenceName} = require './extension-helper'
mathjaxHelper = require './mathjax-helper'

highlighter = null
{resourcePath} = atom.getLoadSettings()
packagePath = path.dirname(__dirname)

exports.toHtml = (text='', filePath, grammar, renderLaTeX, callback) ->
  roaster ?= require 'roaster'
  options =
    sanitize: false
    breaks: atom.config.get('markdown-preview-plus.breakOnSingleNewline')

  # Remove the <!doctype> since otherwise marked will escape it
  # https://github.com/chjj/marked/issues/354
  text = text.replace(/^\s*<!doctype(\s+.*)?>\s*/i, '')

  # Parse test for latex equations
  if renderLaTeX
    text = mathjaxHelper.preprocessor(text)

  roaster text, options, (error, html) =>
    return callback(error) if error

    grammar ?= atom.syntax.selectGrammar(filePath, text)
    # Default code blocks to be coffee in Literate CoffeeScript files
    defaultCodeLanguage = 'coffee' if grammar.scopeName is 'source.litcoffee'

    html = sanitize(html)
    html = resolveImagePaths(html, filePath)
    html = tokenizeCodeBlocks(html, defaultCodeLanguage)
    if renderLaTeX
      mathjaxHelper.postprocessor(html, callback)
    else
      callback(null, html.html().trim())

exports.toText = (text, filePath, grammar, callback) ->
  exports.toHtml text, filePath, grammar, false, (error, html) ->
    if error
      callback(error)
    else
      string = $(document.createElement('div')).append(html)[0].innerHTML
      callback(error, string)

sanitize = (html) ->
  o = cheerio.load("<div>#{html}</div>")
  # Do not remove MathJax script delimited blocks
  o("script:not([type^='math/tex'])").remove()
  attributesToRemove = [
    'onabort'
    'onblur'
    'onchange'
    'onclick'
    'ondbclick'
    'onerror'
    'onfocus'
    'onkeydown'
    'onkeypress'
    'onkeyup'
    'onload'
    'onmousedown'
    'onmousemove'
    'onmouseover'
    'onmouseout'
    'onmouseup'
    'onreset'
    'onresize'
    'onscroll'
    'onselect'
    'onsubmit'
    'onunload'
  ]
  o('*').removeAttr(attribute) for attribute in attributesToRemove
  o.html()

resolveImagePaths = (html, filePath) ->
  html = $(html)
  for imgElement in html.find('img')
    img = $(imgElement)
    if src = img.attr('src')
      continue if src.match(/^(https?|atom):\/\//)
      continue if src.startsWith(process.resourcesPath)
      continue if src.startsWith(resourcePath)
      continue if src.startsWith(packagePath)

      if src[0] is '/'
        img.attr('src', atom.project.resolve(src.substring(1)))
      else
        img.attr('src', path.resolve(path.dirname(filePath), src))

  html

tokenizeCodeBlocks = (html, defaultLanguage='text') ->
  html = $(html)

  if fontFamily = atom.config.get('editor.fontFamily')
    $(html).find('code').css('font-family', fontFamily)

  for preElement in $.merge(html.filter("pre"), html.find("pre"))
    codeBlock = $(preElement.firstChild)
    fenceName = codeBlock.attr('class')?.replace(/^lang-/, '') ? defaultLanguage

    highlighter ?= new Highlights(registry: atom.syntax)
    highlightedHtml = highlighter.highlightSync
      fileContents: codeBlock.text()
      scopeName: scopeForFenceName(fenceName)

    highlightedBlock = $(highlightedHtml)
    # The `editor` class messes things up as `.editor` has absolutely positioned lines
    highlightedBlock.removeClass('editor').addClass("lang-#{fenceName}")
    highlightedBlock.insertAfter(preElement)
    preElement.remove()

  html
