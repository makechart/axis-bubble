# axis-bubble 的 test case ( @makechart/viewer 的 mctest )
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n, seed = n) ->
  rnd = mctest.random seed
  raw: [0 til n].map -> {val: Math.round((rnd! * 50 + 10) * 100) / 100, x: rnd!, cat: Math.ceil(5 * rnd!)}
  binding: {color: {key: \cat}, radius: {key: \val}, xpos: {key: \x}}
# 版面由 mod.tick 的模擬推動 ( alpha 0.9 降到 0.001 約 300 步 ). 切到 manual 前已用真實時間跑過幾格,
# 先清掉位置與模擬重來, 再推 anim 的時鐘
reset = (c) ->
  c.data.map (d) -> <[x y vx vy index]>.map (k) -> delete d[k]
  c.sim = null
  c.resize!; c.render!
run = (c) -> for i from 0 til 320 => c.anim.step 16
layout = [reset, run]

mctest.suite do
  size: [560, 360]
  data:
    many: mk 80
    few: mk 12
  cases:
    * name: "many", data: \many, steps: layout
    * name: "few", data: \few, steps: layout
    * name: "palette", data: \few, config: {palette: {colors: <[#333 #c00 #0a0]>}}, steps: layout
    # 點一下: 依 color 上下分開
    * name: "click:split", data: \many
      steps: layout ++ [((c, ctx) -> ctx.root.querySelector('svg').dispatchEvent new MouseEvent(\click, {bubbles: true})), run]

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
