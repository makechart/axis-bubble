# Change Logs

## v0.0.2

 - extend the lite base ( `@makechart/base` `lite/index.html`, no d3 ): needs `@makechart/base` >= 0.2.0
   and `@plotdb/chart` >= 3.7.0
   d3 is replaced by `d3-force` ( with `d3-dispatch`, `d3-quadtree`, `d3-timer` ) and `d3-force-boundary`
 - fix bug: it didn't render at all. layout is now disabled ( it has no layout markup ), the svg is
   positioned at the top left, and the simulation is actually started
 - fix bug: `d3-force-boundary` was used but not loaded
 - fix bug: `root.seed` was used instead of `@seed`
 - fix bug: clicking before the simulation is ready threw
 - remove debug alpha text
 - fix bug: labels blocked hovering ( `pointer-event` instead of `pointer-events` )
 - add test cases ( `test/index.ls`, run with `npm test` via `@makechart/viewer` )


## v0.0.1

init release
