# Påminn mig!

En native iOS-app för smarta påminnelser byggd med Swift och SwiftUI.

## Funktioner

- **Tidsbaserade påminnelser** med stöd för avancerad upprepning (daglig, veckovis, varannan vecka, månadsvis, anpassad m.m.)
- **Platsbaserade påminnelser** via geofencing - bli påmind när du anländer till en specifik plats, även när appen är stängd
- **Kontextbaserade påminnelser** - triggas vid WiFi-anslutning eller app-öppning
- **Snooze** med smarta förslag (15 min, 1 timme, imorgon bitti, nästa måndag, helgen m.m.)
- **Tysta timmar** - inga notiser under nattid (kritiska påminnelser bryter igenom)
- **Kategorier** - organisera påminnelser med egna kategorier och filtrera
- **Prioritetsnivåer** - normal, hög och kritisk
- **Home screen widget** - se och bocka av dagens påminnelser direkt från hemskärmen
- **Bakgrundsövervakning** - WiFi- och platsbaserade påminnelser fungerar även när appen är helt stängd

## Teknikstack

- **Swift 5.9+** / **SwiftUI**
- **SwiftData** för datalagring
- **CoreLocation** för geofencing och platsbaserade påminnelser
- **UserNotifications** för lokala notiser med åtgärdsknappar
- **BackgroundTasks** (BGTaskScheduler) för WiFi-kontroll i bakgrunden
- **NetworkExtension** (NEHotspotNetwork) för WiFi SSID-identifiering
- **WidgetKit** för home screen widget
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
│   ├── Reminder.swift          # SwiftData-modell med recurrence, location & context triggers
│   ├── QuietHours.swift        # Tysta timmar-konfiguration
│   └── AppTheme.swift          # Färgpalett och designkonstanter
├── Services/
│   ├── NotificationService.swift   # Lokal notishantering med snooze & quiet hours
│   ├── LocationService.swift       # Geofencing, platssökning, bakgrundsövervakning
│   └── ContextService.swift        # WiFi-övervakning, BGTaskScheduler, app-open triggers
├── Views/
│   ├── HomeScreen.swift            # Huvudvy med flikar (Idag/Alla/Klara)
│   ├── CreateReminderScreen.swift  # Skapa/redigera påminnelse
│   ├── SettingsScreen.swift        # Inställningar med tysta timmar
│   ├── SplashScreen.swift          # Splash screen med animerad ikon
│   └── Components/
│       ├── ReminderCard.swift      # Påminnelsekort med swipe-actions
│       ├── DetailSheet.swift       # Detaljvy för påminnelse
│       ├── LocationPicker.swift    # Platssökning och val
│       ├── ContextPicker.swift     # WiFi/App-kontext-väljare
│       ├── RecurrencePicker.swift  # Upprepningsmönster-väljare
│       └── CategoryFilterSheet.swift
├── Utils/
│   ├── DateHelpers.swift       # Datumformatering
│   ├── SnoozeOptions.swift     # Smarta snooze-alternativ
│   └── CommonApps.swift        # Lista med vanliga iOS-appar
└── PaminnMigApp.swift          # App entry point, deep links, notis-delegate

PaminnMigWidget/
└── PaminnMigWidget.swift       # Home screen widget
```

## Bundle ID

`com.freberdev.paminnmig`

## Version

0.1.0

## Licens

Copyright (c) freber.dev
