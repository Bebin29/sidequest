# Scrum-Rollen im Team Sidequest

## Rollenverteilung

### Ole Böhm -- Teamleitung & Produktentwicklung

Ole übernimmt die Rolle des **Product Owners** und ist gleichzeitig der aktivste Frontend-Entwickler im Team. Als Teamleitung koordiniert er die wöchentlichen Sprints, legt Prioritäten im Backlog fest und stellt sicher, dass die Produkt-Vision eingehalten wird. Im Sprint Planning entscheidet er, welche Issues in den nächsten Sprint aufgenommen werden, und nimmt im Sprint Review die Ergebnisse ab.

**Konkrete Aufgaben:**
- Teamleitung und Koordination des Gesamtprojekts
- Planung und Verteilung der Aufgaben im Team
- Entwicklung großer Teile des iOS-Frontends (SwiftUI Views, Navigation, Feed-Logik)
- Gestaltung der Benutzeroberfläche und Sicherstellung einer einheitlichen UI-Sprache
- Pflege der Produkt-Vision und Entscheidung über Feature-Prioritäten
- Kommunikation mit dem Lehrerteam als Stakeholder

### Dennis Brinks -- Testing & Entwicklung

Dennis ist verantwortlich für die **Qualitätssicherung** und fungiert als interner QA-Verantwortlicher des Teams. Er testet neue Features systematisch auf dem Gerät, dokumentiert Fehler als GitHub Issues und überwacht den Projektfortschritt anhand der Meilensteine. Zusätzlich unterstützt er bei der Frontend-Entwicklung und stellt sicher, dass Zeitplanung und Deadlines eingehalten werden.

**Konkrete Aufgaben:**
- Durchführung manueller App-Tests (Blackbox-Testing) auf physischen Geräten
- Qualitätssicherung während der Entwicklung (Code Review, Funktionsprüfung)
- Unterstützung bei der Frontend-Entwicklung (SwiftUI Views, kleinere Features)
- Überwachung des Projektfortschritts auf dem GitHub Project Board
- Kontrolle von Zeitplanung und Sprint-Meilensteinen

### Max Dwortzak -- UI-Design & Frontend

Max bringt die **Design-Perspektive** ins Team und ist verantwortlich dafür, dass die App nicht nur funktioniert, sondern auch gut aussieht und intuitiv bedienbar ist. Er entwickelt Design-Konzepte, setzt UI-Elemente im Frontend um und achtet auf ein konsistentes visuelles Erscheinungsbild über alle Screens hinweg. Zusätzlich hat Max an der **Server-Infrastruktur** mitgewirkt -- unter anderem hat er den HAProxy als Reverse Proxy eingerichtet und die Benutzerverwaltung auf dem Server konfiguriert, sodass das Team nicht ausschließlich über den Root-Zugang arbeiten muss.

**Konkrete Aufgaben:**
- Entwicklung von Design- und UX-Konzepten für neue Features
- Gestaltung moderner, ansprechender Benutzeroberflächen
- Umsetzung von UI-Elementen im SwiftUI-Frontend (Farben, Typografie, Layouts, Animationen)
- Sicherstellung eines konsistenten Designs über alle Views hinweg
- Fokus auf Benutzerfreundlichkeit, Barrierefreiheit und visuelle Qualität
- Erstellung von Mockups und Prototypen vor der Implementierung
- Einrichtung des HAProxy als Reverse Proxy auf dem Produktionsserver (Port 80 → API / Dashboard)
- Anlegen und Konfiguration von Benutzerkonten auf dem Server (Rechtetrennung, kein dauerhafter Root-Zugang)

### Benedikt Koch -- Backend & Infrastruktur

Ben übernimmt die Rolle des **Scrum Masters** und ist gleichzeitig alleinverantwortlich für die gesamte technische Infrastruktur. Er hat den Server aufgesetzt, die Datenbank konfiguriert, die CI/CD-Pipeline gebaut und die REST-API entwickelt. Als Scrum Master organisiert er den Entwicklungsprozess, verwaltet das GitHub Repository (Branches, PRs, Protection Rules) und sorgt dafür, dass das Team ungestört arbeiten kann.

**Konkrete Aufgaben:**
- Entwicklung der gesamten Backend-Architektur (Node.js REST-API, pure `http`-Module)
- Aufbau und Pflege der Server-Infrastruktur (Ubuntu-Server, Docker, HAProxy, SSH)
- Design und Migration der PostgreSQL-Datenbank (11 Migrations, 7 Tabellen)
- Einrichtung der CI/CD-Pipeline (GitHub Actions: iOS Build & Test, Backend Tests, TestFlight Deploy)
- Verwaltung des GitHub-Repositories (Branch Protection, Labels, Milestones, Project Board)
- Organisation des Scrum-Prozesses: Sprint Planning, Reviews, Retrospektiven
- Server-Monitoring und Deployment-Management

