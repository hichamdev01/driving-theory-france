#!/usr/bin/env python3
"""Extract the road-sign artwork used by the app from the supplied reference sheets."""

from collections import deque
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
OUTPUT = ROOT / "TheoryPrep/Resources/Content/france/images"

SHEETS = {
    "indications": DOWNLOADS / "68d0f44cb77de411032d783d_66e9462fc010ad7f6a133fd0_6667fcec17eea57b98dbb504_panneaux-indications.png",
    "obligations": DOWNLOADS / "68d0f44bb77de411032d7821_66e94092a0870c6a06edd920_6667fc0f0596b7f640c33aea_OBLIGATIONS%2520(1).png",
    "interdictions": DOWNLOADS / "68d0f44cb77de411032d7834_66e9462fc010ad7f6a133fbd_6667fc9fc27b9d5e8218f59f_panneaux-interdictions.png",
    "dangers": DOWNLOADS / "68d0f44bb77de411032d782a_66e9462fc010ad7f6a133fc0_6667fc8c4dc135b5258d87cc_panneaux-danger.png",
}

# Coordinates intentionally contain only the sign, never the sheet labels or branding.
SIGNS = {
    "road_sign_danger_permanent.png": ("dangers", (38, 198, 175, 320)),
    "road_sign_bend_right.png": ("dangers", (611, 198, 748, 320)),
    "road_sign_no_entry.png": ("interdictions", (234, 192, 362, 319)),
    "road_sign_speed_limit_50.png": ("interdictions", (234, 1795, 362, 1922)),
    "road_sign_no_parking.png": ("interdictions", (43, 645, 171, 772)),
    "road_sign_pedestrian_crossing.png": ("indications", (44, 192, 175, 318)),
    "road_sign_roundabout_ahead.png": ("dangers", (803, 1554, 940, 1676)),
    "road_sign_turn_right.png": ("obligations", (43, 419, 171, 546)),
}

X_CENTERS = [107, 298, 489, 680, 871]

DANGER_SIGNS = [
    ("Permanent danger", "Danger permanent"),
    ("Temporary danger", "Danger temporaire"),
    ("Priority to traffic from the right", "Cédez le passage aux véhicules arrivant à votre droite"),
    ("Right bend", "Virage à droite"),
    ("Left bend", "Virage à gauche"),
    ("Double bend, first to the right", "Succession de virages dont le premier est à droite"),
    ("Double bend, first to the left", "Succession de virages dont le premier est à gauche"),
    ("Uneven road", "Cassis ou dos-d’âne"),
    ("Speed hump", "Ralentisseur"),
    ("Road narrows on the right", "Chaussée rétrécie par la droite"),
    ("Road narrows on the left", "Chaussée rétrécie par la gauche"),
    ("Road narrows", "Chaussée rétrécie"),
    ("Slippery road", "Chaussée particulièrement glissante"),
    ("Opening bridge", "Pont mobile"),
    ("Manually operated barriers", "Barrières à fonctionnement manuel"),
    ("Level crossing without barrier", "Passage à niveau sans barrière ni demi-barrière"),
    ("Tramway crossing", "Traversée de voies de tramways"),
    ("Public transport crossing", "Traversée de voies de transport en commun"),
    ("Children", "Endroit fréquenté par les enfants"),
    ("Pedestrian crossing", "Passage pour piétons"),
    ("Other danger", "Danger pouvant être précisé ou non par un panonceau"),
    ("Cattle crossing", "Passage d’animaux domestiques"),
    ("Sheep crossing", "Passage d’animaux domestiques"),
    ("Wild animals", "Passage d’animaux sauvages"),
    ("Horse riders", "Passage de cavaliers"),
    ("Steep descent", "Descente dangereuse"),
    ("Traffic lights ahead", "Annonce de feux tricolores"),
    ("Two-way traffic", "Circulation dans les deux sens"),
    ("Falling rocks", "Risque de chute de pierres"),
    ("Quayside or riverbank", "Débouché sur un quai ou une berge"),
    ("Cyclists crossing", "Débouché de cyclistes venant de droite ou de gauche"),
    ("Low-flying aircraft", "Traversée d’une aire de danger aérien"),
    ("Crosswind", "Risque de fort vent latéral"),
    ("Priority intersection", "Intersection où vous êtes prioritaire"),
    ("Roundabout ahead", "Carrefour à sens giratoire avec priorité aux usagers circulant sur l’anneau"),
]

