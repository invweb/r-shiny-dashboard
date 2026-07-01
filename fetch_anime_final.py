#!/usr/bin/env python3

import subprocess
import json
import csv
import time
import os
import sys

BASE_URL = "https://api.jikan.moe/v4/anime"
LIMIT = 5
page = 1
total_added = 0
all_items = []
WORK_DIR = "/Users/vasiliikarpenko/VS_Code_Projects/R"

csv_path = os.path.join(WORK_DIR, "anime_data.csv")
json_path = os.path.join(WORK_DIR, "anime_data.json")
tmp_path = "/tmp/jikan_page.json"

csv_file = open(csv_path, "w", newline="", encoding="utf-8")
writer = csv.writer(csv_file)
writer.writerow(["id","title","title_japanese","type","source","episodes","status","aired_from","aired_to","score","scored_by","rank","popularity","members","favorites","rating","duration","year","season","genres","studios","image_url","synopsis"])

def fetch_page_curl(page_num):
    url = f"{BASE_URL}?page={page_num}&limit={LIMIT}"
    try:
        result = subprocess.run(
            ["curl", "-s", "-m", "60", "--compressed", "-o", tmp_path, url],
            capture_output=True, timeout=65
        )
        if result.returncode != 0:
            return None
        size = os.path.getsize(tmp_path)
        if size < 100:
            return None
        with open(tmp_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError:
        return None
    except Exception:
        return None

while True:
    print(f"Fetching page {page} (total: {total_added})...")
    sys.stdout.flush()

    resp_data = None
    for attempt in range(5):
        resp_data = fetch_page_curl(page)
        if resp_data and resp_data.get("data"):
            break
        wait_time = 3 * (attempt + 1)
        print(f"  Retry {attempt+1}/5, waiting {wait_time}s...")
        sys.stdout.flush()
        time.sleep(wait_time)

    if not resp_data or not resp_data.get("data"):
        print(f"Failed after retries at page {page}. Stopping.")
        break

    for item in resp_data["data"]:
        genres = ", ".join(g["name"] for g in item.get("genres", []))
        studios = ", ".join(s["name"] for s in item.get("studios", []))
        img = ""
        try:
            img = item.get("images", {}).get("jpg", {}).get("image_url", "")
        except:
            pass
        synopsis = (item.get("synopsis") or "")[:500]
        row = [
            item.get("mal_id", ""),
            item.get("title", ""),
            item.get("title_japanese", ""),
            item.get("type", ""),
            item.get("source", ""),
            item.get("episodes", ""),
            item.get("status", ""),
            (item.get("aired") or {}).get("from", ""),
            (item.get("aired") or {}).get("to", ""),
            item.get("score", ""),
            item.get("scored_by", ""),
            item.get("rank", ""),
            item.get("popularity", ""),
            item.get("members", ""),
            item.get("favorites", ""),
            item.get("rating", ""),
            item.get("duration", ""),
            item.get("year", ""),
            item.get("season", ""),
            genres,
            studios,
            img,
            synopsis,
        ]
        writer.writerow(row)
        all_items.append(row)

    csv_file.flush()
    total_added += len(resp_data["data"])

    if total_added % 10 < LIMIT:
        print(f">>> Total anime added so far: {total_added}")
        sys.stdout.flush()

    has_more = resp_data.get("pagination", {}).get("has_next_page", False)
    if not has_more:
        print("No more pages. Done.")
        break

    page += 1
    time.sleep(1.5)

csv_file.close()

with open(json_path, "w", encoding="utf-8") as f:
    json.dump(all_items, f, ensure_ascii=False, indent=2)

print(f"\n=== DONE ===")
print(f"Total anime saved: {total_added}")
print(f"Files: {csv_path}, {json_path}")
