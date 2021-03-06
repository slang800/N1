_ = require 'underscore'
React = require 'react/addons'
{DOMUtils} = require 'nylas-exports'

###
IMPORTANT: This has been deprecated. Use the native `title=` attribute instead.
This will ensure native-behavior cross platform.
The Tooltip component displays a consistent hovering tooltip for use when
extra context information is required.

Activate by adding a `data-tooltip="Label"` to any element

It's a global-level singleton
###

class Tooltip extends React.Component
  @displayName: "Tooltip"

  constructor: (@props) ->
    @state =
      top: 0
      pos: "below"
      left: 0
      width: 0
      pointerLeft: 0
      display: false
      content: ""

  componentWillMount: =>
    @CONTENT_PADDING = 15
    @DEFAULT_DELAY = 2000
    @KEEP_DELAY = 300
    @_showDelay = @DEFAULT_DELAY
    @_showTimeout = null
    @_showDelayTimeout = null

  componentWillUnmount: =>
    clearTimeout @_showTimeout
    clearTimeout @_showDelayTimeout
    @_mutationObserver?.disconnect()
    @_enteredTooltip = false

  render: =>
    <div className="tooltip-wrap #{@state.pos}" style={@_positionStyles()}>
      <div className="tooltip-content">{@state.content}</div>
      <div className="tooltip-pointer" style={left: @state.pointerLeft}></div>
    </div>

  _positionStyles: =>
    top: @state.top
    left: @state.left
    width: @state.width
    display: if @state.display then "block" else "none"

  # This are public methods so they can be bound to the window event
  # listeners.
  onMouseOver: (e) =>
    elWithTooltip = @_elementWithTooltip(e.target)
    if elWithTooltip and DOMUtils.nodeIsVisible(elWithTooltip)
      if elWithTooltip isnt @_lastTarget
        @_onTooltipEnter(elWithTooltip)
    else if @state.display
      @_hideTooltip()

  onMouseOut: (e) =>
    if @_elementWithTooltip(e.fromElement) and not @_elementWithTooltip(e.toElement)
      @_onTooltipLeave()

  onMouseDown: (e) =>
    if @state.display
      @_hideTooltip()

  _elementWithTooltip: (target) =>
    while target
      break if target?.dataset?.tooltip?
      target = target.parentNode
    return target

  _onTooltipEnter: (target) =>
    # https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver
    @_mutationObserver?.disconnect()
    @_mutationObserver = new MutationObserver(@_onTooltipLeave)
    @_mutationObserver.observe(target.parentNode, attributes: true, subtree: true, childList: true)

    @_lastTarget = target
    @_enteredTooltip = true
    clearTimeout(@_showTimeout)
    clearTimeout(@_showDelayTimeout)
    @_showTimeout = setTimeout =>
      @_showTooltip(target)
    , @_showDelay

  _onTooltipLeave: =>
    return unless @_enteredTooltip
    @_enteredTooltip = false
    clearTimeout(@_showTimeout)
    @_hideTooltip()

    @_showDelay = 10
    clearTimeout(@_showDelayTimeout)
    @_showDelayTimeout = setTimeout =>
      @_showDelay = @DEFAULT_DELAY
    , @KEEP_DELAY

  _showTooltip: (target) =>
    return unless DOMUtils.nodeIsVisible(target)
    content = target.dataset.tooltip
    return if (content ? "").trim().toLowerCase().length is 0

    guessedWidth = @_guessWidth(content)
    dim = target.getBoundingClientRect()
    left = dim.left + dim.width / 2

    TOOLTIP_HEIGHT = 50
    FLIP_THRESHOLD = TOOLTIP_HEIGHT + 30
    top = dim.top + dim.height + 14
    tooltipPos = "below"
    if top + FLIP_THRESHOLD > @_windowHeight()
      tooltipPos = "above"
      top = dim.top - TOOLTIP_HEIGHT

    # If for some reason the element was removed from underneath us, we
    # won't know until we get here. The element's dimensions will return
    # (0, 14), which we can use to filter out bad displays. This can
    # happen if our mutation observer misses the event. In some cases
    # (like the multi-select toolbar), the button's great-grandparent is
    # removed from the DOM and no mutation observer event is fired.
    if left < 20 and top < 20
      @_hideTooltip()
      return

    @setState
      top: top
      pos: tooltipPos
      left: @_tooltipLeft(left, guessedWidth)
      width: guessedWidth
      pointerLeft: @_tooltipPointerLeft(left, guessedWidth)
      display: true
      content: target.dataset.tooltip

  _guessWidth: (content) =>
    # roughly 11px per character
    guessWidth = content.length * 11
    return Math.max(Math.min(guessWidth, 250), 50)

  _tooltipLeft: (targetLeft, guessedWidth) =>
    max = @_windowWidth() - guessedWidth - @CONTENT_PADDING
    left = Math.min(Math.max(targetLeft - guessedWidth/2, @CONTENT_PADDING), max)
    return left

  _tooltipPointerLeft: (targetLeft, guessedWidth) =>
    POINTER_WIDTH = 6 + 2 #2px of border-radius
    max = @_windowWidth() - @CONTENT_PADDING
    min = @CONTENT_PADDING
    absoluteLeft = Math.max(Math.min(targetLeft, max), min)
    relativeLeft = absoluteLeft - @_tooltipLeft(targetLeft, guessedWidth)

    left = Math.max(Math.min(relativeLeft, guessedWidth-POINTER_WIDTH), POINTER_WIDTH)
    return left

  _windowWidth: =>
    document.body.offsetWidth

  _windowHeight: =>
    document.body.offsetHeight

  _hideTooltip: =>
    @_mutationObserver?.disconnect()
    @_lastTarget = null
    @setState
      top: 0
      left: 0
      width: 0
      pointerLeft: 0
      display: false
      content: ""


module.exports = Tooltip
