# typstage-geogebra

GeoGebra applets for [typstage](https://github.com/Loewe1000/typstage). The
construction is built by GeoGebra, the dramaturgy comes from the slides.

**Try it without installing anything:** [two example
decks](https://loewe1000.github.io/typstage-geogebra/beispiele/) running in
your browser. One shows the slides driving the applet, the other shows a hand
driving it from the speaker window.

The manual is available in
[English](https://loewe1000.github.io/typstage-geogebra/en.html) and in
[German](https://loewe1000.github.io/typstage-geogebra/).

```typ
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
```

`ggb-run`, `-set`, `-show`, `-hide`, `-style`, `-view`, `-animate`, `-tween`
all take a step selector and reach the applet when that step is entered. On the
way back the run is replayed from its start, so commands should be repeatable.



## Installation

The package lives in the local `@schule` namespace and is not (yet) on Typst
Universe. Clone it under the package path to use it:

```bash
git clone https://github.com/Loewe1000/typstage-geogebra \
  ~/Library/Application\ Support/typst/packages/schule/typstage-geogebra/0.1.0
```

On Linux that path is `~/.local/share/typst/packages/schule/…`, on Windows
`%APPDATA%\typst\packages\schule\…`.

`typstage` itself is needed as well: <https://github.com/Loewe1000/typstage>

The documentation is built with `@schule/schuldocs`; one run produces the
manual, the website and its stylesheet:

```bash
typst compile docs/docs.typ build --format bundle --features bundle,html
```

## Which applet is meant

Nothing says `"probe"` above: with one applet on the slide there is nothing to
choose between, and the commands find it by themselves — no matter whether they
stand above or below it in the source.

Two applets on one slide need names, and then the commands need `target`:

```typ
geogebra("left", height: 200pt)
geogebra("right", height: 200pt)
ggb-run("A=(0,0)", target: "left")
ggb-run("B=(1,1)", target: "right")
```

Leave `target` out there and it does not guess — it says which applets it found
and stops. A dropped command is far harder to notice than a failed build.

The applet takes the size of the box it stands in and keeps it across step
changes and window sizes, so how much of the plane is on screen follows from
`width` and `height`. Where a particular range matters, say it with `ggb-view`
rather than letting the box width decide it.

`ggb-tween` counts a value up frame by frame — build an object that depends on
it and the construction draws itself.

A `.ggb` file cannot be embedded: Typst has no base64 encoding. Build the
construction with `ggb-run` or load it through `material`.

In the PDF there is no applet. `fallback` puts your own drawing there instead,
`link` at least the way to the live one.

## From the speaker view

The speaker window of typstage runs its own copy of every applet, and `m`
switches its pointer from the pen to the embedded frame. In that mode the
applet in front of you is the live one: drag a point, move a slider, pan the
view, and the projected copy follows. Only what a hand touched travels, so an
animation running on both sides sends nothing.

What crosses is what a hand can move: a point as its coordinates, a slider as
its value. Everything that follows from those is left alone, because the other
copy works it out for itself. Creating, deleting or renaming sends the whole
construction instead.

A step change resets both copies from the base as before, so a change made by
hand lasts as long as the step does. If a position is meant to survive, put it
in the deck with `ggb-set` and drag on from there.

[`examples/example-speaker.typ`](examples/example-speaker.typ) is a deck built around this: Thales with a point to walk
along the half circle, and a parabola with two sliders. Open it, press `n`,
press `m`, and drag.

One thing to know when you build for it: `Point(k)` is a point on the path that
a hand can take, `Point(k, 0.3)` is pinned to that parameter and cannot be
dragged at all. Say where it starts with `position:` instead.
