{$, View} = require 'atom-space-pen-views'
Delegato = require 'delegato'
{CompositeDisposable, Disposable, Emitter} = require 'event-kit'

MinimapRenderView = require './minimap-render-view'
MinimapIndicator = require './minimap-indicator'
MinimapOpenQuickSettingsView = require './minimap-open-quick-settings-view'

# Public: A `MinimapView` instance is created for every `Editor` opened in Atom.
# It provides delegation to many `Editor` and {MinimapRenderView} methods so
# that in most case you can just substitute a {MinimapView} instance
# instead of an `Editor`.
#
# The following methods are delegated to the {MinimapRenderView} instance:
#
# - [getLineHeight]{MinimapRenderView::getLineHeight}
# - [getCharHeight]{MinimapRenderView::getCharHeight}
# - [getCharWidth]{MinimapRenderView::getCharWidth}
# - [getLinesCount]{MinimapRenderView::getLinesCount}
# - [getMinimapHeight]{MinimapRenderView::getMinimapHeight}
# - [getMinimapScreenHeight]{MinimapRenderView::getMinimapScreenHeight}
# - [getMinimapHeightInLines]{MinimapRenderView::getMinimapHeightInLines}
# - [getFirstVisibleScreenRow]{MinimapRenderView::getFirstVisibleScreenRow}
# - [getLastVisibleScreenRow]{MinimapRenderView::getLastVisibleScreenRow}
# - [pixelPositionForScreenPosition]{MinimapRenderView::pixelPositionForScreenPosition}
# - [decorateMarker]{DecorationManagement::decorateMarker}
# - [removeDecoration]{DecorationManagement::removeDecoration}
# - [decorationsForScreenRowRange]{DecorationManagement::decorationsForScreenRowRange}
# - [removeAllDecorationsForMarker]{DecorationManagement::removeAllDecorationsForMarker}
#
# The following methods are delegated to the `Editor` instance:
#
# - getSelection
# - getSelections
# - getLastSelection
# - bufferRangeForBufferRow
# - getTextInBufferRange
# - getEofBufferPosition
# - scanInBufferRange
# - markBufferRange
module.exports =
class MinimapView extends View
  Delegato.includeInto(this)

  @delegatesMethods 'getLineHeight', 'getCharHeight', 'getCharWidth', 'getLinesCount', 'getMinimapHeight', 'getMinimapScreenHeight', 'getMinimapHeightInLines', 'getFirstVisibleScreenRow', 'getLastVisibleScreenRow', 'pixelPositionForScreenPosition', 'decorateMarker', 'removeDecoration', 'decorationsForScreenRowRange', 'removeAllDecorationsForMarker', toProperty: 'renderView'

  @delegatesMethods 'getSelection', 'getSelections', 'getLastSelection', 'bufferRangeForBufferRow', 'getTextInBufferRange', 'getEofBufferPosition', 'scanInBufferRange', 'markBufferRange', toProperty: 'editor'

  @delegatesProperty 'lineHeight', toMethod: 'getLineHeight'
  @delegatesProperty 'charWidth', toMethod: 'getCharWidth'

  @content: ({minimapView}) ->
    @div class: 'minimap', =>
      if atom.config.get('minimap.displayPluginsControls')
        @subview 'openQuickSettings', new MinimapOpenQuickSettingsView(minimapView)
      @div outlet: 'miniScroller', class: "minimap-scroller"
      @div outlet: 'miniWrapper', class: "minimap-wrapper", =>
        @div outlet: 'miniUnderlayer', class: "minimap-underlayer"
        @subview 'renderView', new MinimapRenderView
        @div outlet: 'miniOverlayer', class: "minimap-overlayer", =>
          @div outlet: 'miniVisibleArea', class: "minimap-visible-area"

  isClicked: false

  ### Public ###

  #    #### ##    ## #### ########
  #     ##  ###   ##  ##     ##
  #     ##  ####  ##  ##     ##
  #     ##  ## ## ##  ##     ##
  #     ##  ##  ####  ##     ##
  #     ##  ##   ###  ##     ##
  #    #### ##    ## ####    ##

  # Creates a new {MinimapView}.
  #
  # editorView - The `TextEditorView` for which displaying a minimap.
  constructor: (editorView, @paneView) ->
    @emitter = new Emitter
    @setEditorView(editorView)

    @paneView.classList.add('with-minimap')

    @subscriptions = new CompositeDisposable

    super({minimapView: this, editorView})

    @computeScale()
    @miniScrollView = @renderView.scrollView
    @offsetLeft = 0
    @offsetTop = 0
    @indicator = new MinimapIndicator()

    @scrollView = @getEditorViewRoot().querySelector('.scroll-view')

    @scrollViewLines = @scrollView.querySelector('.lines')

    @subscribeToEditor()

    @renderView.minimapView = this
    @renderView.setEditorView(@editorView)

    @updateMinimapView()

  # Internal: Initializes the minimap view by registering to various events and
  # by retrieving the base configuration.
  initialize: ->
    @element.addEventListener 'mousewheel', @onMouseWheel
    @element.addEventListener 'mousedown', @onMouseDown
    @miniVisibleArea[0].addEventListener 'mousedown', @onDragStart

    @subscriptions.add new Disposable =>
      @element.removeEventListener 'mousewheel', @onMouseWheel
      @element.removeEventListener 'mousedown', @onMouseDown
      @miniVisibleArea[0].removeEventListener 'mousedown', @onDragStart

    @obsPane = @pane.observeActiveItem @onActiveItemChanged

    # Fix items moving to another pane.
    # @subscriptions.add @paneView.model.onDidRemoveItem ({item}) =>
    #   @destroy() if item is @editor

    @subscriptions.add @renderView.onDidUpdate @updateMinimapSize
    @subscriptions.add @renderView.onDidChangeScale =>
      @computeScale()
      @updatePositions()

    # The mutation observer is required so that we can relocate the minimap
    # everytime the children of the pane changes.
    @observer = new MutationObserver (mutations) =>
      @updateTopPosition()

    config = childList: true
    @observer.observe @paneView, config

    # Update the minimap whenever theme is reloaded
    @subscriptions.add atom.themes.onDidReloadAll =>
      @updateTopPosition()
      @updateMinimapView()

    # The resize:end event is dispatched at the end of an animated resize
    # to not flood the cpu with updates.
    @subscriptions.add new Disposable =>
      window.removeEventListener 'resize:end', @onScrollViewResized
    window.addEventListener 'resize:end', @onScrollViewResized

    @miniScrollVisible = atom.config.get('minimap.minimapScrollIndicator')
    @miniScroller.toggleClass 'visible', @miniScrollVisible

    @displayCodeHighlights = atom.config.get('minimap.displayCodeHighlights')

    @subscriptions.add atom.config.observe 'minimap.minimapScrollIndicator', =>
      @miniScrollVisible = atom.config.get('minimap.minimapScrollIndicator')
      @miniScroller.toggleClass 'visible', @miniScrollVisible

    @subscriptions.add atom.config.observe 'minimap.useHardwareAcceleration', =>
      @updateScroll() if @ScrollView?

    @subscriptions.add atom.config.observe 'minimap.displayCodeHighlights', =>
      newOptionValue = atom.config.get 'minimap.displayCodeHighlights'
      @setDisplayCodeHighlights(newOptionValue)

    @subscriptions.add atom.config.observe 'minimap.adjustMinimapWidthToSoftWrap', (value) =>
      if value
        @updateMinimapSize()
      else
        @resetMinimapWidthWithWrap()

    @subscriptions.add atom.config.observe 'editor.lineHeight', =>
      @computeScale()
      @updateMinimapView()

    @subscriptions.add atom.config.observe 'editor.fontSize', =>
      @computeScale()
      @updateMinimapView()

    @subscriptions.add atom.config.observe 'editor.softWrap', =>
      @updateMinimapSize()
      @updateMinimapView()

    @subscriptions.add atom.config.observe 'editor.preferredLineLength', =>
      @updateMinimapSize()

  onDidScroll: (callback) ->
    @emitter.on 'did-scroll', callback

  # Internal: Computes the scale of the minimap display relatively to the
  # corresponding editor view.
  # The scale factor are used to map scrolling and offset from the minimap
  # to the editor and vice versa.
  computeScale: ->
    originalLineHeight = @getEditorLineHeight()
    computedLineHeight = @getLineHeight()

    @scaleX = @scaleY = computedLineHeight / originalLineHeight

  getEditorLineHeight: ->
    lineHeight = window.getComputedStyle(@getEditorViewRoot().querySelector('.lines')).getPropertyValue('line-height')
    parseInt(lineHeight)

  # Destroys this view and release all its subobjects.
  destroy: ->
    @resetMinimapWidthWithWrap()
    @paneView.classList.remove('with-minimap')
    @off()
    @obsPane.dispose()
    @subscriptions.dispose()
    @observer.disconnect()

    @detachFromPaneView()
    @renderView.destroy()
    @remove()

  setEditorView: (@editorView) ->
    @editor = @editorView.getModel()
    if @paneView?
      @pane = @paneView.getModel()
    else
      @pane = atom.workspace.paneForItem(@editor)
      @paneView = atom.views.getView(@pane)

    @renderView?.setEditorView(@editorView)

    if @obsPane?
      @obsPane.dispose()
      @obsPane = @pane.observeActiveItem @onActiveItemChanged

  getEditorViewRoot: ->
    @editorView.shadowRoot ? @editorView

  #    ########  ####  ######  ########  ##          ###    ##    ##
  #    ##     ##  ##  ##    ## ##     ## ##         ## ##    ##  ##
  #    ##     ##  ##  ##       ##     ## ##        ##   ##    ####
  #    ##     ##  ##   ######  ########  ##       ##     ##    ##
  #    ##     ##  ##        ## ##        ##       #########    ##
  #    ##     ##  ##  ##    ## ##        ##       ##     ##    ##
  #    ########  ####  ######  ##        ######## ##     ##    ##

  # Toggles the display of the code highlights rendering.
  #
  # value - A {Boolean} of whether to render the code highlights or not.
  setDisplayCodeHighlights: (value) ->
    if value isnt @displayCodeHighlights
      @displayCodeHighlights = value
      @renderView.forceUpdate()

  # Internal: Attaches the minimap view to the DOM.
  attachToPaneView: ->
    @paneView.appendChild(@element)
    @computeScale()
    @updateTopPosition()

  # Internal: Detaches the minimap view to the DOM.
  detachFromPaneView: ->
    @detach()

  # Returns `true` when the minimap is actually attached to the DOM.
  #
  # Returns a {Boolean}.
  minimapIsAttached: -> @paneView.find('.minimap').length is 1

  # Internal: Returns the bounds of the `TextEditorView`.
  #
  # Returns an {Object}.
  getEditorViewClientRect: -> @editorView.getBoundingClientRect()

  # Internal: Returns the bounds of the editor `ScrollView`.
  #
  # returns an {Object}.
  getScrollViewClientRect: -> @scrollViewLines.getBoundingClientRect()

  # Returns the bounds of the minimap.
  #
  # Returns an {Object}
  getMinimapClientRect: -> @element.getBoundingClientRect()

  #    ##     ## ########  ########     ###    ######## ########
  #    ##     ## ##     ## ##     ##   ## ##      ##    ##
  #    ##     ## ##     ## ##     ##  ##   ##     ##    ##
  #    ##     ## ########  ##     ## ##     ##    ##    ######
  #    ##     ## ##        ##     ## #########    ##    ##
  #    ##     ## ##        ##     ## ##     ##    ##    ##
  #     #######  ##        ########  ##     ##    ##    ########

  # Updates the minimap view.
  #
  # The size, scrolling and view area are updated as well as the
  # {MinimapRenderView} if the minimap own scrolling is changed during
  # the update.
  updateMinimapView: =>
    return unless @editorView
    return unless @indicator

    return if @frameRequested

    @updateMinimapSize()
    @frameRequested = true
    requestAnimationFrame =>
      @updateScroll()
      @frameRequested = false

  # Calls the `update` method of the {MinimapRenderView}.
  updateMinimapRenderView: => @renderView.update()

  # Internal: Updates the size of the minimap according to the new
  # size of the editor.
  updateMinimapSize: =>
    return unless @indicator?

    {width, height} = @getMinimapClientRect()
    editorViewRect = @getEditorViewClientRect()
    miniScrollViewRect = @renderView.getClientRect()

    evw = editorViewRect.width
    evh = editorViewRect.height

    minimapVisibilityRatio = miniScrollViewRect.height / height

    @miniScroller.height(evh / minimapVisibilityRatio)
    @miniScroller.toggleClass 'visible', minimapVisibilityRatio > 1 and @miniScrollVisible

    @miniWrapper.css {width}

    # VisibleArea's size
    @indicator.height = evh * @scaleY
    @indicator.width = width / @scaleX

    @miniVisibleArea.css
      width : width / @scaleX
      height: evh * @scaleY

    @updateMinimapWidthWithWrap()

    msvw = miniScrollViewRect.width || 0
    msvh = miniScrollViewRect.height || 0

    # Minimap's size
    @indicator.setWrapperSize width, Math.min(height, msvh)

    # Minimap ScrollView's size
    @indicator.setScrollerSize msvw, msvh

    # Compute boundary
    @indicator.updateBoundary()

  # Internal: Updates the width of the minimap based on the soft-wrap
  # and preferred line length settings.
  updateMinimapWidthWithWrap: ->
    @resetMinimapWidthWithWrap()

    size = atom.config.get('editor.preferredLineLength')
    wraps = atom.config.get('editor.softWrap')
    adjustWidth = atom.config.get('minimap.adjustMinimapWidthToSoftWrap')
    displayLeft = atom.config.get('minimap.displayMinimapOnLeft')

    maxWidth = (size * @getCharWidth())
    if wraps and adjustWidth and size and @width() > maxWidth
      maxWidth = maxWidth + 'px'
      @css maxWidth: maxWidth
      if displayLeft
        @editorView.style.paddingLeft = maxWidth
      else
        @editorView.style.paddingRight = maxWidth
        @getEditorViewRoot().querySelector('.vertical-scrollbar').style.right = maxWidth

  # Internal: Resets the styles modified when the minimap width is adjusted
  # based on the soft-wrap.
  resetMinimapWidthWithWrap: ->
    @css maxWidth: ''
    @editorView.style.paddingRight = ''
    @editorView.style.paddingLeft = ''
    # When called in destroy with shadow DOM disabled, the vertical scrollbar
    # is no longer reachable.
    @getEditorViewRoot().querySelector('.vertical-scrollbar')?.style.right = ''

  # Internal: Updates the vertical scrolling of the minimap.
  #
  # top - The scroll top offset {Number}.
  updateScrollY: (top) =>
    # Need scroll-top value when in find pane or on Vim mode(`gg`, `shift+g`).
    # Or we can find a better solution.
    if top?
      overlayY = top
    else
      scrollViewOffset = @getEditorViewClientRect().top
      overlayerOffset = @getScrollViewClientRect().top
      overlayY = -overlayerOffset + scrollViewOffset

    @indicator.setY(overlayY * @scaleY)
    @updatePositions()

  # Internal: Updates the horizontal scrolling of the minimap.
  updateScrollX: =>
    @indicator.setX(@editor.getScrollLeft())
    @updatePositions()

  # Internal: Updates the scroll of the minimap both horizontally and
  # vertically.
  updateScroll: =>
    @indicator.setX(@editor.getScrollTop())
    @updateScrollY()
    @emitter.emit 'did-scroll'

  # Internal: Updates the position of the various elements of the minimap
  # after a scroll changes.
  updatePositions: ->
    @transform @miniVisibleArea[0], @translate(0, @indicator.y)
    @renderView.scrollTop(@indicator.scroller.y * -1)

    @transform @renderView[0], @translate(0, @indicator.scroller.y + @getFirstVisibleScreenRow() * @getLineHeight())

    @transform @miniUnderlayer[0], @translate(0, @indicator.scroller.y)
    @transform @miniOverlayer[0], @translate(0, @indicator.scroller.y)

    @updateScrollerPosition()

  # Internal: Updates the position of the scroller indicator of the minimap.
  updateScrollerPosition: ->
    height = @miniScroller.height()
    totalHeight = @height()

    scrollRange = totalHeight - height

    @transform @miniScroller[0], @translate(0, @indicator.ratioY * scrollRange)

  # Internal: Adjusts the position of the minimap so that it sticks to the
  # editor view offset. This is needed as the minimap is positioned absolutely
  # and the tree-view, or other packages, may affect the editor view position.
  updateTopPosition: ->
    @offset top: (@offsetTop = @editorView.getBoundingClientRect().top)

  #    ######## ##     ## ######## ##    ## ########  ######
  #    ##       ##     ## ##       ###   ##    ##    ##    ##
  #    ##       ##     ## ##       ####  ##    ##    ##
  #    ######   ##     ## ######   ## ## ##    ##     ######
  #    ##        ##   ##  ##       ##  ####    ##          ##
  #    ##         ## ##   ##       ##   ###    ##    ##    ##
  #    ########    ###    ######## ##    ##    ##     ######

  ### Internal ###

  # Subscribes from the `Editor events`.
  subscribeToEditor: ->
    @subscriptions.add @editor.onDidChangeScrollTop @updateScrollY
    # Hacked scroll-left
    @subscriptions.add @editor.onDidChangeScrollLeft @updateScrollX

    # We can't really know when a tab is dragged from a pane to
    # another one, but as it regains the focus after that we can
    # test if the parent view is still the same or is different.
    @subscriptions.add new Disposable => @editorView.removeEventListener 'focus'
    @editorView.addEventListener 'focus', =>
      pane = atom.workspace.paneForItem(@editor)
      paneView = atom.views.getView(pane)
      if paneView isnt @paneView
        @detachFromPaneView()
        @paneView = paneView
        @attachToPaneView()

      true

  # Unsubscribes from the `Editor events`.
  unsubscribeFromEditor: ->
    @subscriptions.dispose()

  # Event callbacks called when the active editor of a pane view
  # is changed.
  #
  # activeItem - The newly activated pane item.
  onActiveItemChanged: (activeItem) =>
    if activeItem is @editor
      @attachToPaneView() if @parent().length is 0
      @updateMinimapView()
      @renderView.forceUpdate()
    else
      @detachFromPaneView() if @parent().length is 1

  # Receives the mouse wheel event on the minimap itself and scrolls
  # the editor by the corresponding amount.
  onMouseWheel: (e) =>
    return if @isClicked
    {wheelDeltaX, wheelDeltaY} = e
    if wheelDeltaX
      @editor.setScrollLeft(@editor.getScrollLeft() - wheelDeltaX)
    if wheelDeltaY
      @editor.setScrollTop(@editor.getScrollTop() - wheelDeltaY)

  # Receives the mouse down event on the minimap and scrolls the
  # editor accordingly to the mouse location.
  onMouseDown: (e) =>
    # Handle left-click only
    return if e.which isnt 1
    @isClicked = true
    e.preventDefault()
    e.stopPropagation()

    y = e.pageY - @offsetTop
    top = (y + @renderView.scrollTop()) / @scaleY

    position = @editor.displayBuffer.screenPositionForPixelPosition({top, left: 0})
    @editor.scrollToScreenPosition(position, center: true)

    # Fix trigger `mousewheel` event.
    setTimeout =>
      @isClicked = false
    , 377

  # Receives the `resize:end` event and updates the minimap size and position
  # accordingly.
  onScrollViewResized: =>
    @renderView.lineCanvas.height(@editorView.clientHeight)
    @updateMinimapSize()
    @updateMinimapView()
    @updateMinimapWidthWithWrap()
    @renderView.forceUpdate()

  # Receives the mouse down event on the minimap visible area div and initiates
  # the drag gesture.
  onDragStart: (e) =>
    # Handle left-click only
    return if e.which isnt 1
    @isClicked = true
    e.preventDefault()
    e.stopPropagation()
    # compute distance between indicator top and where it has been grabbed
    y = e.pageY - @offsetTop
    @grabY = y - (@indicator.y + @indicator.scroller.y)
    @on 'mousemove.visible-area', @onMove

  # Receives the mouse move and performs the drag gesture.
  onMove: (e) =>
    if e.which is 1
      @onDrag e
    else
      @isClicked = false
      @off '.visible-area'

  # Performs the changes on scrolling based on the drag gesture.
  onDrag: (e) =>
    # The logic for dragging the scroller is a bit different
    # than for a single click.
    # Here we have to compensate for the minimap scroll
    y = e.pageY - @offsetTop
    top = (y-@grabY) * (@indicator.scroller.height-@indicator.height) / (@indicator.wrapper.height-@indicator.height)
    @editor.setScrollTop(top / @scaleY)


  #     #######  ######## ##     ## ######## ########
  #    ##     ##    ##    ##     ## ##       ##     ##
  #    ##     ##    ##    ##     ## ##       ##     ##
  #    ##     ##    ##    ######### ######   ########
  #    ##     ##    ##    ##     ## ##       ##   ##
  #    ##     ##    ##    ##     ## ##       ##    ##
  #     #######     ##    ##     ## ######## ##     ##

  # Returns a {String} containing a css transform translation.
  #
  # x - The {Number} for the x axis translation.
  # y - The {Number} for the y axis translation.
  #
  # Returns a {String}.
  translate: (x=0,y=0) ->
    if atom.config.get 'minimap.useHardwareAcceleration'
      "translate3d(#{x}px, #{y}px, 0)"
    else
      "translate(#{x}px, #{y}px)"

  # Returns a {String} containing a css transform scale.
  #
  # scale - The scale {Number}.
  #
  # Returns a {String}.
  scale: (scale) -> " scale(#{scale}, #{scale})"

  # Applies a css transformation to a DOM element.
  #
  # el - The DOM node onto apply the transformation.
  # transform - The css transformation {String}.
  transform: (el, transform) ->
    el.style.webkitTransform = el.style.transform = transform
