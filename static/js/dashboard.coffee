schema =
    action: ['name', 'code']
    behavior: ['query', 'action']
    message: ['sender', 'type', 'data']

for _type, _attrs of schema
    Axis.create_generic_models _type
    Axis.create_generic_views _type, _attrs

MessagesView::onSync = ->
    @collection.models = @collection.models.reverse()
    @render()

MessageView::renderUpdate = ->
    super()
    @$el.find('.created_at').text moment(@model.get('timestamp')).fromNow()
    @$el.find('.type').addClass 'type-' + @model.get('type')

    # Render data
    $summary = @$el.find('.summary')
    $data = @$el.find('.data')

    if @model.get('type') in ['script', 'command', 'event']
        $summary.text @model.get @model.get 'type'
    else
        $summary.hide()

    if data = @model.get('data')
        if typeof data == 'object'
            $data.JSONView data, collapsed: true
            $data.JSONView 'expand', 1
        else
            $data.text data
    else
        $data.hide()

    # Render args
    $args = @$el.find('.args')
    if @model.get('args')
        $args.JSONView @model.get('args'), collapsed: true
        $args.JSONView 'expand', 1
    else
        $args.hide()

    return

ActionView::events =
    'click': 'open'
    'click [data-action]': 'call'

ActionView::open = (e) ->
    return if $(e.target)[0].tagName != 'INPUT'
    @$el.toggleClass 'open'
    @$el.find('textarea').stayFit()

BehaviorView::save = EditBehaviorView::save
ActionView::save = EditActionView::save

$ ->
    for _type, _attrs of schema
        Axis.initiate_models _type
        Axis.initiate_views _type

    # Activate proper tab when loading
    if !window.location.hash
        window.location.hash = '#messages'
    $(".nav-tabs a[href=#{ window.location.hash }]").tab('show')
    switchToTab window.location.hash

    # Listen for Bootstrap tab events
    $('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
        tabHash = $(e.target).attr('href')
        switchToTab tabHash

    # Handle keydown events in console
    $('#console input').on 'keydown', consoleKeydown

# When switching to a new tab, set the location hash and run
# stayFit on the textareas, then do any tab-specific things
switchToTab = (tabHash) ->
    window.location.hash = tabHash # activated tab
    $(tabHash).find('textarea').each -> $(this).stayFit()
    $('body').scrollTop 0
    console.log 'scrolld up'

    # Focus on console input if console tab
    if tabHash == '#console'
        console.log 'a console'
        $(tabHash).find('input').first().focus()
        #$('#console .page-body').css 'height', $(window).height()
        $('body').css 'background-color', '#222'
    else
        $('body').css 'background-color', '#fff'

# Keep console view focused on last scripts by adjusting container's scrollTop
# Triggered upon every new script or response to a script
window.scrollConsole = () ->
    if $('#console').height() > $(window).height()
        $('#console').css('position', 'static')
        $('body').animate({ scrollTop: $('#console .page-body').height() })
    else
        console.log 'nope'

# Keeping track of script history
localStorage.history = JSON.stringify [] if !localStorage.history?
localStorage.history_at = -1

# Handle keydown events in console
# Enter (13) sends the script and saves to history
# Up (40) retreives the last script from localStorage
# Down (38) retreives the next script from localStorage
window.consoleKeydown = (e) ->

    if e.which == 13 # Enter
        e.preventDefault()
        # Get the script
        _script = $('#console input').val()
        $script = $('<div class="line">')
        $script.append $('<p>').text _script
        $script.prepend $('<span class="prompt">').text '>'
        $('#console .history').append $script
        $('#console input').val ''
        scrollConsole()
        # Keep track in localStorage
        history = JSON.parse localStorage.history
        history.push(_script)
        localStorage.history = JSON.stringify history
        localStorage.history_at = -1
        # Perform the request
        $.post '/console', {script: _script}, (_response) ->
            if _response.data? && typeof _response.data == 'object'
                console.log 'json viewing'
                $response = $('<pre class="response code">').JSONView _response.data, collapsed: true
                $response.JSONView 'expand', 1
            else
                console.log 'not json viewing'
                $response = $('<pre class="response code">').text _response.summary || _response.data
            $response.find('a').on 'click', (e) ->
                e.preventDefault()
                window.open $(@).attr 'href'
            $('#console .history').append $response
            scrollConsole()

    if e.which == 40 # Up
        if localStorage.history.length > 2
            history = JSON.parse localStorage.history
            history_at = JSON.parse localStorage.history_at
            new_val = ''
            if (history_at) < -1
                history_at = -1
            else
                new_val = history[history.length - history_at]
            localStorage.history_at = history_at - 1
            $('#console input').val(new_val)
            setCaretPosition($('#console input'), new_val.length) if new_val

    if e.which == 38 # Down
        if localStorage.history.length > 2 # "[]"
            e.preventDefault()
            history = JSON.parse localStorage.history
            history_at = JSON.parse localStorage.history_at
            if history.length > (history_at + 1)
                history_at += 1
            localStorage.history_at = history_at
            new_val = history[history.length - 1 - history_at]
            $('#console input').val(new_val)
            setCaretPosition($('#console input'), new_val.length) if new_val

# Helper for setting caret inside input
setCaretPosition = ($el, caretPos) ->
    elem = $el[0]
    if elem?
        if elem.createTextRange
            range = elem.createTextRange()
            range.move "character", caretPos
            range.select()
        else
            if elem.selectionStart
                elem.focus()
                elem.setSelectionRange caretPos, caretPos
            else
                elem.focus()

