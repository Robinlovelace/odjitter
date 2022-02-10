# devtools::install_github("itsleeds/od")
library(sf)
library(tmap)
library(tidyverse)
library(stplanr)


# read-in data ------------------------------------------------------------
od = readr::read_csv("https://github.com/Robinlovelace/odjitter/releases/download/1/od_central.csv")
zones = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/zones.geojson")
centroids = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/centroids.geojson")
road_network_min = sf::read_sf("https://github.com/ITSLeeds/od/releases/download/v0.3.1/road_network_min.geojson")
road_network_buffer = sf::read_sf("https://github.com/Robinlovelace/odjitter/releases/download/1/road_network_buffer.geojson")
central_edinburgh = tmaptools::geocode_OSM(q = "edinburgh", as.sf = TRUE)
central_edinburgh_5km = sf::st_buffer(central_edinburgh, dist = 5000)
edinburgh_region = sf::read_sf("https://github.com/ITSLeeds/od/releases/download/v0.3.1/edinburgh_region.geojson")
zones_centroids = sf::st_centroid(zones)
zones_centroids_5km = zones_centroids[central_edinburgh_5km, ]


# Figure 1 ----------------------------------------------------------------
m1 = tm_shape(zones) + tm_polygons("TotPop2011", title = "Population", palette = "viridis") +
  tm_scale_bar() +
  tm_minimap(zoomLevelOffset = -7)
tmap_leaflet(m1)


# Figure 2 ----------------------------------------------------------------

# head(centroids)
od_sf = od::od_to_sf(od, centroids)
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
bbox = sf::st_bbox(zones_in_top3)
m1 = tm_shape(od_sf_top3, bbox = bbox) +
  tm_lines("foot", palette = "Set1", breaks = c(100, 200, 300, 400), lwd = 6) +
  tm_shape(zones) +
  tm_borders() +
  tm_shape(zones_in_top3) +
  tm_text("InterZone", size = 0.8) +
  tm_scale_bar()


# Figure 3 ----------------------------------------------------------------
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
tmap_arrange(m1, m2, m3, m4, nrow = 2)

od_combined = rbind(
  od_sf_top3 %>% transmute(foot, type = fn[1]),
  od_top3_jittered %>% transmute(foot, type = fn[2]),
  od_top3_road %>% transmute(foot, type = fn[3]),
  od_top3_disaggregated %>% transmute(foot, type = fn[4])
)
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
knitr::kable(od_to_disag, caption = "Attribute data associated with an OD pair before disaggregation.", booktabs = TRUE)

## ----dis2-----------------------------------------------------------------------------------------------------------------------------------
knitr::kable(od_disaggregated, caption = "Attribute data associated with an OD pair after disaggregation.", booktabs = TRUE)

# Figure 4 ----------------------------------------------------------------
bbox = tmaptools::bb(od_sf, ext = 1.2)
od_sf_jittered = od::od_jitter(od_sf, z = zones)
od_sf_road = od::od_jitter(od_sf, z = zones, road_network_buffer, max_per_od = 1000)
od_sf_disaggregated = od::od_jitter(od_sf, z = zones, road_network_buffer, max_per_od = 100)
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
tmap_arrange(m1, m2, m3, m4, nrow = 2)


# Figure 5 ----------------------------------------------------------------

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

