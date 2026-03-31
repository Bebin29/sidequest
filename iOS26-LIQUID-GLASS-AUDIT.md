# iOS 26 Liquid Glass Audit - Sidequest

Generated: 2026-04-01

## Summary

| Kategorie | Anzahl |
|-----------|--------|
| Auto-Upgrades (nur recompile) | 14 |
| Direkte Replacements | 12 |
| Zentrale Upgrades (GlassModifiers.swift) | 4 Funktionen |
| Redesigns noetig | 3 |
| Zu loeschende Dateien | 1 (VisualEffectBlur.swift) |
| Anti-Patterns | 1 |

---

## Priority 1: Auto-Upgrades (recompile mit Xcode 26 SDK)

Diese bekommen automatisch Liquid Glass — kein Code-Aenderung noetig:

| Element | Datei | Zeile | Hinweis |
|---------|-------|-------|---------|
| `TabView` | Home.swift | 24 | Tab Bar wird automatisch Glass |
| `NavigationStack` | Home.swift | 26, 40, 46, 56, 70 | Nav Bars werden Glass |
| `NavigationStack` | SettingsView.swift | 19 | Nav Bar wird Glass |
| `NavigationStack` | FriendsView.swift | 23, 396 | Nav Bar wird Glass |
| `NavigationStack` | PlaceSearchView.swift | 25 | Nav Bar wird Glass |
| `NavigationStack` | ProfileShareCardView.swift | 118 | Nav Bar wird Glass |
| `NavigationStack` | OnboardingView.swift | 21 | Nav Bar wird Glass |
| `NavigationStack` | AdminView.swift | 12 | Nav Bar wird Glass |
| `NavigationStack` | LocationFilterView.swift | 23 | Nav Bar wird Glass |
| `NavigationStack` | RingCodeScannerView.swift | 27 | Nav Bar wird Glass |
| `.toolbar` | diverse Views | diverse | Toolbar wird Glass |
| `.sheet` / `.fullScreenCover` | diverse Views | diverse | Sheet-Chrome wird Glass |
| `.pickerStyle(.segmented)` | LocationFilterView.swift | 71 | Segmented Control wird Glass |

### Moegliche Konflikte bei Auto-Upgrade

| Datei | Zeile | Code | Problem |
|-------|-------|------|---------|
| RingCodeScannerView.swift | 109 | `.toolbarBackground(.hidden, for: .navigationBar)` | Koennte Auto-Glass der Nav Bar blockieren — pruefen ob noch gewuenscht |

---

## Priority 2: Zentrale Upgrades — GlassModifiers.swift

**Dies ist der wichtigste Schritt.** Die Datei `GlassModifiers.swift` ist als zentrale Stelle fuer Glass-Styling konzipiert. Alle 4 Modifier-Funktionen + 2 ButtonStyles + GlassGroup muessen auf native iOS 26 APIs umgestellt werden.

### adaptiveGlass (Zeile 55-60)

**Aktuell:**
```swift
func adaptiveGlass(in shape: ...) -> some View {
    self
        .background(.ultraThinMaterial, in: shape)
        .modifier(LiquidGlassChrome(shape: shape, intensity: 1.0))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
}
```

**iOS 26 Replacement:**
```swift
func adaptiveGlass(in shape: some Shape = RoundedRectangle(cornerRadius: 16, style: .continuous)) -> some View {
    self.glassEffect(.regular, in: shape)
}
```

**Genutzt in:** UserProfileView (Z. 185, 302), MyProfileView (Z. 191), LocationDetailView (Z. 408)

---

### adaptiveClearGlass (Zeile 62-67)

**Aktuell:** `.ultraThinMaterial.opacity(0.5)` + Chrome + Shadow

**iOS 26 Replacement:**
```swift
func adaptiveClearGlass(in shape: some Shape = ...) -> some View {
    self.glassEffect(.clear, in: shape)
}
```

---

### adaptiveInteractiveGlass (Zeile 69-74)

**Aktuell:** `.ultraThinMaterial` + Chrome (intensity 1.2) + Shadow

**iOS 26 Replacement:**
```swift
func adaptiveInteractiveGlass(in shape: some Shape = ...) -> some View {
    self.glassEffect(.regular.interactive(), in: shape)
}
```

**Genutzt in:** LocationDetailView (Z. 164, 182, 207, 232, 399)

---

### adaptiveTintedGlass (Zeile 76-82)

**Aktuell:** `color.opacity(0.5)` + `.ultraThinMaterial` + Chrome + Shadow

**iOS 26 Replacement:**
```swift
func adaptiveTintedGlass(_ color: Color, in shape: some Shape = ...) -> some View {
    self.glassEffect(.regular.tint(color), in: shape)
}
```

**Genutzt in:** LocationDetailView (Z. 194)

---

### GlassButtonStyle (Zeile 103-115)

**iOS 26 Replacement:** `.buttonStyle(.glass)`

**Genutzt in:** UserProfileView (Z. 209)

---

### GlassProminentButtonStyle (Zeile 117-130)

**iOS 26 Replacement:** `.buttonStyle(.glassProminent)`

**Genutzt in:** UserProfileView (Z. 176, 198)

---

### GlassGroup (Zeile 87-99)

**iOS 26 Replacement:** `GlassEffectContainer(spacing:)`

**Genutzt in:** LocationDetailView (Z. 154, 366)

---

### LiquidGlassChrome (Zeile 14-49)

**iOS 26:** Komplett loeschen. Native Glass hat echte Refraktion und Specular-Highlights.

---

## Priority 3: Direkte Replacements (ausserhalb GlassModifiers)

Stellen die `.ultraThinMaterial` oder `VisualEffectBlur` direkt nutzen statt ueber die Modifier:

