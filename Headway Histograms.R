library(sf)
library(ggplot2)
library(dplyr)

# read shapefile and drop geometry
routes_df <- st_read("Cairo Shapefiles/Combined_P_U.shp") %>% st_drop_geometry() 

routes_df <-  subset(routes_df, agency_id==c('CTA', 'CTA_M', 'P_O_14'))

# plot headways

# To change the facet labels https://www.datacamp.com/community/tutorials/facets-ggplot-r
variable_names <- c(
  "CTA" = "CTA Bus - Formal" ,
  "CTA_M" = "CTA Minibus - Formal",
  "P_O_14" = "Microbus - Informal")


ggplot(routes_df, aes(x=headway_se)) +
      geom_histogram(alpha=0.5, show.legend = FALSE, color = 'black') +
        #ggtitle("Headway Distribution for All Modes") + theme(plot.title = element_text(hjust=0.5, size = 25)) +
        labs(x = "Headway (s)", y = "No. of Routes") +
        theme(axis.text=element_text(size=14),
              axis.title=element_text(size=17)) +
        scale_x_continuous(labels = scales::comma_format())  +                        # add comma to x labels
  #geom_vline(data = ddply(routes_df, "agency_id", summarize, headway = mean(headway_se)), aes(xintercept=headway)) +
      facet_wrap(~agency_id,  nrow =1, labeller = labeller(agency_id = variable_names)) +
        theme(strip.text.x = element_text(face = "bold", size = 20))
  
ggsave("Visuals/headways.pdf", width = 10)



routes_df %>% group_by(agency_id) %>% 
  summarise(Average_Headway = (mean(headway_se))/60,
            SD_Headway      = (sd(headway_se))/60)
