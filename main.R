library(geojsonsf)
library(sf)
library(data.table)

csv_path = "data/od_min.csv"
zones = sf::read_sf("data/zones_min.geojson")

jitter = function(
        zones,
        csv_path,
        max_per_od=1,
        origin_key='geo_code1',
        destination_key='geo_code2',
        all_key='all'
        ) {

  # browser()
  od_original = data.table::fread(csv_path)
  i = 1
  system.time({

  odgeoms = lapply(seq(nrow(od_original)), function(i) {
  # odgeoms = lapply(1, function(i) {
    message(i)
    origin_code = od_original[[1]][i]
    destination_code = od_original[[2]][i]
    origin_zone = zones$geometry[zones[[1]] == origin_code]
    destination_zone = zones$geometry[zones[[1]] == destination_code]
    n_row = ceiling(od_original$all[i] / max_per_od)
    o_point = sf::st_sample(origin_zone, size = n_row)
    d_point = sf::st_sample(destination_zone, size = n_row)
    o_mat = sfheaders::sfc_to_df(o_point)
    d_mat = sfheaders::sfc_to_df(d_point)
    od::odc_to_sf(cbind(o_mat, d_mat))
  })
  })
  od_sfc = do.call(what = c, args = odgeoms)

}
