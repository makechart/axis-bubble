module.exports =
  pkg:
    name: 'axis-bubble', version: '0.0.1'
    # lite: 不帶 d3 的 base ( 見 @plotdb/chart utils )
    extend: {name: "@makechart/base", path: "lite/index.html"}
    # 排版用 d3-force ( 依相依順序載入, 不需要 d3 core ) 與 d3-force-boundary
    dependencies: [
    * name: \d3-dispatch, version: "3.0.1", path: "dist/d3-dispatch.min.js", async: false
    * name: \d3-quadtree, version: "3.0.1", path: "dist/d3-quadtree.min.js", async: false
    * name: \d3-timer, version: "3.0.1", path: "dist/d3-timer.min.js", async: false
    * name: \d3-force, version: "3.0.0", path: "dist/d3-force.min.js", async: false
    * name: \d3-force-boundary, path: "dist/d3-force-boundary.min.js"
    ]
  init: ({root, context, pubsub}) ->
    # 這張圖沒有 layout ( 直接畫在 svg 上 ), 要關掉, 不然 core 找不到 .pdl-layout 會丟錯
    pubsub.fire \init, mod: mod({context}), layout: false .then ~> it.0

mod = ({context}) ->
  {d3, forceBoundary, ldcolor, chart} = context
  {scale: Scale, color: {turbo, discrete}, anim: {join}} = chart.utils
  svgns = "http://www.w3.org/2000/svg"
  kids = (p, sel) -> Array.from(p.querySelectorAll ":scope > #sel")
  # 同 d3.extent: 略過 null / NaN
  extent = (list) ->
    vs = list.filter -> it? and +it >= +it
    if vs.length => [vs.reduce(((a,b) -> if b < a => b else a)), vs.reduce(((a,b) -> if b > a => b else a))]
    else [undefined, undefined]
  # 同 d3.randomLcg ( 移植自 d3-random, ISC ): 沒給種子時用 Math.random 當種子
  lcg = (seed = Math.random!) ->
    [mul, inc, eps] = [0x19660D, 0x3C6EF35F, 1 / 0x100000000]
    state = (if 0 <= seed and seed < 1 => seed / eps else Math.abs(seed)) .|. 0
    -> eps * ((state := (mul * state + inc) .|. 0) .>>>. 0)
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
    # 沒有 layout 時 svg 接在 base 的 layout 區塊後面, 會被擠到可視範圍外; 疊回左上角
    @svg.style <<< position: \absolute, left: 0, top: 0
    # 點一下切換: 依 color 上下分開 / 全部擠在中線
    @svg.addEventListener \click, ~>
      @type = !@type
      @resize!
      @render!
      if @sim =>
        @sim.stop!
        @sim.alpha 0.9
  parse: ->
    @xextent = extent(@data.map -> it.xpos)
    @rextent = extent @data.map -> it.radius
    @cextent = extent @data.map -> it.color
  resize: ->
    # 同 d3.randomUniform.source(d3.randomLcg(@seed))(0, 1) ( 原本寫成 root.seed, 這裡沒有 root )
    rng = lcg @seed
    @scale-x = Scale.linear!domain @xextent .range [0, @box.width]
    if @type =>
      @scale-y = Scale.linear!domain @cextent .range [0, @box.height]
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
    # 版面由 mod.tick 的模擬推動 ( 原本沒有呼叫 start, 模擬從來沒跑 )
    @start!
  render: ->
    rate = @rate
    @scale = do
      color: turbo
      r: Scale.linear!domain(@rextent).range([0,1])
      c: Scale.linear!domain(@cextent).range([0,1])
    pal = if @cfg.palette => @cfg.palette.colors.map -> ldcolor.web(it.value or it) else <[#f00 #0f0 #00f #f90 #9f0 #0f9]>
    int-color = discrete pal
    @scale.color = ~> int-color(@scale.c it)

    bj = join root: @svg, tag: \circle, cls: \bubble, data: @data
    bj.exit.map -> it.remove!
    bj.enter.map (n) ~>
      n.setAttribute \r, 0
      n.setAttribute \fill, @scale.color n.__data__.c
    kids(@svg, \circle.bubble).map (n) ~>
      d = n.__data__
      n.setAttribute \cx, d.x
      n.setAttribute \cy, d.y
      n.setAttribute \fill, @scale.color d.c
      n.setAttribute \r, (d.r >? 2) * @rate

    lj = join root: @svg, tag: \g, cls: \label, data: @data
    lj.exit.map -> it.remove!
    lj.enter.map (n) ->
      n.appendChild document.createElementNS(svgns, \text)
        ..setAttribute \dy, \-.28em
        ..setAttribute \text-anchor, \middle
        ..setAttribute \font-size, \.7em
        ..setAttribute \font-family, \Rubik
        # 標籤不擋滑鼠 ( 原本拼成 pointer-event, 沒有作用 )
        ..style.pointerEvents = \none
    kids(@svg, \g.label).map (n) ->
      d = n.__data__
      n.setAttribute \transform, "translate(#{d.x},#{d.y})"
      kids(n, \text).map (t, i) ->
        t.__data__ = d
        t.setAttribute \opacity, (if ( d.r * 2 * rate ) < "#{(d.val).toFixed(2)}".length * 7 => 0 else 1)
        t.setAttribute \dy, \.38em
        t.textContent = if i == 0 =>
          if d.val > 1000000 => (d.val/1000000).toFixed(2) + "M"
          else if d.val > 1000 => (d.val/1000).toFixed(2) + "K"
          else (d.val).toFixed(2)
        else d._idx

  tick: ->
    if !@data or !@box => return
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
    if alpha < 0.001 => @stop!
    @data.map -> it.y = it.y + (it.ty - it.y) * alpha * 0.1
    @render!
