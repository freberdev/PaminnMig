import SwiftUI
import CoreLocation

struct LocationPicker: View {
    @Binding var locationTrigger: LocationTrigger?
    @State private var searchText = ""
    @State private var radiusText = "200"
    @State private var searchResults: [PlaceSearchResult] = []
    @State private var isSearching = false
    @State private var isLoadingLocation = false
    @State private var selectedName: String?
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "location")
                    .foregroundColor(AppTheme.accentColor)
                Text("Platsbaserad påminnelse")
                    .font(.system(size: 16, weight: .semibold))
            }

            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Sök adress eller plats...", text: $searchText)
                    .font(.system(size: 15))
                    .onChange(of: searchText) { _, newValue in
                        onSearchChanged(newValue)
                    }
                if !searchText.isEmpty {
                    Button { searchText = ""; searchResults = []; selectedName = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.subtleBorder))

            // Search results
            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults) { result in
                        Button { selectResult(result) } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.accentColor.opacity(0.06))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.accentColor)
                                    )
                                VStack(alignment: .leading) {
                                    Text(result.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                    if !result.address.isEmpty {
                                        Text(result.address)
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        if result.id != searchResults.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.subtleBorder))
            }

            // Current location button
            if isLoadingLocation {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                Button { useCurrentLocation() } label: {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text("Använd nuvarande plats")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.subtleBorder))
                }
            }

            // Selected location
            if let name = selectedName, latitude != nil {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.successColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(latitude!.formatted(.number.precision(.fractionLength(5)))), \(longitude!.formatted(.number.precision(.fractionLength(5))))")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.successColor.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.successColor.opacity(0.16)))
            }

            // Radius
            HStack(spacing: 8) {
                Image(systemName: "wave.3.left")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                Text("Radie:")
                    .font(.system(size: 14))
                TextField("200", text: $radiusText)
                    .keyboardType(.numberPad)
                    .frame(width: 70)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.subtleBorder))
                    .onChange(of: radiusText) { _, _ in updateTrigger() }
                Text("meter")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.subtleBorder))
        .onAppear { loadExisting() }
    }

    private func loadExisting() {
        guard let lt = locationTrigger else { return }
        selectedName = lt.placeName
        searchText = lt.placeName ?? ""
        radiusText = "\(Int(lt.radiusMeters))"
        latitude = lt.latitude
        longitude = lt.longitude
    }

    private func onSearchChanged(_ query: String) {
        searchTask?.cancel()
        // Clear previous selection when user types a new query
        if query != selectedName {
            latitude = nil
            longitude = nil
            selectedName = nil
            locationTrigger = nil
        }
        guard query.trimmingCharacters(in: .whitespaces).count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            let results = await LocationService.shared.searchPlaces(query: query)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }

    private func selectResult(_ result: PlaceSearchResult) {
        latitude = result.latitude
        longitude = result.longitude
        selectedName = result.name
        searchText = result.name
        searchResults = []
        updateTrigger()
    }

    private func useCurrentLocation() {
        isLoadingLocation = true
        LocationService.shared.requestPermissions()
        Task {
            if let coord = await LocationService.shared.getCurrentPosition() {
                await MainActor.run {
                    latitude = coord.latitude
                    longitude = coord.longitude
                    selectedName = "Min position"
                    searchText = "Min position"
                    isLoadingLocation = false
                    updateTrigger()
                }
            } else {
                await MainActor.run { isLoadingLocation = false }
            }
        }
    }

    private func updateTrigger() {
        guard let lat = latitude, let lon = longitude else { return }
        let radius = Double(radiusText) ?? 200
        locationTrigger = LocationTrigger(
            latitude: lat,
            longitude: lon,
            radiusMeters: radius,
            placeName: selectedName
        )
    }
}
