import SwiftUI
import DGCharts
import Charts
import CoreData
import UIKit

struct Movie: Identifiable {
    let id: Int
    let title: String
    let genre: String
    let director: String
    let overview: [String]
    let release_date: String?
    let cast: [String]
    let budget: Int?
}

class ViewingExperienceDetails: Identifiable, ObservableObject {
    let id = UUID()  // Provide an explicit id
    let movie: Movie
    @Published var rating: Double
    @Published var selectedDate: Date
    @Published var watchedInTheaters: Bool
    
    init(movie: Movie, rating: Double, selectedDate: Date, watchedInTheaters: Bool) {
        self.movie = movie
        self.rating = rating
        self.selectedDate = selectedDate
        self.watchedInTheaters = watchedInTheaters
    }
}

class SelectedMoviesStore: ObservableObject {
    @Published var selectedMovies: [MoviesUserSelect] = []
    let managedObjectContext = PersistenceController.shared.container.viewContext

    init() {
        fetchMovies()
    }

    private func fetchMovies() {
        let fetchRequest: NSFetchRequest<MoviesUserSelect> = MoviesUserSelect.fetchRequest()
        do {
            selectedMovies = try managedObjectContext.fetch(fetchRequest)
        } catch {
            print("Error fetching movies: \(error)")
        }
    }

    func addMovie(_ movie: MoviesUserSelect) {
        selectedMovies.append(movie)

        do {
            try managedObjectContext.save()
            fetchMovies() // Fetch the updated list of movies
        } catch {
            print("Error saving movie: \(error)")
        }
    }
}

struct AppTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Select Movie", systemImage: "film")
                }

            MovieView()
                .tabItem {
                    Label("My Movies", systemImage: "list.bullet")
                }

            DataView()
                .tabItem {
                    Label("Data Analysis", systemImage: "chart.pie.fill")
                }
        }
    }
}

struct ContentView: View {
    @State private var userInput: String = ""
    @State private var recommendedMovies: [Movie] = []
    
    var body: some View {
            NavigationView {
                VStack {
                    TextField("Enter a movie", text: $userInput, onCommit: onUserInputChanged)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    List(recommendedMovies) { movie in
                        NavigationLink(destination: MovieDetailsView(movie: movie)) {
                            VStack(alignment: .leading) {
                                Text("Title: \(movie.title)")
                                    .padding(.bottom, 4)
                                Text("Genre: \(movie.genre)")
                                Text("Director: \(movie.director)")
                                Text("Cast: \(movie.cast.joined(separator: ", "))")
                                    .multilineTextAlignment(.leading)
                                if let releaseDate = movie.release_date {
                                    Text("Release Date: \(releaseDate)")
                                }
                                if let budget = movie.budget {
                                    if budget == 0 {
                                        Text("Budget: Unknown")
                                    }
                                    else {
                                        Text("Budget: $\(budget)")
                                    }
                                }
                                Text("Overview: \(movie.overview.joined(separator: ", "))")
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle("Select Your Movie")
            }
            
        }
    private func onUserInputChanged() {
        recommendedMovies.removeAll()
        fetchMovieData(for: userInput)
    }
    
    private func fetchMovieData(for movieTitle: String) {
        let apiKey: String? = a; //replace with TMDb API Key
        
        guard let apiKey = apiKey else {
            print("Please provide your TMDb API key.")
            return
        }
        
        let query = movieTitle.replacingOccurrences(of: " ", with: "%20")
        let urlString = "https://api.themoviedb.org/3/search/movie?api_key=\(apiKey)&query=\(query)"
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("API request error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Invalid response or status code")
                    return
                }
                
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
                        DispatchQueue.main.async {
                            self.fetchDetailsAndUpdateMovies(for: decodedResponse.results)
                        }
                    } catch {
                        print("Failed to decode the response data: \(error)")
                        return
                    }
                } else {
                    print("No data received from the API.")
                }
            }.resume()
        }
    }
    
    private func fetchDetailsAndUpdateMovies(for movies: [TMDBMovie]) {
        let group = DispatchGroup()

        for tmdbMovie in movies {
            group.enter()
            fetchMovieDetails(for: tmdbMovie.id) { details in
                defer { group.leave() }

                guard let details = details else {
                    return
                }

                let genre = details.genres.first?.name ?? "Unknown"
                let director = details.credits.crew.first(where: { $0.job == "Director" })?.name ?? "Unknown"
                let cast = details.credits.cast.prefix(3).map { $0.name }  // Get top 3 credited actors
                
                
                let budget = details.budget  // Get the budget from movie details

                let movie = Movie(id: tmdbMovie.id,
                                  title: tmdbMovie.title,
                                  genre: genre,
                                  director: director,
                                  overview: [tmdbMovie.overview],
                                  release_date: details.release_date,
                                  cast: Array(cast),
                                  budget: budget)  // Set the budget property

                DispatchQueue.main.async {
                    recommendedMovies.append(movie)
                }
            }
        }

        group.notify(queue: .main) {
            print("All movie details fetched.")
        }
    }
    
    private func fetchMovieDetails(for movieID: Int, completion: @escaping (MovieDetails?) -> Void) {
        let apiKey: String? = "2e8775dd9c8d8533f92584259b674410"
        
        guard let apiKey = apiKey else {
            print("Please provide your TMDb API key.")
            completion(nil)
            return
        }
        
        let urlString = "https://api.themoviedb.org/3/movie/\(movieID)?api_key=\(apiKey)&append_to_response=credits"
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("API request error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Invalid response or status code")
                    completion(nil)
                    return
                }
                
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(MovieDetails.self, from: data)
                        completion(decodedResponse)
                    } catch {
                        print("Failed to fetch movie details: \(error)")
                        completion(nil)
                    }
                } else {
                    print("No data received from the API.")
                    completion(nil)
                }
            }.resume()
        } else {
            completion(nil)
        }
    }
}

