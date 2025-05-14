//
//  MapUtils.swift
//  NearMe
//
//  Created by EKbana on 13/05/2025.
//
import MapKit

func getRoute(from:MKMapItem, to:MKMapItem) async -> MKRoute? {
    let request = MKDirections.Request()
    request.transportType = .automobile
    request.source = from
    request.destination = to
    let directions = MKDirections(request: request)
    let response = try? await directions.calculate()
    return response?.routes.first
}

func performSearch(query:String, visibleRegions:MKCoordinateRegion?) async throws -> [MKMapItem] {
    let request = MKLocalSearch.Request()
    request.resultTypes = .pointOfInterest
    request.naturalLanguageQuery = query
    guard let visibleRegions else {return []}
    request.region = visibleRegions
    let search = MKLocalSearch(request: request)
    let response = try await search.start()
    return response.mapItems
}

