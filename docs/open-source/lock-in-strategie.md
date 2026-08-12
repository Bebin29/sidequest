# Umgang mit Lock-in-Effekten

## Was sind Lock-in-Effekte?

Ein Lock-in-Effekt entsteht, wenn der Wechsel von einem Anbieter oder einer Technologie zu einer Alternative unverhältnismäßig teuer, aufwändig oder riskant ist. Die Wechselkosten können finanzieller (Lizenzgebühren, Migrationsaufwand), technischer (Inkompatibilität, Datenformate) oder organisatorischer Natur (Umschulung, Prozessänderungen) sein. Je höher die Wechselkosten, desto stärker der Lock-in.

## Identifizierte Lock-in-Risiken bei Sidequest

| Risiko | Betroffene Komponente | Schwere | Wahrscheinlichkeit |
|--------|-----------------------|---------|---------------------|
| Apple erhöht Developer Program Gebühren oder ändert App Store Richtlinien | Xcode, App Store, TestFlight | Hoch | Mittel |
| GitHub ändert Preismodell für Actions oder Private Repos | GitHub, GitHub Actions | Mittel | Gering |
| Strato stellt vServer-Produkt ein oder erhöht Preise drastisch | Server-Hosting | Gering | Gering |
| Apple stellt SwiftUI-Unterstützung für ältere iOS-Versionen ein | SwiftUI-Frontend | Mittel | Hoch (passiert regelmäßig) |

## Wie könnten Lock-in-Effekte zukünftig behandelt werden?

### 1. API-First-Architektur beibehalten

Die wichtigste strategische Entscheidung im Projekt ist bereits getroffen: Die **REST-API ist vollständig vom Frontend entkoppelt**. Das Backend weiß nicht, ob der Client eine iOS-App, eine Android-App oder ein Web-Browser ist. Diese Architektur ermöglicht es, jederzeit weitere Clients hinzuzufügen, ohne das Backend anzupassen.

**Maßnahme:** Die API-Dokumentation aktuell halten und sicherstellen, dass alle Endpunkte plattformneutral bleiben (kein Apple-spezifisches Verhalten in der API).

### 2. Datenportabilität sicherstellen

PostgreSQL speichert alle Daten in einem standardisierten Format. Ein vollständiger Export ist jederzeit über `pg_dump` möglich. Die Daten können in jede andere SQL-Datenbank (MySQL, MariaDB, SQLite) importiert werden.

**Maßnahme:** Regelmäßige Backups als SQL-Dumps erstellen. Keine PostgreSQL-spezifischen Erweiterungen verwenden, die die Portabilität einschränken (z.B. PostGIS vermeiden, wenn einfache Haversine-Berechnungen ausreichen -- was wir bereits tun).

### 3. CI/CD-Logik abstrahieren

Die GitHub Actions Workflows sind derzeit GitHub-spezifisch. Die zugrundeliegende Logik (Build → Test → Deploy) ist jedoch universell. Eine Migration zu GitLab CI oder Jenkins wäre mit Aufwand, aber ohne grundlegende Architekturänderungen möglich.

**Maßnahme:** Komplexe Build-Logik in Shell-Skripte auslagern statt direkt in YAML-Workflows zu schreiben. So bleibt der CI/CD-Anbieter austauschbar, während die eigentliche Logik portabel ist.

### 4. Multi-Plattform-Strategie evaluieren

Der größte Lock-in ist das Apple-Ökosystem. Langfristig könnte eine Cross-Platform-Strategie dieses Risiko reduzieren:
- **Web-App** (React/Vue + bestehende REST-API) als plattformunabhängiger Zugang
- **Android-App** (Kotlin/Jetpack Compose) für die zweite große Mobile-Plattform
- **Progressive Web App (PWA)** als Kompromiss zwischen Web und Native

**Maßnahme:** Kurzfristig nicht nötig, aber bei einer kommerziellen Weiterentwicklung sollte die Android-Version priorisiert werden.

## Was sollte ein Unternehmen tun, um bewusst mit Lock-in umzugehen?

### Strategische Ebene

1. **Technologie-Radar führen**: Regelmäßig (z.B. quartalsweise) die verwendeten Technologien und ihre Alternativen bewerten. Fragen: Gibt es Veränderungen bei Lizenzen, Preisen oder Roadmaps? Sind neue Alternativen entstanden?

2. **Exit-Strategie definieren**: Für jede kritische Komponente einen dokumentierten Migrationsplan haben. Nicht als aktives Projekt, sondern als "Plan B" in der Schublade. Was würden wir tun, wenn Apple die Developer-Gebühren verdreifacht? Wie schnell könnten wir von GitHub zu GitLab wechseln?

3. **Kosten-Nutzen-Analyse**: Lock-in ist nicht grundsätzlich schlecht. Apple-Lock-in gibt uns Zugang zu einer zahlungskräftigen Nutzerbasis und hervorragenden Frameworks. Die Frage ist nicht "Wie vermeiden wir Lock-in?", sondern "Ist der Nutzen den Lock-in wert, und kennen wir die Risiken?"

### Technische Ebene

4. **Offene Standards bevorzugen**: Bei Entscheidungen für neue Technologien Open-Source und offene Standards bevorzugen, sofern die Qualität stimmt. Beispiel: PostgreSQL statt Oracle, Docker statt proprietärer Container-Lösungen.

5. **Abstraktionsschichten einbauen**: Wo sinnvoll, eine Abstraktionsschicht zwischen der eigenen Anwendung und dem Anbieter einbauen. In unserem Fall: Die REST-API abstrahiert das Backend vom Frontend. Der Wechsel des Frontends erfordert keine Backend-Änderungen.

6. **Daten-Souveränität sicherstellen**: Die eigenen Daten immer exportierbar halten. Keine Daten in proprietären Formaten speichern, die nur der Anbieter lesen kann. Regelmäßige Backups in offenen Formaten.

### Organisatorische Ebene

7. **Wissen breit streuen**: Nicht nur einen Mitarbeiter auf einer Technologie ausbilden. Wenn nur eine Person Xcode beherrscht und diese das Unternehmen verlässt, wird der Lock-in zum Personalproblem.

8. **Verträge prüfen**: Bei proprietärer Software die Vertragsbedingungen genau lesen. Fragen: Was passiert mit den Daten bei Vertragsende? Gibt es eine Exportmöglichkeit? Wie lange ist der Vertrag bindend?
