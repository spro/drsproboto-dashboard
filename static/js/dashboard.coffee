schema =
    action: ['name', 'code']
    behavior: ['query', 'action']
    message: ['sender', 'type', 'data']

for _type, _attrs of schema
    Axis.create_generic_models _type
    Axis.create_generic_views _type, _attrs

window.initTemplate = (template_name) ->
    $($('#' + template_name + '-template').html())

DashboardView = Backbone.View.extend
    el: '#dashboard .page-body'

    initialize: ->
        console.log "Creating Dashboard"

    render: ->
        $row1 = $('<div class="row">')
        $col1 = $('<div class="col-md-8">')
        $col2 = $('<div class="col-md-4">')
        $row2 = $('<div class="row">')
        $col3 = $('<div class="col-md-4">')
        $col4 = $('<div class="col-md-4">')
        $col5 = $('<div class="col-md-4">')

        messages_chart = new MessagesChart()
        $col1.append messages_chart.$el
        messages_chart.getMessages()

        tweets_list = new TweetsList()
        $col2.append tweets_list.$el
        tweets_list.getTweets()

        btc_chart = new BTCChart()
        $col3.append btc_chart.$el
        btc_chart.getBTCs()

        weather_widget = new WeatherWidget()
        $col4.append weather_widget.$el
        weather_widget.getWeather()

        sweater_widget = new SweaterWidget()
        $col5.append sweater_widget.$el
        sweater_widget.getSweater()

        $row1.append $col1
        $row1.append $col2
        $row2.append $col3
        $row2.append $col4
        $row2.append $col5

        @$el.append $row1
        @$el.append $row2

MessageView::events =
    'click .details': 'toggleOpen'

MessageView::toggleOpen = ->
    @$el.find('.full').slideToggle()

MessagesView::events =
    'click .filters .label': 'toggleFilter'

MessagesView::typed_views = {}
MessagesView::addItem = (model) ->
    if @isSynced
        item_view = new @ItemView({model: model})

        # Add to collection of typed views
        typed_views = @typed_views[model.get('type')] or []
        typed_views.push item_view
        @typed_views[model.get('type')] = typed_views

        @$el.find('.items').prepend item_view.render()

MessagesView::toggleFilter = (e) ->
    console.log 'o hea?'
    $(e.target).toggleClass('active')
    type = e.target.className.match(/type-(\w+)/)[1]
    _.each @typed_views[type], (item_view) ->
        item_view.$el.toggle()

render_register = (msg) ->
    client_name = msg.get('args').name
    $el = $("<span><strong>#{ client_name }</strong> </span>")

    if (handlers = msg.get('args').handlers).length
        $el.append 'with handlers:'
        $handlers = $("<span class='handlers'></span>")
        for handler in msg.get('args').handlers
            $handlers.append $("<pre class='handler'>#{ handler }</pre>")
        $handlers.appendTo $el

    return $el

render_script = (msg) ->
    $el = $($("#script-preview-template").html())
    $el.find('.sender').text msg.get('sender')
    $el.find('.script').text msg.get('script')
    return $el

render_scheduled = (msg) ->
    $el = $($("#scheduled-preview-template").html())
    $el.find('.script').text msg.get('script')
    return $el

render_btc = (msg) ->
    $el = $($("#btc-preview-template").html())
    $el.find('.last').text msg.get('data')?.last
    return $el

render_tweet = (msg) ->
    $el = $($("#tweet-preview-template").html())
    tweet = msg.get('data')
    $el.find('.screen_name').text tweet.user.screen_name
    $el.find('.avatar').attr 'src', tweet.user.profile_image_url
    $el.find('.text').text tweet.text
    return $el

render_github_event = (msg) ->
    $el = $($("#github_event-preview-template").html())
    if msg.get('data').pusher
        $el.find('.username').text msg.get('data').pusher.name
        $el.find('.action').text 'pushed to'
        $el.find('.repo_name').text msg.get('data').repository.name
    else
        $el.find('.action').text '???'
    return $el

render_email = (msg) ->
    $el = $($("#email-preview-template").html())
    email = msg.get('data')
    $el.find('.from').text email.from
    $el.find('.subject').text email.subject
    $el.find('.text').text email.stripped_text
    return $el

