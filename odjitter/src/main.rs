use std::collections::HashMap;
use std::fs::File;
use std::io::Write;

use anyhow::Result;
use geo::algorithm::bounding_rect::BoundingRect;
use geo::algorithm::contains::Contains;
use geo_types::{LineString, MultiPolygon, Point};
use geojson::GeoJson;
use rand::rngs::StdRng;
use rand::{Rng, SeedableRng};

// TODO Subsample from the roads
// TODO As a library... weight the subsamples, building importance

fn main() -> Result<()> {
    let zones = load_zones("../data/zones_min.geojson", "InterZone")?;
    println!("Scraped {} zones", zones.len());

    let all_subpoints = scrape_points("../data/road_network_min.geojson")?;
    println!("Scraped {} subpoints", all_subpoints.len());

    let max_per_od = 10;
    let output = jitter(
        &zones,
        "../data/od_min.csv",
        max_per_od,
        &mut StdRng::seed_from_u64(42),
    )?;

    // Transform to geojson
    let geom_collection: geo::GeometryCollection<f64> =
        output.iter().map(|(geom, _)| geom.clone()).collect();
    let mut feature_collection = geojson::FeatureCollection::from(&geom_collection);
    for (feature, (_, kv)) in feature_collection.features.iter_mut().zip(output) {
        let mut properties = serde_json::Map::new();
        for (k, v) in kv {
            properties.insert(k, v.into());
        }
        feature.properties = Some(properties);
    }
    let gj = GeoJson::from(feature_collection);
    let mut file = File::create("output.geojson")?;
    write!(file, "{}", serde_json::to_string_pretty(&gj)?)?;
    println!("Wrote output.geojson");

    Ok(())
}

fn load_zones(geojson_path: &str, name_key: &str) -> Result<HashMap<String, MultiPolygon<f64>>> {
    let geojson_input = std::fs::read_to_string(geojson_path)?;
    let geojson = geojson_input.parse::<GeoJson>()?;

    let mut zones: HashMap<String, MultiPolygon<f64>> = HashMap::new();
    if let geojson::GeoJson::FeatureCollection(collection) = geojson {
        for feature in collection.features {
            let zone_name = feature
                .property(name_key)
                .unwrap()
                .as_str()
                .unwrap()
                .to_string();
            let gj_geom: geojson::Geometry = feature.geometry.unwrap();
            let geo_geometry: geo_types::Geometry<f64> = gj_geom.try_into().unwrap();
            if let geo_types::Geometry::MultiPolygon(mp) = geo_geometry {
                zones.insert(zone_name, mp);
            }
        }
    }
    Ok(zones)
}

fn jitter(
    zones: &HashMap<String, MultiPolygon<f64>>,
    csv_path: &str,
    max_per_od: usize,
    rng: &mut StdRng,
) -> Result<Vec<(LineString<f64>, HashMap<String, String>)>> {
    let mut output = Vec::new();
    for rec in csv::Reader::from_reader(File::open(csv_path)?).deserialize() {
        let mut kv: HashMap<String, String> = rec?;
        let origin = &zones[&kv["geo_code1"]];
        let destination = &zones[&kv["geo_code2"]];

        // How many times will we jitter this one row?
        let repeat = (kv["all"].parse::<f64>()? / (max_per_od as f64)).ceil();

        // Scale all of the numeric values
        for value in kv.values_mut() {
            if let Ok(x) = value.parse::<f64>() {
                *value = (x / repeat).to_string();
            }
        }

        for _ in 0..repeat as usize {
            let o = random_pt(rng, origin);
            let d = random_pt(rng, destination);
            output.push((vec![o, d].into(), kv.clone()));
        }
    }
    Ok(output)
}

fn random_pt(rng: &mut StdRng, poly: &MultiPolygon<f64>) -> Point<f64> {
    // TODO If bounding_rect is slow, also cache per zone
    let bounds = poly.bounding_rect().unwrap();
    loop {
        let x = rng.gen_range(bounds.min().x..=bounds.max().x);
        let y = rng.gen_range(bounds.min().y..=bounds.max().y);
        let pt = Point::new(x, y);
        if poly.contains(&pt) {
            return pt;
        }
    }
}

fn scrape_points(path: &str) -> Result<Vec<Point<f64>>> {
    let geojson_input = std::fs::read_to_string(path)?;
    let geojson = geojson_input.parse::<GeoJson>()?;
    let mut points = Vec::new();
    if let geojson::GeoJson::FeatureCollection(collection) = geojson {
        for feature in collection.features {
            if let Some(geom) = feature.geometry {
                let geo_geometry: geo_types::Geometry<f64> = geom.try_into().unwrap();
                // TODO Scrape points from all types
                if let geo_types::Geometry::LineString(ls) = geo_geometry {
                    points.extend(ls.into_points());
                }
            }
        }
    }
    Ok(points)
}
