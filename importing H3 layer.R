library(sf)
library(ggplot2)
library(tmap)

# import the shapefile
cairo_hexagons <- st_read("Cairo Shapefiles/H3-res8/H3res-8_GCR_4326.shp")

# Remove all NUCs
# cairo_inner_central <- cairo_hexagons %>% filter(znng_t_ != "Outer")

# Remove 10th of Ramadan (it is in Sharqeya)
# dplyer::filter with !grepl. This removes all rows that contain 10th of Ramadan OR '10 of Rammadan' in nam_tfc column

cairo_hexagons <- cairo_hexagons %>% filter(!grepl('10th of Ramadan|10 Of Rammadan', nam_tfc))





# what is the projection?
#st_crs(cairo_hexagons)

# PLOT IT TO CHECK 
# plot(st_geometry(cairo_hexagons))
# plot(cairo_hexagons["pop2018cap"])


# get centroids in seperate feature (this is not the best way to get centroids)
h3_centroids <- st_centroid(cairo_hexagons)

#plot the centroids with the polygons (check that they are correct)
#tmap_mode("view")

#tm_shape(cairo_hexagons) +
#  tm_polygons(col = NA, alpha = 0.5) +
#tm_shape(h3_centroids) +
#  tm_dots(col = "blue")


# function to split c(lat, lon) to two seperate columns  FROM JM London (https://github.com/r-spatial/sf/issues/231)
# lat = Y lon = X
sfc_as_cols <- function(x, names = c("lon","lat")) {
  stopifnot(inherits(x,"sf") && inherits(sf::st_geometry(x),"sfc_POINT"))
  ret <- sf::st_coordinates(x)
  ret <- tibble::as_tibble(ret)
  stopifnot(length(names) == ncol(ret))
  x <- x[ , !names(x) %in% names]
  ret <- setNames(ret,names)
  dplyr::bind_cols(x,ret)
}

# add lon and lat columns to dataframe using sfc_as_cols function
h3_centroids <- sfc_as_cols(h3_centroids)