struct MovieDetailsView: View {
    let movie: Movie
    @State private var isViewingExperiencePresented: Bool = false

    var body: some View {
        VStack {
            Text(movie.title)
                .font(.title)

            Text("Genre: \(movie.genre)")
            Text("Director: \(movie.director)")
            Text("Cast: \(movie.cast.joined(separator: ", "))")
                .multilineTextAlignment(.center)
            if let releaseDate = movie.release_date {
                Text("Release Date: \(releaseDate)")
            }
            if let budget = movie.budget {
                if budget == 0 {
                    Text("Budget: Unknown")
                }
                else {
                    Text("Budget: $\(budget)")
                }
            }
            Text("Overview: \(movie.overview.joined(separator: ", "))")

            Spacer()

            Button("Select") {
                isViewingExperiencePresented.toggle()
            }
            .sheet(isPresented: $isViewingExperiencePresented) {
                ViewingExperienceView(movie: movie)
            }
        }
        .padding()
        .navigationTitle("Movie Details")
    }
}

struct TMDBMovieResponse: Codable {
    let results: [TMDBMovie]
}

struct TMDBMovie: Codable {
    let id: Int
    let title: String
    let overview: String
}

struct Genre: Codable {
    let id: Int
    let name: String
}

struct MovieDetails: Codable {
    let genres: [Genre]
    let credits: Credits
    let release_date: String?
    let budget: Int?
}

struct Credits: Codable {
    let crew: [CrewMember]
    let cast: [CastMember]  // Include cast information
}

struct CastMember: Codable {
    let name: String
}

struct CrewMember: Codable {
    let name: String
    let job: String
}

