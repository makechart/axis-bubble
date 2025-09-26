module.exports =
  pkg:
    name: 'axis-bubble', version: '0.0.1'
    extend: {name: "base", version: "0.0.1"}
    dependencies: []
  init: ({root, context, pubsub}) ->
    pubsub.fire \init, mod: mod {context} .then ~> it.0

mod = ({context}) ->
  {d3, forceBoundary, ldcolor, repeatString$} = context
  sample: ->
    raw: [0 to 200].map (val) ~> 
      {val: Math.random! * 50 + 10, x: Math.random!, cat: Math.ceil(5 * Math.random!)}
    binding: do
      color: {key: \cat}
      radius: {key: \val}
      xpos: {key: \x}
  config: {}
  dimension:
    color: {type: \R, name: "顏色"}
    radius: {type: \R, name: "半徑"}
    xpos: {type: \R, name: "X座標"}
  init: ->
    @svg.addEventListener \click, ~>
      @type = !@type
      @resize!
      @render!
      @sim.stop!
      @sim.alpha 0.9
    @svg.appendChild t = document.createElementNS('http://www.w3.org/2000/svg', 'text')
    @text = d3.select(t)
    @text
      .attr \x, 20
      .attr \y, 20
  parse: ->
    @xextent = d3.extent(@data.map -> it.xpos)
    @rextent = d3.extent @data.map -> it.radius
    @cextent = d3.extent @data.map -> it.color
  resize: ->
    rng = d3.randomUniform.source(d3.randomLcg(root.seed))(0, 1)
    @scale-x = d3.scaleLinear!domain @xextent .range [0, @box.width]
    if @type =>
      @scale-y = d3.scaleLinear!domain @cextent .range [0, @box.height]
    else
      @scale-y = ~> @box.height / 2
    @data.map (v) ~>
      v <<< {
        x: v.x or @scale-x(v.xpos)
        y: v.y or @box.height / 2
        ty: @scale-y(v.color)
        val: v.radius
        r: v.radius
        c: v.color
      }
    @area = @box.width * @box.height 
    @rate = 0.5
  render: ->
    rate = @rate
    @scale = do
      color: d3.interpolateTurbo
      r: d3.scaleLinear!domain(@rextent).range([0,1])
      c: d3.scaleLinear!domain(@cextent).range([0,1])
    pal = if @cfg.palette => @cfg.palette.colors.map -> ldcolor.web(it.value or it) else <[#f00 #0f0 #00f #f90 #9f0 #0f9]>
    int-color = d3.interpolateDiscrete pal
    @scale.color = ~> int-color(@scale.c it)

    d3.select @svg .selectAll \circle.bubble .data @data
      ..exit!remove!
      ..enter!append \circle
        .attr \class, \bubble
        .attr \r, (d,i) ~> 0
        .attr \fill, (d,i) ~> @scale.color d.c

    d3.select @svg .selectAll \circle.bubble
      .attr \cx, (d,i) -> d.x
      .attr \cy, (d,i) -> d.y
      .attr \fill, (d,i) ~> @scale.color d.c #@scale.r(d.c)
      .attr \r, (d,i) ~> (d.r >? 2) * @rate

    d3.select @svg .selectAll \g.label .data @data
      ..exit!remove!
      ..enter!append \g
        .attr \class, \label
        .each (d,i) ->
          [0] #[0,1]
            .map ~> d3.select(@).append \text
            .map ->
              it
                .attr \dy, \-.28em
                .attr \text-anchor, \middle
                .attr \font-size, \.7em
                .attr \font-family, \Rubik
                .style \pointer-event, \none
    d3.select @svg .selectAll \g.label
      .attr \transform, (d,i) -> "translate(#{d.x},#{d.y})"
      .each (d,i) ->
        d3.select(@).selectAll \text
          .attr \opacity, (if ( d.r * 2 * rate ) < "#{(d.val).toFixed(2)}".length * 7 => 0 else 1)
          .attr \dy, (e,i) -> \.38em #if i == 0 => '-.28em' else '.88em'
          .text (e,i) ->
            if i == 0 =>
              if d.val > 1000000 => (d.val/1000000).toFixed(2) + "M"
              else if d.val > 1000 => (d.val/1000).toFixed(2) + "K"
              else (d.val).toFixed(2)
            else return d._idx

  tick: ->
    if !@sim =>
      kickoff = true
      @fc = fc = d3.forceCollide!
      @sim = d3.forceSimulation!
        .force \center, @fg = d3.forceCenter @box.width/2, @box.height/2
        .force \x, @fx = d3.forceX(@box.width / 2).strength(0.15)
        .force \y, @fy = d3.forceY((@box.height) / 2).strength(0.1)
        .force \b, @fb = forceBoundary((->it.r), (->it.r), (~>@box.width - it.r), (~>@box.height - it.r))
        .force \collide, fc
      @sim.stop!
      @sim.alpha 0.9
      @sim.nodes(@data)
    @fc.strength 1.0
    @fc.radius ~> @rate * it.r + 2
    @fg.x @box.width/2
    @fg.y @box.height/2
    @fx.strength 0.15
    @fy.strength 0.01
    @sim.tick if kickoff => 20 else 1
    alpha = @sim.alpha!
    @text.text alpha
    if alpha < 0.001 => @stop!
    @data.map -> it.y = it.y + (it.ty - it.y) * alpha * 0.1

    d3.select @svg .selectAll \circle.bubble
      .attr \cx, (d,i) -> d.x
      .attr \cy, (d,i) -> d.y
    d3.select @svg .selectAll \g.label
      .attr \transform, (d,i) -> "translate(#{d.x},#{d.y})"
    @render!
