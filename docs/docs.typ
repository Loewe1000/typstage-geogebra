// Handbuch und Website in einem Lauf:
//
//   typst compile docs.typ build --format bundle --features bundle,html --root /

#import "@schule/schuldocs:0.2.0": *

#let pkg = toml("../typst.toml")

// Die Sprache ausdrücklich. Typsts Vorgabe ist Englisch, und ohne diese Zeile
// trennte ein deutscher Text nach englischen Regeln, setzte englische
// Anführungszeichen und bekäme die englischen Wörter der Vorlage.
#set text(lang: "de")

#show: docs.with(
  toml: pkg,
  authors: pkg.package.authors,
  abstract: [
    Das Begleitpaket zu `typstage` setzt GeoGebra-Applets in Folien und steuert
    sie Schritt für Schritt: die Konstruktion baut GeoGebra, die Dramaturgie
    kommt aus den Folien. Ein eigenes Paket, damit eine Präsentation ohne
    Applets das Brückenskript nicht mitlädt.
  ],
  links: (
    (name: "GitHub", url: "https://github.com/Loewe1000/Typst-Schule"),
    (name: "Beispiele", url: "https://loewe1000.github.io/typstage-geogebra/beispiele/"),
    (name: "typstage", url: "https://github.com/Loewe1000/Typst-Schule"),
  ),
  notices: ([Begleitpaket zu `typstage`],),
)

#include "content.typ"