OBLIGATION_SIGNS = [
    ("Turn left before the sign", "Obligation de tourner à gauche avant le panneau"),
    ("Turn right before the sign", "Obligation de tourner à droite avant le panneau"),
    ("Pass the obstacle on the right", "Contournement obligatoire de l’obstacle par la droite"),
    ("Pass the obstacle on the left", "Contournement obligatoire de l’obstacle par la gauche"),
    ("Go straight", "Direction obligatoire à la prochaine intersection : tout droit"),
    ("Turn right", "Direction obligatoire à la prochaine intersection : à droite"),
    ("Turn left", "Direction obligatoire à la prochaine intersection : à gauche"),
    ("Go straight or turn left", "Direction obligatoire à la prochaine intersection : tout droit ou à gauche"),
    ("Go straight or turn right", "Direction obligatoire à la prochaine intersection : tout droit ou à droite"),
    ("Turn left or right", "Direction obligatoire à la prochaine intersection : à gauche ou à droite"),
    ("Mandatory cycle track", "Piste ou bande obligatoire pour cycles sans side-car à 2 ou 3 roues"),
    ("Pedestrian area", "Entrée d’aire piétonne"),
    ("Mandatory horse-rider path", "Chemin obligatoire pour cavaliers"),
    ("Minimum speed 50", "Vitesse minimale obligatoire"),
    ("Snow chains required", "Chaînes à neige obligatoires sur au moins 2 roues motrices"),
    ("Reserved public-transport lane", "Voie réservée aux véhicules des services réguliers de transport en commun"),
    ("Reserved tramway lane", "Voie réservée aux tramways"),
    ("Turn on your lights", "Obligation dont la nature est mentionnée sur le panneau"),
    ("End of mandatory cycle track", "Fin de piste ou de bande cyclable"),
    ("End of pedestrian area", "Sortie d’aire piétonne"),
    ("End of mandatory horse-rider path", "Fin de chemin obligatoire pour cavaliers"),
    ("End of minimum speed", "Fin de vitesse minimale obligatoire"),
    ("End of snow-chain requirement", "Fin de l’obligation d’utilisation des chaînes à neige"),
    ("End of reserved public-transport lane", "Fin de voie réservée aux véhicules des services réguliers de transport en commun"),
    ("End of lights-on requirement", "Fin d’obligation d’allumage des feux"),
]

