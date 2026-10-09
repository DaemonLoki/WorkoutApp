"""Muscle Map, refined Mosaic ("Glass Mosaic"): anatomy v2 and the concept sheet.

Usage: mosaic.py <out-dir>   →  writes e-glass-mosaic.svg

Anatomy: front and back, 200 x 440 each, centre line x = 100. Only the right half is drawn; it is mirrored.
Each Muscle Group is one or more tiles (its natural heads), all lit together. Neutral parts (head, hands,
knees, feet) are quieter tiles, so the figure is made of its muscles.
"""
import os
import sys

# --- Anatomy v2 ------------------------------------------------------------------------------------
FRONT = {
    "traps": ["M111,64 C116,74 128,79 141,82 C132,86 122,87 114,86 C112,79 111,71 111,64 Z"],
    "frontDelts": ["M141,85 C150,83 158,87 161,95 C162,105 159,117 153,127 C149,117 145,105 139,97 "
                   "C138,92 139,88 141,85 Z"],
    "sideDelts": ["M163,93 C170,99 173,109 171,121 C169,127 165,131 159,133 C162,121 164,107 163,93 Z"],
    "chest": ["M103,91 C114,87 128,87 137,91 C145,99 149,113 146,127 C142,137 131,143 118,143 "
              "C110,143 105,141 103,139 Z"],
    "biceps": ["M153,135 C159,131 166,135 168,143 C171,157 171,170 167,180 C162,183 157,180 155,172 "
               "C152,160 151,147 153,135 Z"],
    "forearms": ["M158,186 C165,182 172,184 175,191 C180,207 182,227 181,247 C177,250 173,249 171,245 "
                 "C167,227 161,205 158,186 Z"],
    "abs": ["M103,149 L117,147 C119,155 119,163 118,169 L103,170 Z",
            "M103,174 L118,173 C119,181 119,189 118,195 L103,196 Z",
            "M103,200 L118,199 C118,209 116,219 112,227 C108,230 105,232 103,233 Z"],
    "obliques": ["M123,147 C134,149 143,155 146,165 C147,183 144,201 138,215 C132,219 126,222 121,224 "
                 "C123,204 125,176 123,147 Z"],
    "adductors": ["M102,240 C104,237 107,237 109,239 C108,259 109,279 112,297 C107,289 103,271 102,255 Z"],
    "quads": ["M113,243 C117,236 122,232 127,231 C127,259 128,289 131,316 C124,320 118,316 116,307 "
              "C113,287 112,265 113,243 Z",
              "M131,229 C141,223 150,227 151,239 C153,267 148,297 140,320 C138,322 136,321 135,317 "
              "C133,291 131,261 131,229 Z"],
    "calves": ["M119,346 C125,341 133,341 136,346 C139,362 138,380 133,396 C129,399 124,399 122,396 "
               "C117,380 116,362 119,346 Z",
               "M139,348 C143,353 145,365 143,379 C142,385 140,389 137,391 C140,377 141,362 139,348 Z"],
}
BACK = {
    "traps": ["M100,58 L110,62 C116,72 130,80 144,84 C134,88 123,95 116,103 C110,116 106,132 102,148 "
              "L100,150 Z"],
    "rearDelts": ["M144,87 C153,85 160,91 162,99 C162,109 158,119 153,127 C149,117 145,107 140,99 "
                  "C139,94 141,90 144,87 Z"],
    "sideDelts": FRONT["sideDelts"],
    "upperBack": ["M121,105 C131,98 142,99 147,107 C150,117 148,129 142,137 C133,141 121,141 111,138 "
                  "C112,125 115,113 121,105 Z"],
    "lats": ["M148,140 C152,148 153,158 150,170 C146,190 137,204 125,215 C121,215 119,213 118,209 "
             "C116,191 113,173 110,155 C112,148 116,146 121,147 C131,147 141,145 148,140 Z"],
    "lowerBack": ["M102,158 L107,156 C109,176 112,196 114,216 C110,222 106,224 102,224 Z"],
    "triceps": ["M153,133 C160,129 167,133 168,141 C171,155 171,168 167,180 C162,183 157,180 155,172 "
                "C152,160 151,146 153,133 Z"],
    "forearms": FRONT["forearms"],
    "glutes": ["M102,230 C112,222 130,220 142,228 C149,240 148,258 138,268 C126,274 112,272 102,266 Z"],
    "adductors": ["M102,274 L104,276 C104,290 106,304 108,314 C104,306 102,292 102,274 Z"],
    "hamstrings": ["M107,277 C113,275 118,275 122,275 C122,293 124,309 127,323 C120,327 115,323 112,315 "
                   "C109,303 107,291 107,277 Z",
                   "M126,275 C134,273 142,273 146,277 C148,297 144,317 138,327 C134,329 131,327 130,323 "
                   "C128,307 126,291 126,275 Z"],
    "calves": ["M114,343 C119,337 125,335 128,337 C128,353 128,369 126,381 C120,383 116,379 114,373 "
               "C111,363 111,351 114,343 Z",
               "M131,337 C137,337 141,341 142,347 C144,359 142,371 136,381 C133,383 131,381 130,379 "
               "C130,365 130,351 131,337 Z"],
}
NEUTRAL_FRONT = [
    "M104,236 C112,234 120,230 127,226 C134,222 141,219 147,218 C149,221 150,224 150,226 "
    "C143,222 135,224 129,227 C121,231 113,236 106,239 C105,239 104,238 104,236 Z",  # hip crease
    "M168,256 C174,252 181,254 183,260 C185,270 183,282 177,286 C171,286 167,278 167,268 Z",  # hand
    "M120,325 C126,321 134,321 138,325 C140,333 137,339 130,340 C124,340 120,336 119,331 Z",  # knee
    "M122,405 C126,402 132,402 135,405 C139,411 142,417 141,423 C134,425 125,425 119,423 "
    "C119,415 120,409 122,405 Z",  # foot
]
NEUTRAL_BACK = [
    NEUTRAL_FRONT[1],
    NEUTRAL_FRONT[2],
    "M121,404 C125,400 133,400 136,404 C139,411 139,418 137,423 L120,423 C118,417 118,410 121,404 Z",  # heel
]

