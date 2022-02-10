# devtools::install_github("itsleeds/od")
library(sf)
library(tmap)
library(tidyverse)
library(stplanr)


## ---- eval=FALSE----------------------------------------------------------------------------------------------------------------------------
## file.copy("README.html", "jittering-paper.html")
## file.copy("README.pdf", "jittering-paper-resubmission.pdf", TRUE)
## piggyback::pb_upload("jittering-paper-resubmission.pdf")
## piggyback::pb_download_url("jittering-paper-resubmission.pdf")
## # Generate citations (requires Zotero)
## library(rbbt)
## # old way:
## # bbt_write_bib(path = "references.bib", keys = bbt_detect_citations("README.Rmd"), overwrite = TRUE)
## # new way:
## bbt_update_bib("README.Rmd", "references.bib")
## # trackdown::upload_file(file = "README.Rmd", path_output = "README.docx")
## # trackdown::update_file(file = "README.Rmd", path_output = "README.docx")


## ----haystack, fig.cap="Illustration of how geographic visualisation and routing can add value to OD datasets and make them more policy relevant."----
# todo: update this if needed, commented out to save space and cut to the chase!
# knitr::include_graphics("https://user-images.githubusercontent.com/1825120/142071229-81358e26-5e8d-437e-9ef8-91704a4e690f.png")


## ----get-osm-data, eval=FALSE---------------------------------------------------------------------------------------------------------------
## road_network_area = osmextract::oe_get_network(place = "Scotland", mode = "cycling")
## road_network = road_network_area[edinburgh_region, ]
## saveRDS(road_network, "road_network.Rds")
## road_network_touching = road_network[zones_touching, ]
## nrow(road_network) # 35k
## nrow(road_network_touching) # 6k
## table(road_network_touching$highway)
## road_network_min = road_network_touching %>%
##   # filter(str_detect(string = highway, pattern = "cycle|prim|sec|tert"))
##   filter(highway %in% c("primary", "secondary", "tertiary"))
## nrow(road_network_min) # 800
## plot(road_network_min["highway"])
## saveRDS(road_network_min, "road_network_min.Rds")
## piggyback::pb_upload("road_network_min.Rds", repo = "itsleeds/od")
## piggyback::pb_download_url("road_network_min.Rds", repo = "itsleeds/od")


## ----read-inputs----------------------------------------------------------------------------------------------------------------------------
# u = "https://github.com/ITSLeeds/od/releases/download/0.2.1/od_iz_ed.Rds"
# f = basename(u)
# if(!file.exists(f)) download.file(u, f)
# od = readRDS("od_iz_ed.Rds")
# readr::write_csv(od, "od_iz_ed.csv")
# piggyback::pb_upload("od_iz_ed.csv", repo = "itsleeds/od")
# piggyback::pb_download_url("od_iz_ed.csv", repo = "itsleeds/od")
# od = readr::read_csv("https://github.com/ITSLeeds/od/releases/download/v0.3.1/od_iz_ed.csv")
od = readr::read_csv("https://github.com/Robinlovelace/odjitter/releases/download/1/od_central.csv")
# head(od)

# u = "https://github.com/ITSLeeds/od/releases/download/0.2.1/iz_zones11_ed.Rds"
# f = basename(u)
# if(!file.exists(f)) download.file(u, f)
# zones = readRDS("iz_zones11_ed.Rds")
# sf::write_sf(zones, "iz_zones11_ed.geojson")
# piggyback::pb_upload("iz_zones11_ed.geojson", repo = "itsleeds/od")
# zones = sf::read_sf("https://github.com/ITSLeeds/od/releases/download/v0.3.1/iz_zones11_ed.geojson")
zones = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/zones.geojson")

# head(zones)

# u = "https://github.com/ITSLeeds/od/releases/download/0.2.1/iz_cents11_ed.Rds"
# f = basename(u)
# if(!file.exists(f)) download.file(u, f)
# centroids = readRDS(f)
# sf::write_sf(centroids, "iz_centroids11_ed.geojson")
# piggyback::pb_upload("iz_centroids11_ed.geojson", repo = "itsleeds/od")
# centroids = sf::read_sf("https://github.com/ITSLeeds/od/releases/download/v0.3.1/iz_centroids11_ed.geojson")
# centroids = centroids[zones, ]
# nrow(centroids) # 71
# sf::write_sf(centroids, "centroids.geojson")
# piggyback::pb_upload("centroids.geojson")
centroids = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/centroids.geojson")