PROHIBITION_SIGNS = [
    ("Road closed to all vehicles", "Circulation interdite à tout véhicule dans les deux sens"),
    ("No entry", "Sens interdit"),
    ("No left turn", "Interdiction de tourner à gauche à la prochaine intersection"),
    ("No right turn", "Interdiction de tourner à droite à la prochaine intersection"),
    ("No U-turn", "Interdiction de faire demi-tour"),
    ("No overtaking", "Interdiction de dépasser tout véhicule à moteur sauf deux roues"),
    ("No overtaking by goods vehicles over 3.5 t", "Interdiction de dépasser pour les transports de marchandises > à 3,5 t"),
    ("Customs stop", "Arrêt obligatoire au poste de douane"),
    ("Gendarmerie stop", "Arrêt obligatoire au barrage de gendarmerie"),
    ("Police stop", "Arrêt obligatoire au barrage de police"),
    ("No parking", "Stationnement interdit"),
    ("No parking on odd-numbered dates", "Stationnement interdit du côté du panneau du 1er au 15 du mois"),
    ("No parking on even-numbered dates", "Stationnement interdit du côté du panneau du 16 à la fin du mois"),
    ("No stopping or parking", "Arrêt et stationnement interdits"),
    ("No motor vehicles except mopeds", "Accès interdit aux véhicules à moteur sauf cyclomoteurs"),
    ("No motor vehicles", "Accès interdit aux véhicules à moteur"),
    ("No goods vehicles", "Accès interdit aux véhicules transportant des marchandises"),
    ("No pedestrians", "Accès interdit aux piétons"),
    ("No cycles", "Accès interdit aux cycles"),
    ("No animal-drawn vehicles", "Accès interdit aux véhicules à traction animale"),
    ("No agricultural vehicles", "Accès interdit aux véhicules agricoles à moteur"),
    ("No handcarts", "Accès interdit aux voitures à bras"),
    ("No public-transport vehicles", "Accès interdit aux véhicules de transport en commun"),
    ("No mopeds", "Accès interdit aux cyclomoteurs"),
    ("No motorcycles or mopeds", "Accès interdit aux motos et motos légères"),
    ("No caravans or trailers over 250 kg", "Accès interdit aux véhicules tractant une caravane ou remorque de plus de 250 kg"),
    ("No vehicles carrying explosives", "Accès interdit aux véhicules de transport de marchandises explosives ou facilement inflammables"),
    ("No vehicles carrying water pollutants", "Accès interdit aux véhicules transportant des marchandises polluant l’eau"),
    ("No vehicles carrying dangerous goods", "Accès interdit aux véhicules transportant des marchandises dangereuses"),
    ("No horns", "Signaux sonores interdits"),
    ("Maximum axle load 2 t", "Interdit aux véhicules de plus de 2 t sur un même essieu"),
    ("Maximum weight 5.5 t", "Interdit aux véhicules de plus de 5,5 t"),
    ("Maximum width 2.5 m", "Accès interdit aux véhicules dont la largeur, chargement compris, dépasse la dimension indiquée"),
    ("Maximum height 3.5 m", "Accès interdit aux véhicules dont la hauteur, chargement compris, dépasse la dimension indiquée"),
    ("Maximum length 10 m", "Accès interdit aux véhicules dont la longueur, chargement compris, dépasse la dimension indiquée"),
    ("Speed limit 30", "Limitation de vitesse à 30 km/h"),
    ("Speed limit 50", "Limitation de vitesse à 50 km/h"),
    ("Speed limit 70", "Limitation de vitesse à 70 km/h"),
    ("Speed limit 90", "Limitation de vitesse à 90 km/h"),
    ("Speed limit 110", "Limitation de vitesse à 110 km/h"),
    ("Speed limit 130", "Limitation de vitesse à 130 km/h"),
    ("Give way to oncoming traffic", "Cédez le passage à la circulation venant en sens inverse"),
    ("Minimum following distance 70 m", "Interdiction de circuler sans maintenir l’intervalle indiqué"),
]

END_PROHIBITION_SIGNS = [
    ("End of all restrictions", "Fin de toutes les interdictions précédemment signalées et imposées aux véhicules en mouvement"),
    ("End of speed limit 30", "Fin de limitation de vitesse à 30 km/h"),
    ("End of speed limit 50", "Fin de limitation de vitesse à 50 km/h"),
    ("End of speed limit 70", "Fin de limitation de vitesse à 70 km/h"),
    ("End of speed limit 90", "Fin de limitation de vitesse à 90 km/h"),
    ("End of speed limit 110", "Fin de limitation de vitesse à 110 km/h"),
    ("End of no-overtaking restriction", "Fin d’interdiction de dépasser"),
    ("End of no-overtaking restriction for goods vehicles", "Fin d’interdiction de dépasser pour les véhicules de transport de marchandises de plus de 3,5 t"),
    ("End of horn restriction", "Fin de l’interdiction de l’emploi des avertisseurs sonores"),
    ("End of indicated restriction", "Fin d’interdiction dont la nature est mentionnée sur le panneau"),
]

