

class Graphene
  demo:->
    @is_demo = true

  build: (json)=>
    _.each _.keys(json), (k)=>
      console.log "building [#{k}]"
      if @is_demo
        klass = Graphene.DemoTimeSeries
      else
        klass = Graphene.TimeSeries

      model_opts = {source: json[k].source}
      delete json[k].source
      if json[k].refresh_interval
        model_opts.refresh_interval = json[k].refresh_interval
        delete json[k].refresh_interval
      ts = new klass(model_opts)

      _.each json[k], (opts, view)=>
        klass = eval("Graphene.#{view}View")
        console.log _.extend({ model: ts, ymin:@getUrlParam(model_opts.source, "yMin"), ymax:@getUrlParam(model_opts.source, "yMax") }, opts)
        new klass(_.extend({ model: ts, ymin:@getUrlParam(model_opts.source, "yMin"), ymax:@getUrlParam(model_opts.source, "yMax") }, opts))
        ts.start()

  discover: (url, dash, parent_specifier, cb)->
    $.getJSON "#{url}/dashboard/load/#{dash}", (data)->
      i = 0
      desc = {}
      _.each data['state']['graphs'], (graph)->
        path = graph[2]
        conf = graph[1]
        title = if conf.title then conf.title else "n/a"
        desc["Graph #{i}"] =
          source: "#{url}#{path}&format=json"
          TimeSeries:
            title: title
            ymin: conf.yMin
            parent: parent_specifier(i, url)
        i++
      cb(desc)

  getUrlParam: (url, variable)->
    value = ''
    query = url.split('?')[1]
    return value unless query

    vars = query.split('&')
    return value unless vars && vars.length > 0

    _.each vars, (v)->
      pair = v.split('=')
      if decodeURIComponent(pair[0]) == variable
        value = decodeURIComponent(pair[1])
    value


@Graphene = Graphene




class Graphene.GraphiteModel extends Backbone.Model
  defaults:
    source:''
    data: null
    ymin: 0
    ymax: 0
    refresh_interval: 10000

  debug:()->
    console.log("#{@get('refresh_interval')}")

  start: ()=>
    @refresh()
    console.log("Starting to poll at #{@get('refresh_interval')}")
    @t_index = setInterval(@refresh, @get('refresh_interval'))

  stop: ()=>
    clearInterval(@t_index)

  refresh: ()=>
    url = @get('source')
    #jQuery expects to see 'jsonp=?' in the url in order to perform JSONP-style requests
    if -1 == url.indexOf('&jsonp=?')
        url = url + '&jsonp=?'

    options =
      url: url
      dataType: 'json'
      jsonp: 'jsonp'
      success: (js) =>
        console.log("got data.")
        @process_data(js)
    $.ajax options

  process_data: ()=>
    return null





class Graphene.DemoTimeSeries extends Backbone.Model
  defaults:
    range: [0, 1000]
    num_points: 100
    num_new_points: 1
    num_series: 2
    refresh_interval: 3000

  debug:()->
    console.log("#{@get('refresh_interval')}")

  start: ()=>
    console.log("Starting to poll at #{@get('refresh_interval')}")
    @data = []
    _.each _.range(@get 'num_series'), (i)=>
        @data.push({
          label: "Series #{i}",
          ymin: 0,
          ymax: 0,
          points: []
        })
    @point_interval = @get('refresh_interval') / @get('num_new_points')

    _.each @data, (d)=>
      @add_points(new Date(), @get('range'), @get('num_points'), @point_interval, d)
    @set(data:@data)

    @t_index = setInterval(@refresh, @get('refresh_interval'))

  stop: ()=>
    clearInterval(@t_index)

  refresh: ()=>
    # clone data - tricks d3/backbone refs
    @data = _.map @data, (d)->
      d = _.clone(d)
      d.points = _.map(d.points, (p)-> [p[0], p[1]])
      d

    last = @data[0].points.pop()
    @data[0].points.push last
    start_date = last[1]

    num_new_points = @get 'num_new_points'
    _.each @data, (d)=>
      @add_points(start_date, @get('range'), num_new_points, @point_interval, d)
    @set(data: @data)


  add_points: (start_date, range, num_new_points, point_interval, d)=>
    _.each _.range(num_new_points), (i)=>
      # lay out i points in time. base time x i*interval
      new_point = [
        range[0] + Math.random()*(range[1]-range[0]),
        new Date(start_date.getTime() + (i+1)*point_interval)
      ]
      d.points.push(new_point)
      d.points.shift() if d.points.length > @get('num_points')
    d.ymin = d3.min(d.points, (d) -> d[0])
    d.ymax = d3.max(d.points, (d) -> d[0])




