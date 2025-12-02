# utils.py

from __future__ import annotations
from typing import Any, Dict, List, Tuple
import math

# ------------ GeoJSON helpers ------------

def extract_lonlat_from_geometry(geom: Dict[str, Any]) -> List[List[Tuple[float, float]]]:
    """
    Extract outer-ring polygons from a GeoJSON geometry.
    Returns a list of polygons, each polygon is a list of (lon, lat) pairs.
    """
    gtype = geom["type"]
    polys: List[List[Tuple[float, float]]] = []

    if gtype == "Polygon":
        outer = geom["coordinates"][0]
        polys.append([(float(lon), float(lat)) for lon, lat in outer])

    elif gtype == "MultiPolygon":
        for poly in geom["coordinates"]:
            if not poly:
                continue
            outer = poly[0]
            polys.append([(float(lon), float(lat)) for lon, lat in outer])

    return polys


def find_name(properties: Dict[str, Any]) -> str:
    """
    Best-effort name extraction. Adjust keys to match your dataset if needed.
    """
    for key in ("name", "NAME_1", "NAME", "state_name", "STATE_NAME", "admin", "ADM1_EN"):
        if key in properties and properties[key]:
            return str(properties[key])
    for v in properties.values():
        if v:
            return str(v)
    return "UNKNOWN"


# ------------ Projection + normalization ------------

def project_points_equirectangular(
    points: List[Tuple[float, float]],
    lon0: float,
    lat0: float
) -> List[Tuple[float, float]]:
    """
    Very simple projection for regional maps:
        x = (lon - lon0) * cos(lat0)
        y = (lat - lat0)
    """
    lat0_rad = math.radians(lat0)
    cos_lat0 = math.cos(lat0_rad)
    out: List[Tuple[float, float]] = []
    for lon, lat in points:
        x = (lon - lon0) * cos_lat0
        y = (lat - lat0)
        out.append((x, y))
    return out


def compute_bounds(points: List[Tuple[float, float]]) -> Tuple[float, float, float, float]:
    """Return (min_x, min_y, max_x, max_y) for a list of (x, y) points."""
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return min(xs), min(ys), max(xs), max(ys)


def normalize_points_to_image(
    points: List[Tuple[float, float]],
    bounds: Tuple[float, float, float, float],
    img_w: int,
    img_h: int,
    margin: int = 10,
) -> List[Tuple[float, float]]:
    """
    Map projected coordinates into pixel coordinates, preserving aspect ratio
    and adding a margin.
    """
    min_x, min_y, max_x, max_y = bounds
    span_x = max_x - min_x
    span_y = max_y - min_y

    usable_w = img_w - 2 * margin
    usable_h = img_h - 2 * margin

    if span_x == 0 or span_y == 0:
        scale = 1.0
    else:
        scale = min(usable_w / span_x, usable_h / span_y)

    out: List[Tuple[float, float]] = []
    for x, y in points:
        px = margin + (x - min_x) * scale
        # flip y so north is up
        py = margin + (max_y - y) * scale
        out.append((px, py))
    return out


# ------------ ID encoding helpers ------------

def id_to_rgb(region_id: int) -> Tuple[int, int, int]:
    """
    Encodes an integer ID into an RGB triple:
        id = (r << 16) | (g << 8) | b
    """
    r = (region_id >> 16) & 0xFF
    g = (region_id >> 8) & 0xFF
    b = region_id & 0xFF
    return r, g, b


def rgb_to_hex(rgb: Tuple[int, int, int]) -> str:
    """Return lowercase 'rrggbb' hex string."""
    r, g, b = rgb
    return f"{r:02x}{g:02x}{b:02x}"
