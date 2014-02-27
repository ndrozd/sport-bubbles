
root = exports ? this

Bubbles = () ->
  
  
  width = 980
  height = 600
  data = []
  node = null
  label = null
  margin = {top: 0, right: 0, bottom: 0, left: 0}
  
  maxRadius = 110

  rScale = d3.scale.sqrt().range([13,maxRadius])
  
  rValue = (d) -> parseInt(d.count)
  idValue = (d) -> d.name
  idImg = (d) -> d.img
  textValue = (d) -> d.name

  collisionPadding = 4
  minCollisionRadius = 12

  jitter = 0.5

  transformData = (rawData) ->
    rawData.forEach (d) ->
      d.count = parseInt(d.count)
      rawData.sort(() -> 0.5 - Math.random())
    rawData

  tick = (e) ->
    dampenedAlpha = e.alpha * 0.1
    
    node
      .each(gravity(dampenedAlpha))
      .each(collide(jitter))
      .attr("transform", (d) -> "translate(#{d.x},#{d.y})")

    label
      .style("left", (d) -> ((margin.left + d.x) - d.dx / 2) + "px")
      .style("top", (d) -> ((margin.top + d.y) - rScale(rValue(d)) / 2) + "px")

  force = d3.layout.force()
    .gravity(0)
    .charge(0)
    .size([width, height])
    .on("tick", tick)

  chart = (selection) ->
    selection.each (rawData) ->

      
      data = transformData(rawData)
      
      maxDomainValue = d3.max(data, (d) -> rValue(d))
      rScale.domain([1000, maxDomainValue])

      svg = d3.select(this).selectAll("svg").data([data])
      svgEnter = svg.enter().append("svg")
      svg.attr("width", width + margin.left + margin.right )
      svg.attr("height", height + margin.top + margin.bottom )
      
      node = svgEnter.append("g").attr("id", "bubble-nodes")
        .attr("transform", "translate(#{margin.left},#{margin.top})")

      node.append("rect")
        .attr("id", "bubble-background")
        .attr("width", width)
        .attr("height", height)
        .on("click", clear)
 
      label = d3.select(this).selectAll("#bubble-labels").data([data])
        .enter()
        .append("div")
        .attr("id", "bubble-labels")

      update()


  update = () ->

    data.forEach (d,i) ->
      d.forceR = Math.max(minCollisionRadius, rScale(rValue(d)))

    force.nodes(data).start()
    updateNodes()
    updateLabels()

  updateNodes = () ->

    node = node.selectAll(".bubble-node").data(data, (d) -> idValue(d))
    node.exit().remove()
    node.enter()
      .append("a")
      .attr("class", "bubble-node" + " qtip-bootstrap")
      .attr("onmouseover", "showtooltip($(this))")
      .attr("title", (d) -> textValue(d) + ": " + rValue(d) + " шт.")
      .attr("xlink:href", (d) -> "#}")
      .attr("z-index", 999)
      .attr("position", "relative")
      .call(force.drag)
      
      .call(connectEvents)
      .append("circle")
      .attr("r", (d) -> rScale(rValue(d)))

  updateLabels = () ->
    
    
    label = label.selectAll(".bubble-label").data(data, (d) -> idValue(d))

    label.exit().remove()

    labelEnter = label.enter().append("a")
      .attr("class", "bubble-label")
      .call(force.drag)
      .call(connectEvents)

    labelEnter.append("img")
      .attr("src", (d) -> idImg(d))
      .style("width",(d) -> rScale(rValue(d)) + "px")

    label.append("span")
      .text((d) -> textValue(d))
      .each((d) -> d.dx = Math.max(1.2 * rScale(rValue(d)), this.getBoundingClientRect().width))
      .remove()

    
    label
      .style("width", (d) -> d.dx + "px")

    label.each((d) -> d.dy = this.getBoundingClientRect().height)

  gravity = (alpha) ->
    
    cx = width / 2
    cy = height / 2
    
    
    ax = alpha / 5
    ay = alpha
  
    (d) ->
      d.x += (cx - d.x) * ax
      d.y += (cy - d.y) * ay
 
  collide = (jitter) ->
    
    
    (d) ->
      data.forEach (d2) ->
        
        
        if d != d2
          
          
          x = d.x - d2.x
          y = d.y - d2.y
          distance = Math.sqrt(x * x + y * y)
          
          
          
          minDistance = d.forceR + d2.forceR + collisionPadding

          
          
          if distance < minDistance
            
            distance = (distance - minDistance) / distance * jitter
            
            moveX = x * distance
            moveY = y * distance
            d.x -= moveX
            d.y -= moveY
            d2.x += moveX
            d2.y += moveY

  connectEvents = (d) ->
    
    d.on("mouseover", mouseover)
    d.on("mouseout", mouseout)
  
  clear = () ->
    location.replace("#")
  
  mouseover = (d) ->
    a = node.attr("title")
    node.classed("bubble-hover", (p) -> p == d)
    
  mouseout = (d) ->
    node.classed("bubble-hover", false)

  chart.jitter = (_) ->
    if !arguments.length
      return jitter
    jitter = _
    force.start()
    chart

  chart.height = (_) ->
    if !arguments.length
      return height
    height = _
    chart

  chart.width = (_) ->
    if !arguments.length
      return width
    width = _
    chart

  chart.r = (_) ->
    if !arguments.length
      return rValue
    rValue = _
    chart  
  return chart


root.plotData = (selector, data, plot) ->
  d3.select(selector)
    .datum(data)
    .call(plot)

texts = [
  {key:"olymp",file:"olymp.csv",name:"dfsfds"}
]

$ ->
  
  plot = Bubbles()
  $("img, a, circle, svg").qtip
    content: "Mouse tracking!"
    position:
      target: "mouse" 
      adjust: 
        x: 5
        y: 5

  display = (data) ->
    plotData("#vis", data, plot)  
  key = decodeURIComponent(location.search).replace("?","")
  text = texts.filter((t) -> t.key == key)[0]

  
  if !text
    text = texts[0]
  
  $("#text-select").val(key)
  
  d3.select("#jitter")
    .on "input", () ->
      plot.jitter(parseFloat(this.output.value))

  
  d3.csv("data/#{text.file}", display)
  

