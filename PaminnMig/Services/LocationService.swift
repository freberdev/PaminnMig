import Foundation
import CoreLocation
import MapKit
import SwiftData

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private static let geofenceTitlesKey = "geofence_titles"

    var onGeofenceTriggered: ((String) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permissions

    func requestPermissions() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }

    var hasPermission: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    // MARK: - Current Position

    func getCurrentPosition() async -> CLLocationCoordinate2D? {
        guard hasPermission else { return nil }
        locationManager.requestLocation()
        return await withCheckedContinuation { continuation in
            currentLocationContinuation = continuation
        }
    }

    private var currentLocationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    // MARK: - Geofencing

    func registerGeofence(for reminder: Reminder) {
        guard let trigger = reminder.locationTrigger,
              CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }

        // Store title for background notification
        var titles = UserDefaults.standard.dictionary(forKey: Self.geofenceTitlesKey) as? [String: String] ?? [:]
        titles[reminder.id] = reminder.title
        UserDefaults.standard.set(titles, forKey: Self.geofenceTitlesKey)

        let coordinate = CLLocationCoordinate2D(latitude: trigger.latitude, longitude: trigger.longitude)
        let radius = min(trigger.radiusMeters, locationManager.maximumRegionMonitoringDistance)
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: reminder.id)
        region.notifyOnEntry = true
        region.notifyOnExit = false

        locationManager.startMonitoring(for: region)
    }

    func unregisterGeofence(for reminderId: String) {
        var titles = UserDefaults.standard.dictionary(forKey: Self.geofenceTitlesKey) as? [String: String] ?? [:]
        titles.removeValue(forKey: reminderId)
        UserDefaults.standard.set(titles, forKey: Self.geofenceTitlesKey)

        for region in locationManager.monitoredRegions {
            if region.identifier == reminderId {
                locationManager.stopMonitoring(for: region)
                break
            }
        }
    }

    func unregisterAll() {
        UserDefaults.standard.removeObject(forKey: Self.geofenceTitlesKey)
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

    func registerAllGeofences(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { !$0.isCompleted && $0.typeRaw == 1 })
        guard let reminders = try? modelContext.fetch(descriptor) else { return }
        for reminder in reminders {
            registerGeofence(for: reminder)
        }
    }

    // MARK: - Place Search (MKLocalSearch)

    func searchPlaces(query: String) async -> [PlaceSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems.prefix(8).map { item in
                let name = item.name ?? query
                var addressParts: [String] = []
                if let thoroughfare = item.placemark.thoroughfare {
                    var street = thoroughfare
                    if let sub = item.placemark.subThoroughfare {
                        street = "\(street) \(sub)"
                    }
                    addressParts.append(street)
                }
                if let postal = item.placemark.postalCode { addressParts.append(postal) }
                if let locality = item.placemark.locality { addressParts.append(locality) }
                if let country = item.placemark.country { addressParts.append(country) }

                return PlaceSearchResult(
                    name: name,
                    address: addressParts.joined(separator: ", "),
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circular = region as? CLCircularRegion else { return }
        showGeofenceNotification(regionId: circular.identifier)
        onGeofenceTriggered?(circular.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let continuation = currentLocationContinuation {
            currentLocationContinuation = nil
            continuation.resume(returning: locations.first?.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let continuation = currentLocationContinuation {
            currentLocationContinuation = nil
            continuation.resume(returning: nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Geofence monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }

    private func showGeofenceNotification(regionId: String) {
        let titles = UserDefaults.standard.dictionary(forKey: Self.geofenceTitlesKey) as? [String: String] ?? [:]
        let title = titles[regionId] ?? "Påminn mig!"

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Du har kommit till platsen för den här påminnelsen"
        content.sound = .default
        content.categoryIdentifier = "reminder"
        content.userInfo = ["reminderId": regionId]

        let request = UNNotificationRequest(
            identifier: "geofence_\(regionId)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

struct PlaceSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}
