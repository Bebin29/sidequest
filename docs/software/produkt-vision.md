# Produkt-Vision: Sidequest

## Vision Statement

**Sidequest** macht es einfach, besondere Orte mit Freunden zu teilen und neue Lieblingsorte in der Umgebung zu entdecken -- persönlich kuratiert statt algorithmusgesteuert.

## Problem

Bestehende Plattformen wie Google Maps oder Yelp setzen auf Masse: Tausende anonyme Bewertungen, bezahlte Platzierungen und algorithmische Empfehlungen. Nutzer vertrauen aber am meisten den Empfehlungen von Freunden -- und genau dafür gibt es kein dediziertes Tool. Empfehlungen gehen in Chat-Verläufen unter, Screenshots werden vergessen, und geteilte Google-Maps-Listen sind umständlich.

## Lösung

Eine mobile App, in der Nutzer Orte (Cafés, Restaurants, Parks, Aussichtspunkte, ...) anlegen, bewerten und gezielt mit ihrem Freundeskreis teilen. Der Feed zeigt ausschließlich Orte von Freunden -- sortiert nach Nähe zum aktuellen Standort.

## Zielgruppe

Junge Erwachsene (18-30), die gerne neue Orte erkunden und Wert auf persönliche Empfehlungen legen. Nutzer, die soziale Netzwerke für Entdeckungen statt für Content-Konsum verwenden wollen.

## Kernfunktionen

| Feature | Beschreibung |
|---------|-------------|
| **Location Sharing** | Orte mit Foto, Beschreibung und Kategorie anlegen und teilen |
| **Freunde-Feed** | Personalisierter Feed mit Orten der eigenen Freunde, sortiert nach Entfernung |
| **Karten-Ansicht** | Alle Orte auf einer interaktiven Karte mit Kategorie-Filtern |
| **Bewertungen & Kommentare** | Orte bewerten und kommentieren |
| **Freundschaftssystem** | Freunde hinzufügen, Vorschläge basierend auf gemeinsamen Kontakten |
| **Push-Benachrichtigungen** | Info wenn Freunde neue Orte teilen |
| **Admin-Dashboard** | Server-Monitoring und Nutzerverwaltung |

## Abgrenzung

Sidequest ist **kein** allgemeines Bewertungsportal. Es gibt keine öffentlichen Rankings, keine gesponserten Einträge und keinen Discover-Algorithmus. Die App lebt vom eigenen sozialen Netzwerk -- die einzige Datenquelle sind echte Freunde.

## Technische Eckpfeiler

- **iOS-App** (SwiftUI, iOS 26)
- **REST-API** (Node.js, pure `http`-Module)
- **PostgreSQL** als Datenbank mit Geo-Queries (Haversine-Distanz)
- **Apple Sign-In** für Authentifizierung
- **CI/CD** via GitHub Actions mit automatisiertem Testing und Deployment (TestFlight + Server)

## Erfolgskriterien

- Nutzer können innerhalb von 30 Sekunden einen Ort anlegen und teilen
- Der Feed zeigt relevante Orte von Freunden nach Nähe
- Die App ist über TestFlight für Tester verfügbar
- Server und Datenbank werden über ein integriertes Monitoring überwacht
