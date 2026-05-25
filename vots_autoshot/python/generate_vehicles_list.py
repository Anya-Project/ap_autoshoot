import os
import xml.etree.ElementTree as ET
import re
import json

vehicles_dirs = [r"e:/ap_roleplay/VotsRP.base/resources/[vehicles]/[import]/[godz]"]

extra_scan_dirs = []

output_json_path = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "data",
    "vehicles_list.json",
)


def get_resource_name(path, base_dirs):
    norm_path = os.path.normpath(path).replace("\\", "/")

    if "Vehicle_Pack_V2/data/rrcaracara500xlc" in norm_path:
        return "Vehicle_Pack_V2"

    for base in base_dirs:
        norm_base = os.path.normpath(base).replace("\\", "/")
        if norm_path.startswith(norm_base):
            relative = norm_path[len(norm_base) :].lstrip("/")
            parts = relative.split("/")
            if parts:
                return parts[0]
    return "unknown"


def parse_with_regex(file_content):
    items = []
    init_datas_match = re.search(
        r"<InitDatas>(.*?)</InitDatas>", file_content, re.DOTALL
    )
    if not init_datas_match:
        return items

    init_datas_content = init_datas_match.group(1)
    item_blocks = re.findall(
        r"<Item\b[^>]*>(.*?)</Item>", init_datas_content, re.DOTALL
    )
    for block in item_blocks:
        model_match = re.search(r"<modelName\b[^>]*>(.*?)</modelName>", block)
        if model_match:
            model = model_match.group(1).strip()

            make_match = re.search(
                r"<vehicleMakeName\b[^>]*>(.*?)</vehicleMakeName>", block
            )
            make = make_match.group(1).strip() if make_match else ""

            game_match = re.search(r"<gameName\b[^>]*>(.*?)</gameName>", block)
            game = game_match.group(1).strip() if game_match else ""

            items.append(
                {"modelName": model, "vehicleMakeName": make, "gameName": game}
            )
    return items


def parse_vehicles_meta(file_path):
    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return []

    try:
        root = ET.fromstring(content)
        init_datas = root.find("InitDatas")
        items = []
        if init_datas is not None:
            for item in init_datas.findall("Item"):
                model_el = item.find("modelName")
                if model_el is not None and model_el.text:
                    model = model_el.text.strip()

                    make_el = item.find("vehicleMakeName")
                    make = (
                        make_el.text.strip()
                        if (make_el is not None and make_el.text)
                        else ""
                    )

                    game_el = item.find("gameName")
                    game = (
                        game_el.text.strip()
                        if (game_el is not None and game_el.text)
                        else ""
                    )

                    items.append(
                        {"modelName": model, "vehicleMakeName": make, "gameName": game}
                    )
            return items
    except Exception as xml_err:
        return parse_with_regex(content)


vehicles_found = {}
all_dirs_to_scan = [(d, vehicles_dirs) for d in vehicles_dirs] + [
    (d, vehicles_dirs) for d in extra_scan_dirs
]

for base_dir, reference_dirs in all_dirs_to_scan:
    if not os.path.exists(base_dir):
        print(f"Directory does not exist: {base_dir}")
        continue

    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.lower() == "vehicles.meta":
                full_path = os.path.join(root, file)
                resource = get_resource_name(full_path, reference_dirs)

                if "backup" in full_path.lower():
                    continue

                parsed_items = parse_vehicles_meta(full_path)
                for item in parsed_items:
                    model = item["modelName"]
                    if not model:
                        continue

                    make = item["vehicleMakeName"]
                    game = item["gameName"]

                    if make.lower() in ["null", "none", ""]:
                        make = ""
                    if game.lower() in ["null", "none", ""]:
                        game = model

                    label = game
                    if make:
                        if make.lower() in game.lower():
                            label = game
                        else:
                            label = f"{make} {game}"

                    label = " ".join(
                        [
                            w.capitalize() if not w.isupper() else w
                            for w in label.split()
                        ]
                    )

                    lower_model = model.lower()
                    if lower_model in vehicles_found:
                        old_res = vehicles_found[lower_model]["resource"]
                        if "pack" in resource.lower() and not "pack" in old_res.lower():
                            vehicles_found[lower_model] = {
                                "spawn_code": model,
                                "label": label,
                                "resource": resource,
                            }
                    else:
                        vehicles_found[lower_model] = {
                            "spawn_code": model,
                            "label": label,
                            "resource": resource,
                        }

final_list = list(vehicles_found.values())
final_list.sort(key=lambda x: x["spawn_code"].lower())

with open(output_json_path, "w", encoding="utf-8") as f:
    json.dump(final_list, f, indent=4, ensure_ascii=False)

print(f"Scan completed. Found {len(final_list)} vehicles. Saved to: {output_json_path}")
