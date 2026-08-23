#import "@schule/schuldocs:0.2.0": show-example, show-module, show-code, tip, info, warning

= What this package is

`typstage-geogebra` puts GeoGebra applets on the slides of `typstage` and
drives them step by step: GeoGebra builds the construction, the slides supply
the dramaturgy. Jobs can sit on every step. Set values, show or hide objects,
change colours, move the viewport, start a motion.

That this is a package of its own has a simple reason: a presentation without
applets should not carry the bridge script around. The boot script and the
applet document are a few kilobytes that would otherwise travel in every deck.
From the core this package needs only two public parts. `embed(bridge: …)`
registers a frame as a target, and `bridge-job` sends it something on a step.
What is in the jobs, the core never reads.

This manual is arranged as follows:

+ *Quick start* — one applet on one slide
+ *Which applet is meant* — names and `target`
+ *Building the construction* — `ggb-run` and where it stops
+ *Values, appearance, viewport* — `ggb-set`, `ggb-style`, `ggb-view`
+ *Motion* — `ggb-animate` against `ggb-tween`
+ *On paper* — `fallback` and `link`
+ *How the applet looks* — `seamless`, `background`, size
+ *From the speaker view* — operating the applet by hand
+ *When nothing happens* — the traps

= Quick start

An applet stands on the slide with `geogebra()`, and the commands stand in the
same slide body, because that is where they are collected. They produce no
output themselves.

#show-code[```typ
#import "@schule/typstage:0.1.0": *
#import "@schule/typstage-geogebra:0.1.0": *

#presentation(
  slide([Remote controlled], {
    geogebra(app: "classic", perspective: "G", height: 240pt,
             link: "https://www.geogebra.org/calculator")
    ggb-run("a=1", "f(x)=a*x^2")
    ggb-set((a: 3), at: 2)
  }),
)
```]

The parabola is there from the beginning; on step 2 `a` is set to 3 and it
draws itself together.

`at` is a step selector on every command, as it is on `anim`: `2` means "from
step two on", and `"1-2"`, `"2,4"` and `"-2"` mean what they say. The default
is `"1-"`, since most jobs set the construction up as the slide is entered. The
applet frame itself uses no step and pushes nothing along: the bullets beside it
belong on step one, not behind its jobs.

#info[
  The applet lives in the HTML export only. In the PDF, what stands in its
  place is described in the chapter _On paper_.
]

= Which applet is meant

In the quick start no command carries a name. With one applet on the slide
there is nothing to choose between, and the commands find it by themselves,
whether they stand above or below it in the source.

Two applets on one slide need names, and then the commands need `target`. The
name may be a string or a label, and Typst colours it as what it is:

#show-code[```typ
geogebra(<left>, height: 200pt)
geogebra(<right>, height: 200pt)
ggb-run("A=(0,0)", target: <left>)
ggb-run("B=(1,1)", target: "right")
```]

Where the argument is missing and there is more than one applet, nothing is
guessed. The build stops and names what it found:

#show-code[```
error: panicked with: typstage-geogebra: 2 applets on this slide
(left, right) — say which one is meant, e.g. target: "left".
```]

The same holds where the slide carries no applet at all. A command dropped in
silence is far harder to notice than a failed build.

= Building the construction

`ggb-run` takes any number of GeoGebra commands and hands them to `evalCommand`
one at a time. The order counts: whatever is needed has to exist first.

#show-code[```typ
ggb-run(at: "1-",
        "k: x^2+y^2=4", "t=Slider(0,6.283,0.01)",
        "P=(2cos(t),2sin(t))", "s=Segment((0,0),P)")