class Graphene.BarChart extends Graphene.GraphiteModel
  process_data: (js)=>
    console.log 'process data barchart'
    data = _.map js, (dp)->
      min = d3.min(dp.datapoints, (d) -> d[0])
      return null unless min != undefined
      max = d3.max(dp.datapoints, (d) -> d[0])
      return null unless max != undefined

      _.each dp.datapoints, (d) -> d[1] = new Date(d[1]*1000)
      return {
        points: _.reject(dp.datapoints, (d)-> d[0] == null),
        ymin: min,
        ymax: max,
        label: dp.target
      }
    data = _.reject data, (d)-> d == null
    @set(data:data)

class Graphene.TimeSeries extends Graphene.GraphiteModel
  process_data: (js)=>
    data = _.map js, (dp)->
      min = d3.min(dp.datapoints, (d) -> d[0])
      return null unless min != undefined
      max = d3.max(dp.datapoints, (d) -> d[0])
      return null unless max != undefined
      last = _.last(dp.datapoints)[0] ? 0
      return null unless last != undefined      
      _.each dp.datapoints, (d) -> d[1] = new Date(d[1]*1000)
      return {
        points: _.reject(dp.datapoints, (d)-> d[0] == null),
        ymin: min,
        ymax: max,
        last: last,
        label: dp.target
      }
    data = _.reject data, (d)-> d == null
    @set(data:data)






class Graphene.GaugeGadgetView extends Backbone.View
  className: 'gauge-gadget-view'
  tagName: 'div'
  initialize: ()->
    @title  = @options.title
    @type   = @options.type

    @parent = @options.parent || '#parent'
    @value_format  = @options.value_format || ".3s"
    @null_value = 0

    @from = @options.from || 0
    @to = @options.to || 100

    @observer = @options.observer

    @vis = d3.select(@parent).append("div")
            .attr("class", "ggview")
            .attr("id", @title+"GaugeContainer")

    config =
      size: @options.size || 120
      label: @title
      minorTicks: 5
      min: @from
      max: @to


    config.redZones = []
    config.redZones.push({ from: @options.red_from || 0.9*@to, to: @options.red_to || @to })

    config.yellowZones = []
    config.yellowZones.push({ from: @options.yellow_from || 0.75*@to, to: @options.yellow_to || 0.9*@to })

    @gauge = new Gauge("#{@title}GaugeContainer", config)
    @gauge.render()

    @model.bind('change', @render)
    console.log("GG view ")


  by_type:(d)=>
    switch @type
      when "min"     then d.ymin
      when "max"     then d.ymax
      when "current" then d.last
      else d.points[0][0]

  render: ()=>
    console.log("rendering.")
    data = @model.get('data')
    datum = if data && data.length > 0 then data[0] else { ymax: @null_value, ymin: @null_value, points: [[@null_value, 0]] }

    @observer(@by_type(datum)) if @observer

    @gauge.redraw(@by_type(datum), @value_format)






class Graphene.GaugeLabelView extends Backbone.View
  className: 'gauge-label-view'
  tagName: 'div'
  initialize: ()->
    @unit   = @options.unit
    @title  = @options.title
    @type   = @options.type
    @parent = @options.parent || '#parent'
    @value_format  = @options.value_format || ".3s"
    @value_format = d3.format(@value_format)
    @null_value = 0
    @observer = @options.observer

    @vis = d3.select(@parent).append("div")
            .attr("class", "glview")
    if @title
      @vis.append("div")
          .attr("class", "label")
          .text(@title)

    @model.bind('change', @render)
    console.log("GL view ")


  by_type:(d)=>
    switch @type
      when "min"     then d.ymin
      when "max"     then d.ymax
      when "current" then d.last
      else d.points[0][0]

  render: ()=>
    data = @model.get('data')
    console.log data
    datum = if data && data.length > 0 then data[0] else { ymax: @null_value, ymin: @null_value, points: [[@null_value, 0]] }

    # let observer know about this
    @observer(@by_type(datum)) if @observer

    vis = @vis
    metric_items = vis.selectAll('div.metric')
      .data([datum], (d)=> @by_type(d))

    metric_items.exit().remove()

    metric = metric_items.enter()
      .insert('div', ":first-child")
      .attr('class',"metric#{if @type then ' '+@type else ''}")

    metric.append('span')
      .attr('class', 'value')
      .text((d)=>@value_format(@by_type(d)))
    if @unit
      metric.append('span')
        .attr('class', 'unit')
        .text(@unit)



