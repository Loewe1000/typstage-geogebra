#import "@schule/schuldocs:0.2.0": show-example, show-module, show-code, tip, info, warning

= Über dieses Paket

`typstage-geogebra` setzt GeoGebra-Applets in die Folien von `typstage` und
steuert sie Schritt für Schritt: die Konstruktion baut GeoGebra, die
Dramaturgie kommt aus den Folien. Auf jedem Schritt können Aufträge liegen --
Werte setzen, Objekte zeigen oder verbergen, Farben ändern, den Ausschnitt
verschieben, eine Bewegung anstoßen.

Dass das ein eigenes Paket ist, hat einen einfachen Grund: eine Präsentation
ohne Applets soll das Brückenskript nicht mitschleppen. Das Bootskript und das
Applet-Dokument sind einige Kilobyte, die sonst in jedem Foliensatz mitreisen
würden. Aus dem Kern braucht dieses Paket nur zwei öffentliche Teile --
`embed(bridge: …)` meldet einen Rahmen als Ziel an, `bridge-job` schickt ihm
auf einem Schritt etwas zu. Was in den Aufträgen steht, liest der Kern nicht.

Dieses Handbuch gliedert sich wie folgt:

+ *Schnellstart* -- ein Applet auf einer Folie
+ *Welches Applet gemeint ist* -- Namen und `target`
+ *Die Konstruktion aufbauen* -- `ggb-run` und seine Grenze
+ *Werte, Aussehen, Ausschnitt* -- `ggb-set`, `ggb-style`, `ggb-view`
+ *Bewegung* -- `ggb-animate` gegen `ggb-tween`
+ *Auf Papier* -- `fallback` und `link`
+ *Aussehen des Applets* -- `seamless`, `background`, Größe

= Schnellstart

Ein Applet steht mit `geogebra()` auf der Folie, die Befehle stehen im selben
Folienrumpf -- dort werden sie eingesammelt. Sie geben selbst nichts aus.

#show-code[```typ
#import "@schule/typstage:0.1.0": *
#import "@schule/typstage-geogebra:0.1.0": *

#presentation(
  slide([Ferngesteuert], {
    geogebra(app: "classic", perspective: "G", height: 240pt,
             link: "https://www.geogebra.org/calculator")
    ggb-run("a=1", "f(x)=a*x^2")
    ggb-set((a: 3), at: 2)
  }),
)
```]

Die Parabel steht von Anfang an da; auf Schritt 2 wird `a` auf 3 gesetzt und
sie zieht sich zusammen.

`at` ist bei allen Befehlen ein Schrittwähler wie bei `anim`: `2` heißt „ab
Schritt zwei“, `"1-2"`, `"2,4"` und `"-2"` heißen, was sie sagen. Vorgabe ist
`"1-"`, denn die meisten Aufträge richten die Konstruktion beim Betreten der
Folie ein. Der Applet-Rahmen selbst verbraucht keinen Schritt und schiebt auch
nichts weiter: die Stichpunkte neben ihm gehören auf Schritt eins, nicht hinter
seine Aufträge.

#info[
  Das Applet lebt nur im HTML-Export. Im PDF steht an seiner Stelle, was
  das Kapitel _Auf Papier_ beschreibt.
]

= Welches Applet gemeint ist

Im Schnellstart steht bei keinem Befehl ein Name. Mit einem Applet auf der
Folie gibt es nichts zu wählen, und die Befehle finden es von selbst -- gleich,
ob sie im Quelltext darüber oder darunter stehen.

Zwei Applets auf einer Folie brauchen Namen, und dann brauchen die Befehle
`target`. Der Name darf eine Zeichenkette sein oder eine Marke -- Typst färbt
sie als das, was sie ist:

#show-code[```typ
geogebra(<links>, height: 200pt)
geogebra(<rechts>, height: 200pt)
ggb-run("A=(0,0)", target: <links>)
ggb-run("B=(1,1)", target: "rechts")
```]

Fehlt die Angabe bei mehreren Applets, wird nicht geraten. Der Bau bricht ab
und nennt, was er gefunden hat:

#show-code[```
error: panicked with: typstage-geogebra: 2 applets on this slide
(links, rechts) — say which one is meant, e.g. target: "links".
```]

Ebenso, wenn auf der Folie überhaupt kein Applet steht. Ein stillschweigend
fallengelassener Befehl ist weit schwerer zu bemerken als ein
fehlgeschlagener Bau.

= Die Konstruktion aufbauen

`ggb-run` nimmt beliebig viele GeoGebra-Befehle und gibt sie einzeln an
`evalCommand` weiter. Die Reihenfolge zählt: was gebraucht wird, muss vorher
entstanden sein.

#show-code[```typ
ggb-run(at: "1-",
        "k: x^2+y^2=4", "t=Slider(0,6.283,0.01)",
        "P=(2cos(t),2sin(t))", "s=Segment((0,0),P)")
