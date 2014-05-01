KEY_ENTER = 13

# jQuery function for keeping a textarea height fit
$.fn.stayFit = ->
    $el = $(this)
    $el.attr 'rows', 1
    padding = $el.outerHeight() - $el.height()
    line = parseInt $el.css('line-height')
    _stayFit = (adj) ->
        $el.height('auto')
        $el.height $el[0].scrollHeight - padding + (adj or 0)
    _stayFit()
    # Back out here if they're already listening
    return if $el.data 'fit'
    $el.on 'keydown', (e) ->
        adj = if e.keyCode == KEY_ENTER then line else 0
        _stayFit(adj)
        console.log 'activating'
    $el.on 'keyup', (e) ->
        _stayFit()
    # Mark as fit
    $el.data 'fit', true
