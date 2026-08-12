# Abnahmekriterien (MoSCoW)

Sechs Teilhandlungen, jede mit Must/Should/Could. Das ist die eigentliche Bewertungsgrundlage —
alles andere im Lernfeld läuft darauf zu. Die Statusspalte hält fest, wo Sidequest aktuell
steht; sie wird im Lauf des Lernfelds fortgeschrieben.

Legende: ✅ erfüllt · 🟡 teilweise · ⬜ offen

---

## 1. Nachhaltigkeit

> Unser Planet ist nur begrenzt belastbar. Um weiterhin gut leben zu können und dies auch
> zukünftigen Generationen zu ermöglichen, gilt es unseren Konsum und unsere Produktionstechniken
> zu verändern. Ein Baustein dazu sind Regeln für den Umgang mit begrenzten Ressourcen, für den
> Arbeits-, Gesundheits- und Umweltschutz.
> *(Bundesregierung, 11.09.2019)*

**Must**

- ⬜ Auseinandersetzung mit den UN-Nachhaltigkeitszielen — Ziele 11 und 12 in der Gruppe
  diskutieren
- ⬜ Entscheidung für eines der beiden Ziele (11 oder 12), und diese Entscheidung bei Planung
  **und** Umsetzung der Software berücksichtigen

---

## 2. Produkt und Zielgruppe bestimmen

> Wer versucht jeden zu erreichen, erreicht am Ende niemanden. Deswegen ist es wichtig, seine
> Kund:innen zu verstehen und ein Produkt zu entwickeln, das sich an deren Bedürfnissen
> orientiert. Personas sind der Schlüssel, um als Unternehmen die Zielgruppe zu begeistern und
> mit Empathie zu punkten.

**Must**

- ⬜ Wesentliche Merkmale des Produkts beschreiben
- ⬜ Potenzielle Zielgruppe als Persona darstellen, mindestens ausgestattet mit
  - demografischen Merkmalen (Wohnort, Alter, Gender, Familienstand …)
  - sozioökonomischen Merkmalen (Bildungsstand, Beruf, Einkommen …)
  - Kaufverhalten (Preissensibilität, Mediennutzung …)
- ⬜ Empathy Map zur Visualisierung der Kundenbedürfnisse, entlang der vier Bereiche
  **Sehen, Hören, Denken, Sagen**

**Should**

- ⬜ Alleinstellungsmerkmal (USP) des Produkts erläutern
- ⬜ Persona zusätzlich mit psychografischen Merkmalen (Einstellungen, Überzeugungen, Wünsche,
  Werte, Lebensstil)
- ⬜ Empathy Map um **Gefühle und Handeln** erweitern

**Could**

- ⬜ Mögliche Substitutionsgüter am Markt benennen
- ⬜ Ängste, Abneigungen und Herausforderungen der Persona erläutern
- ⬜ Empathy Map um **Pain and Gain** ergänzen

---

## 3. Geschäftsprozess erläutern und darstellen

> Um sich eine Vorstellung von dem Problem zu machen, wird der Ist-Zustand des bestehenden
> Geschäftsprozesses definiert, um daraus einen Plan für den Soll-Zustand zu entwickeln.

**Must**

- ⬜ Beschreibung des aktuellen Geschäftsprozesses (Ist-Zustand)
- ⬜ Analyse und Erläuterung der Defizite und Probleme des Ist-Zustands
- ⬜ Vision des verbesserten oder neuen Geschäftsprozesses (Soll-Zustand)
- ⬜ Erläuterung der Vorteile, die sich aus der Vision ergeben
- ⬜ Meilensteine zur Erreichung des Soll-Zustands festlegen

**Should**

- ⬜ Visualisierung des Geschäftsprozesses

**Could**

- ⬜ Promo-Video der Vision für eine Crowdfunding-Plattform und potenzielle Investoren

---

## 4. Planung mit Prozessen und Planungstools

> Der Design-Thinking-Prozess wird iterativ durchlaufen. Bei zwei bis drei Wochen Umsetzung
> können pro Woche ein bis zwei Sprints stattfinden. Elemente: Planung, Planungsboard,
> Schätzung, Priorisierung, Implementierung, Auslieferung, Retrospektive. Planung, Stand-ups und
> Team-Retros finden auf Englisch statt.

