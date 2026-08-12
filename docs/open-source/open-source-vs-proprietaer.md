# Open-Source vs. proprietäre Software

## Definitionen

### Open-Source-Software

Open-Source-Software (OSS) ist Software, deren Quellcode öffentlich zugänglich ist. Jeder darf den Code einsehen, verwenden, verändern und weiterverbreiten -- unter den Bedingungen der jeweiligen Lizenz (z.B. MIT, GPL, Apache 2.0). Die Entwicklung findet oft in offenen Communities statt, in denen Entwickler weltweit zusammenarbeiten.

**Merkmale:**
- Quellcode ist frei einsehbar und veränderbar
- Kostenlos nutzbar (Lizenzkosten = 0, aber Betriebskosten entstehen trotzdem)
- Community-getriebene Entwicklung mit öffentlichen Issue Trackern und Pull Requests
- Transparenz: Sicherheitslücken können von jedem gefunden und gemeldet werden
- Freiheit: Kein Vendor Lock-in, da man den Code selbst hosten und anpassen kann

**Beispiele:** Linux, PostgreSQL, Node.js, Swift, Git, Docker, HAProxy

### Proprietäre Software (Closed-Source)

Proprietäre Software ist Software, deren Quellcode dem Hersteller gehört und nicht öffentlich zugänglich ist. Die Nutzung wird durch Lizenzen geregelt, die oft Einschränkungen enthalten (z.B. keine Weitergabe, kein Reverse Engineering). Der Hersteller kontrolliert Entwicklung, Updates und Preisgestaltung.

**Merkmale:**
- Quellcode ist nicht einsehbar -- die Software ist eine "Black Box"
- Nutzung erfordert Lizenzen (einmalig, Abo, oder nutzungsbasiert)
- Entwicklung und Roadmap werden vom Hersteller gesteuert
- Support und Wartung durch den Hersteller (SLA-basiert)
- Abhängigkeit vom Hersteller bei Updates, Bugfixes und Kompatibilität

**Beispiele:** Apple Xcode, macOS, App Store Connect, TestFlight, Microsoft Office, Adobe Creative Cloud

## Wesentliche Unterschiede

| Kriterium | Open-Source | Proprietär |
|-----------|-----------|-----------|
| **Kosten** | Keine Lizenzkosten, aber Betriebskosten (Hosting, Wartung, Know-how) | Lizenzgebühren (Abo oder einmalig), dafür oft weniger Eigenaufwand |
| **Transparenz** | Volle Einsicht in den Code, Audit möglich | Black Box, Vertrauen in den Hersteller nötig |
| **Anpassbarkeit** | Unbegrenzt anpassbar, eigene Forks möglich | Nur im Rahmen der vom Hersteller vorgesehenen Schnittstellen |
| **Sicherheit** | "Many eyes"-Prinzip: Mehr Augen finden mehr Bugs. Aber: auch Angreifer sehen den Code | Sicherheit durch Geheimhaltung ("Security by Obscurity"). Aber: weniger externe Prüfung |
| **Support** | Community-Support (Foren, GitHub Issues), kommerzieller Support optional (z.B. Red Hat) | Garantierter Support durch den Hersteller (je nach Lizenz) |
| **Abhängigkeit** | Gering -- bei Unzufriedenheit kann man den Code forken oder selbst pflegen | Hoch -- Wechsel ist teuer und aufwändig (Lock-in) |
| **Innovation** | Schnelle Innovation durch globale Community | Innovation durch dedizierte Entwicklerteams mit klarer Roadmap |
| **Langlebigkeit** | Kann auch ohne ursprünglichen Entwickler weiterleben (Community-Forks) | Stirbt, wenn der Hersteller den Support einstellt |

## Hybridmodelle

In der Praxis ist die Grenze oft fließend. Viele Unternehmen nutzen ein **Open-Core-Modell**: Der Kern der Software ist Open-Source, aber Premium-Features oder gehostete Versionen sind proprietär (z.B. GitLab CE vs. GitLab EE, oder Docker CE vs. Docker Desktop).

Auch unser Projekt nutzt diesen Mix: Die gesamte Eigenentwicklung (Backend, iOS-App) ist auf GitHub gehostet, während wir proprietäre Tools von Apple (Xcode, TestFlight, App Store Connect) für die Distribution nutzen.
