# Planungs- und Schätzmethode

## Verwendete Methode: T-Shirt-Sizing

Neben dem GitHub Project Board als Planungstool haben wir **T-Shirt-Sizing** als Schätzmethode für den Aufwand unserer Issues verwendet.

### Funktionsweise

Jedes Issue im Backlog wird vom Team gemeinsam in eine von vier Größen eingeordnet:

| Größe | Bedeutung | Beispiel |
|-------|-----------|---------|
| **S** (Small) | < 1 Stunde, klar definiert, kein Risiko | Bugfix, Label hinzufügen, Text ändern |
| **M** (Medium) | 1–3 Stunden, bekannte Technologie | Neuen API-Endpoint bauen, View erstellen |
| **L** (Large) | 3–8 Stunden, eventuell Abhängigkeiten | Freundschaftssystem, Feed-Algorithmus |
| **XL** (Extra Large) | > 8 Stunden, unbekannte Technologie oder hohes Risiko | CI/CD-Pipeline aufsetzen, Push Notifications |

### Ablauf im Sprint Planning

1. Product Owner stellt die Issues für den Sprint vor
2. Jedes Teammitglied nennt gleichzeitig seine Schätzung (S/M/L/XL)
3. Bei Abweichungen wird kurz diskutiert -- die Person mit der höchsten Schätzung erklärt ihr Risiko
4. Das Team einigt sich auf eine Größe
5. XL-Issues werden nach Möglichkeit in mehrere M/L-Issues aufgeteilt

### Bewertung: War es ein Zugewinn?

**Ja.** T-Shirt-Sizing war für unser Team ein klarer Zugewinn, aus folgenden Gründen:

- **Niedrige Einstiegshürde**: Keine Einarbeitung in Story Points oder Planning Poker nötig. Jeder konnte sofort mitmachen.
- **Schnelle Durchführung**: Die Schätzung aller Sprint-Issues dauerte ca. 10–15 Minuten. Bei Story Points hätte das deutlich länger gedauert.
- **XL als Warnsignal**: Wenn ein Issue als XL eingestuft wurde, haben wir es immer aufgeteilt. Das hat uns vor zu großen, unüberschaubaren Tasks bewahrt.
- **Gute Trefferquote**: Die meisten S- und M-Issues wurden im geschätzten Zeitrahmen fertig. Bei L-Issues gab es gelegentlich Abweichungen, was aber akzeptabel war.

**Einschränkung**: Für größere Teams oder längere Projekte wäre Planning Poker mit Story Points wahrscheinlich genauer, weil es feinere Abstufungen erlaubt. Für ein 4-Personen-Team mit 1-Wochen-Sprints war T-Shirt-Sizing aber genau richtig.