struct ViewingExperienceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var selectedMoviesStore: SelectedMoviesStore
    @State private var rating: Double = 0.0
    @State private var selectedDate = Date()
    @State private var watchedInTheaters = false

    var movie: Movie // This is the movie object from your Movie struct

    var body: some View {
        NavigationView {
                    Form {
                        Section(header: Text("Rating")) {
                            HStack {
                                Text("Rating:")
                                Spacer()
                                RatingView(rating: $rating)
                                    .font(.largeTitle)
                            }
                        }

                Section(header: Text("Date Watched")) {
                    // Use .datePickerStyle and .yearAndMonth to display only the month and year
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)  // Use graphical style
                        .labelsHidden()  // Hide the labels (day and time)
                }

                Section(header: Text("Viewing Experience")) {
                    Toggle(isOn: $watchedInTheaters) {
                        Text("In Theaters?")
                    }
                }
            }
            .navigationTitle("Viewing Experience")
            .navigationBarItems(trailing: Button("Save") {
                // Create a new instance of MoviesUserSelect
                let newMovie = MoviesUserSelect(context: selectedMoviesStore.managedObjectContext)
                
                // Set properties based on the movie object
                newMovie.title = movie.title
                newMovie.genre = movie.genre
                newMovie.director = movie.director
                newMovie.budget = Double(movie.budget ?? 0)
                let castArray = movie.cast
                let castString = castArray.joined(separator: ",")
                newMovie.cast = castString
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                if let releaseDateString = movie.release_date,
                   let releaseDate = dateFormatter.date(from: releaseDateString) {
                    newMovie.releaseDate = releaseDate
                }
                
                newMovie.rating = Double(rating)
                newMovie.dateWatched = selectedDate
                newMovie.watchedInTheaters = watchedInTheaters

                // Save the new movie to Core Data
                selectedMoviesStore.addMovie(newMovie)

                // Dismiss the view
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct RatingView: View {
    @Binding var rating: Double
    
    var body: some View {
        VStack {
            Text("Enter Rating (out of 10)")
                .font(.headline)
            Stepper(value: $rating, in: 0...10, step: 1) {
                Text("\(rating, specifier: "%.1f")")
                    .font(.system(size: 30))
            }
        }
    }
}

struct MovieView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var selectedMoviesStore: SelectedMoviesStore
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"  // Use your desired format
        return formatter
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Swipe to delete extraneous entries")
                
                List {
                    ForEach(selectedMoviesStore.selectedMovies) { movieDetails in
                        VStack(alignment: .leading) {
                            Text("Movie: \(movieDetails.title ?? "")") // Access title from MoviesUserSelect
                            Text(String(format: "Rating: %.1f / 10", movieDetails.rating))
                            if let dateWatched = movieDetails.dateWatched {
                                let formattedDate = dateFormatter.string(from: dateWatched)
                                Text("Date Watched: \(formattedDate)")
                            } else {
                                Text("Date Watched: N/A")
                            }
                            Text("Watched in Theaters: \(movieDetails.watchedInTheaters ? "Yes" : "No")")
                        }
                        .contextMenu {
                            Button(action: {
                                // Delete the selected movie entry from Core Data
                                if let index = selectedMoviesStore.selectedMovies.firstIndex(where: { $0.id == movieDetails.id }) {
                                    let movieToDelete = selectedMoviesStore.selectedMovies[index]
                                    selectedMoviesStore.selectedMovies.remove(at: index)

                                    // Delete the movie from Core Data
                                    selectedMoviesStore.managedObjectContext.delete(movieToDelete)

                                    do {
                                        try selectedMoviesStore.managedObjectContext.save()
                                    } catch {
                                        print("Error deleting movie from Core Data: \(error)")
                                    }
                                }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indices in
                        // Delete the selected movie entries from Core Data
                        for index in indices {
                            let movieToDelete = selectedMoviesStore.selectedMovies[index]
                            selectedMoviesStore.selectedMovies.remove(at: index)
                            
                            // Delete the movie from Core Data
                            selectedMoviesStore.managedObjectContext.delete(movieToDelete)
                        }
                        
                        do {
                            try selectedMoviesStore.managedObjectContext.save()
                        } catch {
                            print("Error deleting movies from Core Data: \(error)")
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

struct DataView: View {
    @EnvironmentObject var selectedMoviesStore: SelectedMoviesStore
    @State private var firstChoice: String? = nil
    @State private var secondChoice: String? = nil
    @State private var isScatterplotPresented: Bool = false
    
    
    enum GraphType: String, CaseIterable {
        case pieChart = "Pie Chart"
        case barGraph = "Bar Graph"
        
        var title: String {
            return rawValue
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Data Analysis")
                    .font(.largeTitle)
                    .padding()
                
                // First choice buttons (e.g., genre, release date, etc.)
                if firstChoice == nil {
                    Text("Select First Choice:")
                    VStack {
                        HStack(spacing: 20) { // Use HStack to place buttons side by side
                            Button(action: {
                                firstChoice = "Genre"
                            }) {
                                Text("Genre")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                            
                            Button(action: {
                                firstChoice = "Director"
                            }) {
                                Text("Director")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                        }
                        
                        HStack(spacing: 20) { // Use HStack to place buttons side by side
                            Button(action: {
                                firstChoice = "Cast"
                            }) {
                                Text("Cast")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                            
                            Button(action: {
                                firstChoice = "In theaters"
                            }) {
                                Text("In theaters")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                        }
                        
                        HStack(spacing: 20) { // Use HStack to place buttons side by side
                            Button(action: {
                                firstChoice = "Budget"
                            }) {
                                Text("Budget")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                            
                            Button(action: {
                                firstChoice = "Date watched"
                            }) {
                                Text("Date watched")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                        }
                        
                        HStack(spacing: 20) { // Use HStack to place buttons side by side
                            Button(action: {
                                firstChoice = "Release Date"
                            }) {
                                Text("Release Date")
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding()
                }
                
                // Second choice buttons (e.g., pie chart, scatterplot, bar graph)
                if let _ = firstChoice, secondChoice == nil {
                    Text("Select Second Choice:")
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(GraphType.allCases, id: \.self) { graphType in
                                Button(action: {
                                    secondChoice = graphType.rawValue
                                }) {
                                    Text(graphType.title)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(Color.blue, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 82)
                }
                
                // Section for displaying the selected graph
                if let selectedGraph = secondChoice {
                    Divider()
                    Text("Selected Graph: \(selectedGraph)")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    // Display the corresponding graph based on the first and second choices
                    if let firstChoice = firstChoice {
                        if firstChoice == "Genre" {
                            // Genre Pie Chart
                            if selectedGraph == "Pie Chart" {
                                let genreData = analyzeGenreData()
                                VStack {
                                    Text("Pie Chart: Genre")
                                        .font(.largeTitle)
                                        .padding()
                                    PieChartView(data: genreData)
                                }
                            } else if selectedGraph == "Bar Graph" {
                                let genreAverages = calculateAverageRatingForVariable("Genre")
                                BarGraphView(data: genreAverages, variable: "Genre")
                            }
                        } else if firstChoice == "Director" {
                            // Director Pie Chart
                            if selectedGraph == "Pie Chart" {
                                let directorData = analyzeDirectorData()
                                VStack {
                                    Text("Pie Chart: Director")
                                        .font(.largeTitle)
                                        .padding()
                                    PieChartView(data: directorData)
                                }
                            } else if selectedGraph == "Bar Graph" {
                                let directorAverages = calculateAverageRatingForVariable("Director")
                                BarGraphView(data: directorAverages, variable: "Director")
                            }
                            
                        } else if firstChoice == "Cast" {
                            // Cast Bar Graph
                            if selectedGraph == "Pie Chart" {
                                let castData = analyzeCastData()
                                VStack {
                                    Text("Pie Chart: Cast")
                                        .font(.largeTitle)
                                        .padding()
                                    PieChartView(data: castData)
                                }
                            } else if selectedGraph == "Bar Graph" {
                                let castAverages = calculateAverageRatingForVariable("Cast")
                                BarGraphView(data: castAverages, variable: "Cast")
                            }
                        } else if firstChoice == "In theaters" {
                            // In theaters Pie Chart
                            if selectedGraph == "Pie Chart" {
                                let inTheatersData = analyzeInTheatersData()
                                VStack {
                                    Text("Pie Chart: In Theaters?")
                                        .font(.largeTitle)
                                        .padding()
                                    PieChartView(data: inTheatersData)
                                }
                            } else {
                                let theaterAverages = calculateAverageRatingForVariable("In theaters")
                                BarGraphView(data: theaterAverages, variable: "In theaters")
                            }
                        } else if firstChoice == "Budget" {
                            // Budget Pie Chart
                            if selectedGraph == "Pie Chart" {
                                let budgetData = analyzeBudgetData()
                                VStack {
                                    Text("Pie Chart: Budget")
                                        .font(.largeTitle)
                                        .padding()
                                    PieChartView(data: budgetData)
                                }
                            } else if selectedGraph == "Bar Graph" {
                                let budgetAverages = calculateAverageRatingForVariable("Budget")
                                BarGraphView(data: budgetAverages, variable: "Budget")
                            }
                        } else if firstChoice == "Date watched" {
                            // Date watched Pie Chart
                            if selectedGraph == "Pie Chart" {
                                let dateWatchedData = analyzeDateWatchedData()
                                VStack {
                                    Text("Pie Chart: Date Watched")
                                        .font(.largeTitle)
                                        .padding()
                                    PieChartView(data: dateWatchedData)
                                }
                            }  else if selectedGraph == "Bar Graph" {
                                let dateAverages = calculateAverageRatingForVariable("Date watched")
                                BarGraphView(data: dateAverages, variable: "Date watched")
                            }
                        } else if firstChoice == "Release Date" {
                            // Release Date Pie Chart
                            if selectedGraph == "Pie Chart" {
                                let releaseDateData = analyzeReleaseDateData()
                                VStack {
                                    Text("Pie Chart: Release Date vs. Average Rating")
                                        .font(.largeTitle)
                                        .padding()
                                    PieChartView(data: releaseDateData)
                                }
                            }  else if selectedGraph == "Bar Graph" {
                                let releaseAverages = calculateAverageRatingForVariable("Release Date")
                                BarGraphView(data: releaseAverages, variable: "Release Date")
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationBarItems(
                leading:
                    Button(action: {
                        // Clear the first and second choices when going back
                        firstChoice = nil
                        secondChoice = nil
                    }) {
                        HStack {
                            if firstChoice != nil {
                                Image(systemName: "chevron.left") // Blue arrow
                                Text("Back")
                            }
                        }
                    }
            )
        }
        .onDisappear {
            // Clear the first and second choices when the view disappears
            firstChoice = nil
            secondChoice = nil
        }
    }
    
    private func calculateAverageRatingForVariable(_ variable: String) -> [(String, Double)] {
        var variableRatings: [String: [Double]] = [:]
        var variableCounts: [String: Int] = [:]

        if variable == "Cast" {
            for movieDetails in selectedMoviesStore.selectedMovies {
                if let castString = movieDetails.cast {
                    let castArray = castString.components(separatedBy: ",")
                    // Now, castArray contains the individual cast members
                    for actor in castArray {
                        variableCounts[actor, default: 0] += 1
                    }
                }
            }

            var actorCounts: [(String, Int)] = []
            var otherCount = 0

            for (actor, count) in variableCounts {
                actorCounts.append((actor, count))
            }

            // Sort actors by the number of movies watched in descending order
            actorCounts.sort { $0.1 > $1.1 }

            // Limit to the top 8 actors
            let topActors = Array(actorCounts.prefix(4))

            // Calculate the average rating for top actors
            var actorAverages: [(String, Double)] = []

            for (actor, _) in topActors {
                var totalRating = 0.0
                var numberOfMovies = 0
                for movieDetails in selectedMoviesStore.selectedMovies {
                    if let castString = movieDetails.cast {
                        let castArray = castString.components(separatedBy: ",")
                        // Now, castArray contains the individual cast members
                        if castArray.contains(actor) {
                            // Actor is found in the castArray
                            totalRating += movieDetails.rating
                            numberOfMovies += 1
                        }
                    }
                }
                if numberOfMovies > 0 {
                    let averageRating = totalRating / Double(numberOfMovies)
                    actorAverages.append((actor, averageRating))
                }
            }

            // Sort actors by average rating in descending order
            actorAverages.sort { $0.1 > $1.1 }

            // Add the "Other" category if there are more actors
            if actorCounts.count > 8 {
                for i in 8..<actorCounts.count {
                    otherCount += actorCounts[i].1
                }
                actorAverages.append(("Other", Double(otherCount)))
            }

            return actorAverages
        } else if variable == "Director" {
            for movieDetails in selectedMoviesStore.selectedMovies {
                if let director = movieDetails.director {
                    variableCounts[director, default: 0] += 1
                }
            }

            var directorCounts: [(String, Int)] = []
            var otherCount = 0

            for (director, count) in variableCounts {
                directorCounts.append((director, count))
            }

            // Sort directors by the number of movies watched in descending order
            directorCounts.sort { $0.1 > $1.1 }

            // Limit to the top 4 directors
            let topDirectors = Array(directorCounts.prefix(4))

            // Calculate the average rating for top directors
            var directorAverages: [(String, Double)] = []

            for (director, _) in topDirectors {
                var totalRating = 0.0
                var numberOfMovies = 0

                for movieDetails in selectedMoviesStore.selectedMovies {
                    if movieDetails.director == director {
                        totalRating += movieDetails.rating
                        numberOfMovies += 1
                    }
                }

                if numberOfMovies > 0 {
                    let averageRating = totalRating / Double(numberOfMovies)
                    directorAverages.append((director, averageRating))
                }
            }

            // Sort directors by average rating in descending order
            directorAverages.sort { $0.1 > $1.1 }

            // Add the "Other" category if there are more directors
            if directorCounts.count > 4 {
                for i in 4..<directorCounts.count {
                    otherCount += directorCounts[i].1
                }

                directorAverages.append(("Other", Double(otherCount)))
            }

            return directorAverages
        } else if variable == "Genre" {
            for movieDetails in selectedMoviesStore.selectedMovies {
                if let genre = movieDetails.genre {
                    variableCounts[genre, default: 0] += 1
                }
            }

            var genreCounts: [(String, Int)] = []
            var otherCount = 0

            for (genre, count) in variableCounts {
                genreCounts.append((genre, count))
            }

            // Sort genres by the number of movies watched in descending order
            genreCounts.sort { $0.1 > $1.1 }

            // Limit to the top 4 genres
            let topGenres = Array(genreCounts.prefix(4))

            // Calculate the average rating for top genres
            var genreAverages: [(String, Double)] = []

            for (genre, _) in topGenres {
                var totalRating = 0.0
                var numberOfMovies = 0

                for movieDetails in selectedMoviesStore.selectedMovies {
                    if movieDetails.genre == genre {
                        totalRating += movieDetails.rating
                        numberOfMovies += 1
                    }
                }

                if numberOfMovies > 0 {
                    let averageRating = totalRating / Double(numberOfMovies)
                    genreAverages.append((genre, averageRating))
                }
            }

            // Sort genres by average rating in descending order
            genreAverages.sort { $0.1 > $1.1 }

            // Add the "Other" category if there are more genres
            if genreCounts.count > 4 {
                for i in 4..<genreCounts.count {
                    otherCount += genreCounts[i].1
                }

                genreAverages.append(("Other", Double(otherCount)))
            }

            return genreAverages
        } else {
            for movieDetails in selectedMoviesStore.selectedMovies {
                var key: String
                
                switch variable {
                case "Director":
                    key = movieDetails.director ?? "Unknown Director"
                case "Genre":
                    key = movieDetails.genre ?? "Unknown Genre"
                case "Cast":
                    // You would need to modify this part to iterate through the cast and handle it
                    // appropriately, similar to what you did in other functions
                    key = "Cast"
                case "In theaters":
                    key = movieDetails.watchedInTheaters ? "In Theaters" : "Out of Theaters"
                case "Budget":
                    // Handle budget variable by categorizing it into four ranges
                    let budgetCategory: String
                    let budget = movieDetails.budget // No need for optional binding here

                    switch budget {
                    case 0..<50000000:
                        budgetCategory = "Low Budget"
                    case 50000000..<100000000:
                        budgetCategory = "Medium Budget"
                    case 100000000...:
                        budgetCategory = "High Budget"
                    default:
                        budgetCategory = "Unknown Budget"
                    }
                    key = budgetCategory
                case "Date watched":
                    var monthCounts: [String: (Double, Int)] = [:]
                    var month: String = "Unknown" // Initialize with a default value

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMMM"

                    for movieDetails in selectedMoviesStore.selectedMovies {
                        if let selectedDate = movieDetails.dateWatched {
                            month = dateFormatter.string(from: selectedDate) // Assign the value to 'month'
                        }
                        let rating = movieDetails.rating
                        if monthCounts[month] != nil {
                            monthCounts[month]?.0 += rating
                            monthCounts[month]?.1 += 1
                        } else {
                            monthCounts[month] = (rating, 1)
                        }
                    }

                    var monthAverages: [(String, Double)] = []

                    for (month, (totalRating, numberOfMovies)) in monthCounts {
                        let averageRating = totalRating / Double(numberOfMovies)
                        monthAverages.append((month, averageRating))
                    }

                    // Sort months by average rating in descending order
                    monthAverages.sort { $0.1 > $1.1 }

                    // Return the sorted monthAverages
                    return monthAverages
                case "Release Date":
                    var releaseDecadeCounts: [String: (Double, Int)] = [:]

                    let calendar = Calendar.current
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy"

                    for movieDetails in selectedMoviesStore.selectedMovies {
                        if let releaseDate = movieDetails.releaseDate {
                            let yearComponent = calendar.component(.year, from: releaseDate)
                            let yearString = dateFormatter.string(from: releaseDate)
                            
                            if let year = Int(yearString) {
                                let decade = "\((year / 10) * 10)s"
                                let rating = movieDetails.rating
                                if releaseDecadeCounts[decade] != nil {
                                    releaseDecadeCounts[decade]?.0 += rating
                                    releaseDecadeCounts[decade]?.1 += 1
                                } else {
                                    releaseDecadeCounts[decade] = (rating, 1)
                                }
                            }
                        }
                    }

                    var releaseDecadeAverages: [(String, Double)] = []

                    for (decade, (totalRating, numberOfMovies)) in releaseDecadeCounts {
                        let averageRating = totalRating / Double(numberOfMovies)
                        releaseDecadeAverages.append((decade, averageRating))
                    }

                    // Sort decades by average rating in descending order
                    releaseDecadeAverages.sort { $0.1 > $1.1 }
                    return releaseDecadeAverages
                default:
                    key = "Unknown"
                }

                variableRatings[key, default: []].append(movieDetails.rating)
            }

            var averages: [(String, Double)] = []

            for (key, ratings) in variableRatings {
                if !ratings.isEmpty {
                    let averageRating = ratings.reduce(0, +) / Double(ratings.count)
                    averages.append((key, averageRating))
                }
            }

            return averages
        }
    }
    private func analyzeGenreData() -> [(Double, Color, String, Color)] {
        var genreCounts: [String: Int] = [:]
        
        for movieDetails in selectedMoviesStore.selectedMovies {
            if let genre = movieDetails.genre {
                genreCounts[genre, default: 0] += 1
            } else {
                // Provide a default genre or handle this case as needed
                // For example, you can use a placeholder like "Unknown Genre"
                let defaultGenre = "Unknown Genre"
                genreCounts[defaultGenre, default: 0] += 1
            }        }
        
        // Sort genres by count in descending order
        let sortedGenres = genreCounts.sorted { $0.value > $1.value }
        
        let totalMovies = Double(selectedMoviesStore.selectedMovies.count)
        var genreColors: [Color] = []
        var slices: [(Double, Color, String, Color)] = []
        
        var otherCount = 0
        
        for (index, (genre, count)) in sortedGenres.enumerated() {
            if index < 7 {
                let percentage = Double(count) / totalMovies
                let color = Color.random()
                genreColors.append(color)
                slices.append((percentage, color, genre, color))
            } else {
                otherCount += count
            }
        }
        
        // Add the "Other" category if there are genres beyond the threshold
        if otherCount > 0 {
            let percentage = Double(otherCount) / totalMovies
            let color = Color.gray // You can set a specific color for "Other"
            genreColors.append(color)
            slices.append((percentage, color, "Other", color))
        }
        
        return slices
    }
    
    private func analyzeDirectorData() -> [(Double, Color, String, Color)] {
        var directorCounts: [String: Int] = [:]
        
        for movieDetails in selectedMoviesStore.selectedMovies {
            let director = movieDetails.director
            if let director = movieDetails.director {
                directorCounts[director, default: 0] += 1
            } else {
                // Provide a default genre or handle this case as needed
                // For example, you can use a placeholder like "Unknown Genre"
                let defaultDirector = "Unknown Director"
                directorCounts[defaultDirector, default: 0] += 1
            }
        }
        
        // Sort directors by count in descending order
        let sortedDirectors = directorCounts.sorted { $0.value > $1.value }
        
        let totalMovies = Double(selectedMoviesStore.selectedMovies.count)
        var directorColors: [Color] = []
        var slices: [(Double, Color, String, Color)] = []
        
        var otherCount = 0
        
        for (index, (director, count)) in sortedDirectors.enumerated() {
            if index < 7 {
                let percentage = Double(count) / totalMovies
                let color = Color.random()
                directorColors.append(color)
                slices.append((percentage, color, director, color))
            } else {
                otherCount += count
            }
        }
        
        // Add the "Other" category if there are directors beyond the threshold
        if otherCount > 0 {
            let percentage = Double(otherCount) / totalMovies
            let color = Color.gray // You can set a specific color for "Other"
            directorColors.append(color)
            slices.append((percentage, color, "Other", color))
        }
        
        return slices
    }
    
    private func analyzeCastData() -> [(Double, Color, String, Color)] {
        var actorCounts: [String: Int] = [:]

        for movieDetails in selectedMoviesStore.selectedMovies {
            if let cast = movieDetails.cast {
                for actor in cast.components(separatedBy: ",") {
                    actorCounts[actor, default: 0] += 1
                }
            }
        }

        // Sort actors by count in descending order
        let sortedActors = actorCounts.sorted { $0.value > $1.value }

        let totalMovies = Double(selectedMoviesStore.selectedMovies.count)
        var actorColors: [Color] = []
        var slices: [(Double, Color, String, Color)] = []

        var otherCount = 0

        for (index, (actor, count)) in sortedActors.enumerated() {
            if index < 7 {
                let percentage = Double(count) / totalMovies
                let color = Color.random()
                actorColors.append(color)
                slices.append((percentage, color, actor, color))
            } else {
                otherCount += count
            }
        }

        // Add the "Other" category if there are actors beyond the threshold
        if otherCount > 0 {
            let percentage = Double(otherCount) / totalMovies
            let color = Color.gray // You can set a specific color for "Other"
            actorColors.append(color)
            slices.append((percentage, color, "Other", color))
        }

        return slices
    }
    
    private func analyzeInTheatersData() -> [(Double, Color, String, Color)] {
        var inTheatersCounts: [String: Int] = ["In Theaters": 0, "Out of Theaters": 0]
        
        for movieDetails in selectedMoviesStore.selectedMovies {
            let key = movieDetails.watchedInTheaters ? "In Theaters" : "Out of Theaters"
            inTheatersCounts[key]! += 1
        }
        
        let totalMovies = Double(selectedMoviesStore.selectedMovies.count)
        
        var inTheatersColors: [Color] = []
        
        var slices: [(Double, Color, String, Color)] = []
        
        for (key, count) in inTheatersCounts {
            let percentage = Double(count) / totalMovies
            let color = Color.random()
            inTheatersColors.append(color)
            slices.append((percentage, color, key, color))
        }
        
        return slices
    }
    
    private func analyzeBudgetData() -> [(Double, Color, String, Color)] {
        var budgetCounts: [String: Int] = ["Low Budget": 0, "Medium Budget": 0, "High Budget": 0, "Unknown": 0]
        var totalMoviesWithBudget = 0  // Track the total number of movies with a non-zero budget
        
        for movieDetails in selectedMoviesStore.selectedMovies {
            let budget = movieDetails.budget // No need for 'if let' here
            
            if budget > 0 {
                // Count movies with a non-zero budget
                totalMoviesWithBudget += 1
                if budget < 50000000 {
                    budgetCounts["Low Budget"]! += 1
                } else if budget < 100000000 {
                    budgetCounts["Medium Budget"]! += 1
                } else {
                    budgetCounts["High Budget"]! += 1
                }
            }
        }
        
        // If there are movies with a budget of $0, count them as "Unknown"
        if totalMoviesWithBudget < selectedMoviesStore.selectedMovies.count {
            budgetCounts["Unknown"] = selectedMoviesStore.selectedMovies.count - totalMoviesWithBudget
        }
        
        let totalMovies = Double(selectedMoviesStore.selectedMovies.count)
        
        var budgetColors: [Color] = []
        
        var slices: [(Double, Color, String, Color)] = []
        
        for (key, count) in budgetCounts {
            let percentage = Double(count) / totalMovies
            let color = Color.random()
            budgetColors.append(color)
            slices.append((percentage, color, key, color))
        }
        
        return slices
        
    }
    
    private func analyzeDateWatchedData() -> [(Double, Color, String, Color)] {
        var dateMonthCounts: [String: Int] = [:]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"

        for movieDetails in selectedMoviesStore.selectedMovies {
            if let selectedDate = movieDetails.dateWatched {
                let month = dateFormatter.string(from: selectedDate)
                dateMonthCounts[month, default: 0] += 1
            }
        }

        let totalMovies = Double(selectedMoviesStore.selectedMovies.count)

        var dateMonthColors: [Color] = []

        var slices: [(Double, Color, String, Color)] = []

        for (month, count) in dateMonthCounts {
            let percentage = Double(count) / totalMovies
            let color = Color.random()
            dateMonthColors.append(color)
            slices.append((percentage, color, month, color))
        }

        return slices
    }
    private func analyzeReleaseDateData() -> [(Double, Color, String, Color)] {
        var releaseDecadeCounts: [String: Int] = [:]
        
        for movieDetails in selectedMoviesStore.selectedMovies {
            if let releaseDate = movieDetails.releaseDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy"
                let yearString = dateFormatter.string(from: releaseDate)
                
                if let year = Int(yearString) {
                    let decade = "\((year / 10) * 10)s"
                    releaseDecadeCounts[decade, default: 0] += 1
                }
            }
        }
        
        let totalMovies = Double(selectedMoviesStore.selectedMovies.count)
        
        var releaseDecadeColors: [Color] = []
        
        var slices: [(Double, Color, String, Color)] = []
        
        for (decade, count) in releaseDecadeCounts {
            let percentage = Double(count) / totalMovies
            let color = Color.random()
            releaseDecadeColors.append(color)
            slices.append((percentage, color, decade, color))
        }
        
        return slices
    }
        
    }
    
    private func PieChartView(data: [(Double, Color, String, Color)]) -> some View {
        return VStack {
            Pie(slices: data)
                .frame(width: 300, height: 300)
                .padding(.top, 20)
            LegendView(items: data.map { ($2, $3) })
        }
    }
    
    struct Pie: View {
        @State var slices: [(Double, Color, String, Color)]
        
        var body: some View {
            Canvas { context, size in
                let total = slices.reduce(0) { $0 + $1.0 }
                context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
                var pieContext = context
                pieContext.rotate(by: .degrees(-90))
                let radius = min(size.width, size.height) * 0.48
                var startAngle = Angle.zero
                for (value, color, _, _) in slices { // Updated to include the genre color
                    let angle = Angle(degrees: 360 * (value / total))
                    let endAngle = startAngle + angle
                    let path = Path { p in
                        p.move(to: .zero)
                        p.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                        p.closeSubpath()
                    }
                    pieContext.fill(path, with: .color(color))
                    
                    startAngle = endAngle
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
    
    
    
    struct LegendView: View {
        let items: [(String, Color)]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.0) { (genre, color) in
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                        Text(genre)
                    }
                }
            }
        }
    }
    
struct ScatterplotView: View {
    @EnvironmentObject var selectedMoviesStore: SelectedMoviesStore
    
    private func analyzeBudgetAndRatingData() -> [(Double, Double)] {
        var budgetAndRatingData: [(Double, Double)] = []
        
        for movieDetails in selectedMoviesStore.selectedMovies {
            if movieDetails.budget > 0 {
                // Only include movies with a non-zero budget
                let rating = movieDetails.rating
                budgetAndRatingData.append((Double(movieDetails.budget), rating))
            }
        }
        
        return budgetAndRatingData
    }
    
    var body: some View {
        VStack {
            Text("Scatterplot: Budget vs. Rating")
                .font(.largeTitle)
                .padding()
            
            let budgetAndRatingData = analyzeBudgetAndRatingData()
            
            ScatterplotChart(dataPoints: budgetAndRatingData)
                .frame(width: 300, height: 300)
                .padding(.top, 20)
        }
    }
}
    
    struct ScatterplotChart: View {
        var dataPoints: [(Double, Double)] // Array of (budget, rating) data points
        
        var body: some View {
            Chart {
                ForEach(dataPoints.indices, id: \.self) { index in
                    let dataPoint = dataPoints[index]
                    PointMark(
                        x: .value("Budget", dataPoint.0), // Budget value
                        y: .value("Rating", dataPoint.1) // Rating value
                    )
                }
            }
        }
    }
    
struct DateWatchedScatterplotView: View {
    @EnvironmentObject var selectedMoviesStore: SelectedMoviesStore
    
    private func analyzeDateWatchedData() -> [(Double, Double)] {
        var dateWatchedData: [(Double, Double)] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for movieDetails in selectedMoviesStore.selectedMovies {
            if let date = movieDetails.dateWatched {
                let rating = movieDetails.rating
                let timeInterval = date.timeIntervalSince1970
                dateWatchedData.append((Double(timeInterval), rating))
            }
        }
        
        return dateWatchedData
    }
    
    var body: some View {
        VStack {
            Text("Scatterplot: Date Watched vs. Rating")
                .font(.largeTitle)
                .padding()
            
            let dateWatchedData = analyzeDateWatchedData()
            
            ScatterplotChart(dataPoints: dateWatchedData)
                .frame(width: 300, height: 300)
                .padding(.top, 20)
        }
    }
}
    
    struct BarGraphView: View {
        let data: [(String, Double)]
        let variable: String
        
        var body: some View {
            VStack {
                Text("Bar Graph: \(variable) vs. Average Rating")
                    .font(.largeTitle)
                    .padding()
                
                BarChart(dataPoints: data)
                    .frame(width: 300, height: 300)
                    .padding(.top, 20)
            }
        }
    }
    struct BarChart: View {
        let dataPoints: [(String, Double)]
        
        var body: some View {
            Chart {
                ForEach(dataPoints, id: \.0) { (category, rating) in
                    BarMark(
                        x: .value(category, category),
                        y: .value("Average Rating", rating)
                    )
                }
            }
        }
    }

extension Color {
    static func random() -> Color {
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        return Color(red: red, green: green, blue: blue)
    }
}
