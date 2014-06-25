class window.WemoWidget extends Backbone.View

    initialize: ->
        @$el = initTemplate 'wemo-widget'

    getWemo: ->
        $.post '/script', {script: 'wemo-status'}, (msg) =>
            @render msg.data

    wemoOn: ->
        $.post '/script', {script: 'wemo-on'}, =>
            @render true
    wemoOff: ->
        $.post '/script', {script: 'wemo-off'}, =>
            @render false

    render: (is_on) ->
        if is_on
            @$el.attr 'wemo-status', 'on'
        else
            @$el.attr 'wemo-status', 'off'