# --- Sample Workouts: Emphasis per Muscle Group, already normalised ---------------------------------
PUSH = {"chest": 1.0, "frontDelts": 0.9, "triceps": 0.65, "sideDelts": 0.55}
PULL = {"lats": 1.0, "upperBack": 0.9, "rearDelts": 0.6, "biceps": 0.6, "traps": 0.3, "forearms": 0.3}
LEGS = {"quads": 1.0, "glutes": 0.85, "hamstrings": 0.6, "adductors": 0.35, "calves": 0.6, "lowerBack": 0.3}


def step(w):
    return 3 if w >= 0.75 else 2 if w >= 0.45 else 1 if w > 0 else 0


# Colours per appearance: neutral tile gradient, and per step a (top, bottom) gradient of solid colours.
THEMES = {
    "light": {
        "bg": "#F2F2F7", "card": "#FFFFFF", "ink": "#1C1C1E", "sub": "#8E8E93", "gap": "#FFFFFF",
        "base": ("#E5E5EA", "#D5D5DC"), "quiet": ("#EDEDF1", "#E2E2E7"),
        "steps": [("#F7DCC4", "#F0C9A6"), ("#FDB877", "#F79A47"), ("#FF9233", "#FF6F00")],
        "sheen": 0.55, "glow": 0.35,
    },
    "dark": {
        "bg": "#000000", "card": "#1C1C1E", "ink": "#F2F2F7", "sub": "#8E8E93", "gap": "#1C1C1E",
        "base": ("#3A3A3D", "#2E2E31"), "quiet": ("#323235", "#2A2A2D"),
        "steps": [("#8A5A33", "#744A28"), ("#C2702A", "#A85C1C"), ("#FFA040", "#FF7A0A")],
        "sheen": 0.18, "glow": 0.55,
    },
}


