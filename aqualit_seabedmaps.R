library(sf)
library(tidyverse)
library(leaflet)
library(htmltools)
library(rgdal)

#import microplastic data as geospatial data
mpseabed <- st_read("./data/seabed_pt.csv",stringsAsFactors=FALSE)
mpseabed_sp <- st_as_sf(mpseabed, 
                        coords = c("Start_long","Start_lat"), 
                        crs=4326)

#checking the CRS never hurts
st_crs(mpseabed_sp) 

#plot geospatial data using ggplot
ggplot(data = mpseabed_sp) +
  geom_sf(aes(color = Class)) +
  #colorbrewer palettes: http://colorbrewer2.org
  scale_color_brewer(palette="YlOrRd") 

#plot geospatial data using leaflet (also check out https://rstudio.github.io/leaflet/)

#first step: define color palette
mp_pal <- colorFactor(palette="YlOrRd",domain = mpseabed_sp$Class)

#basic map
mp_map <- leaflet() %>%
  addTiles() %>%
  #set view to center coordinates of Europe + OSM zoom level 3 (https://wiki.openstreetmap.org/wiki/Zoom_levels)
  setView(25.33,54.90,3) %>%
  addCircleMarkers(data=mpseabed_sp,
                   color = ~mp_pal(mpseabed_sp$Class),
                   radius = 5,
                   stroke = FALSE,
                   fillOpacity=1,
                   #add extra information (here: source) in popup
                   popup = mpseabed_sp$Reference,
                   popupOptions = popupOptions(maxWidth = 1000, 
                                               closeOnClick = TRUE))
mp_map

#full option map
mp_map <- leaflet() %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  setView(25.33,54.90,3) %>%
  addCircleMarkers(data=mpseabed_sp,
                   color = ~mp_pal(mpseabed_sp$Class),
                   radius = 5,
                   stroke = FALSE,
                   fillOpacity=1,
                   #clusterOptions = markerClusterOptions(),
                   popup = mpseabed_sp$Reference,
                   popupOptions = popupOptions(maxWidth = 1000, 
                                               closeOnClick = TRUE),
                   group = "AQUA-LIT") %>%
  addWMSTiles("http://www.ifremer.fr/services/wms/emodnet_chemistry2",
              layers = "sl_totalabundance",
              options = WMSTileOptions(format = "image/png", transparent = TRUE),
              group = "EMODnet Chemistry") %>%
  addWMSTiles("https://www.gebco.net/data_and_products/gebco_web_services/web_map_service/mapserv?",
              layers = "GEBCO_LATEST",
              options = WMSTileOptions(format = "image/png", transparent = TRUE),
              group = "GEBCO global grid") %>% 
  addLegend("bottomright",
            values=mpseabed_sp$Class,
            pal=mp_pal,
            title = "Percentage of litter originating from aquaculture and/or fisheries",
            opacity = 1
  ) %>% 
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner Lite", "GEBCO global grid"),
    overlayGroups = c("AQUA-LIT", "EMODnet Chemistry"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  addMiniMap(toggleDisplay = TRUE)
mp_map

