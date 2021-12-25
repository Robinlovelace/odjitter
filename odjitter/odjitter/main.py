import csv
import geojson
import json
from math import ceil
import random
import shapely
from shapely.geometry import shape, LineString, Point


def jitter(max_per_od):
    # Build a dictionary from zone codes to polygons
    zones = {}
    gj = geojson.load(open("../data/zones_min.geojson"))
    for feature in gj['features']:
        name = feature['properties']['InterZone']
        polygon = shape(feature['geometry'])
        zones[name] = polygon

    # (linestring, dictionary) pairs
    output = []

    for row in csv.DictReader(open("../data/od_min.csv")):
        origin_zone = zones[row['geo_code1']]
        destination_zone = zones[row['geo_code2']]

        # How many times will we jitter this one row?
        this_row_n = float(row['all'])
        factor = this_row_n / max_per_od

        # Scale all of the properties
        del row['geo_code1']
        del row['geo_code2']

        for k, v in row.items():
            row[k] = float(v) * factor

        for _ in range(ceil(factor)):
            o = random_point_in_polygon(origin_zone)
            d = random_point_in_polygon(destination_zone)
            line = LineString([o, d])
            output.append((row, line))

    return output



# 100 rows, max = 200 -> 1 output
# 100 rows, max = 1 -> 100 output

# 100 rows, max = 2 -> 50 output
    # bike = 1
    # car = 99 
    

# all, car, bike, drive, jog
# max_per_od = 5




def random_point_in_polygon(poly):
    min_x, min_y, max_x, max_y = poly.bounds
    while True:
        pt = Point(random.uniform(min_x, max_x), random.uniform(min_y, max_y))
        if poly.contains(pt):
            return pt


if __name__ == '__main__':
    jittered = jitter(max_per_od=10)
    features = []
    # Transform to geojson
    for properties, line_string in jittered:
        features.append(geojson.Feature(geometry=line_string, properties=properties))
    fc = geojson.FeatureCollection(features)
    with open('output.geojson', 'w') as f:
        f.write(geojson.dumps(fc))