INDICATION_SIGNS = [
    ("Pedestrian crossing", "Passage pour piétons"),
    ("Meeting zone entrance", "Entrée de zone de rencontre"),
    ("End of meeting zone", "Sortie de zone de rencontre"),
    ("Pedestrian area entrance", "Entrée d’aire piétonne"),
    ("End of pedestrian area", "Sortie d’aire piétonne"),
    ("Parking", "Lieu aménagé pour le stationnement : parking"),
    ("Free time-limited parking with disc", "Lieu aménagé pour le stationnement gratuit à durée limitée avec contrôle par disque"),
    ("Paid parking", "Stationnement payant"),
    ("Advisory speed 70", "Vitesse conseillée"),
    ("End of advisory speed", "Fin de vitesse conseillée"),
    ("Taxi rank", "Station de taxis"),
    ("Bus stop", "Station d’arrêt d’autobus"),
    ("Emergency stopping place", "Emplacement d’arrêt d’urgence"),
    ("Car-sharing vehicle stop", "Station pour véhicule bénéficiant du label Autopartage"),
    ("One-way traffic", "Circulation à sens unique"),
    ("Dead end", "Impasse ou rue sans issue"),
    ("Advance warning of a dead end", "Présignalisation d’une impasse"),
    ("Dead end with pedestrian exit", "Impasse comportant une issue pour les piétons"),
    ("Dead end with pedestrian and cycle exit", "Impasse comportant une issue pour les piétons et les cyclistes"),
    ("Priority over oncoming traffic", "Priorité par rapport à la circulation venant en sens inverse"),
    ("Special traffic conditions on the centre lane", "Conditions particulières de circulation sur la voie centrale"),
    ("Special lane speed limits", "Conditions particulières de circulation par voie en terme de limitation de vitesse"),
    ("Two-way cycle traffic", "Chaussée à double sens. Sens opposé réservé aux cycles"),
    ("Two-way road with opposing bus lane", "Chaussée à double sens. Sens opposé réservé aux bus"),
    ("Three lanes in this direction", "Conditions particulières de circulation : trois voies de circulation dans ce sens"),
    ("Lane direction indication", "Signalisation par voie"),
    ("Assigned lanes", "Voies affectées"),
    ("Special traffic conditions by lane", "Conditions particulières de circulation sur la route ou la voie embranchée"),
    ("Contraflow cycle lane", "La voie de circulation en sens inverse est réservée aux cyclistes"),
    ("Escape lane", "Voie de détresse"),
    ("Escape lane", "Voie de détresse"),
    ("Tramway crossing", "Traversée de voie de tramways"),
    ("Speed hump", "Ralentisseur"),
    ("Public transport crossing", "Traversée de voie de véhicules routiers des services réguliers de transport en commun"),
    ("Overtaking lane on a three-lane road", "Créneau de dépassement sur section de route à trois voies"),
    ("Lane reduction", "Réduction du nombre de voies"),
    ("Lane reduction", "Réduction du nombre de voies"),
    ("Lane reduction", "Réduction du nombre de voies"),
    ("End of overtaking lane", "Fin de créneau de dépassement"),
    ("Advance warning of an overtaking lane", "Annonce d’un créneau de dépassement ou d’une route 2x2 voies"),
    ("Three assigned lanes", "Section de route à trois voies affectées"),
    ("Miscellaneous indication", "Indications diverses"),
    ("Variable speed section ahead", "Présignalisation du début d’une section à vitesse régulée"),
    ("End of variable speed section", "Fin de section à vitesse régulée"),
    ("Regulated caravan parking", "Stationnement réglementé pour les caravanes et les autocaravanes"),
    ("Toll ticket machine ahead", "Présignalisation d’une borne de retrait de ticket de péage"),
    ("Payment by bank card", "Paiement par carte bancaire"),
    ("Automatic coin payment", "Paiement automatique par pièces de monnaie"),
    ("Subscription payment", "Paiement par abonnement"),
    ("Payment to a toll collector", "Paiement auprès d’un péagiste"),
    ("Payment by bank or credit card", "Paiement par carte bancaire ou accréditive"),
    ("Automatic payment by coins and notes", "Paiement automatique par pièces et billets"),
    ("Regulated-access road", "Route à accès réglementé"),
    ("End of regulated-access road", "Fin de route à accès réglementé"),
    ("Tunnel entrance", "Entrée d’un tunnel"),
    ("Tunnel exit", "Sortie de tunnel"),
    ("Recommended cycle track", "Piste ou bande cyclable conseillée et réservée aux cycles à 2 ou 3 roues"),
    ("End of recommended cycle track", "Fin de piste ou bande cyclable conseillée et réservée aux cycles à 2 ou 3 roues"),
    ("Greenway entrance", "Début de voie verte"),
    ("End of greenway", "Fin de voie verte"),
    ("Motorway entrance", "Début d’une section d’autoroute"),
    ("End of motorway", "Fin d’une section d’autoroute"),
    ("Motorway under video surveillance", "Indication sur autoroute"),
    ("Tunnel under video surveillance", "Indication sur autoroute"),
]