# u = "https://github.com/ITSLeeds/od/releases/download/v0.3.1/road_network_min.Rds"
# f = basename(u)
# if(!file.exists(f)) download.file(u, f)
# road_network_min = readRDS(f)
# sf::write_sf(road_network_min, "road_network_min.geojson")
# piggyback::pb_upload("road_network_min.geojson", repo = "itsleeds/od")
road_network_min = sf::read_sf("https://github.com/ITSLeeds/od/releases/download/v0.3.1/road_network_min.geojson")
road_network_buffer = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/road_network_buffer.geojson")


## ----read-region----------------------------------------------------------------------------------------------------------------------------
# lads_uk = ukboundaries::lad2018
# # # names(lads_uk)
# lads_scotland = lads_uk %>%
#   filter(str_detect(lau118cd, "S"))
# # saveRDS(lads_scotland, "lads_scotland.Rds")
# # library(dplyr)
# # lads_scotland = readRDS("lads_scotland.Rds")
# # piggyback::pb_upload("lads_scotland.Rds")
#
# edinburgh_region = lads_scotland %>%
#   dplyr::filter(lau118nm == "Edinburgh, City of")
# # saveRDS(edinburgh_region, "edinburgh_region.Rds")
# sf::write_sf(edinburgh_region, "edinburgh_region.geojson")
# piggyback::pb_upload("edinburgh_region.geojson", repo = "itsleeds/od")
central_edinburgh = tmaptools::geocode_OSM(q = "edinburgh", as.sf = TRUE)
central_edinburgh_5km = sf::st_buffer(central_edinburgh, dist = 5000)
edinburgh_region = sf::read_sf("https://github.com/ITSLeeds/od/releases/download/v0.3.1/edinburgh_region.geojson")
zones_centroids = sf::st_centroid(zones)
zones_centroids_5km = zones_centroids[central_edinburgh_5km, ]
# zones = zones %>%
#   filter(InterZone %in% zones_centroids_5km$InterZone)
# road_network_buffer = road_network_touching[zones, ]
# saveRDS(road_network_buffer, "road_network_buffer.Rds")
# sf::write_sf(road_network_buffer, "road_network_buffer.geojson")
# piggyback::pb_upload("road_network_buffer.geojson")

# sum(zones$TotPop2011) # 476626
m1 = tm_shape(zones) + tm_polygons("TotPop2011", title = "Population", palette = "viridis") +
  tm_scale_bar() +
  tm_minimap(zoomLevelOffset = -7)
# tmap_leaflet(m1)


## ----izs, fig.cap="Overview of the study region with the population from the 2011 Census at the level of Intermediate Zones corresponding to fill colour.", out.width="50%"----
# See interactive map online at https://rpubs.com/RobinLovelace/843442
knitr::include_graphics("figures/overview-zones-central.png")


## ----odsf-----------------------------------------------------------------------------------------------------------------------------------
# head(centroids)
od_sf = od::od_to_sf(od, centroids)
# od_sf_central = od_sf %>%
#   filter(geo_code1 %in% zones$InterZone) %>%
#   filter(geo_code2 %in% zones$InterZone)
# od_sf = od_sf_central %>%
#   top_n(n = 500, wt = foot)
# od_central = od_sf %>% sf::st_drop_geometry()
# nrow(od_central) # 514
# write_csv(od_central, "od_central.csv")
# piggyback::pb_upload("od_central.csv")


od_sf_top3 = od_sf %>%
  filter(geo_code1 != geo_code2) %>%
  top_n(n = 3, wt = all) %>%
  select(geo_code1, geo_code2, all, foot, bicycle, bus, car_driver) %>%
  arrange(desc(all))
centroids_top = centroids %>%
  filter(InterZone %in% c(od_sf_top3$geo_code1, od_sf_top3$geo_code2))