```]

#warning[
  GeoGebra's scripting commands, `SetColor`, `SetValue`, `SetVisibleInView` and
  their relatives, are *not* accepted by `evalCommand`; inside `ggb-run` they
  would come to nothing. That is what `ggb-set`, `ggb-style`, `ggb-show` and
  `ggb-hide` are for: they reach for the JavaScript interface, which can do it.
]

What GeoGebra refuses does not vanish quietly: the applet reports the rejected
commands back, and the runtime writes them into the browser's console.

On entering a slide and on paging back, the run is repeated from its beginning,
and the applet returns to its initial state for that. Commands should therefore
be repeatable. For the same reason it is worth fixing the colour on `"1-"`
straight away: on a rebuild GeoGebra would otherwise hand out the next colour
of its palette, and the slide would look different after paging back.

#show-code[```typ
ggb-run("a=1", "f(x)=a*x^2", at: "1-")
ggb-style("f", at: "1-", color: dark, thickness: 3)
```]

#info[
  A `.ggb` file cannot be embedded: Typst has no base64 encoding, and without
  it the file's content never reaches the HTML. The construction is therefore
  built with `ggb-run`, or it is loaded from GeoGebra through `material`:
  `geogebra(material: "abc123xy")`.
]

= Values, appearance, viewport

`ggb-set` takes a dictionary of object name and value, `ggb-show` and `ggb-hide`
any number of object names. The usual way is to build everything up at the
start and only make it visible when its turn comes:

#show-code[```typ
ggb-hide("P", "s", "t", at: "1-")
ggb-show("P", "s", at: 2)
ggb-set((a: 3), at: 2)
ggb-set((a: -2, b: 0.5), at: 3)
```]

== Appearance

`ggb-style` takes the object names and, with them, what should change. Every
setting is available on its own; what is not named stays as it is.

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: 0.4pt + luma(75%),
  table.header([*Setting*], [*Effect*]),
  [`color`], [colour, as a Typst colour and not a GeoGebra one],
  [`thickness`], [line weight],
  [`line-style`], [line style as a number (solid, dashed, dotted …)],
  [`filling`], [fill, 0 to 1],
  [`point-size`], [point size],
  [`trace`], [trace on or off],
  [`label`], [label visible or not],
  [`label-mode`], [kind of label as a number (name, value, caption …)],
  [`fixed`], [held against being moved],
  [`caption`], [a caption of your own],
  [`layer`], [layer, that is, what lies in front of what],
  [`position`], [place as `(x, y)`],
)

That `color` takes a Typst colour is the point of it: the construction carries
the colours of the slides instead of GeoGebra's palette.

#show-code[```typ
ggb-style("P", at: 2, color: accent, point-size: 6)
ggb-style("s", at: 2, color: dark, thickness: 3)
ggb-style("d", at: 3, color: accent, filling: 0.18, thickness: 4)
```]

#warning[
  `position` counts in the coordinates of the plane for most objects, but in
  pixels of the applet for a slider made with the `Slider` command, because
  such a slider sits at an absolute place on the screen. Measured: written as
  `(-3.9, 2.2)` two sliders both landed in the same corner on top of one
  another.
]

== Viewport

`ggb-view` sets the visible range as well as the grid and the axes. `x` and `y`
only take effect together, both being pairs of smallest and largest value.

#show-code[```typ
ggb-view(at: 2, x: (-3, 3), y: (-3, 3), grid: false)
ggb-view(at: 3, axes: false)
```]

#warning[
  `ggb-view` sets the x range and the y range separately, so a range that does
  not match the shape of the box stretches one axis. A circle becomes an
  ellipse and a right angle stops looking like one. Where the geometry carries
  the argument, give the box a fixed size and match the ranges to it: 424 by
  262 is 1.618 to one, and so is 8.4 by 5.2.
]

The applet takes the size of the box it stands in and keeps it across step
changes and window sizes. How much of the plane is on screen therefore follows
from `width` and `height` on the `geogebra` line: a wide box shows more x
range. Where a particular range matters, say it with `ggb-view` rather than
letting the box width decide it.

= Motion

There are two ways to set something moving, and they do different things.

`ggb-animate` starts GeoGebra's own animation. It runs back and forth without
end until the slide is left, which is right for a point going round a circle or
a slider demonstrating a relationship. `trace` switches on the trace of the
named objects, `speed` sets the pace, `playing: false` stops it.

#show-code[```typ
ggb-animate("t", at: 3, speed: 1.2, trace: ("P",))
```]

`ggb-tween` goes once from A to B and stays there. The browser counts the value
up frame by frame; an object that depends on it grows with it, a segment whose
endpoint travels, an arc whose angle follows. That is how a construction draws
itself. `from` gives the starting value where it should not be the one
currently in force, `duration` the time in milliseconds, `easing` the shape of
it (`"ease-in-out"` or `"linear"`).

#show-code[```typ
ggb-run("t_1=0", "s=Segment(A,(4*t_1,0))", at: "1-")
ggb-tween("t_1", at: 2, to: 1, duration: 700)
```]

#warning[
  `ggb-tween` needs a step number, not a range: `at: 2`, not `at: "2-"`.
  Otherwise the build stops with "`ggb-tween() needs a step number`".

  And a tween on step 1 would never arrive as a motion. On entering a slide the
  runtime replays the run up to the current step at once, and tweens are set to
  their target value rather than played. Step 1 is for building up; drawing
  starts at step 2.
]

From the step after the tween the value sits on its target anyway. Whoever
pages back therefore sees the finished drawing and not the motion a second
time.

= On paper

In the PDF there is no applet. Without further arguments a labelled placeholder
stays in the size of the frame; `link` puts the way to the live applet beneath
it, clickable in the PDF.

#show-example(
  rendered: {
    import "../src/lib.typ": geogebra
    geogebra(height: 90pt, link: "https://www.geogebra.org/calculator")
  },
  source: ```typ
  #geogebra(height: 90pt, link: "https://www.geogebra.org/calculator")
  ```,
  width: 12cm,
)

Better is a drawing of your own in its place. `fallback` takes any content, an
image, a table, and above all a drawing with CeTZ:

#show-example(
  rendered: {
    import "../src/lib.typ": geogebra
    import "@schule/typstage:0.1.0": dark
    import "@preview/cetz:0.4.2"
    geogebra(height: 120pt, link: "https://www.geogebra.org/calculator",
      fallback: cetz.canvas(length: 0.8cm, {
        import cetz.draw: *
        line((-2.6, 0), (2.6, 0), stroke: luma(70%))
        line((0, -0.4), (0, 2.6), stroke: luma(70%))
        line(..range(0, 45).map(i => (-2.2 + i * 0.1, 0.5 * calc.pow(-2.2 + i * 0.1, 2))),
             stroke: dark + 1.6pt)
      }))
  },
  source: ```typ
  #geogebra(height: 120pt, link: "https://www.geogebra.org/calculator",
    fallback: cetz.canvas(length: 0.8cm, {
      import cetz.draw: *
      line((-2.6, 0), (2.6, 0), stroke: luma(70%))
      line((0, -0.4), (0, 2.6), stroke: luma(70%))
      line(..range(0, 45).map(i => (-2.2 + i * 0.1, 0.5 * calc.pow(-2.2 + i * 0.1, 2))),
           stroke: dark + 1.6pt)
    }))
  ```,
  width: 12cm,
)

#tip[
  Paper can show a sequence where a screen can only show one moment. Where the
  applet runs through several states, the better stand-in is often the whole
  run as a small table or a row of pictures, rather than a photograph of one
  step of it.
]

Both settings take effect in the PDF only; in the browser the applet itself
stands there.

= How the applet looks

The default is `seamless: true`: the applet carries no frame of its own, and
its drawing area takes the colour of the slide. It then no longer looks like a
window inside a window but like part of the slide. `background` sets that
colour; `auto` takes the presentation's paper white, which is worth changing on
a tinted slide.

#show-code[```typ
geogebra(height: 240pt, background: rgb("#f4f1ea"))
geogebra(height: 240pt, seamless: false)   // with GeoGebra's own frame
```]

#tip[
  `background: auto` takes the package's paper white and not the theme's. On a
  theme whose paper is pure white, an applet left to `auto` therefore sits as a
  faintly grey box. `background: themes.lesson.paper` is the way to say it.
]

`grid` and `axes` leave GeoGebra's own default alone as long as they are
`auto`, and force one or the other otherwise. `perspective: "G"` shows the
graphics view alone, `app` chooses the GeoGebra app (the default is
`"classic"`), `language` the language of the interface, and `animation-button`
shows GeoGebra's play button.

#info[
  The applet is loaded from `codebase`, from `geogebra.org` as it ships.
  Without a network the frame stays empty; whoever presents offline puts
  GeoGebra's files beside the deck and points `codebase` at them.
]

== Size

`width` and `height` give the size in the measurements of the slide, not in
screen pixels.

For most embeds the runtime spans the frame in points of the slide and then
enlarges it with `zoom`. An applet is exempt and gets real screen pixels
instead. The reason is measured: Safari counts that zoom twice for GeoGebra, a
canvas buffer of 1400 points at a width of 253, which is zoom times zoom times
pixel density. The applet drew too small, and correcting its size instead
moved the place where it could be hit: it then drew correctly but believed
itself 704 points wide while being shown 424 wide, and a point could only be
grabbed by clicking far to the right of it.

That every window still shows the same crop therefore does not hang on the
pixel count but on the range. The applet sets that from the box in slide
points the first time, at GeoGebra's 50 points per unit; after that `ggb-view`
decides, and a change of size leaves the range where it is.

The applet takes its pixel size from the frame, not from a number written at
compile time. `width: 100%` cannot be a number before the slide has been laid
out, and an applet that guessed one drew a third of the box it sat in.

#tip[
  Two applets side by side sit best in a `grid`, each with `width: 100%` and a
  height of its own.
]

= From the speaker view

The speaker window of `typstage` runs a copy of every applet of its own. `m`
switches its pointer from the pen to the embedded frame, and from then on the
applet in front of you is the live one: drag a point, push a slider, pan the
view, and the copy on the canvas follows.

What crosses is what a hand can move: a point as its coordinates, a slider as
its value. Whatever follows from those is left alone, because the other copy
works it out for itself. Creating, deleting or renaming sends the whole
construction instead, and panning and zooming travel too.

#tip[
  Measured: a point on a half circle reported four states per frame while being
  dragged, the point, both segments and the angle. The three dependent ones are
  not merely redundant. Their XML redefines them on the other side, and that
  wipes away the trace the dragged point had just left behind.
]

Only what a hand has touched is reported. An animation that runs on both sides
anyway therefore sends nothing.

#warning[
  A step change resets both copies from the base as before and replays the jobs
  of the slide. A change made by hand lives as long as the step does. Where a
  position is meant to stay, it belongs in the deck with `ggb-set`.
]

== The keyboard

Click the applet and it holds the focus, so every key then lands inside it.
Measured before deciding what to do about that: focus sits on the applet's
canvas, it sees every key tried, it calls `preventDefault` on none of them, and
it changes nothing in the construction. Without a toolbar and without an
algebra input this applet has no use for the keyboard at all.

The core therefore hands the keys of the talk back out of the frame, so paging
and `m` keep working with the applet in focus. Anything outside that set, such
as `Delete`, stays with the applet.

#info[
  Should that ever change, with a toolbar shown for instance, a change made
  with the keyboard travels too: the window in which the mirror is awake opens
  on a key as well as on a press.
]

One difference is worth knowing when building for this: `Point(k)` is a point
on the path that a hand can take; `Point(k, 0.3)` is pinned to that parameter
and cannot be dragged at all, and `isMoveable` answers false for it. Where it
should start is said with `position:`.

`examples/example-speaker.typ` is a deck built around exactly this: Thales with a point
that walks along the half circle and leaves its trace, and a parabola with two
sliders.

= When nothing happens

/ The frame stays empty: the applet is loaded from `geogebra.org`, so without a
  network there is nothing to load. Point `codebase` at a local copy.
/ A command has no effect: it is one of GeoGebra's scripting commands, which
  `evalCommand` does not accept. `ggb-set`, `ggb-style`, `ggb-show` and
  `ggb-hide` reach the interface that can do it.
/ The build stops naming two applets: two frames on one slide and no `target`.
  Nothing is guessed here on purpose.
/ The colours change after paging back: GeoGebra hands out the next colour of
  its palette on a rebuild. Fix the colour on `"1-"`.
/ The circle is an ellipse: the x range and the y range of `ggb-view` do not
  match the shape of the box.
/ A tween does not play: it sits on step 1, where the runtime sets tweens to
  their target instead of playing them, or it was given a range instead of a
  step number.
/ Two sliders lie on top of one another: `position` counts in pixels for a
  slider made with `Slider`, not in coordinates.
/ A point cannot be dragged in the speaker view: it was made with
  `Point(k, 0.3)` and is pinned to that parameter.

= API reference

Generated from the comments in the source file. `resolve-target` and
`no-stray-target` belong to the internals and are therefore not listed.

#show-module(read("../src/lib.typ"), name: "typstage-geogebra",
             exclude: ("resolve-target", "no-stray-target"))