def defs(t, uid):
    """Gradients and the glow filter for one theme; ids are suffixed so themes don't collide."""
    def grad(name, top, bottom):
        return (f'<linearGradient id="{name}-{uid}" x1="0" y1="0" x2="0" y2="1">'
                f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>')
    out = [grad("base", *t["base"]), grad("quiet", *t["quiet"])]
    for i, (top, bottom) in enumerate(t["steps"], start=1):
        out.append(grad(f"s{i}", top, bottom))
    out.append(f'<linearGradient id="sheen-{uid}" x1="0" y1="0" x2="0" y2="1">'
               f'<stop offset="0" stop-color="#FFFFFF" stop-opacity="{t["sheen"]}"/>'
               f'<stop offset="0.45" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>')
    out.append(f'<filter id="glow-{uid}" x="-30%" y="-30%" width="160%" height="160%">'
               f'<feGaussianBlur stdDeviation="5"/></filter>')
    return "<defs>" + "".join(out) + "</defs>"


def mirrored(inner):
    return f'{inner}<g transform="translate(200,0) scale(-1,1)">{inner}</g>'


def figure(view, emphasis, uid, gap, detail=True):
    """One view. `gap` is in figure units; `detail` adds sheen and glow (full size only)."""
    tiles = FRONT if view == "front" else BACK
    neutral = NEUTRAL_FRONT if view == "front" else NEUTRAL_BACK
    glow, body, sheen = "", "", ""
    for d in neutral:
        body += f'<path d="{d}" fill="url(#quiet-{uid})"/>'
    for group, paths in tiles.items():
        s = step(emphasis.get(group, 0))
        fill = f"url(#s{s}-{uid})" if s else f"url(#base-{uid})"
        for d in paths:
            body += f'<path d="{d}" fill="{fill}"/>'
            if detail:
                sheen += f'<path d="{d}" fill="url(#sheen-{uid})"/>'
                if s == 3:
                    glow += f'<path d="{d}"/>'
    head = f'<ellipse cx="100" cy="36" rx="21" ry="26" fill="url(#quiet-{uid})"/>'
    out = ""
    if glow:
        out += (f'<g fill="url(#s3-{uid})" filter="url(#glow-{uid})" opacity="GLOWOP">'
                f'{mirrored(glow)}</g>')
    out += (f'<g stroke="GAPCOL" stroke-width="{gap}" stroke-linejoin="round">'
            f'{head}{mirrored(body)}</g>')
    if detail:
        out += f'<g>{mirrored(sheen)}</g>'
    return out


def dominant_view(emphasis):
    """Compact maps show one view: the one carrying more Emphasis (ties: front)."""
    def total(tiles):
        return sum(w for g, w in emphasis.items() if g in tiles and not (g in FRONT and g in BACK))
    return "back" if total(BACK) > total(FRONT) else "front"


def single(emphasis, uid, t, x, y, scale, gap_pt=0.8):
    """The compact map: one view, no sheen or glow (they don't read at ~50 pt)."""
    view = dominant_view(emphasis)
    g = f'<g transform="translate({x},{y}) scale({scale})">{figure(view, emphasis, uid, gap_pt / scale, False)}</g>'
    return g.replace("GAPCOL", t["card"]).replace("GLOWOP", str(t["glow"]))


def pair(emphasis, uid, t, x, y, scale, detail=True, gap_pt=1.6):
    """Front and back side by side; the gap stays `gap_pt` on screen whatever the scale."""
    gap = gap_pt / scale
    g = f'<g transform="translate({x},{y}) scale({scale})">'
    g += figure("front", emphasis, uid, gap, detail)
    g += f'<g transform="translate(212,0)">{figure("back", emphasis, uid, gap, detail)}</g></g>'
    return g.replace("GAPCOL", t["card"]).replace("GLOWOP", str(t["glow"]))


def text(x, y, s, size, color, weight=400, anchor="start", rounded=False):
    family = "SF Pro Rounded, -apple-system, Helvetica" if rounded else "-apple-system, SF Pro Text, Helvetica"
    return (f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" font-weight="{weight}" '
            f'fill="{color}" text-anchor="{anchor}">{s}</text>')


def legend(t, uid, x, y):
    out = ""
    for i, label in enumerate(["Most", "Some", "A little"]):
        cx = x + i * 78
        out += f'<rect x="{cx}" y="{y - 9}" width="12" height="12" rx="4" fill="url(#s{3 - i}-{uid})"/>'
        out += text(cx + 18, y + 1, label, 12, t["sub"])
    return out


def card(t, uid, x, y, w, title, summary, emphasis):
    """The Workout editor header: a rounded card with the map, the summary line and the legend."""
    h, scale = 404, 0.66
    out = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="24" fill="{t["card"]}"/>'
    out += text(x + 20, y + 34, title, 17, t["ink"], 600)
    out += pair(emphasis, uid, t, x + (w - 412 * scale) / 2, y + 52, scale)
    out += text(x + 20, y + h - 40, summary, 13, t["sub"])
    out += legend(t, uid, x + 20, y + h - 16)
    return out


def row(t, uid, x, y, w, name, groups, emphasis, last):
    """An Exercise row with the compact map (~44 pt tall), as in the library and picker."""
    out = single(emphasis, uid, t, x + 20, y + 5, 0.118)
    out += text(x + 60, y + 26, name, 15, t["ink"])
    out += text(x + 60, y + 44, groups, 12, t["sub"])
    if not last:
        out += f'<rect x="{x + 60}" y="{y + 59.5}" width="{w - 60}" height="0.5" fill="{t["sub"]}" opacity="0.4"/>'
    return out


ROWS = [
    ("Bench Press", "Chest · Front Delts, Triceps", {"chest": 1.0, "frontDelts": 0.5, "triceps": 0.5}),
    ("Face Pull", "Rear Delts, Upper Back · Side Delts", {"rearDelts": 1.0, "upperBack": 1.0, "sideDelts": 0.5}),
    ("Romanian Deadlift", "Hamstrings, Glutes · Lower Back, Adductors",
     {"hamstrings": 1.0, "glutes": 1.0, "lowerBack": 0.5, "adductors": 0.5}),
    ("Ab Wheel Rollout", "Abs, Obliques · Lats", {"abs": 1.0, "obliques": 1.0, "lats": 0.5}),
]


def sheet(path):
    W, H = 1240, 1100
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">']
    for i, (name, t) in enumerate(THEMES.items()):
        uid, y0 = name, i * 550
        out.append(defs(t, uid))
        out.append(f'<rect x="0" y="{y0}" width="{W}" height="550" fill="{t["bg"]}"/>')
        if i == 0:
            out.append(text(32, 44, "Glass Mosaic", 28, t["ink"], 700, rounded=True))
            out.append(text(32, 70, "Every muscle a soft tile made of its own heads; trained ones glow in the accent. "
                                    "Strong Emphasis gets the Step Up glow.", 14, t["sub"]))
        out.append(text(W - 32, y0 + 44, name.title(), 13, t["sub"], 600, "end"))
        top = y0 + 96
        out.append(card(t, uid, 32, top, 340, "Push Day", "Mostly Chest, Front Delts and Triceps", PUSH))
        out.append(card(t, uid, 392, top, 340, "Pull Day", "Mostly Lats, Upper Back and Biceps", PULL))
        # Exercise list (inset grouped list)
        lx, lw = 752, 456
        out.append(text(lx + 16, top + 14, "EXERCISES", 12, t["sub"], 500))
        out.append(f'<rect x="{lx}" y="{top + 24}" width="{lw}" height="{len(ROWS) * 60}" rx="24" fill="{t["card"]}"/>')
        for j, (ex, groups, emph) in enumerate(ROWS):
            out.append(row(t, uid, lx, top + 24 + j * 60, lw, ex, groups, emph, j == len(ROWS) - 1))
        # Leg Day, compact card sizes
        out.append(text(lx + 16, top + 300, "NEXT UP", 12, t["sub"], 500))
        out.append(f'<rect x="{lx}" y="{top + 310}" width="{lw}" height="94" rx="24" fill="{t["card"]}"/>')
        out.append(pair(LEGS, uid, t, lx + 18, top + 318, 0.18, detail=False, gap_pt=0.9))
        out.append(text(lx + 108, top + 350, "Leg Day", 17, t["ink"], 600))
        out.append(text(lx + 108, top + 372, "6 Exercises · Mostly Quads and Glutes", 13, t["sub"]))
    out.append("</svg>")
    with open(path, "w") as f:
        f.write("".join(out))


if __name__ == "__main__":
    os.makedirs(sys.argv[1], exist_ok=True)
    sheet(os.path.join(sys.argv[1], "e-glass-mosaic.svg"))
    print("ok")
