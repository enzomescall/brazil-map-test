from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Tuple

from PIL import Image, ImageDraw # pyright: ignore[reportMissingImports]

from utils import (
    extract_lonlat_from_geometry,
    find_name,
    project_points_equirectangular,
    compute_bounds,
    normalize_points_to_image,
    id_to_rgb,
    rgb_to_hex,
)


@dataclass
class MapRegion:
    """One region (state, município, etc.) in image-space coordinates."""
    id: int
    name: str
    polygons: List[List[Tuple[float, float]]]  # list of polygons, each list of (x,y)

    @property
    def id_rgb(self) -> Tuple[int, int, int]:
        return id_to_rgb(self.id)

    @property
    def id_color_html(self) -> str:
        return rgb_to_hex(self.id_rgb)


def build_regions_from_geojson(
    geojson_path: Path,
    img_width: int,
    margin: int = 10,
) -> Tuple[List[MapRegion], int, int]:
    """
    Main worker: load GeoJSON, project coordinates, normalize to image space,
    and return MapRegion objects plus image size (w, h).

    - All polygons are returned in image-pixel coordinates.
    - This keeps Godot integration very simple (you can draw 1:1).
    """
    with geojson_path.open("r", encoding="utf-8") as f:
            geo = json.load(f)

    features = geo["features"]

    # 1) Extract all lon/lat polygons & names
    features_polys_lonlat: List[List[List[Tuple[float, float]]]] = []
    feature_names: List[str] = []
    all_lonlat_points: List[Tuple[float, float]] = []

    for feat in features:
        geom = feat["geometry"]
        polys = extract_lonlat_from_geometry(geom)
        if not polys:
            continue
        features_polys_lonlat.append(polys)
        feature_names.append(find_name(feat["properties"]))
        for poly in polys:
            all_lonlat_points.extend(poly)

    if not all_lonlat_points:
        raise RuntimeError("No polygon coordinates found in GeoJSON.")

    # 2) Decide projection center
    lons = [p[0] for p in all_lonlat_points]
    lats = [p[1] for p in all_lonlat_points]
    lon0 = (min(lons) + max(lons)) * 0.5
    lat0 = (min(lats) + max(lats)) * 0.5

    # 3) Project all polygons to (x, y)
    all_projected_points: List[Tuple[float, float]] = []
    features_polys_proj: List[List[List[Tuple[float, float]]]] = []

    for polys in features_polys_lonlat:
        proj_polys: List[List[Tuple[float, float]]] = []
        for poly in polys:
            proj_poly = project_points_equirectangular(poly, lon0, lat0)
            proj_polys.append(proj_poly)
            all_projected_points.extend(proj_poly)
        features_polys_proj.append(proj_polys)

    # 4) Compute bounds and image size
    min_x, min_y, max_x, max_y = compute_bounds(all_projected_points)
    span_x = max_x - min_x
    span_y = max_y - min_y

    if span_x == 0 or span_y == 0:
        aspect = 1.0
    else:
        aspect = span_y / span_x

    img_w = img_width
    img_h = max(1, int(img_width * aspect))

    bounds = (min_x, min_y, max_x, max_y)

    # 5) Normalize projected coords into image coords
    regions: List[MapRegion] = []
    for idx, (name, proj_polys) in enumerate(zip(feature_names, features_polys_proj)):
        polys_img: List[List[Tuple[float, float]]] = []
        for proj_poly in proj_polys:
            poly_img = normalize_points_to_image(proj_poly, bounds, img_w, img_h, margin=margin)
            polys_img.append(poly_img)

        region = MapRegion(
            id=idx,
            name=name,
            polygons=polys_img,
        )
        regions.append(region)

    return regions, img_w, img_h


def rasterize_id_map(regions: List[MapRegion], img_w: int, img_h: int) -> Image.Image:
    """
    Draw a PNG where each region is filled with its unique ID color.
    This is the O(1) picking map you’ll sample in Godot.
    """
    img = Image.new("RGB", (img_w, img_h), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    for region in regions:
        color = region.id_rgb
        for poly in region.polygons:
            draw.polygon(poly, fill=color)

    return img

def rasterize_pretty_map(regions, img_w, img_h):
    img = Image.new("RGBA", (img_w, img_h), (245, 245, 245, 255))  # light background
    draw = ImageDraw.Draw(img)

    # Assign random or palette-based colors
    import random
    random.seed(42)
    region_colors = {}
    for r in regions:
        region_colors[r.id] = (
            random.randint(100, 200),
            random.randint(100, 200),
            random.randint(100, 200),
            255
        )

    # Draw filled polygons
    for r in regions:
        fill = region_colors[r.id]
        for poly in r.polygons:
            draw.polygon(poly, fill=fill)

    # Draw borders
    for r in regions:
        for poly in r.polygons:
            draw.line(poly + [poly[0]], fill=(0,0,0,255), width=2)

    return img


def serialize_regions_to_json(regions: List[MapRegion], img_w: int, img_h: int) -> Dict[str, Any]:
    """
    Convert regions to a JSON-friendly dict.
    All polygons are in image-space coordinates.
    """
    provinces_out: List[Dict[str, Any]] = []

    for region in regions:
        polys_rounded: List[List[List[float]]] = []
        for poly in region.polygons:
            poly_r = [[round(float(x), 3), round(float(y), 3)] for x, y in poly]
            polys_rounded.append(poly_r)

        provinces_out.append({
            "id": region.id,
            "name": region.name,
            "id_color_html": region.id_color_html,
            "polygons": polys_rounded,
        })

    return {
        "projection": "image_space",
        "image_width": img_w,
        "image_height": img_h,
        "provinces": provinces_out,
    }
