# In anatomy, the second cervical vertebra (C2) of the spine is named the axis 
# (from Latin axis, "axle") or epistropheus.  It forms the pivot upon which the 
# first cervical vertebra (the atlas), which carries the head, rotates.

window.Axis = {}
VERBOSE = false

# Make it work nice with Mongo objects
Backbone.Model::idAttribute = '_id'
Backbone.Collection::parse = (resp, xhr) ->
    @meta = resp.meta if resp.meta?
    return resp.data || resp

reverseSortBy = (sortByFunction) ->
    (left, right) ->
        l = sortByFunction(left)
        r = sortByFunction(right)
        return -1  if l is undefined
        return 1  if r is undefined
        (if l < r then 1 else (if l > r then -1 else 0))

# Hack to let any element with a data-action attribute
# call the function of the model referenced...
# e.g. <a data-action='delete_now'>kill it</a>
# will call model.delete_now() when clicked.
Backbone.View::call = (e) ->
    target = $(e.target).closest('[data-action]')
    func = target.data('action')
    @[func](e, target) if @[func]?
Backbone.View::events =
    'click [data-action]': 'call'

# --------------
# GENERIC MODELS
# --------------

Axis.Model = Backbone.Model.extend
    url: ->
        if @id
            "/#{ @type }s/#{ @id }.json"
        else
            #"/#{ @type }s.json"
            if _.isFunction @collection.url
                @collection.url()
            else
                @collection.url

Axis.Collection = Backbone.Collection.extend
    url: (id=null) ->
        _url = '/' + @collection
        _url += (if id then '/' + id else '') + '.json'
        return _url

# -------------
# GENERIC VIEWS
# -------------

Axis.ItemView = Backbone.View.extend
    initialize: ->
        @template = $(@template || "##{ @type }-template").html()
        @$el = $(@template)
        @model.on 'sync', @renderUpdate, @

    renderUpdate: (v=VERBOSE) ->
        if v
            console.log 'Axis.ItemView renderUpdate'
            console.log @$el
            console.log @model.attributes
        return if !@model
        for attr in @attrs
            attr_val = @model.get(attr)
            if v
                console.log "#{ attr }: #{ attr_val }"
            if typeof attr_val is 'object'
                if v
                    console.log 'Stringifying object...'
                attr_val = JSON.stringify attr_val
            $attr_el = @$el.find('.' + attr)
            if $attr_el.length
                if $attr_el[0].tagName.toLowerCase() in ['input', 'textarea', 'select']
                    $attr_el.val attr_val
                else
                    $attr_el.text attr_val

    render: ->
        @renderUpdate(false)
        @delegateEvents()
        return @$el

    confirm_delete: ->
        $btn = @$el.find('[data-action=confirm_delete]')
        $btn.text 'Really Delete?'
        $btn.data 'action', 'delete'
        setTimeout ->
            $btn.text 'Delete'
            $btn.data 'action', 'confirm_delete'
        , 2500

    delete: ->
        @model.destroy()
        @$el.remove()

# Generic view for lists of items
Axis.ListView = Backbone.View.extend

    initialize: ->
        @collection.on 'add', @addItem, @
        @collection.on 'reset', @reset, @

    onSync: ->
        console.log 'syncing...'
        @isSynced = true
        @render()

    addItem: (model) ->
        item_view = new @ItemView({model: model})
        @$el.find('.items').prepend item_view.render()

    changeSort: (e) ->
        sort_attr = $(e.target).data('sort')
        if @sort_data.attr == sort_attr
            @sort_data.inc = !@sort_data.inc
        @sort_data.attr = sort_attr
        @setSort()

    setSort: ->
        @collection.comparator = (model) =>
            got = model.get @sort_data.attr
            if typeof got == 'object'
                return got.name
            else
                return got
        if !@sort_data.inc
            @collection.comparator = reverseSortBy(@collection.comparator)
        @$el.find('a[data-sort]').removeClass('sorting')
        _sorting = @$el.find("a[data-sort=#{ @sort_data.attr }]")
        _sorting.addClass('sorting')
        if @sort_data.inc
            _sorting.find('i').removeClass('fa-caret-up').addClass('fa-caret-down')
        else
            _sorting.find('i').removeClass('fa-caret-down').addClass('fa-caret-up')
        @sort()

    sort: ->
        @collection.sort()

    reset: ->
        @$el.find('.items').empty()
        @render()

    render: ->
        if @isSynced
            console.log "[ListView] rendering..."
            @collection.each @addItem, @
            @delegateEvents()

