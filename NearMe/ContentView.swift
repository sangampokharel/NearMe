//
//  ContentView.swift
//  NearMe
//
//  Created by EKbana on 13/05/2025.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var query = ""
    @State private var locationManager = LocationManager.shared
    @State private var position:MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedDetents:PresentationDetent = .fraction(0.15)
    @State private var isSearching = false
    @State private var mapItems:[MKMapItem] = []
    @State private var searchOptions:[String:String] = ["Restaurants":"fork.knife","Hotels":"bed.double.fill","Coffee":"cup.and.saucer.fill"]
    @State private var selectedMapItem:MKMapItem?
    @State private var lookAroundScene:MKLookAroundScene?
    @State private var route:MKRoute?
    
    var body: some View {
        Map(position: $position,selection: $selectedMapItem){
          
            ForEach(mapItems,id:\.self) { item in
                Marker(item: item)
            }
            
            if let route {
                MapPolyline(route)
                    .stroke(.blue,lineWidth: 5)
            }
            UserAnnotation()
        }.sheet(isPresented: .constant(true)) {
            VStack {
                
                if let selectedMapItem {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(selectedMapItem.name ?? "")
                                .font(.title3)
                            Spacer()
                            
                            Image(systemName:"xmark")
                                .onTapGesture{
                                    self.selectedMapItem = nil
                                }
                        }
                        Text(selectedMapItem.phoneNumber ?? "")
                        if selectedDetents != .fraction(0.15) {
                            LookAroundPreview(initialScene: lookAroundScene)
                        }
                        
                    }
                    .frame(maxWidth:.infinity,alignment: .leading)
                    .padding()
                    
                    
                }else{
                    TextField("Search", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .onSubmit {
                            isSearching = true
                        }
                    
                    ScrollView(.horizontal,showsIndicators: false) {
                        HStack {
                            ForEach(searchOptions.sorted(by: >), id:\.0) { key,value in
                                Button (action:{
                                    query = key
                                    isSearching = true
                                }, label: {
                                    HStack {
                                        Image(systemName: value)
                                        Text(key)
                                    }
                                })
                                .tint(Color.gray)
                                .buttonStyle(.borderedProminent)
                            }
                        }.padding(.horizontal)
                    }
                    List(mapItems, id:\.self) { item in
                        VStack(alignment: .leading) {
                            
                            Text(item.name ?? "")
                                .font(.title3)
                            Text(item.phoneNumber ?? "")
                        }.onTapGesture {
                            self.selectedMapItem = item
                        }
                    }
                }
                
                Spacer()
            }.presentationDetents([.fraction(0.15),.medium, .large],selection: $selectedDetents)
                .interactiveDismissDisabled()
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            
        }.onReceive(locationManager.$region) { value in
            withAnimation {
                self.position = .region(value)
            }
        }.task(id: isSearching) {
            if isSearching {
                await search()
            }
        } .task(id: selectedMapItem) {
            if let selectedMapItem {
                lookAroundScene = nil
                let request = MKLookAroundSceneRequest(mapItem: selectedMapItem)
                lookAroundScene = try? await request.scene
                
                route = nil
                guard let userLocation = locationManager.clManager.location else {return}
                let startingMapItem = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
                self.route = await getRoute(from: startingMapItem, to: selectedMapItem)
            }
            
        }.onMapCameraChange { context in
            locationManager.region = context.region
        }
        
    }
    
    private func search() async{
        do {
            mapItems = try await performSearch(query: query, visibleRegions: locationManager.region)
        }catch {
            mapItems = []
            print(error.localizedDescription)
        }
        isSearching = false
    }
}

#Preview {
    ContentView()
}
