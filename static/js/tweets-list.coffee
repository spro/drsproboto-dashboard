get_tweets_script = (n) -> """
    mongo find messages $( obj event tweet ) $( obj sort $( obj _id $(-1) ) limit #{ n } ) 
"""

class Tweet extends Backbone.Model

class TweetItem extends Backbone.View
    events:
        'click a[href]': 'openLink'

    initialize: (_tweet) ->
        @tweet = new Tweet _tweet
        @$el = initTemplate 'tweet-item'

    render: ->
        @$('.avatar').attr 'src', @tweet.get('data').user.profile_image_url
        @$('.screen_name').text @tweet.get('data').user.screen_name
        @$('.time').text moment(@tweet.get('data').created_at).fromNow()
        tweet_text = @tweet.get('data').text
        for url in @tweet.get('data').entities.urls
            expanded_url = "<a href='#{ url.expanded_url }'>#{ url.display_url }</a>"
            tweet_text = tweet_text.replace url.url, expanded_url
        @$('.text').html tweet_text
        @

    openLink: (e) ->
        e.stopPropagation()
        e.preventDefault()
        window.open $(e.target).attr('href')

class TweetsList extends Backbone.View

    initialize: ->
        @$el = initTemplate 'tweets-list'

    getTweets: (n = 50) ->
        $.post '/script', {script: get_tweets_script(n)}, (msg) =>
            @render msg.data

    render: (_data) ->
        for _tweet in _data
            @$('.items').append new TweetItem(_tweet).render().$el

window.TweetsList = TweetsList