# tmap_mode("view")
zones_in_top3 = zones %>%
  filter(InterZone %in% c(od_sf_top3$geo_code1, od_sf_top3$geo_code2))

k = od_sf_top3 %>%
  sf::st_drop_geometry() %>%
  kableExtra::kable()
# k
# zones_touching = zones[zones_in_top3, ]
# saveRDS(zones_touching, "zones_touching.Rds")
bbox = sf::st_bbox(zones_in_top3)
m1 = tm_shape(od_sf_top3, bbox = bbox) +
  tm_lines("foot", palette = "Set1", breaks = c(100, 200, 300, 400), lwd = 6) +
  tm_shape(zones) +
  tm_borders() +
  tm_shape(zones_in_top3) +
  tm_text("InterZone", size = 0.8) +
  tm_scale_bar()
# m1
# writeLines(k, "/tmp/kable.html")
# browseURL("/tmp/kable.html")


## ----od, fig.cap="Illustration of input data in tabular (bottom right, inset) and geographic form (in the map). Note how the ID codes in the first two columns of the table correspond with IDs in the zone data and how the cells in the 'foot' column are represented geographically on the map.", fig.show='hold', out.width="80%"----
knitr::include_graphics(c(
  "figures/od-top-3-zones-metafigure.png"
  # "figures/od-top-3-table.png",
  # "figures/od-top-3.png"
))


## ----jitters, fig.cap="Illustration of jittering and disaggregation of OD data with a minimal input dataset.", out.width="80%"--------------
set.seed(2021)
fn = c(
  "A) Centroid based desire lines",
  "B) Jittered desire lines (random point sampling)",
  "C) Jittered desire lines (sample from network)",
  "D) Jittered desire lines (with disaggregation)"
)
od_top3_jittered = od::od_jitter(od_sf_top3, z = zones)
od_top3_road = od::od_jitter(od_sf_top3, z = zones, road_network_min, max_per_od = 1000)
od_top3_disaggregated = od::od_jitter(od_sf_top3, z = zones, road_network_min, max_per_od = 100)
# od_top3_disaggregated = od::od_jitter(od_sf_top3, z = zones, road_network_min, max_per_od = 200, population_column = "foot")
m1 =  tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(od_sf_top3, bbox = bbox) +
  tm_lines("foot", palette = "Set1", breaks = c(100, 200, 300, 400), lwd = 6, title.col = "Walking trips per day") +
  tm_layout(title = "A) Single origin and destination point per zone", title.bg.color =  "white")
m2 =  tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(od_top3_jittered, bbox = bbox) +
  tm_lines("foot", palette = "Set1", breaks = c(100, 200, 300, 400), lwd = 6, title.col = "Walking trips per day") +
  tm_layout(title = "B) Randomised origin and destination points", title.bg.color =  "white")
m3 =  tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(road_network_min, bbox = bbox) +
  tm_lines(col = "darkgreen") +
  tm_shape(od_top3_road) +
  tm_lines("foot", palette = "Set1", breaks = c(100, 200, 300, 400), lwd = 6, title.col = "Walking trips per day") +
  tm_layout(title = "C) Randomised points sampled from transport network", title.bg.color =  "white", legend.position = c("right", "bottom"))
m4 = tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(road_network_min, bbox = bbox) +
  tm_lines(col = "darkgreen") +
  tm_shape(od_top3_disaggregated, bbox = bbox) +
  tm_lines("foot", palette = "Set1", lwd = 6, breaks = c(50, 60, 70, 80), title.col = "Walking trips per day") +
  tm_layout(title = "D) Jittered result with disaggregation and points on network", title.bg.color =  "white", legend.position = c("right", "bottom"))
# todo: add a 4th figure showing sampling on the network
# m3
tmap_arrange(m1, m2, m3, m4, nrow = 2)

od_combined = rbind(
  od_sf_top3 %>% transmute(foot, type = fn[1]),
  od_top3_jittered %>% transmute(foot, type = fn[2]),
  od_top3_road %>% transmute(foot, type = fn[3]),
  od_top3_disaggregated %>% transmute(foot, type = fn[4])
)