class Graphene.TimeSeriesView extends Backbone.View
  tagName: 'div'

  initialize: ()->
    @line_height = @options.line_height || 16
    @animate_ms = @options.animate_ms || 500
    @num_labels = @options.num_labels || 3
    @sort_labels = @options.labels_sort
    @display_verticals = @options.display_verticals || false
    @width = @options.width || 400
    @height = @options.height || 100
    @padding = @options.padding || [@line_height*2, 32, @line_height*(3+@num_labels), 32] #trbl
    @title = @options.title
    @label_formatter = @options.label_formatter || (label) -> label
    @firstrun = true
    @parent = @options.parent || '#parent'
    @null_value = 0
    @show_current = @options.show_current || false
    @observer = @options.observer

    @vis = d3.select(@parent).append("svg")
            .attr("class", "tsview")
            .attr("width",  @width  + (@padding[1]+@padding[3]))
            .attr("height", @height + (@padding[0]+@padding[2]))
            .append("g")
            .attr("transform", "translate(" + @padding[3] + "," + @padding[0] + ")")
    # Is this used in the timeseries? -dvdv
    @value_format  = @options.value_format || ".3s"
    @value_format = d3.format(@value_format)

    @model.bind('change', @render)
    console.log("TS view: #{@width}x#{@height} padding:#{@padding} animate: #{@animate_ms} labels: #{@num_labels}")


  render: ()=>
    console.log("rendering.")
    data = @model.get('data')

    data = if data && data.length > 0 then data else [{ ymax: @null_value, ymin: @null_value, points: [[@null_value, 0],[@null_value, 0]] }]

    #
    # find overall min/max of sets
    #
    dmax = _.max data, (d)-> d.ymax
    dmax.ymax_graph = @options.ymax || dmax.ymax
    dmin = _.min data, (d)-> d.ymin
    dmin.ymin_graph = @options.ymin ? dmin.ymin

    #
    # build dynamic x & y metrics.
    #
    xpoints = _.flatten (d.points.map((p)->p[1]) for d in data)
    xmin = _.min xpoints, (x)->x.valueOf()
    xmax = _.max xpoints, (x)->x.valueOf()

    x = d3.time.scale().domain([xmin, xmax]).range([0, @width])
    y = d3.scale.linear().domain([dmin.ymin_graph, dmax.ymax_graph]).range([@height, 0]).nice()

    #
    # build axis
    #
    xtick_sz = if @display_verticals then -@height else 0
    xAxis = d3.svg.axis().scale(x).ticks(4).tickSize(xtick_sz).tickSubdivide(true)
    yAxis = d3.svg.axis().scale(y).ticks(4).tickSize(-@width).orient("left").tickFormat(d3.format("s"))

    vis = @vis

    #
    # build dynamic line & area, note that we're using dynamic x & y.
    #
    line = d3.svg.line().x((d) -> x(d[1])).y((d) -> y(d[0]))
    area = d3.svg.area().x((d) -> x(d[1])).y0(@height - 1).y1((d) -> y(d[0]))

    #
    # get first X labels
    #
    if @sort_labels
      order = if(@sort_labels == 'desc') then -1 else 1
      data = _.sortBy(data, (d)-> order*d.ymax)


    # let observer know about this
    @observer(data) if @observer

    #
    # get raw data points (throw away all of the other blabber
    #
    points = _.map data, (d)-> d.points


    if @firstrun
      @firstrun = false

      #
      # Axis
      #
      vis.append("svg:g")
          .attr("class", "x axis")
          .attr("transform", "translate(0," + @height + ")")
          .transition()
          .duration(@animate_ms)
          .call(xAxis)

      vis.append("svg:g").attr("class", "y axis").call(yAxis)

      #
      # Line + Area
      #
      # Note that we can't use idiomatic d3 here - data is one big chunk of data (single property),
      # this is a result of us wanting to use a *single* SVG line element to render the data.
      # so enter() exit() semantics are invalid. We will append here, and later just replace (update).
      # To see an idiomatic d3 handling, take a look at the legend fixture.
      #
      vis.selectAll("path.line").data(points).enter().append('path').attr("d", line).attr('class',  (d,i) -> 'line '+"h-col-#{i+1}")
      vis.selectAll("path.area").data(points).enter().append('path').attr("d", area).attr('class',  (d,i) -> 'area '+"h-col-#{i+1}")

      #
      # Title + Legend
      #
      if @title
        title = vis.append('svg:text')
          .attr('class', 'title')
          .attr('transform', "translate(0, -#{@line_height})")
          .text(@title)

      @legend = vis.append('svg:g')
        .attr('transform', "translate(0, #{@height+@line_height*2})")
        .attr('class', 'legend')

    #---------------------------------------------------------------------------------------#
    # Update Graph
    #---------------------------------------------------------------------------------------#


    #
    # update the legend (dynamic legend ordering responds to min/max)
    #

    # first inject datapoints into legend items.
    # note the data mapping is by label name (not index)
    leg_items = @legend.selectAll('g.l').data(_.first(data, @num_labels), (d)->Math.random())

    # remove legend item.
    leg_items.exit().remove()

    # only per entering item, attach a color box and text.
    litem_enters = leg_items.enter()
      .append('svg:g')
      .attr('transform', (d, i) => "translate(0, #{i*@line_height})")
      .attr('class', 'l')
    litem_enters.append('svg:rect')
      .attr('width', 5)
      .attr('height', 5)
      .attr('class', (d,i) -> 'ts-color '+"h-col-#{i+1}")
    litem_enters_text = litem_enters.append('svg:text')
      .attr('dx', 10)
      .attr('dy', 6)
      .attr('class', 'ts-text')
      .text((d) => @label_formatter(d.label))

    litem_enters_text.append('svg:tspan')
        .attr('class', 'min-tag')
        .attr('dx', 10)
        .text((d) => @value_format(d.ymin)+"min")

    litem_enters_text.append('svg:tspan')
        .attr('class', 'max-tag')
        .attr('dx', 2)
        .text((d) => @value_format(d.ymax)+"max")

    if @show_current is true
      litem_enters_text.append('svg:tspan')
          .attr('class', 'last-tag')
          .attr('dx', 2)
          .text((d) => @value_format(d.last)+"last")



    #
    # update the graph
    #
    vis.transition().ease("linear").duration(@animate_ms).select(".x.axis").call(xAxis)
    vis.select(".y.axis").call(yAxis)

    vis.selectAll("path.area")
        .data(points)
        .attr("d", area)
        .transition()
        .ease("linear")
        .duration(@animate_ms)


    vis.selectAll("path.line")
        .data(points)
        .attr("d", line)
        .transition()
        .ease("linear")
        .duration(@animate_ms)


