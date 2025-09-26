(function(){
  var mod;
  module.exports = {
    pkg: {
      name: 'axis-bubble',
      version: '0.0.1',
      extend: {
        name: "base",
        version: "0.0.1"
      },
      dependencies: []
    },
    init: function(arg$){
      var root, context, pubsub;
      root = arg$.root, context = arg$.context, pubsub = arg$.pubsub;
      return pubsub.fire('init', {
        mod: mod({
          context: context
        })
      }).then(function(it){
        return it[0];
      });
    }
  };
  mod = function(arg$){
    var context, d3, forceBoundary, ldcolor, repeatString$;
    context = arg$.context;
    d3 = context.d3, forceBoundary = context.forceBoundary, ldcolor = context.ldcolor, repeatString$ = context.repeatString$;
    return {
      sample: function(){
        return {
          raw: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200].map(function(val){
            return {
              val: Math.random() * 50 + 10,
              x: Math.random(),
              cat: Math.ceil(5 * Math.random())
            };
          }),
          binding: {
            color: {
              key: 'cat'
            },
            radius: {
              key: 'val'
            },
            xpos: {
              key: 'x'
            }
          }
        };
      },
      config: {},
      dimension: {
        color: {
          type: 'R',
          name: "顏色"
        },
        radius: {
          type: 'R',
          name: "半徑"
        },
        xpos: {
          type: 'R',
          name: "X座標"
        }
      },
      init: function(){
        var t, this$ = this;
        this.svg.addEventListener('click', function(){
          this$.type = !this$.type;
          this$.resize();
          this$.render();
          this$.sim.stop();
          return this$.sim.alpha(0.9);
        });
        this.svg.appendChild(t = document.createElementNS('http://www.w3.org/2000/svg', 'text'));
        this.text = d3.select(t);
        return this.text.attr('x', 20).attr('y', 20);
      },
      parse: function(){
        this.xextent = d3.extent(this.data.map(function(it){
          return it.xpos;
        }));
        this.rextent = d3.extent(this.data.map(function(it){
          return it.radius;
        }));
        return this.cextent = d3.extent(this.data.map(function(it){
          return it.color;
        }));
      },
      resize: function(){
        var rng, this$ = this;
        rng = d3.randomUniform.source(d3.randomLcg(root.seed))(0, 1);
        this.scaleX = d3.scaleLinear().domain(this.xextent).range([0, this.box.width]);
        if (this.type) {
          this.scaleY = d3.scaleLinear().domain(this.cextent).range([0, this.box.height]);
        } else {
          this.scaleY = function(){
            return this$.box.height / 2;
          };
        }
        this.data.map(function(v){
          return v.x = v.x || this$.scaleX(v.xpos), v.y = v.y || this$.box.height / 2, v.ty = this$.scaleY(v.color), v.val = v.radius, v.r = v.radius, v.c = v.color, v;
        });
        this.area = this.box.width * this.box.height;
        return this.rate = 0.5;
      },
      render: function(){
        var rate, pal, intColor, x$, y$, this$ = this;
        rate = this.rate;
        this.scale = {
          color: d3.interpolateTurbo,
          r: d3.scaleLinear().domain(this.rextent).range([0, 1]),
          c: d3.scaleLinear().domain(this.cextent).range([0, 1])
        };
        pal = this.cfg.palette
          ? this.cfg.palette.colors.map(function(it){
            return ldcolor.web(it.value || it);
          })
          : ['#f00', '#0f0', '#00f', '#f90', '#9f0', '#0f9'];
        intColor = d3.interpolateDiscrete(pal);
        this.scale.color = function(it){
          return intColor(this$.scale.c(it));
        };
        x$ = d3.select(this.svg).selectAll('circle.bubble').data(this.data);
        x$.exit().remove();
        x$.enter().append('circle').attr('class', 'bubble').attr('r', function(d, i){
          return 0;
        }).attr('fill', function(d, i){
          return this$.scale.color(d.c);
        });
        d3.select(this.svg).selectAll('circle.bubble').attr('cx', function(d, i){
          return d.x;
        }).attr('cy', function(d, i){
          return d.y;
        }).attr('fill', function(d, i){
          return this$.scale.color(d.c);
        }).attr('r', function(d, i){
          var ref$;
          return ((ref$ = d.r) > 2 ? ref$ : 2) * this$.rate;
        });
        y$ = d3.select(this.svg).selectAll('g.label').data(this.data);
        y$.exit().remove();
        y$.enter().append('g').attr('class', 'label').each(function(d, i){
          var this$ = this;
          return [0].map(function(){
            return d3.select(this$).append('text');
          }).map(function(it){
            return it.attr('dy', '-.28em').attr('text-anchor', 'middle').attr('font-size', '.7em').attr('font-family', 'Rubik').style('pointer-event', 'none');
          });
        });
        return d3.select(this.svg).selectAll('g.label').attr('transform', function(d, i){
          return "translate(" + d.x + "," + d.y + ")";
        }).each(function(d, i){
          return d3.select(this).selectAll('text').attr('opacity', d.r * 2 * rate < (d.val.toFixed(2) + "").length * 7 ? 0 : 1).attr('dy', function(e, i){
            return '.38em';
          }).text(function(e, i){
            if (i === 0) {
              if (d.val > 1000000) {
                return (d.val / 1000000).toFixed(2) + "M";
              } else if (d.val > 1000) {
                return (d.val / 1000).toFixed(2) + "K";
              } else {
                return d.val.toFixed(2);
              }
            } else {
              return d._idx;
            }
          });
        });
      },
      tick: function(){
        var kickoff, fc, alpha, this$ = this;
        if (!this.sim) {
          kickoff = true;
          this.fc = fc = d3.forceCollide();
          this.sim = d3.forceSimulation().force('center', this.fg = d3.forceCenter(this.box.width / 2, this.box.height / 2)).force('x', this.fx = d3.forceX(this.box.width / 2).strength(0.15)).force('y', this.fy = d3.forceY(this.box.height / 2).strength(0.1)).force('b', this.fb = forceBoundary(function(it){
            return it.r;
          }, function(it){
            return it.r;
          }, function(it){
            return this$.box.width - it.r;
          }, function(it){
            return this$.box.height - it.r;
          })).force('collide', fc);
          this.sim.stop();
          this.sim.alpha(0.9);
          this.sim.nodes(this.data);
        }
        this.fc.strength(1.0);
        this.fc.radius(function(it){
          return this$.rate * it.r + 2;
        });
        this.fg.x(this.box.width / 2);
        this.fg.y(this.box.height / 2);
        this.fx.strength(0.15);
        this.fy.strength(0.01);
        this.sim.tick(kickoff ? 20 : 1);
        alpha = this.sim.alpha();
        this.text.text(alpha);
        if (alpha < 0.001) {
          this.stop();
        }
        this.data.map(function(it){
          return it.y = it.y + (it.ty - it.y) * alpha * 0.1;
        });
        d3.select(this.svg).selectAll('circle.bubble').attr('cx', function(d, i){
          return d.x;
        }).attr('cy', function(d, i){
          return d.y;
        });
        d3.select(this.svg).selectAll('g.label').attr('transform', function(d, i){
          return "translate(" + d.x + "," + d.y + ")";
        });
        return this.render();
      }
    };
  };
}).call(this);