## ----desire---------------------------------------------------------------------------------------------------------------------------------
# od_top_100 = od %>%
#   top_n(n = 100, wt = all)
# desire_lines = od::od_to_sf(x = od_top_100, z = centroids)
# nrow(desire_lines)
# plot(desire_lines)
# subpoints = sf::st_sample(x = zones, size = 10000)


## ----jittered-------------------------------------------------------------------------------------------------------------------------------
# desire_lines_jittered = od::od_jitter(od = desire_lines, z = zones)
# plot(desire_lines$geometry)
# plot(desire_lines_jittered$geometry)


## -------------------------------------------------------------------------------------------------------------------------------------------
od_to_disag = od_sf_top3 %>%
  sf::st_drop_geometry() %>%
  slice(1) %>%
  transmute(representation = "original", geo_code1, geo_code2, all, foot)
od_disaggregated = od_top3_disaggregated %>%
  sf::st_drop_geometry() %>%
  filter(o_agg == od_to_disag$geo_code1) %>%
  filter(d_agg == od_to_disag$geo_code2) %>%
  transmute(representation = "disaggregated", geo_code1 = o_agg, geo_code2 = d_agg, all, foot)


## ----dis1-----------------------------------------------------------------------------------------------------------------------------------
# kableExtra::kable(od_to_disag, caption = "Attribute data associated with an OD pair before disaggregation.")
# gt::gt(od_to_disag, caption = "Attribute data associated with an OD pair before disaggregation.")
knitr::kable(od_to_disag, caption = "Attribute data associated with an OD pair before disaggregation.", booktabs = TRUE)


## ----dis2-----------------------------------------------------------------------------------------------------------------------------------
# knitr::kable(od_disaggregated, caption = "Attribute data associated with an OD pair after disaggregation.")
# gt::gt(od_disaggregated, caption = "Attribute data associated with an OD pair after disaggregation.")
knitr::kable(od_disaggregated, caption = "Attribute data associated with an OD pair after disaggregation.", booktabs = TRUE)


## ----jittered514, fig.cap="Results showing the conversion of OD data to geographic desire lines using population weighted centroids for origins and destinations (A) and jittered results. The jittered results illustrate jittering with simple random sampling of origin and destination locations (B), sampling on the network (C), and sampling on the network plus disaggregation of OD pairs representing more than 100 trips (D)."----
# sum(od_sf$foot) / sum(od_sf_central$foot) # 80%
# qtm(zones) +
# tm_shape(od_sf) +
#   tm_lines()
bbox = tmaptools::bb(od_sf, ext = 1.2)

od_sf_jittered = od::od_jitter(od_sf, z = zones)
od_sf_road = od::od_jitter(od_sf, z = zones, road_network_buffer, max_per_od = 1000)
od_sf_disaggregated = od::od_jitter(od_sf, z = zones, road_network_buffer, max_per_od = 100)
# od_sf_disaggregated = od::od_jitter(od_sf, z = zones, road_network_min, max_per_od = 200, population_column = "foot")
m1 =  tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(od_sf, bbox = bbox) +
  tm_lines(lwd = "foot", scale = 3, title.lwd = "Walking trips per day", legend.lwd.show = FALSE) +
  tm_layout(title = "A) Single origin and destination point per zone", title.bg.color =  "white", legend.position = c("right", "bottom"), legend.bg.alpha = 0.3)
m2 =  tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(od_sf_jittered, bbox = bbox) +
  tm_lines(lwd = "foot", scale = 3, title.lwd = "Walking trips per day", legend.lwd.show = FALSE) +
  tm_layout(title = "B) Randomised origin and destination points", title.bg.color =  "white", legend.position = c("right", "bottom"), legend.bg.alpha = 0.3)
m3 =  tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(road_network_buffer, bbox = bbox) +
  tm_lines(col = "darkgreen", lwd = 0.1) +
  tm_shape(od_sf_road) +
  tm_lines(lwd = "foot", scale = 3, title.lwd = "Walking trips per day", legend.lwd.show = FALSE) +
  tm_layout(title = "C) Randomised points sampled from transport network", title.bg.color =  "white", legend.position = c("right", "bottom"), legend.bg.alpha = 0.3)