### MainView.swift — FAB Button (Zeile 125-152)

**Aktuell:** Manuell aufgebauter Glass-Button mit Circle + `.fill(.ultraThinMaterial)` + Gradient-Overlay + Shadow

**iOS 26 Replacement:**
```swift
Image(systemName: "plus")
    .font(.body.weight(.semibold))
    .foregroundStyle(Theme.textPrimary)
    .frame(width: 40, height: 40)
    .glassEffect(.regular.interactive(), in: .circle)
```

---

### Karte.swift — Map Controls (Zeile 89-97)

**Aktuell:** `RoundedRectangle.fill(.ultraThinMaterial)` + Stroke + Shadow

**iOS 26 Replacement:**
```swift
.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30))
```

---

### Karte.swift — Loading Indicator (Zeile 129)

**Aktuell:** `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))`

**iOS 26 Replacement:**
```swift
.glassEffect(.regular, in: .rect(cornerRadius: 12))
```

---

### FeedCarouselCard.swift — Bottom Blur Overlay (Zeile 50-68)

**Aktuell:** `Rectangle().fill(.ultraThinMaterial)` mit Gradient-Mask

**iOS 26:** Dies ist ein Content-Layer-Effekt (Text-Lesbarkeit ueber Bild). Glass ist hier **nicht ideal** weil es fuer Navigation-Layer gedacht ist. Besser: behalten oder auf `.glassEffect(.clear)` mit Mask testen.

---

### LocationDetailView.swift — Content Background Blur (Zeile 93-109)

**Aktuell:** `Rectangle().fill(.ultraThinMaterial)` mit Gradient-Mask

**iOS 26:** Gleiche Situation wie FeedCarouselCard — Content-Layer. `.glassEffect(.clear)` testen oder behalten.

---

### FriendsView.swift — Search Bar (Zeile 401-405)

**Aktuell:** `VisualEffectBlur(blurStyle: .systemUltraThinMaterial).clipShape(RoundedRectangle(...))`

**iOS 26 Replacement:**
```swift
TextField("Username suchen...", text: $searchText)
    .padding()
    .glassEffect(.regular, in: .rect(cornerRadius: 20))
```

---

### PlaceSearchView.swift — Search Bar (Zeile 40-44)

**Aktuell:** `VisualEffectBlur(blurStyle: .systemUltraThinMaterial).clipShape(RoundedRectangle(...))`

**iOS 26 Replacement:**
```swift
TextField("Ort suchen", text: $searchText)
    .padding()
    .glassEffect(.regular, in: .rect(cornerRadius: Radius.medium))
```

---

## Priority 4: Datei loeschen

### VisualEffectBlur.swift

Die gesamte Datei `Views/VisualEffectBlur.swift` (UIViewRepresentable-Wrapper fuer UIBlurEffect) wird nicht mehr benoetigt wenn alle Stellen auf native `.glassEffect()` umgestellt sind.

**Genutzt in:**
- FriendsView.swift (Z. 403) 
- PlaceSearchView.swift (Z. 42)
- AddLocationFormView.swift (Z. 91 — bereits auskommentiert)

---

## Priority 5: Neue Moeglichkeiten

Stellen die aktuell kein Glass haben, aber davon profitieren koennten:

| Datei | Was | Vorschlag |
|-------|-----|-----------|
| SettingsView.swift | Cards mit `.clipShape(RoundedRectangle)` | `.glassEffect(.regular, in: .rect(cornerRadius: Radius.card))` |
| TagBadge.swift | `color.opacity(0.6)` Fill | `.glassEffect(.regular.tint(color), in: .capsule)` |
| RingCodeScannerView.swift | `.background(.black.opacity(0.6))` Button | `.glassEffect(.regular.interactive(), in: .capsule)` |
| Home.swift | TabView | `.tabBarMinimizeBehavior(.onScrollDown)` fuer collapsible Glass Tab |
| Home.swift | TabView | `.tabViewBottomAccessory { }` fuer Content ueber Tab Bar |
| diverse ScrollViews | Scroll-Kante bei Glass Bars | `.scrollEdgeEffectStyle(.soft, for: .top)` |

---

## Anti-Patterns zu beachten

| Problem | Wo | Empfehlung |
|---------|----|------------|
| Manuelle Shadows bei Glass-Elementen | GlassModifiers.swift (alle 4 Funktionen) | Entfernen — native Glass handhabt Tiefe selbst |
| `.clipShape` + Material | diverse | Ersetzen durch `.glassEffect(in: shape)` — shape ist Parameter von glassEffect |

---

## Empfohlene Migrations-Reihenfolge

1. **Branch erstellen** — `ios26-liquid-glass` (basierend auf `ui-ole-2`)
2. **GlassModifiers.swift komplett umschreiben** — das deckt ~60% der Glass-Stellen ab (alle die `adaptiveGlass`, `adaptiveInteractiveGlass`, etc. nutzen)
3. **Direkte Material-Stellen ersetzen** — MainView FAB, Karte Controls, Karte Loading
4. **VisualEffectBlur-Stellen ersetzen** — FriendsView, PlaceSearchView Search Bars
5. **VisualEffectBlur.swift loeschen**
6. **Auto-Upgrade testen** — Recompile, pruefen ob TabBar/NavBar/Sheets korrekt aussehen
7. **toolbarBackground pruefen** — RingCodeScannerView
8. **Neue Features hinzufuegen** — tabBarMinimizeBehavior, scrollEdgeEffectStyle, etc.
9. **Accessibility testen** — Reduce Transparency + Increase Contrast
10. **Dark Mode testen** — Glass sieht in Light/Dark sehr unterschiedlich aus
