# MovieMap

## Overview
MovieMap is an iOS application designed to help movie enthusiasts track their viewing experience and gain insights into their movie preferences. The app allows users to search for movies, add them to their personal collection, rate them, and analyze their viewing habits through various data visualizations.

## Features

### 1. Movie Search and Selection
- **Search Functionality**: Enter the title of any movie to find it via the TMDb API
- **Detailed Movie Information**: View comprehensive details about each movie:
  - Title
  - Genre
  - Director
  - Cast members
  - Release date
  - Budget information
  - Movie overview

### 2. Viewing Experience Tracking
- **Add Movies**: Select movies you've watched to add to your personal collection
- **Rate Movies**: Rate movies on a scale of 0-10
- **Date Tracking**: Record when you watched a movie
- **Theater Experience**: Indicate whether you watched the movie in theaters

### 3. Personal Movie Collection
- **My Movies Tab**: View all the movies you've added to your collection
- **Movie Details**: See all recorded information about your movies at a glance
- **Delete Entries**: Swipe to delete any movie entries you no longer want to track

### 4. Data Analysis and Visualization
- **Comprehensive Analytics**: Visualize your movie-watching patterns through charts
- **Primary Categories for Analysis**:
  - Genre
  - Director
  - Cast
  - Theater vs. Non-Theater Viewing
  - Budget Range
  - Date Watched
  - Release Date
- **Visualization Types**:
  - Pie Charts: See the distribution of various movie attributes
  - Bar Graphs: Compare average ratings across different categories

## How to Use the App

### Getting Started
1. Launch the MovieMap app
2. You'll be presented with the main interface that has three tabs at the bottom:
   - Select Movie
   - My Movies
   - Data Analysis

### Searching and Adding a Movie
1. In the "Select Movie" tab, enter the title of a movie you've watched in the search field
2. As you type, the app will search the TMDb database for matching movies
3. Select a movie from the search results to view its details
4. Click the "Select" button to add this movie to your collection and record your viewing experience
5. In the viewing experience screen:
   - Set your rating using the stepper control (0-10)
   - Select the date you watched the movie using the date picker
   - Toggle whether you watched the movie in theaters
6. Tap "Save" to add the movie to your collection

### Managing Your Movie Collection
1. Navigate to the "My Movies" tab to view your entire collection
2. Each entry shows:
   - Movie title
   - Your rating
   - Date watched
   - Viewing location (theater or not)
3. To delete a movie:
   - Swipe left on the movie entry, or
   - Long press to open the context menu and select "Delete"

### Analyzing Your Movie Data
1. Go to the "Data Analysis" tab
2. Select what you want to analyze (First Choice):
   - Genre
   - Director
   - Cast
   - In theaters
   - Budget
   - Date watched
   - Release Date
3. Choose a visualization type (Second Choice):
   - Pie Chart: Shows the distribution of your selection
   - Bar Graph: Displays average ratings across categories
4. View the resulting visualization with a legend explaining the data points
5. Tap "Back" to select different analysis parameters

## Data Analysis Features Explained

### Pie Charts
- **Genre Distribution**: See which genres dominate your viewing habits
- **Director Analysis**: Find which directors' works you watch most frequently
- **Cast Member Tracking**: Discover which actors appear most in your collection
- **Theater vs. Home Viewing**: Compare how often you watch movies in theaters versus elsewhere
- **Budget Categories**: View the distribution of high, medium, and low-budget films in your collection
- **Monthly Viewing**: See which months you tend to watch the most movies
- **Release Decade**: Analyze which decades your favorite movies come from

### Bar Graphs
- **Rating by Genre**: Compare your average ratings across different genres
- **Rating by Director**: See which directors' films you tend to rate higher
- **Rating by Cast**: Find which actors appear in your highest-rated movies
- **Theater vs. Home Rating**: Compare how your ratings differ between theater and non-theater viewing
- **Rating by Budget**: Analyze how budget ranges correlate with your ratings
- **Rating by Month Watched**: See if certain months correlate with higher ratings
- **Rating by Release Decade**: Compare how you rate films from different decades

## Technical Details
- **Persistence**: The app uses Core Data to store your movie collection locally on your device
- **API Integration**: MovieMap connects to The Movie Database (TMDb) API to retrieve movie information
- **Visualization**: Uses SwiftUI's Charts framework for data visualization
- **Platform**: Built for iOS using SwiftUI

## Tips for Optimal Use
- **Regular Updates**: Add movies to your collection right after watching them for the most accurate tracking
- **Complete Information**: Always include ratings and viewing dates for the best analysis results
- **Explore Analysis**: Try different combinations of analysis parameters to discover unexpected patterns
- **Movie Details**: Take time to review all movie details before adding to your collection to ensure accuracy

---

Happy movie watching!
