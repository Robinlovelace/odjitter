import csv
import geojson
import json
from math import ceil
import random
import shapely
from shapely.geometry import shape, LineString, Point

# TODO timer
# TODO drop into a repl


def jitter(
        zones,
        csv_path,
        max_per_od=1,
        origin_key='geo_code1',
        destination_key='geo_code2',
        all_key='all'):
    """
    Jitter origin/destination pairs between zones to specific points.

    Args:
        zones: a dictionary from string zone names to polygons
        csv_path: the path to a CSV file with OD data to process
        max_per_od: transform each row to no more than this many output pairs
        origin_key: the name of the key in the CSV data for the origin zone
        destination_key: the name of the key in the CSV data for the destination zone
        all_key: the name of the key in the CSV data that specifies the total number of trips

    Returns:
        A list of (LineString, dictionary) pairs. Each LineString points from a
        jittered origin to destination. The dictionary is copied from each CSV
        row, with the origin_key and destination_key removed, and with all
        numeric values scaled appropriately.
    """

    output = []

    orig_total = 0.0

    for row in csv.DictReader(open(csv_path)):
        origin_zone = zones[row[origin_key]]
        destination_zone = zones[row[destination_key]]

        # How many times will we jitter this one row?
        this_row_n = float(row[all_key])
        orig_total += this_row_n
        factor = this_row_n / max_per_od

        # Scale all of the properties
        del row[origin_key]
        del row[destination_key]

        for k, v in row.items():
            # TODO Leave it alone if it's not numeric
            row[k] = float(v) / factor

        for _ in range(ceil(factor)):
            o = random_point_in_polygon(origin_zone)
            d = random_point_in_polygon(destination_zone)
            line = LineString([o, d])
            output.append((row, line))

    print(f'originally total is {orig_total}')
    new_total = 0.0
    for row, _ in output:
        new_total += row['all']
    print(f'new total is {new_total}')

    return output


def load_zones_from_geojson(path, name_key='InterZone'):
    """ Build a dictionary from zone codes to polygons """
    zones = {}
    gj = geojson.load(open(path))
    for feature in gj['features']:
        name = feature['properties'][name_key]
        polygon = shape(feature['geometry'])
        zones[name] = polygon
    return zones


def random_point_in_polygon(poly):
    min_x, min_y, max_x, max_y = poly.bounds
    while True:
        pt = Point(random.uniform(min_x, max_x), random.uniform(min_y, max_y))
        if poly.contains(pt):
            return pt


if __name__ == '__main__':
    zones = load_zones_from_geojson('../data/zones_min.geojson')
    results = jitter(zones, '../data/od_min.csv', max_per_od=1)

    # Write the results as GeoJSON
    features = []
    for properties, line_string in results:
        features.append(geojson.Feature(
            geometry=line_string, properties=properties))
    print(f'Writing {len(features)} jittered rows to output.geojson')
    fc = geojson.FeatureCollection(features)
    with open('output.geojson', 'w') as f:
        f.write(geojson.dumps(fc, pretty))
