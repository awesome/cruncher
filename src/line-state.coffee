window.Cruncher = Cr = window.Cruncher || {}

makeGutterMarker = (stateClass, iconClass, tooltip) ->
    -> ($ '<i></i>')
        .addClass(stateClass)
        .addClass(iconClass)
        .attr('title', tooltip)
        .tooltip(
            html: true
            placement: 'bottom'
            container: 'body'
        )
        .get 0

lineStates =
    parseError:
        gutterMarker:
            makeGutterMarker 'parse-error-icon',
                'icon-remove-circle',
                'I can\'t understand this line.'
        lineClass: 'parse-error-line'

    overDetermined:
        gutterMarker:
            makeGutterMarker 'over-determined-icon',
                'icon-lock',
                'This line doesn\'t have enough <span class="over-determined-free">free numbers</span> for me to change.'
        lineClass: 'over-determined-line'

    underDetermined:
        gutterMarker:
            makeGutterMarker 'under-determined-icon',
                'icon-unlock',
                'This line has too many <span class="over-determined-free">free numbers</span>!' +
                'I don\'t know how to solve it.'
        lineClass: 'under-determined-line'

# assumption: only one line state at a time
Cr.setLineState = (line, stateName) ->
    state = lineStates[stateName]

    Cr.editor.setGutterMarker line, 'lineState',
        state.gutterMarker()
    Cr.editor.markText { line: line, ch: 0 },
        { line: line, ch: (Cr.editor.getLine line).length },
        { className: state.lineClass }

    (Cr.editor.getLineHandle line).state = stateName

Cr.unsetLineState = (line, stateName) ->
    handle = Cr.editor.getLineHandle line
    return unless handle.state? and handle.state == stateName

    state = lineStates[stateName]

    Cr.editor.setGutterMarker line, 'lineState', null

    if handle.markedSpans?
        for span in handle.markedSpans
            if span.marker.className == state.lineClass
                span.marker.clear()

    delete handle.state

Cr.getLineState = (line) ->
    (Cr.editor.getLineHandle line).state

Cr.updateSign = (line, handle) ->
    handle.equalsMark?.clear()

    idx = handle.text.indexOf '='
    return unless idx > -1

    leftNum = handle.parsed.left.num
    rightNum = handle.parsed.right.num

    if leftNum < rightNum
        replacedWith = ($ '<span>&lt;</span>')[0]
    else if leftNum > rightNum
        replacedWith = ($ '<span>&gt;</span>')[0]
    else return

    handle.equalsMark = Cr.editor.markText {
        line: line
        ch: idx
    }, {
        line: line
        ch: idx + 1
    }, replacedWith: replacedWith