def remove_connected_white(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    seen: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))

    while queue:
        x, y = queue.popleft()
        if (x, y) in seen:
            continue
        seen.add((x, y))
        red, green, blue, _ = pixels[x, y]
        if min(red, green, blue) < 238:
            continue
        alpha = max(0, min(255, (min(red, green, blue) - 238) * 15))
        pixels[x, y] = (red, green, blue, 255 - alpha)
        if x:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))

    bbox = image.getbbox()
    return image.crop(bbox) if bbox else image


def regular_polygon(center: tuple[float, float], radius: float, sides: int, rotation: float) -> list[tuple[float, float]]:
    from math import cos, pi, sin

    cx, cy = center
    return [
        (cx + radius * cos(rotation + 2 * pi * index / sides), cy + radius * sin(rotation + 2 * pi * index / sides))
        for index in range(sides)
    ]


def make_missing_reference_signs() -> None:
    scale = 4
    canvas_size = 128 * scale
    center = (canvas_size / 2, canvas_size / 2)

    stop = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(stop)
    outer = regular_polygon(center, 59 * scale, 8, -3.14159 / 8)
    inner = regular_polygon(center, 53 * scale, 8, -3.14159 / 8)
    draw.polygon(outer, fill="#FFFFFF")
    draw.line(outer + [outer[0]], fill="#263238", width=2 * scale, joint="curve")
    draw.polygon(inner, fill="#C8102E")
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 34 * scale)
    draw.text(center, "STOP", font=font, fill="white", anchor="mm", stroke_width=1 * scale, stroke_fill="white")
    stop.resize((128, 128), Image.Resampling.LANCZOS).save(OUTPUT / "road_sign_stop.png", optimize=True)

    yield_sign = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(yield_sign)
    outer = regular_polygon((center[0], center[1] + 4 * scale), 60 * scale, 3, 3.14159 / 2)
    middle = regular_polygon((center[0], center[1] + 4 * scale), 54 * scale, 3, 3.14159 / 2)
    inner = regular_polygon((center[0], center[1] + 4 * scale), 43 * scale, 3, 3.14159 / 2)
    draw.polygon(outer, fill="#263238")
    draw.polygon(middle, fill="#D7262E")
    draw.polygon(inner, fill="#FFFFFF")
    yield_sign.resize((128, 128), Image.Resampling.LANCZOS).save(OUTPUT / "road_sign_yield.png", optimize=True)

    priority = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(priority)
    outer = regular_polygon(center, 61 * scale, 4, 3.14159 / 4)
    white = regular_polygon(center, 55 * scale, 4, 3.14159 / 4)
    yellow = regular_polygon(center, 43 * scale, 4, 3.14159 / 4)
    draw.polygon(outer, fill="#263238")
    draw.polygon(white, fill="#FFFFFF")
    draw.polygon(yellow, fill="#F7D117")
    priority.resize((128, 128), Image.Resampling.LANCZOS).save(OUTPUT / "road_sign_priority_road.png", optimize=True)


