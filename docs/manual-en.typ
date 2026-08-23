// The English manual, website and PDF in one run:
//
//   typst compile manual-en.typ build --format bundle --features bundle,html --root /
//
// A second entry point rather than a switch inside `docs.typ`: `docs()` is a
// show rule and emits exactly two documents, so one file cannot carry both
// languages.

#import "@schule/schuldocs:0.2.0": *

#let pkg = toml("../typst.toml")

// The template has a few words of its own, and they follow the document's
// language.
#set text(lang: "en")

#show: docs.with(
  // As with the core package: the description in `typst.toml` is German,
  // because that is what Typst Universe shows.
  toml: pkg.package + (
    description: "GeoGebra applets for typstage: GeoGebra builds the "
      + "construction, the slides supply the dramaturgy. A package of its own, "
      + "so that a presentation without applets never loads the bridge script.",
  ),
  authors: pkg.package.authors,
  html-name: "en.html",
  pdf-name: "typstage-geogebra-en.pdf",
  abstract: [
    The companion package to `typstage` puts GeoGebra applets on slides and
    drives them step by step: GeoGebra builds the construction, the slides
    supply the dramaturgy. A package of its own, so that a presentation
    without applets never loads the bridge script.
  ],
  links: (
    (name: "GitHub", url: "https://github.com/Loewe1000/typstage-geogebra"),
    (name: "Examples", url: "https://loewe1000.github.io/typstage-geogebra/beispiele/"),
    (name: "typstage", url: "https://github.com/Loewe1000/typstage"),
    // Absolute, not relative: the same entry stands on the title page of the
    // PDF, and there a path leads nowhere.
    (name: "Deutsch", url: "https://loewe1000.github.io/typstage-geogebra/"),
  ),
  notices: ([Companion package to `typstage`],),
)

#include "content-en.typ"
