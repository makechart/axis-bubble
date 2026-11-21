module.exports =
  pkg:
    name: 'axis-bubble', version: '0.0.1'
    # lite: 不帶 d3 的 base ( 見 @plotdb/chart utils )
    extend: {name: "@makechart/base", path: "lite/index.html"}
    # 排版用 d3-force ( 依相依順序載入, 不需要 d3 core ). 邊界由 tick 直接夾住, 不需要 d3-force-boundary
    dependencies: [
    * name: \d3-dispatch, version: "3.0.1", path: "dist/d3-dispatch.min.js", async: false
    * name: \d3-quadtree, version: "3.0.1", path: "dist/d3-quadtree.min.js", async: false
    * name: \d3-timer, version: "3.0.1", path: "dist/d3-timer.min.js", async: false
    * name: \d3-force, version: "3.0.0", path: "dist/d3-force.min.js", async: false
    ]
  init: ({root, context, pubsub}) ->
    pubsub.fire \init, mod: mod({context}) .then ~> it.0

mod = ({context}) ->
  {d3, ldcolor, chart} = context
  {scale: Scale, anim: {join}} = chart.utils
  svgns = "http://www.w3.org/2000/svg"
  kids = (p, sel) -> Array.from(p.querySelectorAll ":scope > #sel")
  attrs = (n, o) -> for k, v of o => n.setAttribute k, v
  num = (v) -> if v? and v != '' and !isNaN(+v) => +v else NaN
  # 同 d3.extent: 略過 null / NaN
  extent = (list) ->
    vs = list.filter -> !isNaN(it)
    if vs.length => [Math.min.apply(Math, vs), Math.max.apply(Math, vs)] else [0, 1]
  sample: ->
    regions = <[Asia Europe Africa America Oceania]>
    raw: [0 til 120].map (i) ~>
      g = Math.floor(Math.random! * regions.length)
      name: "N-#i", region: regions[g]
      x: Math.round((Math.random! * 60 + g * 10) * 10) / 10
      val: Math.round((Math.random! ** 2) * 900 + 10)
    binding: do
      xpos: {key: \x}
      radius: {key: \val}
      color: {key: \region}
      name: {key: \name}
  config: chart.utils.config.from({
    preset: \default
    legend: \legend
    tip: \tip
    xaxis: \axis
  }) <<<
    bubble:
      size: type: \number, default: 1, min: 0.1, max: 3, step: 0.05, desc: {en: "overall bubble size; 1 makes the bubbles cover about 40% of the plot area", "zh-TW": "泡泡整體大小；1 表示泡泡總面積約佔繪圖區的 40%"}
      min-radius: name: "min radius", type: \number, default: 2, min: 0, max: 50, step: 0.5, desc: {en: "smallest radius a bubble can shrink to, in px", "zh-TW": "泡泡最小的半徑 ( px )"}
      opacity: type: \number, default: 0.7, min: 0, max: 1, step: 0.01, desc: {en: "opacity of the bubbles, so overlapping bubbles stay visible", "zh-TW": "泡泡的不透明度，重疊時仍看得到底下的泡泡"}
      stroke: type: \choice, values: <[darker white none]>, default: \darker, desc: {en: "outline of the bubbles: a darker shade of the fill, white, or none", "zh-TW": "泡泡的外框：填色加深、白色或不畫"}
      stroke-width: type: \number, default: 1, min: 0, max: 10, step: 0.5, desc: {en: "outline width ( px )", "zh-TW": "外框粗細 ( px )"}
      gap: type: \number, default: 1, min: -10, max: 20, step: 0.5, desc: {en: "space kept between bubbles ( px ); negative lets them overlap", "zh-TW": "泡泡之間保留的距離 ( px )；負值允許重疊"}
    split:
      enabled: type: \boolean, default: false, desc: {en: "put each group on its own row instead of one shared row", "zh-TW": "每個分組各排一列，而不是全部擠在同一列"}
      label: type: \boolean, default: true, desc: {en: "write the group name at the start of each row", "zh-TW": "在每一列的開頭寫上分組名稱"}
      divider: type: \boolean, default: true, desc: {en: "draw a faint line between rows", "zh-TW": "列與列之間畫一條淡淡的分隔線"}
    label:
      show: type: \choice, values: <[value name none]>, default: \value, desc: {en: "text inside the bubbles; it is hidden when it doesn't fit, hover a bubble to see it in the tooltip", "zh-TW": "泡泡裡的文字；放不下時隱藏，滑鼠移到泡泡上可在提示框看到"}
      format: type: \format, default: \.3~s, desc: {en: "number format of the values in bubbles", "zh-TW": "泡泡裡數值的格式"}
      font: chart.utils.config.from({preset: \font})
  # 段落 ( tab ) 的說明, key 是段落的路徑. preset 的段落由 chart.utils.config.tabinfo 掛上來, 共用的 common 與各處的 font 段落由核心補
  tabinfo: chart.utils.config.tabinfo({xaxis: \axis, legend: \legend, tip: \tip}) <<<
    bubble: desc: {en: "size, opacity, outline and spacing of the bubbles", "zh-TW": "泡泡的大小、不透明度、外框與間距"}
    split: desc: {en: "lay the groups out on separate rows", "zh-TW": "把各分組排成不同的列"}
    label: desc: {en: "text written inside the bubbles", "zh-TW": "寫在泡泡裡的文字"}
  dimension:
    xpos: {type: \R, name: "X position", priority: 1}
    radius: {type: \R, name: "size", priority: 2}
    color: {type: \C, name: "group", priority: 3}
    name: {type: \NC, name: "name", priority: 4}
  init: ->
    @tint = tint = new chart.utils.tint!
    @pos = {}
    @g = Object.fromEntries <[view xaxis legend]>.map ~> [it, @layout.get-group it]
    @g.bubbles = @g.view.appendChild document.createElementNS(svgns, \g)
    @g.labels = @g.view.appendChild document.createElementNS(svgns, \g)
    # 列名畫在泡泡上面 ( 加一圈背景色的描邊 ), 不然會被列頂的泡泡蓋住
    @g.rows = @g.view.appendChild document.createElementNS(svgns, \g)
    [@g.labels, @g.rows].map -> it.style.pointerEvents = \none
    @xaxis = new chart.utils.axis layout: @layout, name: \xaxis, direction: \bottom
    @legend = new chart.utils.legend do
      layout: @layout
      name: \legend
      root: @root
      shape: (d) -> @setAttribute \fill, tint.get d.key
    @legend.on \select, ~> @bind!; @resize!; @render!
    @tip = new chart.utils.tip do
      root: @root
      accessor: ({evt}) ~>
        if !(evt.target and d = evt.target.__data__) or !d._raw => return null
        fmt = chart.utils.format.from @cfg.tip.format or \.3s
        b = @binding
        cap = (k) -> (b[k] or {}).name or (b[k] or {}).key or k
        v = ["#{cap \xpos}: #{fmt d.xpos}#{(b.xpos or {}).unit or ''}"]
        if @has.radius => v.push "#{cap \radius}: #{fmt d.radius}#{(b.radius or {}).unit or ''}"
        name: [d.color, d.name].filter(-> it? and it != '').join(' / ')
        value: v.join ', '
      range: ~> @layout.get-node \view .getBoundingClientRect!
  destroy: -> if @tip => @tip.destroy!
  parse: ->
    @tint.reset!
    @has = {}
    for k in <[radius color name]> => @has[k] = !!@binding[k] and @data.some(-> it[k]?)
    @valid = @data.filter (d) -> !isNaN(num d.xpos)
    @valid.map (d) ~>
      d.xpos = num d.xpos
      d.radius = if @has.radius => (num(d.radius) >? 0) or 0 else 1
      d.key = if @has.color and d.color? => "#{d.color}" else ''
    @groups = if !@has.color => [] else Array.from(new Set(@valid.map -> it.key))
    @groups.sort (a, b) -> a.localeCompare b, undefined, {numeric: true}
    @legend.data @groups.map -> {key: it, text: it}
    @xext = extent @valid.map -> it.xpos
    @rmax = (Math.max.apply Math, @valid.map(-> it.radius)) or 1
  resize: ->
    @tint.set @cfg.palette
    @tip.toggle(if @cfg.tip.enabled? => @cfg.tip.enabled else true)
    @root.querySelector('.pdl-layout').classList
      ..toggle \legend-bottom, @cfg.legend.position == \bottom
      ..toggle \no-xaxis, !@cfg.xaxis.enabled
    @legend.config @cfg.legend
    @legend.update!
    @list = @valid.filter (d) ~> !@has.color or @legend.is-visible d.key
    split = @cfg.split.enabled and @groups.length > 1
    @rows = if split => @groups.filter ~> @legend.is-visible it else ['']
    rowidx = Object.fromEntries @rows.map (d, i) -> [d, i]
    gap = @cfg.bubble.gap or 0
    sw = if @cfg.bubble.stroke == \none => 0 else (@cfg.bubble.stroke-width or 0)

    # 先算半徑: 讓每一列的泡泡總面積約為該列面積的 40% ( 乘上 bubble.size ), 取各列最小的, 各列大小才可以比較
    fit = ~>
      box = @layout.get-box \view
      rh = box.height / (@rows.length or 1)
      sum = {}
      @list.map (d) ~> sum[d.row = if split => rowidx[d.key] else 0] = (sum[d.row] or 0) + d.radius / @rmax
      rate = Math.min.apply Math, ([Infinity] ++ [Math.sqrt(0.4 * box.width * rh / (Math.PI * v)) for k, v of sum when v])
      maxr = (rate * (@cfg.bubble.size or 1)) <? (rh / 2 - sw) <? (box.width / 4)
      maxr >?= 1
      minr = (@cfg.bubble.min-radius or 0) <? maxr
      rmax = @rmax
      @list.map (d) -> d.r = Math.sqrt(d.radius / rmax) * maxr >? minr
      pad = maxr + sw / 2 + 1
      @scale-x = Scale.linear!domain(@xext).range [pad, (box.width - pad) >? pad]
      ticks = @scale-x.ticks((@cfg.xaxis.tick.count or 4) <? (Math.ceil(box.width / 80) >? 2))
      b = @binding.xpos or {}
      @xaxis.config @cfg.xaxis
      @xaxis.ticks ticks
      @xaxis.scale @scale-x
      @xaxis.caption((b.name or b.key or '') + (if b.unit => "(#{b.unit})" else ''))
      @xaxis.render!
      @layout.update false
      @box = box
      @rh = rh
    for i from 0 til 2 => fit!
    @list.map (d) ~>
      d.tx = @scale-x d.xpos
      d.ty = @rh * (d.row + 0.5)
      d.y0 = @rh * d.row
      d.y1 = @rh * (d.row + 1)
      # 沿用上次的位置, 設定或大小改變時從原處移過去; 新的從目標 x 附近開始
      if (p = @pos[d._idx]) => d <<< {x: p.x, y: p.y}
      else d <<< {x: d.tx, y: d.ty + (@random! - 0.5) * (@rh / 2), vx: 0, vy: 0}
    if !@sim =>
      @sim = d3.forceSimulation!
        .force \x, @fx = d3.forceX!strength 0.4
        .force \y, @fy = d3.forceY!strength 0.06
        .force \collide, @fc = d3.forceCollide!iterations 3
      @sim.stop!
    @fx.x (.tx)
    @fy.y (.ty)
    @fc.radius (d) -> d.r + sw / 2 + gap / 2
    @sim.nodes @list
    @sim.alpha 1
    @start!
  render: ->
    {cfg, tint, legend} = @
    color = (d) -> tint.get d.key
    stroke = (d) ->
      if cfg.bubble.stroke == \white => \#fff
      else if cfg.bubble.stroke == \none => \none
      else
        c = ldcolor.hcl(color d)
        c.l = (c.l - 25) >? 0
        ldcolor.web c
    dimmed = (d) ~> @has.color and !legend.is-selected d.key
    bj = join root: @g.bubbles, tag: \circle, cls: \data, data: @list, key: (._idx)
    bj.exit.map -> it.remove!
    bj.nodes.map (n) ~>
      d = n.__data__
      attrs n, do
        cx: d.x, cy: d.y, r: d.r
        fill: color(d), stroke: stroke(d)
        "stroke-width": if cfg.bubble.stroke == \none => 0 else cfg.bubble.stroke-width
        "fill-opacity": cfg.bubble.opacity
        opacity: if dimmed(d) => legend.opacity! else 1

    fmt = chart.utils.format.from cfg.label.format or \.3s
    unit = (@binding.radius or {}).unit or ''
    text = (d) ~>
      if cfg.label.show == \name => d.name or ''
      else if cfg.label.show == \value => (if @has.radius => "#{fmt d.radius}#unit" else '')
      else ''
    family = (cfg.label.font or {}).family
    lj = join root: @g.labels, tag: \text, cls: \label, data: (if cfg.label.show == \none => [] else @list), key: (._idx)
    lj.exit.map -> it.remove!
    lj.nodes.map (n) ~>
      d = n.__data__
      attrs n, do
        class: "label #{if family => family.className or '' else ''}"
        "text-anchor": \middle
        "dominant-baseline": \central
        "font-size": cfg.label.font.size or \.75em
        fill: if ldcolor.hcl(color d).l * cfg.bubble.opacity + 100 * (1 - cfg.bubble.opacity) < 60 => \#fff else \#000
      n.textContent = text d
      # 放不下就藏起來, 滑鼠移到泡泡上時提示框裡看得到
      w = if n.textContent => n.getComputedTextLength! else 0
      h = parseFloat(getComputedStyle(n).fontSize) or 12
      d._lw = w
      n.style.visibility = if !w or w > d.r * 1.8 or h > d.r * 1.6 or dimmed(d) => \hidden else \visible

    # 分列時的列名與分隔線
    split = @rows.length > 1
    rj = join root: @g.rows, tag: \g, cls: \row, data: (if split => @rows else []), key: (-> it)
    rj.exit.map -> it.remove!
    rj.enter.map (n) ->
      n.appendChild document.createElementNS(svgns, \line)
      n.appendChild document.createElementNS(svgns, \text)
    rj.nodes.map (n, i) ~>
      [line, txt] = [n.childNodes.0, n.childNodes.1]
      attrs line, x1: 0, x2: @box.width, y1: @rh * i, y2: @rh * i, stroke: \currentColor, "stroke-opacity": 0.15
      line.style.display = if i and cfg.split.divider => '' else \none
      attrs txt, do
        x: 2, y: @rh * i + 2, "dominant-baseline": \hanging, "font-size": \.8em, fill: \currentColor
        stroke: if !cfg.background or cfg.background == \transparent => \#fff else cfg.background
        "stroke-width": 3, "paint-order": \stroke
      txt.textContent = n.__data__
      txt.style.display = if cfg.split.label => '' else \none
    @legend.render!
    @xaxis.render!
  tick: (t, dt) ->
    if !@sim or !@list => return
    if @sim.alpha! < 0.001 => return @stop!
    @sim.tick!
    # 邊界直接夾住: 不出框, 分列時也不跨到別列 ( 列太矮時置中 )
    w = @box.width
    @list.map (d) ->
      d.x = if 2 * d.r > w => w / 2 else d.x >? d.r <? (w - d.r)
      d.y = if 2 * d.r > d.y1 - d.y0 => (d.y0 + d.y1) / 2 else d.y >? (d.y0 + d.r) <? (d.y1 - d.r)
    @list.map (d) ~> @pos[d._idx] = {x: d.x, y: d.y}
    kids(@g.bubbles, \circle).map (n) -> n.setAttribute(\cx, n.__data__.x); n.setAttribute(\cy, n.__data__.y)
    kids(@g.labels, \text).map (n) -> n.setAttribute(\x, n.__data__.x); n.setAttribute(\y, n.__data__.y)
