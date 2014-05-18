class BTCChart extends Backbone.View
    elid: '#btc-chart .chart'
    
    initialize: ->
        @$el = initTemplate 'btc-chart'

    events:
        'click .settings .select': 'clickSelect'
        'click .settings .select .option': 'clickOption'
    
    clickSelect: (e) ->
        $(e.currentTarget).find('.options').toggle()

    clickOption: (e) ->
        $option = $(e.currentTarget)
        selected = $option.text()
        $option.closest('.select').find('.selected').text selected
        @getBTCs selected

    getBTCs: (n = 50) ->
        $.post '/script', {script: 'last-btcs ' + n}, (msg) =>
            @render msg.data

    render: (_data) ->

        @width = $(@elid).width()
        @height = $(@elid).height() - 40

        # X axis over time
        x = d3.time.scale()
            .range([0, @width])

        y = d3.scale.linear().range([@height, 0])
        parseDate = d3.time.format('%-d-%b-%y').parse

        line = d3.svg.line()
            .x((d) -> x d.date)
            .y((d) -> y d.value)

        d3.select(@elid + ' svg').remove()
        d3.select(@elid)
            .append('svg')
            .attr('width', @width)
            .attr('height', @height + 30)
            .append('path')
            .attr('class', 'sparkline')

        data = []
        _data.forEach (_d) ->
            d = {}
            d.date = new Date _d[0]
            d.value = _d[1]
            data.push d

        x.domain(d3.extent(data, (d) -> d.date))
        y.domain(d3.extent(data, (d) -> d.value))

        xAxis = d3.svg.axis()
            .scale(x)
            .orient('bottom')
            .ticks(5)
            .tickFormat d3.time.format '%I:%M'

        p = d3.select(@elid).select('path')
            .datum(data)

        p.attr('d', line)
            .attr('transform', null)
            .transition()

        # Draw the axis
        d3.select(@elid + ' svg').append('g')
            .attr('class', 'x axis')
            .attr('transform', "translate(0, #{ @height + 10 })")
            .call(xAxis)
            .selectAll('text')
                .attr('x', -3)
                .style('text-anchor', 'start')

        @delegateEvents()

window.BTCChart = BTCChart

