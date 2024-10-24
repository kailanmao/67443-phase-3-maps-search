//
// Created for MyTrips
// by  Stewart Lynch on 2023-12-31
//
// Follow me on Mastodon: @StewartLynch@iosdev.space
// Follow me on Threads: @StewartLynch (https://www.threads.net)
// Follow me on X: https://x.com/StewartLynch
// Follow me on LinkedIn: https://linkedin.com/in/StewartLynch
// Subscribe on YouTube: https://youTube.com/@StewartLynch
// Buy me a ko-fi:  https://ko-fi.com/StewartLynch


import SwiftUI
import MapKit
import SwiftData

struct TripMapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var visibleRegion: MKCoordinateRegion?
    @Environment(LocationManager.self) var locationManager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Query private var listPlacemarks: [MTPlacemark]
  let polygonCoordinates = [
          CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
          CLLocationCoordinate2D(latitude: 37.7768, longitude: -122.4175),
          CLLocationCoordinate2D(latitude: 37.7779, longitude: -122.4165),
          CLLocationCoordinate2D(latitude: 37.7784, longitude: -122.4180),
          CLLocationCoordinate2D(latitude: 37.7773, longitude: -122.4196)
      ]
  let polylineCoordinates = [
          CLLocationCoordinate2D(latitude: 38.7749, longitude: -122.4194),
          CLLocationCoordinate2D(latitude: 38.7768, longitude: -122.4175),
          CLLocationCoordinate2D(latitude: 38.7779, longitude: -122.4165),
          CLLocationCoordinate2D(latitude: 38.7784, longitude: -122.4180),
          CLLocationCoordinate2D(latitude: 38.7773, longitude: -122.4196)
      ]

    
    // Search
    @State private var searchText = ""
    @FocusState private var searchFieldFocus: Bool
    @Query(filter: #Predicate<MTPlacemark> {$0.destination == nil}) private var searchPlacemarks: [MTPlacemark]
    
    @State private var selectedPlacemark: MTPlacemark?
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedPlacemark) {
            UserAnnotation()
            ForEach(listPlacemarks) { placemark in
                Group {
                    if placemark.destination != nil {
                        Marker(coordinate: placemark.coordinate) {
                            Label(placemark.name, systemImage: "star")
                        }
                        .tint(.yellow)
                    } else {
                        Marker(placemark.name, coordinate: placemark.coordinate)
                    }
                }.tag(placemark)
            }
          Marker(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
            Label("polygon", systemImage: "star")
          }
          .tint(.yellow)
          Marker(coordinate: CLLocationCoordinate2D(latitude: 38.7749, longitude: -122.4194)) {
            Label("polyline", systemImage: "star")
          }
          .tint(.blue)
          MapPolygon(coordinates: polygonCoordinates)
                                  .stroke(Color.blue, lineWidth: 3)
          MapPolyline(coordinates: polylineCoordinates)
                                  .stroke(Color.red, lineWidth: 3)
        }
        .sheet(item: $selectedPlacemark) { selectedPlacemark in
            LocationDetailView(selectedPlacemark: selectedPlacemark)
                .presentationDetents([.height(450)])
        }
        .onMapCameraChange{ context in
            visibleRegion = context.region
        }
        .onAppear {
            updateCameraPosition()
        }
        .mapControls{
            MapUserLocationButton()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                VStack {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($searchFieldFocus)
                        .overlay(alignment: .trailing) {
                            if searchFieldFocus {
                                Button {
                                    searchText = ""
                                    searchFieldFocus = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .offset(x: -5)
                            }
                        }
                        .onSubmit {
                            Task {
                                await MapManager.searchPlaces(
                                    modelContext,
                                    searchText: searchText,
                                    visibleRegion: visibleRegion
                                )
                                searchText = ""
                            }
                        }
                }
                .padding()
                VStack {
                    if !searchPlacemarks.isEmpty {
                        Button {
                            MapManager.removeSearchResults(modelContext)
                        } label: {
                            Image(systemName: "mappin.slash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding()
                .buttonBorderShape(.circle)
            }
        }
    }
    
    func updateCameraPosition() {
        if let userLocation = locationManager.userLocation {
            let userRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.15,
                    longitudeDelta: 0.15
                )
            )
            withAnimation {
                cameraPosition = .region(userRegion)
            }
        }
    }
}

#Preview {
    TripMapView()
        .environment(LocationManager())
        .modelContainer(Destination.preview)
}
