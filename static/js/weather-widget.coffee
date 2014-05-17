class window.WeatherWidget extends Backbone.View

    initialize: ->
        @$el = initTemplate 'weather-widget'

    getWeather: ->
        $.post '/script', {script: 'weather-json 94122'}, (msg) =>
            @render msg.data

    render: (_data) ->

        orig_icon_url = _data.icon_url
        icon_type = orig_icon_url.split('/').slice(-1)[0].split('.')[0]

        is_night = icon_type.match(/^nt_/)?

        if icon_type.match /cloud/
            icon_class = 'cloudy'
        else
            if is_night
                icon_class = 'clear'
            else
                icon_class = 'sunny'

        if is_night
            icon_class = 'night-' + icon_class
        else
            icon_class = 'day-' + icon_class
        icon_class = 'wi-' + icon_class

        @$('.result .icon').addClass icon_class
        @$('.result .degrees').text _data.temp_f
        @$('.result .wind span').text _data.wind_mph
