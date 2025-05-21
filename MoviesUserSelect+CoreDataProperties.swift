//
//  MoviesUserSelect+CoreDataProperties.swift
//  MovieRecommend
//
//  Created by Family on 10/7/23.
//
//

import Foundation
import CoreData


extension MoviesUserSelect {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MoviesUserSelect> {
        return NSFetchRequest<MoviesUserSelect>(entityName: "MoviesUserSelect")
    }

    @NSManaged public var genre: String?
    @NSManaged public var director: String?
    @NSManaged public var budget: Double
    @NSManaged public var cast: String?
    @NSManaged public var dateWatched: Date?
    @NSManaged public var releaseDate: Date?
    @NSManaged public var title: String?
    @NSManaged public var watchedInTheaters: Bool
    @NSManaged public var rating: Double

}

extension MoviesUserSelect : Identifiable {

}