**Must**

- ⬜ Scrum-Rollen im Team definieren
- 🟡 Projekt mit der Scrum-Methode planen — Milestones/Sprints und Issues existieren, müssen für
  LF10a aber neu aufgesetzt werden
- ✅ Planungsboard mit dem Lehrerteam geteilt — GitHub Project Board ist öffentlich
- 🟡 Backlog spezifiziert, definiert „Was" und „Wie" — 16 Issues vorhanden, inhaltlich noch aus
  dem alten Scope
- ⬜ Definition of Done im Sinne der SMART-Kriterien

**Should**

- ⬜ Ergebnisse der Team-Retrospektiven dokumentieren
- 🟡 Gitlab als Planungstool — wir nutzen GitHub Projects; abweichend, aber funktional
  gleichwertig. Mit dem Lehrerteam abstimmen.

**Could**

- ⬜ Rollenbeschreibungen um weitere Scrum-Rollen erweitern, die in komplexen Projekten sinnvoll
  wären

---

## 5. Deployment-Pipeline mit Bereitstellung der Web-Services (Infrastructure as Code)

> Der Software Development Life Cycle (SDLC) ist ein Vorgehensmodell der professionellen
> Anwendungsentwicklung — es macht Softwareentwicklung übersichtlicher und die Komplexität
> beherrschbar. Continuous Delivery bezeichnet Techniken, Prozesse und Werkzeuge, die den
> Auslieferungsprozess verbessern und automatisieren. Die Automatisierung von Integration und
> Auslieferung ermöglicht schnelles, zuverlässiges und wiederholbares Deployment auf
> verschiedenen Systemen. Erweiterungen und Fehlerkorrekturen gehen dadurch mit geringerem
> Risiko und weniger manuellem Aufwand in Produktion.

**Must**

- 🟡 Ein Commit wird automatisiert in die Testumgebung deployt (Continuous Integration) —
  `.github/workflows/ios.yml` baut und testet die iOS-App bei Push und PR auf `develop`/`main`.
  Ein **Deployment-Schritt fehlt vollständig**, und das Backend hat gar keine CI.
- 🟡 Unit-Tests laufen automatisiert in der CI — für iOS ja (`Sidequest3Tests`); im Backend ist
  `npm test` noch der Platzhalter `exit 1`.
- ⬜ Integrationstests laufen automatisiert
- ⬜ Pipeline bzw. SDLC enthält mindestens **drei** Maßnahmen zur Qualitätssicherung neben den
  automatisierten Tests — SwiftLint ist die erste, zwei fehlen

**Should**

- ⬜ Testabdeckung wird in der Pipeline gemessen, mit Aussagen zu möglichen Verbesserungen
- ⬜ Ein Commit wird automatisiert in die Produktivumgebung gebracht (Continuous Deployment)

**Could**

- ⬜ Monitoring der Anwendung, das bei Problemen in Produktion das Entwicklungsteam benachrichtigt
- ⬜ Skalierbarkeit der Anwendung aufzeigen oder zumindest erläutern

> Diese Teilhandlung ist unser größter Rückstand — und die einzige, die sich vollständig
> unabhängig vom Design-Thinking-Ergebnis vorbereiten lässt.

---

## 6. Erste Anwendung von Design Patterns

**Must**

- ⬜ Überblick über Design Patterns aus mindestens einer Kategorie (Creational, Behavioral,
  Structural) erläutern
- ⬜ Ein Design Pattern erläutern
- 🟡 Quellcode des Projekts auf sinnvollen Einsatz von Design Patterns analysieren — vorhanden
  sind bereits Dependency Injection (`Services/DependencyContainer.swift`,
  `Services/ServiceProtocol.swift`) und MVVM (`ViewModels/`); die Analyse selbst steht aus

**Should**

- ⬜ Ein konkretes Problem bzw. eine konkrete Anforderung mit einem Design Pattern lösen
- ⬜ Das Pattern durch automatisierte Tests absichern

**Could**

- ⬜ Ein verwendetes Framework auf Design Patterns untersuchen und drei Beispiele aufzeigen
  (Architekturpattern zulässig)