# Barcharts
class Graphene.BarChartView extends Backbone.View
  tagName: 'div'
  initialize: () ->
    @line_height = @options.line_height || 16
    @animate_ms = @options.animate_ms || 500
    @num_labels = @options.num_labels || 3
    @sort_labels = @options.labels_sort || 'desc'
    @display_verticals = @options.display_verticals || false
    @width = @options.width || 400
    @height = @options.height || 100
    @padding = @options.padding || [@line_height*2, 32, @line_height*(3+@num_labels), 32] #trbl
    @title = @options.title
    @label_formatter = @options.label_formatter || (label) -> label
    @firstrun = true
    @parent = @options.parent || '#parent'
    @null_value = 0
    @value_format  = @options.value_format || ".3s"
    @value_format = d3.format(@value_format)

    @vis = d3.select(@parent).append("svg")
            .attr("class", "tsview")
            .attr("width",  @width  + (@padding[1]+@padding[3]))
            .attr("height", @height + (@padding[0]+@padding[2]))
            .append("g")
            .attr("transform", "translate(" + @padding[3] + "," + @padding[0] + ")")
    @model.bind('change', @render)
  render: () =>
    console.log "rendering bar chart."

    # Getting data
    data = @model.get('data')

    dmax = _.max data, (d)-> d.ymax
    dmin = _.min data, (d)-> d.ymin
    data = _.sortBy(data, (d)-> 1*d.ymax)
    points = _.map data, (d)-> d.points

    # Find the minimum and maximum timestamps
    timestamps = _.flatten (_.map points, (series)-> (_.map series, (point)-> point[1]))
    minTimestamp = _.min timestamps
    maxTimestamp = _.max timestamps

    # Find the closest two timestamps (that aren't equal), use that as the difference between timestamps
    orderedTimestamps = _.uniq (_.sortBy timestamps, (ts)-> ts), true, (ts)-> ts.getTime()
    differences = []
    _.each orderedTimestamps, (ts, index, list)->
      if list[index+1] != undefined
        differences.push list[index+1] - ts 
    timestampDifference = (_.min differences)

    # Create x and y scales
    x = d3.time.scale().domain([minTimestamp, maxTimestamp + timestampDifference]).range([0, @width])
    y = d3.scale.linear().domain([dmin.ymin, dmax.ymax]).range([@height, 0]).nice()

    # The total number of groups of columns
    columnGroups = (maxTimestamp - minTimestamp) / timestampDifference + 1
    # The number of columns per group (the number of targets)
    columnsPerGroup = points.length
    # The total number of columns
    columnsTotal = columnGroups * columnsPerGroup
    # The width of each bar
    barWidth = _.max [@width / columnsTotal - 2, 0.1]

    # Functions used to draw rectangles
    calculateX = (d, outerIndex, innerIndex)->
      x(d[1]) + innerIndex * (barWidth + 2)
    calculateY = (d)->
      y(d[0])

    # Create axes
    xtick_sz = if @display_verticals then -@height else 0
    xAxis = d3.svg.axis().scale(x).ticks(_.min([4, columnGroups])).tickSize(xtick_sz).tickSubdivide(true)
    yAxis = d3.svg.axis().scale(y).ticks(4).tickSize(-@width).orient("left").tickFormat(d3.format("s"))
    vis = @vis

    # We need this value because the bars are drawn starting at the top
    canvas_height = @height

    if @firstrun
      @firstrun = false

      # Draw axes
      vis.append("svg:g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + @height + ")")
            .transition()
            .duration(@animate_ms)
            .call(xAxis)
      vis.append("svg:g").attr("class", "y axis").call(yAxis)

      # Draw title and legend
      if @title
        title = vis.append('svg:text')
          .attr('class', 'title')
          .attr('transform', "translate(0, -#{@line_height})")
          .text(@title)

      @legend = vis.append('svg:g')
        .attr('transform', "translate(0, #{@height+@line_height*2})")
        .attr('class', 'legend')

    #---------------------------------------------------------------------------------------#
    # Update Graph
    #---------------------------------------------------------------------------------------#

    # update the legend (dynamic legend ordering responds to min/max)
    # first inject datapoints into legend items.
    # note the data mapping is by label name (not index)
    leg_items = @legend.selectAll('g.l').data(_.first(data, @num_labels), (d)->Math.random())

    # remove legend item.
    leg_items.exit().remove()

    # only per entering item, attach a color box and text.
    litem_enters = leg_items.enter()
      .append('svg:g')
      .attr('transform', (d, i) => "translate(0, #{i*@line_height})")
      .attr('class', 'l')
    litem_enters.append('svg:rect')
      .attr('width', 5)
      .attr('height', 5)
      .attr('class', (d,i) -> 'ts-color '+"h-col-#{i+1}")
    litem_enters_text = litem_enters.append('svg:text')
      .attr('dx', 10)
      .attr('dy', 6)
      .attr('class', 'ts-text')
      .text((d) => @label_formatter(d.label))

    # Draw minimum and maximum information
    litem_enters_text.append('svg:tspan')
        .attr('class', 'min-tag')
        .attr('dx', 10)
        .text((d) => @value_format(d.ymin)+"min")
    litem_enters_text.append('svg:tspan')
        .attr('class', 'max-tag')
        .attr('dx', 2)
        .text((d) => @value_format(d.ymax)+"max")

    # Draw new rectangles
    _.each points, (series, i)->
      className = "h-col-" + (i+1)
      vis.selectAll("rect.area."+className)
        .data(series)
        .enter()
        .append("rect")
          .attr("class", className + " area")
          .attr("x", (d, j)-> calculateX(d, j, i))
          .attr("y", canvas_height)
          .attr("width", barWidth)

    # Update existing rectangles
    _.each points, (series, i)->
      className = "h-col-" + (i+1)
      vis.selectAll("rect.area."+className)
        .data(series)
        .transition().ease("linear").duration(@animate_ms)
          .attr("x", (d, j)-> calculateX(d, j, i))
          .attr("y", (d, j)-> calculateY(d))
          .attr("width", barWidth)
          .attr("height", (d, j) -> canvas_height - calculateY(d))
          .attr("class", className + " area")

    # Update axes
    vis.transition().ease("linear").duration(@animate_ms).select(".x.axis").call(xAxis)
    vis.select(".y.axis").call(yAxis)

    console.log "done drawing"
