message('Loading Packages')
library(rvest)
library(tidyverse)
library(mongolite)
library(xml2)
library(dplyr)
library(tidyr)
library(stringr)

Reviews <- data.frame(User = character(),
                      Rating = numeric(),
                      Review = character(),
                      stringsAsFactors = FALSE)

# Base URL for IMDb reviews with pagination
base_url <- "https://www.imdb.com/title/tt4154796/reviews?spoiler=hide&sort=curated&dir=desc&ratingFilter=0&start="

# Loop over pages to collect reviews
for(i in seq(0, 120, by = 10)) {
  url <- paste0(base_url, i)
  html <- tryCatch({
    read_html(url)
  }, error = function(e) {
    cat("Error in reading URL:", url, "\n")
    return(NULL)
  })
  
  if (!is.null(html)) {
    # Extract user names
    Users <- html %>% 
      html_nodes(".display-name-link") %>% 
      html_text(trim = TRUE)
    
    # Extract reviews
    Reviews_text <- html %>% 
      html_nodes(".text.show-more__control") %>% 
      html_text(trim = TRUE)
    
    # Extract ratings, if available
    Rating_nodes <- html %>% 
      html_nodes(".ipl-ratings-bar .rating-other-user-rating span:nth-child(2)")
    
    # Initialize ratings vector
    Ratings <- numeric(length(Reviews_text))
    
    # Fill ratings vector
    for (j in seq_along(Reviews_text)) {
      if (j <= length(Rating_nodes)) {
        Rating_text <- Rating_nodes[j] %>% html_text(trim = TRUE)
        Rating <- as.numeric(Rating_text)
        Ratings[j] <- ifelse(is.na(Rating), 0, Rating)  # Handling NA values
      } else {
        Ratings[j] <- 0  # Default rating if none exists
      }
    }
    
    # Create a data frame with the collected data
    df_page <- data.frame(User = Users[1:length(Reviews_text)],  # Ensure user length matches review length
                          Rating = Ratings,
                          Review = Reviews_text,
                          stringsAsFactors = FALSE)
    
    # Combine the new page data with the existing data
    Reviews <- bind_rows(Reviews, df_page)
  }
}

# Display the collected reviews
print(Reviews)

srape_data <- sample(1:390,5,replace=F)
data_scrape <- Reviews[srape_data,]

# MONGODB
message('Input Data to MongoDB Atlas')
library(mongolite)
# nama koleksi
collection <- "ReviewFilm"
# nama database
db <- "scraping"
# koneksi ke mongoDB
url <- "mongodb+srv://yuliantiriska:riska12345@cluster0.k7q5ikf.mongodb.net/"
Review <- mongo(collection=collection, db=db, url=url)
Review$insert(data_scrape)
rm(Review)
