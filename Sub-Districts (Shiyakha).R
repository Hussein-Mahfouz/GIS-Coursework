library(sf)
library(ggplot2)
library(ggthemes)
library(tmap)
library(tidyverse)

# import the shapefile
cairo_sub_districts<- st_read("Cairo Shapefiles/Central-Inner_Shiyakha_NDC_CAPMAS.shp")
cairo_sub_districts <- cairo_sub_districts[, c("zoning_tfc", "name_citya", "Unique_ID", "pop2018ad", "area_km2", "pop_2018_c")]

# run 'importing H3 layer' r script to load data for next part. Scripts must be in the same folder
source("importing H3 layer.R")

# GET NUMBER OF JOBS IN EACH SUB-DISTRICT

# jobs are only available in the hexagon layer. We need to intersect it with the sub district layer

# get intersection sub districts with hexagons
# each row is the intersection of one sub-district with one hexagon
jobs_intersect <- st_intersection(cairo_sub_districts, cairo_hexagons)

# get area intersected and jobs intersected for each row
numrows <- nrow(jobs_intersect) # value for number of rows (used in for loop)
for (i in 1:numrows){
    jobs_intersect$int_area[i] <- ((st_area(jobs_intersect$geometry[i]))/1000000) %>% as.numeric()
    jobs_intersect$int_per[i] <- ((jobs_intersect$int_area[i]/1.175))    #1.175km2 is the area of each hexagon
    jobs_intersect$jobs[i] <- ((jobs_intersect$int_per[i])*(jobs_intersect$jobsLFScou[i]))
}

# group intersections by sub district ID. This gets the number of jobs intersected by each sub-district
library(dplyr)
jobs_intersect <- jobs_intersect %>% 
        group_by(Unique_ID) %>% 
        summarise(jobs = sum(jobs))

# merge results back into cairo_sub_districts sf
st_geometry(jobs_intersect) <- NULL  # drop geometry because you cannot merge two simple features. One needs to be a dataframe
cairo_sub_districts <- merge(cairo_sub_districts, jobs_intersect, by.x = "Unique_ID", by.y = "Unique_ID", all.x=TRUE)

# add job density column
# jobs / area : area divided by 1,000,000 so that it is in km^2
cairo_sub_districts$jobsPerSqKm <- cairo_sub_districts$jobs / (st_area(cairo_sub_districts$geometry)/1000000)

#PLOT TO CHECK
breaks = c(0, 1000, 5000, 10000, 15000, 25000, 40000, 60000)  

# to add a basemap - these are used later in tm_shape
#bb = c(30.801369, 29.705080, 31.874483, 30.390664)
#c_osm <- tmaptools::read_osm(bb, ext = 1.05, type = "esri-topo")


tm_jobs <- 
    #tm_shape(c_osm) +
        #tm_rgb() +
    tm_shape(cairo_sub_districts) +
              tm_polygons("jobsPerSqKm",
                        #style = "jenks"    # used instead of user defined breaks
                        breaks = breaks,
                        palette = "BuPu",
                        border.col = "grey", 
                        border.alpha = 0.5,
                        #legend.hist = TRUE,
                        title = "Jobs Per Square Km") +
              tm_legend(title.size=0.9,
                        text.size = 0.6,
                        position = c("right", "bottom")) +
              tm_layout(title = "Job Density in the Greater Cairo Region",        # add a title
                        title.size = 1.5,
                        title.position = c("center", "top"),
                        inner.margins = c(0.09, 0.10, 0.10, 0.08),    # increase map margins to make space for legend
                        fontfamily = 'Georgia',
                        frame = FALSE) +
              tm_scale_bar(color.dark = "gray60",
                           position = c("left", "bottom")) 
              #+ tm_text("name_citya", size = 1/2, remove.overlap = TRUE)

tm_jobs

#two maps in 1 row 
tm_test <- tm_jobs
tmap_both <-  tmap_arrange(tm_jobs, tm_test, nrow = 1)
tmap_both

# 3D Map
library(ggplot2)
library(rayshader)
# 2d map first
ggplot_jobs <- ggplot(cairo_sub_districts) +
                  geom_sf(aes(fill = pop_2018_c)) +
               scale_fill_viridis_c(option = "C")

ggplot_jobs
# use plot_gg() to turn into a 3d map
plot_gg(ggplot_jobs, multicore=TRUE,width=5,height=5,scale=250,windowsize=c(1400,866),
        zoom = 0.1, theta = 330, phi = 10)

render_snapshot()

# CENTROIDS

# get centroids in seperate feature 
district_centroids <- st_centroid(cairo_sub_districts)

# add lon and lat columns to dataframe using sfc_as_cols function
district_centroids <- sfc_as_cols(district_centroids)
