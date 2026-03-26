# Påminn mig!

En native iOS-app för smarta påminnelser byggd med Swift och SwiftUI. Helt på svenska.

## Funktioner

### Tidsbaserade påminnelser
Skapa påminnelser med valfri tid och datum. Stöd för avancerad upprepning:
- Dagligen, vardagar, helger
- Veckovis eller varannan vecka
- Månadsvis (specifik dag eller sista dagen i månaden)
- Årligen
- Anpassad: t.ex. var 4:e timme på utvalda veckodagar, med max antal per dag och valfritt slutdatum

### Platsbaserade påminnelser
Bli påmind när du anländer till en specifik plats via geofencing. Sök efter platser direkt i appen med kartintegration. Fungerar även i bakgrunden när appen är stängd.

### Snooze
Snooza påminnelser med smarta förslag anpassade efter tid på dygnet:
- 15 min, 30 min, 1 timme, 3 timmar
- "Senare idag", "Ikväll", "Imorgon bitti", "Nästa måndag", "Helgen"
- Eget datum och tid via datumväljare

### Tysta timmar
Konfigurera en tidsperiod (t.ex. 22:00–07:00) då inga notiser skickas. Kritiska påminnelser bryter igenom tysta timmar.

### Kategorier
Tagga påminnelser med egna kategorier. Filtrera listan efter kategori. Ta bort kategorier du inte längre behöver.

### Prioritet och kritiska påminnelser
Tre prioritetsnivåer: normal, hög och kritisk. Kritiska påminnelser markeras tydligt i listan och bryter igenom tysta timmar med iOS critical alerts.

### Notiser med åtgärder
Direkt från notisen kan du:
- Markera som klar
- Snooza 15 min, 1 timme eller till imorgon

### Övrig funktionalitet
- **Flikar**: Idag / Alla / Klara för enkel överblick
- **Detaljvy** med fullständig info om varje påminnelse
- **Swipe-actions** för snabb redigering och radering
- **Förfallna påminnelser** markeras visuellt i rött
- **Splash screen** med animerad app-ikon

## Teknikstack

- **Swift 5.9+** / **SwiftUI**
- **SwiftData** för lokal datalagring
- **CoreLocation** för geofencing och platsbaserade påminnelser
- **UserNotifications** för lokala notiser med åtgärdsknappar och critical alerts
- **MapKit** (MKLocalSearch) för platssökning

## Krav

- iOS 17.0+
- Xcode 16.0+

## Bygge

Projektet använder [XcodeGen](https://github.com/yonaskolb/XcodeGen) för att generera Xcode-projektet.

```bash
# Installera xcodegen om det saknas
brew install xcodegen

# Generera Xcode-projektet
xcodegen generate

# Öppna i Xcode
open PaminnMig.xcodeproj
```

## Projektstruktur

```
PaminnMig/
├── Models/
│   ├── Reminder.swift          # SwiftData-modell med recurrence & location triggers
│   ├── QuietHours.swift        # Tysta timmar-konfiguration
│   └── AppTheme.swift          # Färgpalett och designkonstanter
├── Services/
│   ├── NotificationService.swift   # Lokal notishantering med snooze & quiet hours
│   └── LocationService.swift       # Geofencing, platssökning, bakgrundsövervakning
├── Views/
│   ├── HomeScreen.swift            # Huvudvy med flikar (Idag/Alla/Klara)
│   ├── CreateReminderScreen.swift  # Skapa/redigera påminnelse
│   ├── SettingsScreen.swift        # Inställningar med tysta timmar
│   ├── SplashScreen.swift          # Splash screen med animerad ikon
│   └── Components/
│       ├── ReminderCard.swift      # Påminnelsekort med swipe-actions
│       ├── DetailSheet.swift       # Detaljvy för påminnelse
│       ├── LocationPicker.swift    # Platssökning och val
│       ├── RecurrencePicker.swift  # Upprepningsmönster-väljare
│       └── CategoryFilterSheet.swift
├── Utils/
│   ├── DateHelpers.swift       # Datumformatering
│   └── SnoozeOptions.swift     # Smarta snooze-alternativ
└── PaminnMigApp.swift          # App entry point, notis-delegate
```

## Bundle ID

`com.freberdev.paminnmig`

## Version

0.1.0

## Licens

Copyright (c) freber.dev
