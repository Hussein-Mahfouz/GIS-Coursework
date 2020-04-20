# test batch routing

# get the time from each hexagon to each other hexagon

# 1613 hexagons -> all to all routing leads to 1613*1613 = 2601769 routes
#toPlace   = h3_centroids[rep(seq(1, nrow(h3_centroids)), times = nrow(h3_centroids)),]
#fromPlace = h3_centroids[rep(seq(1, nrow(h3_centroids)), each  = nrow(h3_centroids)),]

# to test. ABOVE TAKES 1 DAY
toPlace   = h3_centroids[rep(seq(1, nrow(h3_centroids)), times = 2),]
fromPlace = h3_centroids[rep(seq(11, 12), each  = nrow(h3_centroids)),]



# get the time from each hexagon to each other hexagon
routes2 <- otp_plan(otpcon = otpcon,
                   fromPlace = fromPlace,
                   fromID = as.character(fromPlace$W3W_id),    #take the W3W_id of the hexagon (fromID only accepts characters)
                   toPlace = toPlace,
                   toID = as.character(toPlace$W3W_id),
                   mode = c("WALK","TRANSIT"),
                   date_time = as.POSIXct(strptime("2019-08-05 09:00", "%Y-%m-%d %H:%M")),
                   routingOptions = routingOptions,
                   maxWalkDistance = 850,              # default is 1000, reducing it speeds up processing time
                   numItineraries = 1,                 # return only 1 itinerary
                   get_geometry = FALSE,               # we don't need the geometry, only the time
                   ncores = 2)                         # number of cores to use 


# save this as a csv!
write.csv(routes, file="h3_time_matrix.csv", row.names = F)

# extract the three relevant columns to a 
routes_time <- routes[,c("fromPlace","toPlace","duration")]

# to concatenate multiple dataframes. If running all at the same time continues to fail
allroutes <- rbind(routes, routes2)

# there is some duplication of rows (rows with the same fromPlace, toPlace and duration)
# I grouped them by getting the mean. Mean doesn't matter here because all values were the same

routes_time <- routes_time %>%
  group_by(fromPlace, toPlace) %>%
  summarise(duration=(mean(duration)))

# Calculate Accessibility

# Step 1: have both a) the time between each OD pair and b) the number of jobs at the destination in the same row

# merge cairo_hexagons df with routes_time: I only take the W3W_id and jobsLFScou columns from the cairo_hexagons dataframe
# notice that I am taking the destination jobs ('by.x = toPlace' merges 'W3W_id' and 'jobsLFScou' of destination). 

# from https://stackoverflow.com/questions/24191497/left-join-only-selected-columns-in-r-with-the-merge-function
forAccess <- merge(x = routes_time, y = cairo_hexagons[, c("W3W_id", "jobsLFScou")], by.x = "toPlace", by.y = "W3W_id", all.x=TRUE)

# Step 2: Calculate Accessibility Scores for each OD pair

# get the accessibility score for each OD pair using the Hansen Measure (Deterent Parameter = 1.1 TEST! CHANGE LATER )
# add column to forAccess df
forAccess$access_hansen <- forAccess$jobsLFScou / ((forAccess$duration)*1.1)
# if routing gets time 0 when routing from/to same hexagon then jobs in that hexagon won't be 
# counted for it because the denominator will be 0.

# O'KELLY MEASURE (Decay Parameter) - better because it includes jobs at origin i

# calculate decay parameter
beta <- 0.02   #change later!
# access score for each OD pair
forAccess$access_okelly <- forAccess$jobsLFScou * exp((-beta)*forAccess$duration)

# Step 3: get the accessibility score for each origin by summing up its scores with all destinations

forAccess <- forAccess%>%
  group_by(fromPlace) %>%
  summarise(access_okelly=(sum(access_okelly)))

# merge the results into a new dataframe for plotting! Necessary because hexagon geometry is in cairo_hexagons sfc
accessibility_scores <- merge(x= cairo_hexagons, y = forAccess, by.x = "W3W_id", by.y = "fromPlace", all.x=TRUE)



# plot (won't work unless everything has run)

tm_okelly <- tm_shape(accessibility_scores) +
                tm_polygons("access_okelly") +
                tm_layout(legend.title.size = 0.9 ,legend.text.size = 0.6) 
tm_okelly