```]

#warning[
  GeoGebras Skriptbefehle -- `SetColor`, `SetValue`, `SetVisibleInView` und
  Verwandte -- nimmt `evalCommand` *nicht* an; in `ggb-run` blieben sie
  wirkungslos. Dafür gibt es `ggb-set`, `ggb-style`, `ggb-show` und
  `ggb-hide`: sie greifen zur JavaScript-Schnittstelle, die das kann.
]

Was GeoGebra ablehnt, verschwindet nicht lautlos: das Applet meldet die
abgewiesenen Befehle zurück, und die Laufzeit schreibt sie in die Konsole des
Browsers.

Beim Betreten einer Folie und beim Zurückblättern wird der Lauf von seinem
Anfang an wiederholt -- das Applet geht dazu in seinen Ausgangszustand zurück.
Befehle sollten deshalb wiederholbar sein. Aus demselben Grund lohnt es sich,
die Farbe gleich auf `"1-"` festzulegen: beim Neuaufbau vergäbe GeoGebra sonst
die nächste Farbe seiner Palette, und die Folie sähe nach dem Zurückblättern
anders aus.

#show-code[```typ
ggb-run("a=1", "f(x)=a*x^2", at: "1-")
ggb-style("f", at: "1-", color: dark, thickness: 3)
```]

#info[
  Eine `.ggb`-Datei lässt sich nicht einbetten: Typst kennt keine
  base64-Kodierung, und ohne sie kommt der Inhalt der Datei nie in die
  HTML-Datei. Die Konstruktion entsteht deshalb mit `ggb-run` -- oder sie wird
  über `material` von GeoGebra geladen: `geogebra(material: "abc123xy")`.
]

= Werte, Aussehen, Ausschnitt

`ggb-set` nimmt ein Wörterbuch aus Objektname und Wert, `ggb-show` und
`ggb-hide` beliebig viele Objektnamen. Üblich ist, alles zu Beginn aufzubauen
und erst sichtbar zu machen, wenn es an der Reihe ist:

#show-code[```typ
ggb-hide("P", "s", "t", at: "1-")
ggb-show("P", "s", at: 2)
ggb-set((a: 3), at: 2)
ggb-set((a: -2, b: 0.5), at: 3)
```]

== Aussehen

`ggb-style` nimmt die Objektnamen und dazu, was sich ändern soll. Alle Angaben
sind einzeln zu haben; was nicht genannt wird, bleibt, wie es ist.

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: 0.4pt + luma(75%),
  table.header([*Angabe*], [*Wirkung*]),
  [`color`], [Farbe -- eine Typst-Farbe, keine GeoGebra-Farbe],
  [`thickness`], [Strichstärke],
  [`line-style`], [Strichart als Zahl (durchgezogen, gestrichelt, gepunktet …)],
  [`filling`], [Füllung, 0 bis 1],
  [`point-size`], [Punktgröße],
  [`trace`], [Spur an oder aus],
  [`label`], [Beschriftung sichtbar oder nicht],
  [`label-mode`], [Art der Beschriftung als Zahl (Name, Wert, Beschriftung …)],
  [`fixed`], [gegen Verschieben festhalten],
  [`caption`], [eigene Beschriftung],
  [`layer`], [Ebene, also was vor was liegt],
  [`position`], [Ort als `(x, y)`],
)

Dass `color` eine Typst-Farbe nimmt, ist der Punkt daran: die Konstruktion
trägt die Farben der Folien statt GeoGebras Palette.

#show-code[```typ
ggb-style("P", at: 2, color: accent, point-size: 6)
ggb-style("s", at: 2, color: dark, thickness: 3)
ggb-style("d", at: 3, color: accent, filling: 0.18, thickness: 4)
```]

== Ausschnitt

`ggb-view` setzt den sichtbaren Bereich sowie Gitter und Achsen. `x` und `y`
wirken nur zusammen -- beide sind Paare aus kleinstem und größtem Wert.

#show-code[```typ
ggb-view(at: 2, x: (-3, 3), y: (-3, 3), grid: false)
ggb-view(at: 3, axes: false)
```]

Das Applet nimmt die Maße des Kastens an, in dem es steht, und behält sie über
Schrittwechsel und Fenstergrößen hinweg. Wie viel Welt dabei zu sehen ist,
hängt also an `width` und `height` der `geogebra`-Zeile: ein breiter Kasten
zeigt mehr x-Bereich. Wer einen bestimmten Ausschnitt will, sagt ihn mit
`ggb-view` statt ihn sich aus der Breite zu ergeben.

= Bewegung

Es gibt zwei Arten, etwas in Bewegung zu setzen, und sie tun Verschiedenes.

`ggb-animate` startet GeoGebras eigene Animation. Sie läuft ohne Ende hin und
her, bis die Folie verlassen wird -- richtig für einen Punkt, der auf einem
Kreis umläuft, oder einen Schieberegler, der einen Zusammenhang vorführt.
`trace` schaltet die Spur der genannten Objekte ein, `speed` regelt das Tempo,
`playing: false` hält an.

#show-code[```typ
ggb-animate("t", at: 3, speed: 1.2, trace: ("P",))
```]

`ggb-tween` geht einmal von A nach B und bleibt dort. Der Browser zählt den
Wert Bild für Bild hoch; ein Objekt, das von ihm abhängt, wächst mit -- eine
Strecke, deren Endpunkt wandert, ein Bogen, dessen Winkel folgt. So zeichnet
sich die Konstruktion selbst. `from` gibt den Anfangswert, wenn er nicht der
gerade geltende sein soll, `duration` die Dauer in Millisekunden, `easing` den
Verlauf (`"ease-in-out"` oder `"linear"`).

#show-code[```typ
ggb-run("t_1=0", "s=Segment(A,(4*t_1,0))", at: "1-")
ggb-tween("t_1", at: 2, to: 1, duration: 700)
```]

#warning[
  `ggb-tween` braucht eine Schrittnummer, keinen Bereich: `at: 2`, nicht
  `at: "2-"`. Sonst bricht der Bau mit „`ggb-tween() needs a step number`“ ab.

  Und ein Tween auf Schritt 1 käme nie als Bewegung an: beim Betreten einer
  Folie spielt die Laufzeit den Lauf bis zum aktuellen Schritt sofort nach, und
  Tweens werden dabei auf ihren Zielwert gesetzt statt abgespielt. Schritt 1
  ist zum Aufbauen da; gezeichnet wird ab Schritt 2.
]

Ab dem Schritt nach dem Tween sitzt der Wert ohnehin auf seinem Ziel. Wer
zurückblättert, sieht deshalb die fertige Zeichnung und nicht die Bewegung ein
zweites Mal.

= Auf Papier

Im PDF gibt es kein Applet. Ohne weitere Angabe bleibt ein beschrifteter
Platzhalter in der Größe des Rahmens; `link` setzt darunter den Weg zum
lebenden Applet, anklickbar im PDF.

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

Besser ist eine eigene Zeichnung an seiner Stelle. `fallback` nimmt beliebigen
Inhalt -- ein Bild, eine Tabelle, und vor allem eine Zeichnung mit CeTZ:

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

Beide Angaben wirken nur im PDF; im Browser steht dort das Applet selbst.

= Aussehen des Applets

Vorgabe ist `seamless: true`: das Applet trägt keinen eigenen Rahmen, und
seine Zeichenfläche bekommt die Farbe der Folie. Es sieht dann nicht mehr wie
ein Fenster im Fenster aus, sondern wie ein Teil der Folie. `background`
bestimmt diese Farbe; `auto` nimmt das Papierweiß der Präsentation, was auf
einer getönten Folie zu ändern ist.

#show-code[```typ
geogebra(height: 240pt, background: rgb("#f4f1ea"))
geogebra(height: 240pt, seamless: false)   // mit GeoGebras eigenem Rahmen
```]

#warning[
  Der Ausschnitt lässt sich mit der Hand nicht verschieben, und das ist die
  Vorgabe. Wer im Vortrag danebengreift, schöbe sonst die ganze Ebene weg, und
  die Konstruktion wäre fort -- gemeldet aus dem Gebrauch, nicht ausgedacht.
  `pan: true` gibt Verschieben und Zoomen zurück, wo sie zur Sache gehören;
  Punkte und Schieber lassen sich in beiden Fällen ziehen.
]

`font-size` ist die Schrift des Applets, gezählt in Punkten der Folie -- so wie
`width` und `height` es tun. Sie wächst deshalb mit der Folie mit, statt auf
dem Beamer in ihrer physischen Größe stehenzubleiben. Vorgabe ist 16; für einen
großen Saal ist mehr richtig.

#show-code[```typ
geogebra(height: 240pt, font-size: 22)      // größere Achsenzahlen
geogebra(height: 240pt, pan: true)          // Ausschnitt von Hand
```]

`grid` und `axes` lassen GeoGebras Vorgabe stehen, solange sie `auto` sind,
und erzwingen sonst das eine oder andere. `perspective: "G"` zeigt nur die
Grafik-Ansicht, `app` wählt die GeoGebra-App (Vorgabe `"classic"`), `language`
die Sprache der Oberfläche, `animation-button` blendet GeoGebras Abspielknopf
ein.

#info[
  Das Applet wird von `codebase` geladen, ab Werk von `geogebra.org`. Ohne
  Netz bleibt der Rahmen leer; wer offline vorführt, legt GeoGebras Dateien
  daneben und zeigt mit `codebase` darauf.
]

== Größe

`width` und `height` geben die Größe in den Maßen der Folie -- nicht in
Bildschirmpunkten.

Für die meisten Einbettungen spannt die Laufzeit den Rahmen in Punkten der
Folie auf und vergrößert ihn dann mit `zoom`. Ein Applet ist davon ausgenommen
und bekommt echte Bildschirmpunkte. Der Grund ist gemessen: Safari rechnet
diesen Zoom bei GeoGebra doppelt ein -- ein Leinwandpuffer von 1400 Punkten bei
253 Punkten Breite, also Zoom mal Zoom mal Bildschirmdichte. Das Applet
zeichnete zu klein, und wer die Größe dagegen korrigierte, verschob dafür den
Trefferpunkt: es zeichnete dann richtig, glaubte sich aber 704 Punkte breit,
während es 424 breit gezeigt wurde, und ein Punkt ließ sich nur noch greifen,
wenn man weit rechts daneben klickte.

Dass trotzdem in jedem Fenster derselbe Ausschnitt zu sehen ist, hängt deshalb
nicht an der Pixelzahl, sondern am Bereich. Den setzt das Applet beim ersten
Mal aus den Punktmaßen des Kastens, mit GeoGebras 50 Punkten je Einheit; danach
gilt, was `ggb-view` sagt, und eine Größenänderung lässt den Bereich stehen.

#tip[
  Zwei Applets nebeneinander stehen am besten in einem `grid`, jedes mit
  `width: 100%` und eigener Höhe.
]

= Aus der Sprecheransicht

Das Sprecherfenster von typstage führt von jedem Applet eine eigene Kopie. `m`
schaltet dort den Zeiger vom Stift auf die Einbettung um, und von da an ist das
Applet vor dem Vortragenden das lebende: einen Punkt ziehen, einen Schieber
schieben, den Ausschnitt verschieben -- die Kopie auf der Leinwand zieht nach.

Hinüber geht nur, was eine Hand bewegen kann: ein Punkt als seine Koordinaten,
ein Schieber als sein Wert. Alles, was daraus folgt, bleibt liegen, denn die
andere Kopie rechnet es sich selbst aus. Wird etwas angelegt, gelöscht oder
umbenannt, geht stattdessen die ganze Konstruktion.

#tip[
  Gemessen: ein Punkt auf einem Halbkreis meldete beim Ziehen vier Zustände je
  Bild -- den Punkt, beide Strecken und den Winkel. Die drei abhängigen sind
  nicht nur überflüssig, ihr XML definiert sie drüben neu, und das wischt die
  Spur weg, die der gezogene Punkt gerade gelegt hatte.
]

Nur was eine Hand berührt hat, wird gemeldet. Eine Animation, die ohnehin auf
beiden Seiten läuft, schickt deshalb nichts.

#warning[
  Ein Schrittwechsel setzt beide Kopien wie bisher aus der Basis zurück und
  spielt die Jobs der Folie erneut. Eine Änderung von Hand lebt also so lange
  wie der Schritt. Soll eine Position bleiben, gehört sie mit `ggb-set` ins
  Deck.
]

== Die Tastatur

Wer das Applet anklickt, gibt ihm den Fokus, und von da an landet jede Taste
darin. Nachgemessen, bevor darüber entschieden wurde: der Fokus sitzt auf der
Zeichenfläche des Applets, es sieht jede geprüfte Taste, ruft bei keiner
`preventDefault` und ändert nichts an der Konstruktion. Ohne Werkzeugleiste und
ohne Eingabezeile hat dieses Applet für die Tastatur keine Verwendung.

Der Kern reicht die Tasten des Vortrags deshalb aus dem Rahmen zurück, sodass
Blättern und `m` auch mit dem Applet im Fokus weiter tun, was sie sollen. Alles
außerhalb dieser Menge, `Entf` etwa, bleibt beim Applet.

#info[
  Sollte sich das je ändern, etwa mit eingeblendeter Werkzeugleiste, wandert
  eine mit der Tastatur gemachte Änderung mit: das Fenster, in dem die
  Spiegelung wach ist, öffnet sich auf eine Taste ebenso wie auf einen Druck.
]

#tip[
  Was sich nicht bewegen soll, gehört festgehalten. `ggb-style("A", "B",
  fixed: true)` nagelt die Punkte fest, die eine Konstruktion nur aufspannen.
  Sonst greift eine Hand im Vortrag leicht den Falschen: beim Satz des Thales
  etwa den Durchmesser statt des Punktes auf dem Halbkreis, und der ganze
  Bogen wandert mit. Gemessen am Beispiel-Deck: mit `fixed` bewegt weder ein
  Zug an A noch einer am Bogen irgendetwas, und C läuft weiter auf seiner Bahn.
]

Beim Bauen dafür lohnt ein Unterschied: `Point(k)` ist ein Punkt auf der Bahn,
den eine Hand nehmen kann; `Point(k, 0.3)` ist auf diesen Parameter festgelegt
und lässt sich gar nicht ziehen -- `isMoveable` antwortet dort mit falsch. Wo er
starten soll, sagt `position:`.

`examples/example-speaker.typ` ist ein Deck genau dazu: Thales mit einem Punkt, der über
den Halbkreis wandert, und eine Parabel mit zwei Schiebern.

= API-Referenz

Erzeugt aus den Kommentaren der Quelldatei. `resolve-target` und
`no-stray-target` gehören zum Innenleben und stehen deshalb nicht dabei.

#show-module(read("../src/lib.typ"), name: "typstage-geogebra",
             exclude: ("resolve-target", "no-stray-target"))
