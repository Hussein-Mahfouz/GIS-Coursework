library(osmdata)
library(tidyverse)

# get bounding box of Cairo
bb = getbb('Cairo, Egypt')

# opq used to build an overpass query
q <- opq(bbox = bb) %>%
  add_osm_feature(key = 'highway')
  

osmdata_xml(q, filename = 'test.osm')
osmdata_pbf(q, filename = '.pbf')

# save query as sp then plot to see if we have the correct area  
highways_cairo <- osmdata_sp(query)
sp::plot(highways_cairo$osm_lines)

# as sf (maybe quicker - DEFINATELY NOT. IT CREATES A FACETED PLOT THAT TAKES FOREVER)
# highways_cairo2 <- osmdata_sf(q)
# sf::plot(highways_cairo$osm_lines)

# 2nd Attempt (Cairo + Giza)

bb2 = getbb(c(29.839865, 30.821694, 30.273687, 31.779730))


query2 <- opq(bbox = c(30.801369, 29.705080, 31.874483, 30.390664)) %>%
  add_osm_feature(key = 'highway')   

osmdata_xml(query2, filename = 'OSM/greater-cairo.osm')

# save query as sp then plot to see if we have the correct area  
highways_greaterCairo <- osmdata_sp(query2)
sp::plot(highways_greaterCairo$osm_lines)
