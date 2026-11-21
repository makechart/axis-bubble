# axis-bubble 的 test case ( @makechart/viewer 的 mctest )
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n, seed = n) ->
  rnd = mctest.random seed
  raw: [0 til n].map (i) ->
    g = Math.ceil(4 * rnd!)
    {name: "N-#i", val: Math.round((rnd! ** 2) * 900 + 10), x: Math.round((rnd! * 60 + g * 10) * 10) / 10, cat: "G#g"}
  binding: {color: {key: \cat}, radius: {key: \val, unit: \t}, xpos: {key: \x, name: \score}, name: {key: \name}}
# 版面由 mod.tick 的模擬推動 ( alpha 1 降到 0.001 約 300 步 ). 切到 manual 前已用真實時間跑過幾格,
# 先清掉位置與模擬重來, 再推 anim 的時鐘
reset = (c) ->
  c.pos = {}
  c.sim = null
  c.resize!; c.render!
run = (c) -> for i from 0 til 320 => c.anim.step 16
layout = [reset, run]

mctest.suite do
  size: [560, 360]
  data:
    many: mk 80
    few: mk 12
    # 沒有 group / size: 一種顏色、一樣大
    plain: do
      raw: [0 til 30].map (i) -> {x: (i * 37) % 100}
      binding: {xpos: {key: \x}}
  cases:
    * name: "many", data: \many, steps: layout
    * name: "few", data: \few, steps: layout
    * name: "plain", data: \plain, steps: layout
    * name: "palette", data: \few, config: {palette: {colors: <[#333 #c00 #0a0 #06c]>}}, steps: layout
    * name: "split", data: \many, config: {split: {enabled: true}}, steps: layout
    * name: "split:legend-bottom", data: \many, config: {split: {enabled: true}, legend: {position: \bottom}}, steps: layout
    * name: "label:name", data: \few, config: {label: {show: \name}}, steps: layout
    * name: "stroke:white", data: \many, config: {bubble: {stroke: \white, opacity: 1, size: 0.6}}, steps: layout
    * name: "small", data: \many, size: [240, 160], steps: layout
    # legend 點掉一組: shrink 拿掉, 分列時那一列也拿掉
    * name: "legend:pick", data: \many, config: {split: {enabled: true}}
      steps: [((c) -> c.legend.select <[G1 G3]>; c.bind!; c.resize!; c.render!)] ++ layout

mctest.suite do
  size: [560, 360]
  data: many: mk 80
  cases:
    * name: "anim:layout-frames", data: \many
      steps:
        * reset
        * (c, ctx) ->
            for i from 1 to 3
              for j from 0 til 10 => c.anim.step 16
              ctx.capture "f#{i * 10}"