Axis.EditItemView = Axis.ItemView.extend
    initialize: ->
        @template = $(@template || "#edit-#{ @type }-template").html()
        @$el = $(@template)

    save: (e) ->
        console.log 'trying to save'
        console.log @attrs
        console.log @$el
        #
        # If there's a preSave method, check its result before continuing
        _continue = if @preSave then @preSave() else true
        if !_continue
            return

        # If there's a model we're saving an existing item
        if @model
            updated_item = {}
            for _attr in @attrs
                console.log _attr
                updated_item[_attr] = @$el.find("[name=#{ _attr }]").val()
                console.log updated_item[_attr]
            @model.save updated_item, {wait: true}

        # Otherwise creating a new one
        else
            new_item = {}
            for _attr in @attrs
                new_item[_attr] = @$el.find("[name=#{ _attr }]").val()
            created = window[@type+'s'].create new_item, {wait: true}
            #@$el.find('input, textarea').val('')

        # Run the postSave method if there is one
        @postSave() if @postSave

Axis.NewItemView = Axis.EditItemView.extend
    initialize: ->
        @$el = $("#new-#{ @type }")

# -----------------------
# MODEL & VIEW GENERATION
# -----------------------

Axis.create_generic_models = (type, attrs) ->
    Type = type[0].toUpperCase() + type.slice(1)
    collection = type + 's'
    Collection = collection[0].toUpperCase() + collection.slice(1)

    window[Type] = Axis.Model.extend
        type: type
        collection: collection
        attrs: attrs

    window[Collection] = Axis.Collection.extend
        type: type
        collection: collection
        attrs: attrs
        model: window[Type]

Axis.create_generic_views = (type, attrs) ->
    Type = type[0].toUpperCase() + type.slice(1)
    collection = type + 's'
    Collection = collection[0].toUpperCase() + collection.slice(1)

    window[Type+'View'] = Axis.ItemView.extend
        Type: Type
        type: type
        collection: collection
        attrs: attrs

    window[Collection+'View'] = Axis.ListView.extend
        Type: Type
        type: type
        collection: collection
        attrs: attrs
        el: "##{ collection }"
        ItemView: window[Type+'View']

    window['Edit'+Type+'View'] = Axis.EditItemView.extend
        Type: Type
        type: type
        collection: collection
        attrs: attrs

    window['New'+Type+'View'] = Axis.NewItemView.extend
        Type: Type
        type: type
        collection: collection
        attrs: attrs

# -----------------------
# MODEL & VIEW INITIATION
# -----------------------

Axis.initiate_models = (type, options={}) ->
    Type = type[0].toUpperCase() + type.slice(1)
    collection = type + 's'
    Collection = collection[0].toUpperCase() + collection.slice(1)

    window[collection] = new window[Collection]()
    if options.fetch
        fetch_options =
            data: options.query
        window[collection].fetch(fetch_options)

Axis.initiate_views = (type, options={}) ->
    Type = type[0].toUpperCase() + type.slice(1)
    collection = type + 's'
    Collection = collection[0].toUpperCase() + collection.slice(1)

    window["#{ collection }_view"] = new window[Collection+'View']
        collection: window[collection]
    window["new_#{ type }_view"] = new window["New#{ Type }View"]()

