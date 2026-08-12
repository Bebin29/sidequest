# Sidequest im Rahmen von LF10a

Sidequest war bereits das Projekt in **Lernfeld 08**. Diese Datei hält fest, wie die bestehende
Codebasis in den Auftrag von LF10a passt, was das für den Design-Thinking-Prozess bedeutet und
wo die echten Lücken liegen.

**Status:** Die Weiterarbeit an Sidequest ist vom Lehrerteam freigegeben.

Die abgehakten Anforderungen in `Sidequest3/docs/sessions/2026-03-23.md` beziehen sich auf den
LF08-Kriterienkatalog, nicht auf LF10a. Die Formulierungen überlappen sich teilweise (etwa
„Planungsboard mit dem Lehrerteam teilen"), die Kataloge sind aber verschieden — LF08 drehte
sich um Continuous-Delivery-Pipeline, Prototyp und Open- vs. Closed-Source, LF10a um Design
Thinking, Geschäftsprozess und Design Patterns. Was in LF08 erfüllt war, gilt hier also nicht
automatisch als erledigt.

## Was Sidequest ist

Eine iOS-App (SwiftUI) mit Node/Postgres-Backend rund um Orte: entdecken, bewerten, zu Trips
zusammenstellen, mit Freund:innen teilen.

- **iOS:** SwiftUI, MVVM (`ViewModels/`), Services mit Dependency Injection
  (`Services/DependencyContainer.swift`, `Services/ServiceProtocol.swift`), Views für Home,
  Feed, Karte, Profil
- **Backend:** Node/Express-artiger Aufbau (`backend/src/`), Controller, Router, PG-Pool,
  sechs SQL-Migrationen, Dockerfile
- **Infrastruktur:** eigener Server, PostgreSQL 16 im Docker-Container
- **Prozess:** GitHub Project Board (öffentlich), Issues mit Labels und Milestones,
  Branching `main` → `develop` → `feature/*`, Branch Protection auf beiden geschützten Branches

## Der thematische Reframe: SDG 11

Der Auftrag verlangt Smart Living plus Nachhaltigkeitsziel 11 oder 12. Ortsentdeckung und
Trip-Planung sind erstmal keines von beidem — die Verbindung muss inhaltlich hergestellt werden,
nicht per Etikett.

**Unsere Richtung ist Ziel 11: Städte und Siedlungen inklusiv, sicher, widerstandsfähig und
nachhaltig gestalten.** Smart Living meint die Digitalisierung der Wohn- **und
Lebensumgebung** — die Lebensumgebung endet nicht an der Wohnungstür. Der inhaltliche
Schwerpunkt, der daraus folgt: **barrierearme und inklusive Erkundung der eigenen Stadt.**

Das Datenmodell liefert die Vorlage bereits. In `backend/migrations/002_create_locations.sql`
existieren die Spalten `accessibility`, `is_family_friendly`, `is_dog_friendly`, `parking_info`
und `noise_level`. Bisher sind das ungenutzte Felder — als Schwerpunkt werden sie zu dem, was
die App eigentlich beantwortet: *Welche Orte in meiner Umgebung kann ich mit meinen
Einschränkungen tatsächlich nutzen?*

Das ist kein Etikettenschwindel, sondern ein Feature-Schwerpunkt, der in Sprint 4 ehrlich
implementiert wird.

## Der Design-Thinking-Prozess bleibt ergebnisoffen

Das Mindset sagt: *Wir denken in Problemen, nicht in Lösungen.* Wir haben aber schon eine
Lösung. Die naheliegende Abkürzung — Persona und Empathy Map nachträglich so zuschneiden, dass
die vorhandene App als Antwort herauskommt — fällt bei der Abnahme auf und widerspricht dem
Kern des Lernfelds.

Deshalb die Regel für Sprint 1 und 2:

> Sidequest ist nicht die Antwort. Sidequest ist die Codebasis, auf der die Antwort entsteht.

Der Prozess läuft ergebnisoffen auf den Problemraum „inklusive, nachhaltige Stadt". Wenn Persona
und Empathy Map in eine andere Richtung zeigen, folgen wir dem — die vorhandene Infrastruktur
(Auth, Datenbank, Pipeline, Karte) trägt auch dann noch, wenn sich das Produkt inhaltlich
verschiebt.

## Was bereits erfüllt ist

| Anforderung | Stand |
|---|---|
| Prototyp (Sprint 3) | Lauffähige App plus Backend — der Sprint-3-Anspruch „etwas, was irgendwie funktioniert" ist übererfüllt |
| Planungstools und Board | Project Board öffentlich, Issues mit Labels und Prioritäten, Milestones, definierte Branching-Strategie |
| Versionsverwaltung mit Git | Vorhanden, inklusive Branch Protection und PR-Pflicht |
| CI-Grundzüge | `.github/workflows/ios.yml` — Build, Tests, SwiftLint bei Push und PR |
| Design Patterns im Code | Dependency Injection und MVVM sind bereits implementiert und damit erläuterbar |
| Deploybare Web-Services | Backend läuft in Docker auf eigenem Server — Continuous Deployment ist real machbar |

Der letzte Punkt ist strategisch wichtig: Automatisiertes Deployment einer iOS-App über den App
Store wäre im Rahmen des Lernfelds kaum umsetzbar. Über das Backend ist das Must-have
erreichbar.

## Die drei echten Lücken

### 1. Deployment-Pipeline

Der größte Rückstand — und der einzige Block, der sich komplett unabhängig vom
Design-Thinking-Ergebnis vorbereiten lässt.

- Die CI deckt nur iOS ab; das **Backend hat keine CI**
- `backend/package.json` hat noch den Platzhalter `"test": "echo \"Error: no test specified\" &&
  exit 1"` — es gibt keine Backend-Tests
- Es existiert **kein Deployment-Schritt**, weder in Test- noch in Produktivumgebung
- Integrationstests fehlen vollständig
- Von den geforderten drei QS-Maßnahmen neben den Tests haben wir eine (SwiftLint)

### 2. Unterschiedliche Endgeräte und Betriebssysteme

Der KMK-Rahmenlehrplan verlangt Oberflächen „für unterschiedliche Endgeräte und
Betriebssysteme". iOS-only erfüllt das nicht. Zwei Optionen:

- **iPad/macOS über SwiftUI** — billiger, weil dieselbe Codebasis, deckt die Anforderung aber
  nur knapp ab (ein Hersteller, verwandte Systeme)
- **Web-Frontend auf dem bestehenden Node-Backend** — mehr Arbeit, aber deutlich überzeugender
  und zahlt gleichzeitig auf „Bereitstellung der Web-Services" in der Pipeline-Teilhandlung ein

Die Entscheidung hängt nicht vom Problemraum ab und kann vorab getroffen werden.

### 3. Datenschutzkonformität

Der Rahmenlehrplan verlangt eine Prüfung auf Datenschutzkonformität und Benutzerfreundlichkeit.
Bei einer App, die Standortdaten, Freundschaftsgraphen und nutzergenerierte Bewertungen
speichert, ist das kein Pflichtpunkt zum Abhaken, sondern ein inhaltlich ergiebiges Thema —
Datensparsamkeit, Löschkonzept, Sichtbarkeit öffentlicher Trips, Umgang mit Standorthistorie.

## Design Patterns fürs Barcamp

Naheliegend, weil bereits im Code vorhanden und damit an echtem Beispiel erklärbar:

- **Dependency Injection** — `Services/DependencyContainer.swift`
- **MVC/MVVM** — die gesamte iOS-Schichtung

Die Themenwahl muss mit den anderen Gruppen abgestimmt werden, damit nichts doppelt belegt ist.

## Was bewusst nicht vorbereitet wird

Persona, Empathy Map, Problem Statement und Business Canvas sind Sprint-1- und
Sprint-2-Arbeit mit der ganzen Gruppe. Vorproduziert widersprechen sie dem Mindset und fallen in
der Abnahme auf.
