# Scrum vs. traditionelle Softwareentwicklungsprozesse

## Überblick

| Kriterium | Scrum (agil) | Wasserfallmodell | V-Modell |
|-----------|-------------|-----------------|----------|
| **Vorgehen** | Iterativ, inkrementell | Sequenziell, linear | Sequenziell mit Verifikation |
| **Phasen** | Sprints (1–4 Wochen) | Analyse → Design → Implementierung → Test → Betrieb | Wie Wasserfall, aber jede Phase hat eine zugeordnete Testphase |
| **Anforderungen** | Können sich jederzeit ändern | Werden zu Beginn vollständig festgelegt | Werden zu Beginn festgelegt, Tests werden früh geplant |
| **Kundenfeedback** | Nach jedem Sprint | Erst am Ende | Erst am Ende |
| **Dokumentation** | Minimal, Working Software hat Vorrang | Umfangreich, formale Dokumente pro Phase | Sehr umfangreich, zusätzlich Testdokumentation |
| **Teamstruktur** | Selbstorganisiert, crossfunktional | Hierarchisch, rollenbasiert | Hierarchisch, stark formalisiert |
| **Risikomanagement** | Früh durch kurze Feedbackzyklen | Spät, Probleme werden oft erst im Test sichtbar | Besser als Wasserfall durch frühe Testplanung |

## Vorteile von Scrum

- **Schnelles Feedback**: Durch wöchentliche Sprints konnten wir nach jedem Sprint ein lauffähiges Produkt zeigen und Feedback einarbeiten.
- **Flexibilität**: Als wir gemerkt haben, dass das Ring-Code-Feature keinen Mehrwert bringt, konnten wir es einfach aus dem Backlog entfernen, ohne den gesamten Plan umschreiben zu müssen.
- **Motivation**: Regelmäßige, sichtbare Fortschritte (funktionierender Feed, Freunde-Feature, TestFlight-Build) halten das Team motiviert.
- **Risikominimierung**: Probleme wie das Docker-Rechte-Problem oder die APNS-Konfiguration wurden innerhalb eines Sprints erkannt und gelöst, nicht erst Wochen später.

## Nachteile von Scrum

- **Wenig Dokumentation**: In einem Schulprojekt mit Abgabe ist das ein Problem -- wir mussten Dokumentation nachträglich erstellen, weil Scrum wenig formale Dokumente vorsieht.
- **Overhead bei kleinen Teams**: Daily Standups, Sprint Planning, Review und Retrospektive sind bei einem 4-Personen-Team manchmal überdimensioniert.
- **Schwierige Schätzung**: Ohne Erfahrungswerte war es schwer einzuschätzen, wie viel in einen Sprint passt.

## Vorteile traditioneller Modelle

- **Planbarkeit**: Beim Wasserfall- oder V-Modell ist von Anfang an klar, was wann fertig sein soll. Das erleichtert die Kommunikation mit Stakeholdern.
- **Strukturierte Dokumentation**: Jede Phase erzeugt Dokumente, die den Projektfortschritt nachvollziehbar machen -- ein Vorteil bei Prüfungen und Audits.
- **Geeignet für stabile Anforderungen**: Wenn die Anforderungen von Anfang an feststehen (z.B. bei eingebetteter Software oder regulierten Branchen), vermeidet man den Overhead agiler Zeremonien.

## Nachteile traditioneller Modelle

- **Spätes Feedback**: Beim Wasserfallmodell sieht der Kunde das Ergebnis erst am Ende. Wenn die Anforderungen falsch verstanden wurden, ist der Aufwand zur Korrektur enorm.
- **Keine Flexibilität**: Änderungen in späteren Phasen sind teuer und aufwendig. Beim V-Modell muss bei einer Anforderungsänderung potenziell die gesamte Verifikationskette angepasst werden.
- **Lange Entwicklungszyklen**: Ohne regelmäßige Releases vergehen oft Monate, bis ein Fehler in der Architektur oder im Design auffällt.

## Warum Scrum für Sidequest?

Für unser Projekt war Scrum die richtige Wahl, weil:

1. **Die Anforderungen nicht vollständig feststanden** -- wir wussten zu Beginn nicht genau, welche Features das Produkt braucht und welche nicht (Beispiel: Ring-Code entfernt, Monitoring nachträglich hinzugefügt).
2. **Kurze Projektlaufzeit** (3 Wochen) -- Wasserfall hätte bedeutet, dass wir erst in der letzten Woche testen. Mit Scrum haben wir ab Sprint 1 getestet.
3. **Kleines Team** -- Scrum-Rollen lassen sich gut auf 4 Personen verteilen. Ein V-Modell hätte formalen Overhead erzeugt, der bei unserer Teamgröße unverhältnismäßig wäre.
4. **CI/CD-Pipeline** -- unsere automatisierte Pipeline passt perfekt zu agilen Prinzipien (Continuous Integration, häufige Releases).