def extract_catalog(opened: dict[str, Image.Image]) -> None:
    groups = [
        ("danger", "Danger signs", "Panneaux de danger", "dangers", DANGER_SIGNS, [259, 486, 711, 937, 1164, 1388, 1615], [5] * 7),
        ("obligation", "Mandatory signs", "Panneaux d’obligation", "obligations", OBLIGATION_SIGNS, [255, 482, 708, 934, 1157, 1384], [5, 5, 5, 3, 5, 2]),
        ("prohibition", "Prohibition signs", "Panneaux d’interdiction", "interdictions", PROHIBITION_SIGNS, [256, 482, 708, 934, 1162, 1386, 1611, 1859, 2085], [5, 5, 5, 5, 5, 5, 5, 5, 3]),
        ("end_prohibition", "End of prohibition signs", "Fin d’interdiction", "interdictions", END_PROHIBITION_SIGNS, [2550, 2775], [5, 5]),
        ("indication", "Information signs", "Panneaux d’indication", "indications", INDICATION_SIGNS, [255, 482, 707, 933, 1159, 1385, 1611, 1837, 2063, 2295, 2519, 2745, 2970, 3150], [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 2]),
    ]

    categories = []
    catalog_signs = []
    for slug, english_category, french_category, sheet_name, labels, y_centers, row_counts in groups:
        categories.append({"slug": slug, "translations": {"en": english_category, "fr": french_category}})
        positions = [(column, y) for y, count in zip(y_centers, row_counts) for column in range(count)]
        if len(positions) != len(labels):
            raise RuntimeError(f"{slug}: {len(labels)} labels for {len(positions)} positions")

        for index, ((english, french), (column, y_center)) in enumerate(zip(labels, positions), start=1):
            x_center = X_CENTERS[column]
            half_width = 70
            half_height = 66 if not (slug == "indication" and y_center == 3150) else 50
            box = (x_center - half_width, y_center - half_height, x_center + half_width, y_center + half_height)
            sign = remove_connected_white(opened[sheet_name].crop(box))
            sign.thumbnail((512, 512), Image.Resampling.LANCZOS)
            filename = f"road_sign_{slug}_{index:03d}.png"
            sign.save(OUTPUT / filename, optimize=True)
            catalog_signs.append(
                {
                    "road_sign_category_slug": slug,
                    "image_path": f"france/{filename}",
                    "shape": "circle",
                    "color": "#1E5AA8",
                    "translations": {
                        "en": {"name": english, "meaning": english},
                        "fr": {"name": french, "meaning": french},
                    },
                }
            )

    catalog_path = ROOT / "TheoryPrep/Resources/Content/france/road-signs.json"
    catalog_path.write_text(
        json.dumps({"categories": categories, "signs": catalog_signs}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"catalog: {len(catalog_signs)} independent signs")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    opened = {name: Image.open(path) for name, path in SHEETS.items()}
    for filename, (sheet, box) in SIGNS.items():
        sign = remove_connected_white(opened[sheet].crop(box))
        sign.thumbnail((512, 512), Image.Resampling.LANCZOS)
        sign.save(OUTPUT / filename, optimize=True)
        print(f"{filename}: {sign.width}x{sign.height}")
    make_missing_reference_signs()
    extract_catalog(opened)


if __name__ == "__main__":
    main()
