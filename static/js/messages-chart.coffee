bins = 50

mtype_colors =
    script: '#5b9b9f'
    event: '#ad90b4'
    response: '#97b651'
    register: '#ecbf7b'
    unregister: '#a44b38'

oid2ts = (oid) ->
    parseInt(oid.substring(0,8), 16) * 1000

get_messages_script = (n) -> """
    mongo find messages $( obj ) $( obj sort $( obj _id $(-1) ) limit #{ n } ) | reverse
"""

class MessagesChart extends Backbone.View
    elid: '#messages-chart .chart'

    initialize: ->
        @$el = initTemplate 'messages-chart'

    events:
        'click .settings .select': 'clickSelect'
        'click .settings .select .option': 'clickOption'
    
    clickSelect: (e) ->
        $(e.currentTarget).find('.options').toggle()

    clickOption: (e) ->
        $option = $(e.currentTarget)
        selected = $option.text()
        $option.closest('.select').find('.selected').text selected
        @getMessages selected

    getMessages: (n = 100) ->
        $.post '/script', {script: get_messages_script(n)}, (msg) =>
            @render msg.data

    render: (_data) ->
        @width = $(@elid).width()
        @height = 200

        # Clear previous chart
        d3.select('#messages-chart .chart svg').remove()

        timestamps = []

        # Turn oids into timestamps
        for d in _data
            d.timestamp = oid2ts d._id
            timestamps.push d.timestamp

        # Create bins by time
        data = d3.layout.histogram()
            .bins(bins).value((d) -> d.timestamp)(_data)
        window.data = data
        
        # X axis over time
        x = d3.time.scale()
            .domain(d3.extent(timestamps))
            .range([0, @width])

        xAxis = d3.svg.axis()
            .scale(x)
            .orient('bottom')
            .tickFormat d3.time.format '%H:%M'

        # Y axis 0 - max messages
        y = d3.scale.linear()
            .domain([0, d3.max(data, (d) -> d.length)])
            .range([@height, 0])
        window.y = y

        svg = d3.select('#messages-chart .chart').append('svg')
            .attr('width', @width)
            .attr('height', @height + 20)
            .append('g')

        # Draw the axis
        svg.append('g')
            .attr('class', 'x axis')
            .attr('transform', "translate(0, #{ @height + 5 })")
            .call(xAxis)
            .selectAll('text')
                .attr('x', -3)
                .style('text-anchor', 'start')

        # Create a <g> for each bar
        bar = svg.selectAll('.bar')
            .data(data)
            .enter().append('g')
                .attr('class', 'bar')
                .attr('transform', (d) -> "translate(#{ x(d.x) })")

        # Loop over bars and render stacked sections
        self = @
        bar.each (d) ->

            # Nest by type
            nested = d3.nest()
                .key((m) -> m.type)
                .sortKeys(d3.descending)
                .entries(d)
            return if !nested.length

            # Calculate y and h of each section
            _y = self.height
            for section in nested
                n = section.values.length
                console.log section.key + ': ' + n
                h = self.height - y(n)
                _y -= h
                section.h = h
                section.y = _y
                console.log 'h=' + h + ' : y=' + _y

            console.log nested

            _bar = d3.select(this)
            d0 = 0

            # Render the bar sections
            console.log 'Rendering bar'
            _bar.selectAll('rect')
                .data(nested)
                .enter().append('rect')
                    .attr('x', 0)
                    .attr('fill', (d) -> mtype_colors[d.key] || '#ccc')
                    .attr('width', self.width/bins-1)
                    .attr('height', (d) -> d.h)
                    .attr('y', (d) -> d.y)

window.MessagesChart = MessagesChart

$('#messages-chart .settings .select').on 'click', ->
    $(this).find('.options').toggle()
$('#messages-chart .settings .select .option').on 'click', ->
    selected = $(this).text()
    $(this).closest('.select').find('.selected').text selected
    get_messages selected

