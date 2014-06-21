class window.SweaterWidget extends Backbone.View

    initialize: ->
        @$el = initTemplate 'sweater-widget'

    getSweater: ->
        $.post '/script', {script: 'sweater'}, (msg) =>
            @render msg.data

    sweaterYes: (e) ->
        @$('[data-action=sweaterYes]').addClass 'active'
        $.post '/script', {script: 'sweater-yes'}, (msg) =>
            @getSweater()

    sweaterNo: (e) ->
        @$('[data-action=sweaterNo]').addClass 'active'
        $.post '/script', {script: 'sweater-no'}, (msg) =>
            @getSweater()

    render: (_data) ->
        if _data.sweater > 0.75
            @$('.result .text').text 'Yes'
            @$('.result .icon').attr 'src', '/images/sweater-yes.png'
        else if _data.sweater < 0.25
            @$('.result .text').text 'No'
            @$('.result .icon').attr 'src', '/images/sweater-no.png'
        else
            @$('.result .text').text 'Maybe'
            @$('.result .icon').attr 'src', '/images/sweater-maybe.png'

