# Get raw data into R:

# preprocessing the scottish data
#u = "http://www.scotlandscensus.gov.uk/documents/additional_tables/WU03BSC_IZ2011_Scotland.xlsx"
dir.create("data-raw")
#download.file(u, "data-raw/WU03BSC_IZ2011_Scotland.xlsx")
od_izo_header = readxl::read_excel("WU03BSC_IZ2011_Scotland.xlsx")
# View(od_izo_header)
od_izo = readxl::read_excel("WU03BSC_IZ2011_Scotland.xlsx", sheet = 2, skip = 3)
od_izo
(od_izo_names = od_izo_header$`Scotland's Census 2011 - National Records of Scotland`[9:19])
od_msoa = pct::get_od()
data.frame(od_izo_names, names(od_msoa)[1:11])
od_izo_names_new = c(names(od_msoa)[1:4], c("train", "bus"), names(od_msoa)[c(10:14)])
data.frame(od_izo_names, od_izo_names_new)
#                                                               od_izo_names od_izo_names_new
# 1                                               1. Area of usual residence        geo_code1
# 2                                                     2. Area of workplace        geo_code2
# 3  3. All people aged 16 and over in employment the week before the census              all
# 4                                        4. Work or mainly at or from home        from_home
# 5                       5. Train or underground, metro, light rail or tram            train
# 6                                                 6. Bus, minibus or coach              bus
# 7                                                  7. Driving a car or van       car_driver
# 8                                             8. Passenger in a car or van    car_passenger
# 9                                                               9. Bicycle          bicycle
# 10                                                             10. On foot             foot
# 11                                         11. All other methods of travel            other
names(od_izo) = od_izo_names_new
od_izo = od_izo[-1, ]
od_izo = na.omit(od_izo)
summary(od_izo)
mean(od_izo$car_passenger) / mean(od_izo$car_driver) # looks right
nrow(od_izo) / 1000
saveRDS(od_izo, "od_izo.Rds")

# check with zone data
# zones_iz = readRDS("zones_iz.Rds")
# edinburgh_region = readRDS("edinburgh_region.Rds")
# plot(zones_iz$geometry)
# head(zones_iz$geo_code1)
# head(od_izo$geo_code1)
# summary(od_izo$geo_code1 %in% zones_iz$geo_code1) # all FALSE
# summary(od_izo$geo_code1 %in% desire_iz$geo_code1) # all FALSE

## get 2011 centroids:
# get the centroids
# https://spatialdata.gov.scot/geonetwork/srv/eng/catalog.search#/metadata/0b5ec34c-f73d-44ad-b121-d9c63daae81b
dir.create("data-raw/iz_cents11-uk")
setwd("data-raw/iz_cents11-uk")
u = "https://maps.gov.scot/ATOM/shapefiles/SG_IntermediateZoneCent_2011.zip"
iz_cents11_uk = ukboundaries::duraz(u) # fails
setwd("../..")
iz_cents11_uk = sf::read_sf("data-raw/iz_cents11-uk/SG_IntermediateZone_Cent_2011.shp") # works!
sf::st_crs(iz_cents11_uk) # 27700
iz_cents11_uk = sf::st_transform(iz_cents11_uk, 4326)
plot(iz_cents11_uk$geometry) # pretty sparse in rural areas
summary(iz_cents11_uk$InterZone %in% od_izo$geo_code1) # All true
summary(od_izo$geo_code1 %in% iz_cents11_uk$InterZone) # All true
summary(od_izo$geo_code2 %in% iz_cents11_uk$InterZone) # mostly true!
mean(iz_cents11_uk$TotPop2011)
saveRDS(iz_cents11_uk, "iz_cents11_uk.Rds")
# [1] 4139.879 # like LSOAs

# u = "http://sedsh127.sedsh.gov.uk/Atom_data/ScotGov/ZippedShapefiles/SG_IntermediateZoneBdry_2011.zip"
u = "https://maps.gov.scot/ATOM/shapefiles/SG_IntermediateZoneBdry_2011.zip"
dir.create("data-raw/SG_IntermediateZoneBdry_2011")
setwd("data-raw/SG_IntermediateZoneBdry_2011")
iz_zones11_uk = ukboundaries::duraz(u)
list.files()
iz_zones11_uk = sf::read_sf("SG_IntermediateZone_Bdry_2011.shp")
sf::st_crs(iz_zones11_uk) # 27700
iz_zones11_uk = sf::st_transform(iz_zones11_uk, 4326)
setwd("../..")

# Takes some time:
saveRDS(iz_zones11_uk, "iz_zones11_uk.Rds")
iz_zones11_uk = rmapshaper::ms_simplify(iz_zones11_uk, 0.08, sys = TRUE)
saveRDS(iz_zones11_uk, "iz_zones11_uk_simplified.Rds")
mapview::mapview(iz_zones11_uk[1:9, ])
