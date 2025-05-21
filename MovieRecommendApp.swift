//
//  MovieRecommendApp.swift
//  MovieRecommend
//
//  Created by Family on 8/2/23.
//

import SwiftUI
import Charts
import CoreData

@main
struct MovieRecommenderApp: App {
    @StateObject private var selectedMoviesStore = SelectedMoviesStore()

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(selectedMoviesStore)
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
