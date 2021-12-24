use geo::Point;
use serde_json::to_string_pretty;

fn main() {
    let point1 = Point::new(0.0, 0.0);
    let point2 = Point::new(0.2, 0.0);
    println!("{}", point1.distance(&point2));
}
