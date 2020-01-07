# test Moran's i 
library(spdep)

# 1 - define spatial weights matrix Wij

#convert from sf to sp
cairo_hexagonsSP <- as(cairo_hexagons, 'Spatial')
#calculate the centroids of all the Hexagons
coordsH <- coordinates(cairo_hexagonsSP)
plot(coordsH)

# simple binary matrix of queen’s case neighbours
# Polygons with a shared edge or a corner will be included in computations for the target polygon

#create a neighbours list
cairo_hex_nb <- poly2nb(cairo_hexagonsSP, queen=T)
#plot them
plot(cairo_hex_nb, coordinates(coordsH), col="red")
#add a map underneath
plot(cairo_hexagonsSP, add=T)

#create a spatial weights object from these weights
Cai.lw <- nb2listw(cairo_hex_nb, style="C", zero.policy=TRUE)  # zero.policy=TRUE to avoid error: empty neighbor sets found
head(Cai.lw$neighbours)

# GLOBAL STATISTICS

# calculate global moran's i for jobs_reach
set.ZeroPolicyOption(TRUE) #set's zero.policy = TRUE for subsquent function calls in current session

I_CairoHex_Global_Jobs_Added_Inf <- moran.test(cairo_hexagonsSP@data$jobs_60_inf, Cai.lw)
I_CairoHex_Global_Jobs_Added_Inf
# Moran's I Statistic = 0.51

# calculate Geary’s C (similar values or dissimilar values are clusering)          
C_CairoHex_Global_Jobs_Added_Inf <- geary.test(cairo_hexagonsSP@data$jobs_60_inf, Cai.lw)
C_CairoHex_Global_Jobs_Added_Inf      
# Geary C Statistic = 0.61

# calculate Getis Ord General G (whether high or low values are clustering)
G_CairoHex_Global_Jobs_Added_Inf <- globalG.test(cairo_hexagonsSP@data$jobs_60_inf, Cai.lw)
G_CairoHex_Global_Jobs_Added_Inf      

# LOCAL STATISTICS

# local moran

#localmoran function to generate I for each hexagon
I_CairoHex_Local_Jobs_Added_Inf <- localmoran(cairo_hexagonsSP@data$jobs_60_inf, Cai.lw)
#what does the output (the localMoran object) look like?
head(I_CairoHex_Local_Jobs_Added_Inf)

# copy column 1 (i-score) and 5 (z-score standard deviation) back into the SP dataframe (cairo_hexagonsSP)
cairo_hexagonsSP@data$BLocI <- I_CairoHex_Local_Jobs_Added_Inf[,1]
cairo_hexagonsSP@data$BLocIz <- I_CairoHex_Local_Jobs_Added_Inf[,4]

# MAP OUTPUTS


# breaks based on standard deviations
breaks1<-c(-1000,-2.58,-1.96,-1.65,1.65,1.96,2.58,1000)
# diverging color palette
library(RColorBrewer)
MoranColours<- rev(brewer.pal(8, "RdGy"))

tm_shape(cairo_hexagonsSP) +
  tm_fill("BLocIz",
              style="fixed",
              breaks=breaks1,
              palette=MoranColours,
              midpoint=NA,
              title="Local Moran's I, Additional Job Reach") +
tm_shape(cairo_metro) + 
  tm_lines(col = 'gray23', lwd = 2, alpha = 0.8)
  

# local getis ord
Gi_CairoHex_Local_Jobs_Added_Inf <- localG(cairo_hexagonsSP@data$jobs_60_inf, Cai.lw)
head(Gi_CairoHex_Local_Jobs_Added_Inf)

cairo_hexagonsSP@data$BLocGiR <- Gi_CairoHex_Local_Jobs_Added_Inf

# Map

GIColours<- rev(brewer.pal(8, "RdBu"))

#now plot on an interactive map
tm_shape(cairo_hexagonsSP) +
  tm_polygons("BLocGiR",
              style="fixed",
              breaks=breaks1,
              palette=GIColours,
              midpoint=NA,
              title="Gi*, Additional Job Reach")
