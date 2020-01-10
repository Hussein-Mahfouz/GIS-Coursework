# Load the package
library(opentripplanner)
library(sf)
library(ggplot2)
library(tidyverse)

# Check OpenTripPlanner (Cairo).R for explanation of otp setup

path_data <- file.path("Open-Trip-Planner", "OTP-Cairo-All")
dir.create(path_data) 

path_otp <- otp_dl_jar(path_data)

# Add the GTFS and OSM files to the creater folder, then run this
log <- otp_build_graph(otp = path_otp, dir = path_data, memory = 6000, analyst = TRUE)  

# Launch OTP and load the graph
otp_setup(otp = path_otp, dir = path_data)

# connect r to otp
otpcon <- otp_connect()

# isochrones: test multiple cutoff times
test_iso  <- otp_isochrone(otpcon = otpcon,
                           fromPlace = c(h3_centroids$lon[568], h3_centroids$lat[568]),
                           mode = c("WALK", "TRANSIT"),
                           maxWalkDistance = 700,
                           date_time = as.POSIXct(strptime("2019-08-05 09:00", "%Y-%m-%d %H:%M")),
                           cutoffSec = c(2700, 3600, 4500, 5400)) # Cut offs in seconds


#list to store output
all_isochrones <- list()
# get reach polygon for each centroid and store in reachPolygons list
for (i in 1:20){
  all_isochrones[[i]] <- otp_isochrone(otpcon = otpcon,
                                      fromPlace = c(h3_centroids$lon[i], h3_centroids$lat[i]),
                                      mode = c("WALK", "TRANSIT"),
                                      maxWalkDistance = 1000,
                                      date_time = as.POSIXct(strptime("2019-08-05 09:00", "%Y-%m-%d %H:%M")),
                                      cutoffSec = c(2700, 3600, 4500, 5400)) # Cut offs in seconds
}


plot(all_isochrones[[16]][[3]][[2]])    #last value: [[1]]5400, [[2]]4500, [[3]]3600, [[4]]2700

#GET JOBS 

# empty list to store output
totalJobsCutoff <-list()

library(lwgeom) # for st_make_valid (this handles invalid geometries https://github.com/r-spatial/sf/issues/870)

# THIS DOESN'T WORK BECAUSE THE FEATURE DOESN'T HAVE A CRS 
for (i in 1:20){
  for (j in 1:4){
    totalJobsCutoff[[i]] <- 0    # there are some points that OTP couldn't route from. try() used to assign 0 value to these points
    try({
      totalJobsCutoff[[i]] <- all_isochrones[[i]][[3]][[j]] %>% 
        st_make_valid() %>%   # some geometries are invlid (this prevents an error)
        st_intersection(cairo_hexagons) %>%          # intersect reachPolygon with cairo_hexagons
        mutate(int_area = (st_area(.)/1000000) %>% as.numeric()) %>% # add column with intersection area with each hexagon
        mutate(int_jobs = (int_area/area)*jobsLFScou) %>% # int_jobs is the jobs intersected 
        summarise(total_jobs = sum(int_jobs))  # gets one value for jobs intersected by reachPolygon
  })
}}