MessageView::renderUpdate = ->
    super()
    timestamp = parseInt(@model.get('_id').substring(0,8), 16) * 1000
    @$el.find('.created_at').text moment(timestamp).fromNow()
    @$el.find('.type').addClass 'type-' + @model.get('type')

    # Render data
    $preview = @$el.find('.preview')
    $summary = @$el.find('.summary')
    $full = @$el.find('.full pre')

    type = @model.get('type')

    if type == 'register'
        $preview.empty().append render_register @model

    else if type == 'script' && @model.get('sender') == 'Scheduler'
        $preview.empty().append render_scheduled @model

    else if type == 'script'
        $preview.empty().append render_script @model

    else if @model.get('event') == 'btc'
        $preview.empty().append render_btc @model

    else if type == 'event' and @model.get('event') == 'tweet'
        $preview.empty().append render_tweet @model

    else if type == 'event' and @model.get('event') == 'github'
        $preview.empty().append render_github_event @model

    else if type == 'event' and @model.get('event') == 'email'
        $preview.empty().append render_email @model

    else if type in ['script', 'command', 'event']
        $summary.text @model.get type
    else
        $summary.hide()

    $full.JSONView @model.attributes, collapsed: true
    $full.JSONView 'expand', 1

    return

# Github_eventView::renderUpdate = ->
#     super()
#     timestamp = parseInt(@model.get('_id').substring(0,8), 16) * 1000
#     @$el.find('.created_at').text moment(timestamp).fromNow()
#     @$el.find('.type').addClass 'type-' + @model.get('type')

#     console.log 'amazing'
#     # Render data
#     $preview = @$el.find('.preview')
#     $full = @$el.find('.full pre')
#     $preview.empty().append render_github_event @model
#     $full.JSONView @model.attributes, collapsed: true
#     $full.JSONView 'expand', 1

#     return

GithubEvent = Message.extend
    type: 'github_event'
    collection: 'github_events'
GithubEvents = Messages.extend
    type: 'github_event'
    collection: 'github_events'
    model: GithubEvent
GithubEventsView = MessagesView.extend
    type: 'github_event'
    collection: 'github_events'
    el: "#github"

Tweet = Message.extend
    type: 'tweet'
    collection: 'tweets'
Tweets = Messages.extend
    type: 'tweet'
    collection: 'tweets'
    model: Tweet
TweetsView = MessagesView.extend
    type: 'tweet'
    collection: 'tweets'
    el: "#tweets"

Email = Message.extend
    type: 'email'
    collection: 'emails'
Emails = Messages.extend
    type: 'email'
    collection: 'emails'
    model: Email
EmailsView = MessagesView.extend
    type: 'email'
    collection: 'emails'
    el: "#emails"

Todo = Backbone.Model.extend()
TodoView = Axis.ItemView.extend
    Type: 'Todo'
    type: 'todo'
Todos = Axis.Collection.extend()
TodosView = Axis.ListView.extend
    Type: Todo
    type: 'todo'
    collection: 'todos'
    el: '#todo'

$ ->
    for _type, _attrs of schema
        Axis.initiate_models _type
        Axis.initiate_views _type

    window.dashboard_view = new DashboardView

    window.emails = new Emails()
    window.emails_view = new EmailsView
        collection: emails

    window.tweets = new Tweets()
    window.tweets_view = new TweetsView
        collection: tweets

    window.github_events = new GithubEvents()
    window.github_events_view = new GithubEventsView
        collection: github_events

    window.todos = new Todos()
    window.todos_view = new TodosView
        collection: todos

    # Activate proper tab when loading
    if !window.location.hash
        window.location.hash = '#dashboard'
    $(".nav-tabs a[href=#{ window.location.hash }]").tab('show')
    switchToTab window.location.hash

    # Listen for Bootstrap tab events
    $('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
        tabHash = $(e.target).attr('href')
        switchToTab tabHash

    # Handle keydown events in console
    $('#console input').on 'keydown', consoleKeydown

showLoading = (view) ->

    # Create loading indicator
    $loading = initTemplate 'loading'

    # Center in view
    s = $loading.width()
    $loading.offset
        top: ($(window).height() - s) / 2
        left: ($(window).width() - s) / 2
    view.$el.append $loading

    # Fetch the collection and remove indicator when done
    view.collection.fetch()
    view.collection.once 'sync', ->
        $loading.remove()

prepareTab =
    default: ->
        $('body').css 'background-color', '#fff'

    messages: -> showLoading messages_view
    tweets: -> showLoading tweets_view
    emails: -> showLoading emails_view
    github: -> showLoading github_events_view
    todo: -> showLoading todos_view

    dashboard: ->
        $('body').css 'background-color', '#eee'
        dashboard_view.render()

    console: ->
        $('#console').find('input').first().focus()
        $('body').css 'background-color', '#222'

# When switching to a new tab, set the location hash and run
# stayFit on the textareas, then do any tab-specific things
switchToTab = (tabHash) ->
    window.location.hash = tabHash # activated tab
    $(tabHash).find('textarea').each -> $(this).stayFit()
    $('body').scrollTop 0
    console.log 'scrolld up'

    # Do tab-specific rendering
    tabId = tabHash.slice(1)
    prepareTab.default()
    prepareTab[tabId]()

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
        $.post '/script', {script: _script}, (_response) ->
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