## Scrum-Rollen-Zuordnung

| Scrum-Rolle | Person | Warum diese Zuordnung? |
|-------------|--------|----------------------|
| **Product Owner** | Ole | Als Teamleitung hat Ole den besten Überblick über die Produkt-Vision und die Nutzerbedürfnisse. Er entscheidet, was gebaut wird. |
| **Scrum Master** | Ben | Als Infrastruktur-Verantwortlicher verwaltet Ben bereits das GitHub Repo und die Tooling-Landschaft. Die Scrum-Organisation ist eine natürliche Erweiterung davon. |
| **Entwicklungsteam** | Ole, Dennis, Max, Ben | Alle vier Teammitglieder entwickeln aktiv. Auch Product Owner und Scrum Master tragen Code bei -- in einem 4-Personen-Team ist reine Prozessarbeit ohne Entwicklung nicht tragbar. |

## Rollenbeschreibungen (nach Scrum Guide)

### Product Owner

Der Product Owner vertritt die Interessen der Nutzer und Stakeholder. In unserem Kontext sind die primären Stakeholder das Lehrerteam, das den Projektfortschritt bewertet, sowie potenzielle Endnutzer der App. Der Product Owner pflegt das Product Backlog auf dem GitHub Project Board, priorisiert Issues nach Geschäftswert (MoSCoW-Priorisierung) und definiert die Akzeptanzkriterien für jede User Story. Am Ende jedes Sprints entscheidet er, ob die umgesetzten Features der Definition of Done entsprechen.

### Scrum Master

Der Scrum Master ist kein Vorgesetzter, sondern ein **Servant Leader** -- er dient dem Team. Seine Aufgabe ist es, Hindernisse zu beseitigen (z.B. Server-Probleme, fehlende Zugänge, CI/CD-Fehler), die Sprint-Zeremonien zu moderieren und sicherzustellen, dass der Scrum-Prozess eingehalten wird. Er achtet auf Timeboxing bei Meetings und schützt das Team vor Scope Creep während eines laufenden Sprints.

### Entwicklungsteam

Das Entwicklungsteam ist **selbstorganisiert** und **crossfunktional**. Es entscheidet im Sprint Planning gemeinsam, wer welche Aufgaben übernimmt. Durch die individuellen Stärken (Backend, Frontend, Design, Testing) ergeben sich natürliche Schwerpunkte, aber grundsätzlich kann jedes Teammitglied an jedem Teil des Projekts arbeiten. Die Eigenverantwortung innerhalb des Teams ist hoch -- jeder zieht sich selbständig neue Tasks vom Board.

## Verwendete Tools

| Tool | Zweck | Beschreibung |
|------|-------|-------------|
| **Scrum** | Agiles Framework | Wöchentliche Sprints mit Planning, Review und Retrospektive als Rahmen für die iterative Entwicklung |
| **GitHub Project Board** | Kanban-Board | Aufgabenverwaltung mit den Spalten: Backlog, Ready, In Progress, In Review, Done. Öffentlich zugänglich, mit dem Lehrerteam geteilt. |
| **GitHub Issues** | Backlog-Items | Jede User Story und jeder Bug wird als Issue mit Labels (sprint-1/2/3, backend, ios, testing, documentation), Priorität und Zuordnung erfasst |
| **Notion** | Dokumentation | Ergänzende Dokumentation, Meeting-Notizen und Wissensmanagement außerhalb des Repositories |

## Arbeitsweise

- **Sprint-Dauer**: 1 Woche (angepasst an den Unterrichtsrhythmus)
- **Sprint Planning**: Montags zu Beginn des Unterrichts -- Auswahl der Issues für den Sprint, Schätzung mit T-Shirt-Sizing
- **Daily Standup**: Kurzer Austausch zu Beginn jeder Unterrichtsstunde (Was habe ich geschafft? Was mache ich heute? Gibt es Blocker?)
- **Sprint Review**: Freitags -- Vorstellung der fertigen Features, Abnahme durch Product Owner
- **Sprint Retrospektive**: Freitags nach dem Review -- Was lief gut? Was lief schlecht? Welche Maßnahmen leiten wir ab?
- **Definition of Done**: Feature ist implementiert, getestet (manuell + automatisiert wo möglich), Code ist reviewed und auf `develop` gemergt