m4 = tm_shape(zones, bbox = bbox) +
  tm_borders(col = "grey") +
  tm_shape(road_network_buffer, bbox = bbox) +
  tm_lines(col = "darkgreen", lwd = 0.1) +
  tm_shape(od_sf_disaggregated, bbox = bbox) +
  tm_lines(lwd = "foot", scale = 3, title.lwd = "Walking trips per day", legend.lwd.show = FALSE) +
  tm_layout(title = "D) Jittered result with disaggregation and points on network", title.bg.color =  "white", legend.position = c("right", "bottom"), legend.bg.color = "white", legend.bg.alpha = 0.3)
# todo: add a 4th figure showing sampling on the network
# m3
tmap_arrange(m1, m2, m3, m4, nrow = 2)


## ---- eval=FALSE----------------------------------------------------------------------------------------------------------------------------
## routes_od = route(l = od_sf, route_fun = route_osrm, osrm.profile = "foot")
## sf::write_sf(routes_od, "routes_od.geojson")
## routes_jittered = route(l = od_sf_jittered, route_fun = route_osrm, osrm.profile = "foot")
## sf::write_sf(routes_jittered, "routes_jittered.geojson")
## routes_road = route(l = od_sf_road, route_fun = route_osrm, osrm.profile = "foot")
## sf::write_sf(routes_road, "routes_road.geojson")
## routes_disaggregated = route(l = od_sf_disaggregated, route_fun = route_osrm, osrm.profile = "foot", wait = 0.01)
## sf::write_sf(routes_disaggregated, "routes_disaggregated.geojson")
## f = list.files(pattern = "geojson")
## piggyback::pb_upload(f)
## piggyback::pb_download_url(f)


## ----rneted, fig.cap="Route network results derived from non-jittered OD data (left) and OD data that had been jittered, with pre-processing steps including disaggregation of large flows and randomisation of origin and destionation points on the transport network (right).", out.width="100%"----
# manual approach
# routes_od = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/routes_od.geojson")
# routes_jittered = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/routes_jittered.geojson")
# routes_road = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/routes_road.geojson")
# routes_disaggregated = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/routes_disaggregated.geojson")
f = c(
  "routes_od",
  "routes_jittered",
  "routes_road",
  "routes_disaggregated"
)
i = 1
rnets = purrr::map_dfr(seq(length(f)), function(i) {
  fi = f[i]
  u = paste0("https://github.com/Robinlovelace/odjitter/releases/download/1/", fi, ".geojson")
  routes = sf::read_sf(u)
  rnet = overline(routes, attrib = "foot")
  rnet$type = fn[i]
  rnet
})
# summary(rnets$foot)
tm_shape(rnets %>% mutate(foot = case_when(foot < 50 ~ 50, TRUE ~ foot)), bbox = tmaptools::bb(rnets, 0.5)) +
  tm_lines(lwd = "foot", scale = 15, lwd.legend = c(100, 500, 1000, 2000), title.lwd = "Walking trips per day") +
  tm_facets("type", free.scales.line.lwd = FALSE) +
  tm_layout(legend.outside.position = "top", legend.outside.size = 0.2)
# knitr::include_graphics("figures/rneted-updated.png")



## ----sumtable-------------------------------------------------------------------------------------------------------------------------------
rnets$length_km = as.numeric(sf::st_length(rnets)) / 1000

rnets_summary = rnets %>%
  sf::st_drop_geometry() %>%
  group_by(type) %>%
  mutate(type = str_sub(type, 1, 3)) %>%
  summarise(
    `Network length (km)` = sum(length_km),
    `Average flow per segment` = mean(foot),
    `Standard deviation` = sd(foot)
  )
rnets_summary$`N. OD pairs` = c(rep(nrow(od_sf), 3), nrow(od_sf_disaggregated))

rnets_summary %>%
  select(type, `N. OD pairs`, everything()) %>%
  knitr::kable(booktabs = TRUE, digits = 0, caption = "Summary of desire line and route network level results.")

