# Sequenzdiagramm: Continuous-Delivery-Pipeline

## Gesamtübersicht

Das Diagramm zeigt den vollständigen Weg eines Commits von der lokalen Entwicklungsumgebung durch CI (Qualitätssicherung) bis zum Deployment in die Produktivumgebung -- für iOS und Backend.

```mermaid
sequenceDiagram
    actor Dev as Entwickler
    participant Local as Lokale Umgebung
    participant GH as GitHub (Remote)
    participant CI as GitHub Actions (CI)
    participant TF as Apple TestFlight
    participant Srv as Produktionsserver<br/>(217.x.x.x)

    note over Dev, Srv: Protokolle: HTTPS (Git, GitHub API), SSH (Server-Deploy), TLS (App Store Connect API)

    %% ── Entwicklung ──
    rect rgb(230, 245, 255)
        note right of Dev: Entwicklung (lokal)
        Dev ->> Local: Code schreiben / ändern
        Dev ->> Local: git add & git commit
        Dev ->> GH: git push (HTTPS)
    end

    %% ── Pull Request / Branch ──
    rect rgb(255, 245, 230)
        note right of GH: Code Review & CI-Trigger
        alt Push auf Feature-Branch (PR)
            Dev ->> GH: Pull Request erstellen (HTTPS)
            GH -->> CI: Webhook: pull_request event
        else Push auf develop / main
            GH -->> CI: Webhook: push event
        end
    end

    %% ── iOS CI ──
    rect rgb(235, 255, 235)
        note right of CI: Qualitätssicherung iOS
        par iOS Build & Test
            CI ->> CI: Checkout Code
            CI ->> CI: Xcode selektieren
            CI ->> CI: xcodebuild build (iPhone 16 Simulator)
            CI ->> CI: xcodebuild test (Unit Tests, Swift Testing)
            CI -->> GH: Testergebnis melden (HTTPS)
        and SwiftLint
            CI ->> CI: Checkout Code
            CI ->> CI: SwiftLint installieren (brew)
            CI ->> CI: swiftlint lint (Code-Stil prüfen)
            CI -->> GH: Lint-Ergebnis melden (HTTPS)
        end
    end

    %% ── Backend CI ──
    rect rgb(245, 235, 255)
        note right of CI: Qualitätssicherung Backend
        CI ->> CI: Checkout Code
        CI ->> CI: Node.js 20 einrichten
        CI ->> CI: npm ci (Abhängigkeiten installieren)
        CI ->> CI: npm test (Jest -- Unit & Integrationstests)
        CI -->> GH: Testergebnis melden (HTTPS)
    end

    %% ── Ergebnis ──
    rect rgb(255, 235, 235)
        note right of GH: Ergebnisprüfung
        alt Tests fehlgeschlagen
            GH -->> Dev: Status: failed (HTTPS / E-Mail)
            Dev ->> Local: Fehler beheben
            Dev ->> GH: Erneuter Push (HTTPS)
        else Tests bestanden + PR
            GH -->> Dev: Status: passed (HTTPS)
            Dev ->> GH: PR mergen nach main (HTTPS)
        end
    end

    %% ── CD: Backend Deploy ──
    rect rgb(255, 250, 220)
        note right of CI: Continuous Deployment (nur main)
        GH -->> CI: Webhook: push auf main
        CI ->> CI: Backend-Tests erneut ausführen
        CI ->> Srv: SSH-Verbindung (Port 443, Key Auth)
        CI ->> Srv: bash /opt/sidequest/deploy.sh
        Srv ->> Srv: Docker Container neu bauen & starten
        Srv -->> CI: Deploy erfolgreich
    end

    %% ── CD: iOS Deploy ──
    rect rgb(220, 250, 255)
        note right of CI: Continuous Deployment iOS (nur main)
        CI ->> CI: Signing-Zertifikat installieren
        CI ->> CI: Provisioning Profile installieren
        CI ->> CI: xcodebuild archive (Release)
        CI ->> CI: App Store Connect API Key erstellen
        CI ->> CI: xcodebuild -exportArchive (IPA)
        CI ->> TF: xcrun altool --upload-app (TLS)
        TF -->> Dev: Build verfügbar in TestFlight
    end
```

## Verwendete Protokolle

| Protokoll | Einsatzort | Zweck |
|-----------|-----------|-------|
| **HTTPS** | Git Push/Pull, GitHub API, Webhooks | Quellcode-Transfer, CI-Trigger, Statusmeldungen |
| **SSH** (Port 443) | Backend-Deployment | Sichere Verbindung zum Produktionsserver, Key-basierte Authentifizierung |
| **TLS** | App Store Connect API | Upload der IPA-Datei zu TestFlight (altool + API Key) |

## Qualitätssicherungsmaßnahmen in der Pipeline

| Nr. | Maßnahme | Typ | Automatisiert |
|-----|----------|-----|---------------|
| 1 | **Unit Tests (iOS)** | Swift Testing Framework | Ja (CI) |
| 2 | **Unit & Integrationstests (Backend)** | Jest | Ja (CI) |
| 3 | **SwiftLint** | Statische Code-Analyse | Ja (CI) |
| 4 | **Issue Templates** | Strukturierte Bug-/Feature-Reports | Ja (GitHub) |
| 5 | **Branch-Strategie** | main / develop / feature/* | Organisatorisch |
| 6 | **Code Review** | Pull Requests vor Merge | Organisatorisch |
