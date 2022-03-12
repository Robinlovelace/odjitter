cargo install --git https://github.com/dabreegster/odjitter
odjitter --help

# get data ------------------------------------------------------------
wget https://github.com/Robinlovelace/odjitter/releases/download/1/od_central.csv
wget https://github.com/Robinlovelace/odjitter/releases/download/1/zones.geojson
wget https://github.com/Robinlovelace/odjitter/releases/download/1/centroids.geojson
wget https://github.com/ITSLeeds/od/releases/download/v0.3.1/road_network_min.geojson
wget https://github.com/Robinlovelace/odjitter/releases/download/1/road_network_buffer.geojson

# Figure 4 ----------------------------------------------------------------
odjitter jitter --od-csv-path od_central.csv \
  --disaggregation-key all \
  --zones-path zones.geojson \
  --subpoints-origins-path road_network_buffer.geojson \
  --subpoints-destinations-path road_network_buffer.geojson \
  --rng-seed 42 \
  --disaggregation-threshold 1000 \
  --output-path output_threshold_1000.geojson

odjitter jitter --od-csv-path od_central.csv \
  --disaggregation-key all \
  --zones-path zones.geojson \
  --subpoints-origins-path road_network_buffer.geojson \
  --subpoints-destinations-path road_network_buffer.geojson \
  --rng-seed 42 \
  --disaggregation-threshold 100 \
  --output-path output_threshold_100.geojson

  # Benchmark:
  time odjitter jitter --od-csv-path od_central.csv \
  --disaggregation-key all \
  --zones-path zones.geojson \
  --subpoints-origins-path road_network_buffer.geojson \
  --subpoints-destinations-path road_network_buffer.geojson \
  --rng-seed 42 \
  --disaggregation-threshold 100 \
  --output-path output_threshold_100.geojson

#   Scraped 71 zones from zones.geojson
# Scraped 128906 subpoints from road_network_buffer.geojson
# Scraped 128906 subpoints from road_network_buffer.geojson
# Disaggregating OD data
# Wrote output_threshold_100.geojson

# real    0m0.609s
# user    0m0.552s
# sys     0m0.056s

# # In R:
#    user  system elapsed
#  17.198   0.048  17.216

