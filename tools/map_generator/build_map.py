from __future__ import annotations

import argparse
import json
from pathlib import Path

from map_builder import (
    build_regions_from_geojson,
    rasterize_id_map,
    rasterize_pretty_map,
    serialize_regions_to_json,
)


def main() -> None:
    parser = argparse.ArgumentParser(description="Build game map JSON + ID PNG from GeoJSON.")
    parser.add_argument("--geojson", default="../geo_jsons/br_states.json", help="Input GeoJSON file.")
    parser.add_argument("--out-json", default="../datasets/out.json", help="Output JSON file for game.")
    parser.add_argument("--out-pngs", default="../datasets", help="Output IPNG directory.")
    parser.add_argument("--width", type=int, default=2048,
                        help="Width of ID map in pixels (height auto).")
    args = parser.parse_args()

    geojson_path = Path(args.geojson)
    out_json_path = Path(args.out_json)
    out_png_path = Path(args.out_pngs)

    # 1) Build regions (image-space polygons)
    regions, img_w, img_h = build_regions_from_geojson(
        geojson_path=geojson_path,
        img_width=args.width,
        margin=10,
    )

    # 2) Serialize JSON
    game_json = serialize_regions_to_json(regions, img_w, img_h)
    out_json_path.parent.mkdir(parents=True, exist_ok=True)
    out_json_path.write_text(json.dumps(game_json, indent=2, ensure_ascii=False), encoding="utf-8")

    # 3) Build ID map
    id_img = rasterize_id_map(regions, img_w, img_h)
    out_png_path.parent.mkdir(parents=True, exist_ok=True)
    id_img.save(f"{out_png_path}/id_img.png")

    # 4) Build pretty map
    pretty_img = rasterize_pretty_map(regions, img_w, img_h)
    pretty_img.save(f"{out_png_path}/pretty_img.png")


    print(f"[OK] Wrote {len(regions)} regions → {out_json_path}")
    print(f"[OK] Wrote PNG maps {img_w}x{img_h} → {out_png_path}")


if __name__ == "__main__":
    main()