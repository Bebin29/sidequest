# Sprint-Retrospektiven

## Sprint 1: Foundation (23.03. – 30.03.2026)

### Was lief gut?

- Server-Setup (SSH, Docker, PostgreSQL) an einem Tag komplett abgeschlossen
- GitHub Project Board mit Labels, Milestones und 16 Issues schnell aufgesetzt
- CI/CD-Pipeline für iOS und Backend innerhalb des ersten Sprints lauffähig
- Branching-Strategie (main → develop → feature/*) hat sofort funktioniert
- Grundlegende MVVM-Architektur der iOS-App stand am Ende des Sprints

### Was lief nicht gut?

- Merge-Konflikte bei UI-Dateien, weil Ben und Ole parallel an Views gearbeitet haben
- SwiftLint-Regeln waren anfangs zu streng konfiguriert und haben den Workflow gebremst
- Manche Issues waren zu groß geschnitten und hätten in kleinere Tasks aufgeteilt werden sollen

### Maßnahmen für Sprint 2

- **Klare View-Zuordnung**: Vor dem Sprint festlegen, wer an welchen Views arbeitet, um Konflikte zu vermeiden
- **SwiftLint anpassen**: Zu restriktive Regeln (line_length, file_length) deaktiviert
- **Kleinere Issues**: Große Features in Sub-Tasks aufteilen

---

## Sprint 2: Core Features (31.03. – 06.04.2026)

### Was lief gut?

- Feed-Algorithmus (Sortierung nach Entfernung) funktioniert zuverlässig
- Freundschaftssystem komplett implementiert (Requests, Suggestions, Mutual Friends)
- TestFlight-Deployment automatisiert -- jeder Push auf main liefert automatisch an Tester aus
- HIG-Audit durchgeführt und 90% der Findings behoben
- Kein einziger kritischer Merge-Konflikt dank der Maßnahme aus Sprint 1

### Was lief nicht gut?

- Backend-Deployment-Skript musste mehrfach manuell angepasst werden (Docker-Rechte-Problem)
- Notifications-Feature hat länger gedauert als geschätzt (Push-Zertifikat-Konfiguration)
- UI-Tests sind nur Stubs -- keine Zeit für echte UI-Testabdeckung

### Maßnahmen für Sprint 3

- **Deploy-Skript härten**: Fehlerbehandlung und Logging im deploy.sh verbessern
- **UI-Tests priorisieren**: Mindestens einen echten UI-Test für den kritischen Pfad schreiben
- **Schätzung verbessern**: Für unbekannte Technologien (z.B. APNS) einen Puffer einplanen

---

## Sprint 3: Social + Polish (07.04. – 11.04.2026)

*Retrospektive wird am 11.04.2026 durchgeführt.*
