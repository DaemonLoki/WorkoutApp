"""Muscle Map concept sheets: one anatomy (right half, mirrored), four renderings. Usage: generate.py <out-dir>"""
import os
import sys

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

# --- Anatomy: right half of a 200 x 420 figure, centre line x = 100. -------------------------------
# Muscle Groups (18) and neutral parts. Every path is mirrored to the left half.
FRONT = {
    "traps": "M108,60 C114,68 126,72 138,76 L113,79 C110,72 109,66 108,60 Z",
    "chest": "M102,84 C114,80 128,80 137,82 C146,92 148,108 144,120 C132,128 114,130 102,126 Z",
    "frontDelts": "M139,79 C149,76 160,80 163,90 L158,125 C152,111 147,96 141,86 Z",
    "sideDelts": "M165,92 C171,100 172,113 167,124 L160,127 Z",
    "biceps": "M151,126 C157,123 163,127 166,133 C170,147 171,160 168,170 C162,172 158,168 156,162 C152,150 150,138 151,126 Z",
    "forearms": "M160,177 C166,173 172,175 175,181 C180,197 184,220 184,238 L176,240 C172,222 164,198 160,177 Z",
    "abs": "M102,134 L117,134 C120,152 120,182 117,206 C112,212 106,214 102,214 Z",
    "obliques": "M122,132 C132,134 140,140 142,150 C142,168 140,186 136,200 C130,205 124,207 121,207 C123,180 124,154 122,132 Z",
    "quads": "M119,223 C128,215 138,211 144,215 C148,241 146,271 138,300 C132,306 124,306 118,302 C112,280 112,249 119,223 Z",
    "adductors": "M104,233 C109,229 113,227 116,227 C112,249 112,271 114,291 C108,281 104,263 103,245 Z",
    "calves": "M118,327 C124,323 132,323 138,327 C142,345 140,365 134,383 L124,385 C118,367 115,345 118,327 Z",
}
BACK = {
    "traps": "M100,54 L108,56 C114,66 126,72 139,78 L134,87 C122,101 110,121 102,142 L100,142 Z",
    "rearDelts": "M141,80 C150,77 160,81 163,90 L158,125 C152,111 147,97 141,88 Z",
    "sideDelts": FRONT["sideDelts"],
    "upperBack": "M137,90 C143,99 144,112 140,124 C130,130 118,134 107,138 C112,124 121,107 137,90 Z",
    "lats": "M141,128 C147,134 148,144 146,158 C142,178 132,193 121,203 L116,201 C113,185 110,163 108,144 C120,141 132,135 141,128 Z",
    "lowerBack": "M102,148 L106,146 C108,166 112,186 114,204 C110,210 106,212 102,212 Z",
    "triceps": FRONT["biceps"],
    "forearms": FRONT["forearms"],
    "glutes": "M102,216 C112,209 128,207 140,213 C146,227 144,245 134,253 C122,257 110,255 102,251 Z",
    "hamstrings": "M107,259 C117,257 131,257 142,257 C146,275 142,293 136,305 C128,309 118,307 112,303 C108,289 105,273 107,259 Z",
    "adductors": "M102,258 L104,259 C103,273 105,289 109,301 C104,293 102,277 102,258 Z",
    "calves": "M116,323 C124,317 134,317 140,323 C146,339 144,357 136,371 C128,375 120,373 116,367 C112,353 112,337 116,323 Z",
}
NEUTRAL_FRONT = [
    "M102,58 L109,58 C110,66 112,73 114,79 L102,80 Z",  # neck
    "M174,244 C180,242 186,244 188,250 C190,260 188,270 182,274 C176,274 172,266 172,256 Z",  # hand
    "M121,309 C127,306 133,306 137,310 C139,316 137,321 131,323 C125,323 121,320 120,315 Z",  # knee
    "M123,389 L135,389 C141,396 146,402 145,407 L120,407 C120,400 121,394 123,389 Z",  # foot
    "M102,218 L118,212 C121,214 120,219 117,224 C112,228 107,231 102,232 Z",  # pelvis
]
NEUTRAL_BACK = [
    "M102,58 L108,58 L110,62 L102,62 Z",
    NEUTRAL_FRONT[1],
    "M117,309 C125,306 133,306 139,310 C140,315 138,319 132,320 C124,320 118,318 117,314 Z",
    "M124,378 L134,376 C138,388 141,398 142,407 L121,407 C121,396 122,386 124,378 Z",  # heel/foot
]
HEAD = '<ellipse cx="100" cy="32" rx="19" ry="24"/>'

# --- Sample Workouts (weights: primary 1.0, secondary 0.5, x Sets, normalised; 3 intensity steps) --
PUSH = {"chest": 1.0, "frontDelts": 0.9, "triceps": 0.65, "sideDelts": 0.55}
PULL = {"lats": 1.0, "upperBack": 0.9, "rearDelts": 0.6, "biceps": 0.6, "traps": 0.3, "forearms": 0.3}
LEGS = {"quads": 1.0, "glutes": 0.85, "hamstrings": 0.6, "adductors": 0.35, "calves": 0.6, "lowerBack": 0.3}


def step(w):
    """Bucket a normalised load into three steps (README §9: 'orange intensity steps')."""
    if w >= 0.75:
        return 3
    if w >= 0.45:
        return 2
    return 1 if w > 0 else 0


THEMES = {
    "light": {"bg": "#FFFFFF", "base": "#E5E5EA", "line": "#AEAEB2", "hair": "#D1D1D6", "ink": "#1C1C1E",
              "sub": "#8E8E93", "o": ["#FF7A00", "#FF7A00", "#FF7A00"], "a": [0.28, 0.6, 1.0]},
    "dark": {"bg": "#000000", "base": "#2C2C2E", "line": "#636366", "hair": "#3A3A3C", "ink": "#F2F2F7",
             "sub": "#8E8E93", "o": ["#FF8A1F", "#FF8A1F", "#FF8A1F"], "a": [0.32, 0.62, 1.0]},
}


def mirrored(inner):
    return f'{inner}<g transform="translate(200,0) scale(-1,1)">{inner}</g>'


def regions(view):
    return FRONT if view == "front" else BACK


def neutral(view):
    return NEUTRAL_FRONT if view == "front" else NEUTRAL_BACK


def fill_for(group, load, t, unlit):
    s = step(load.get(group, 0))
    if s == 0:
        return unlit, 1.0
    return t["o"][s - 1], t["a"][s - 1]


# --- Renderings ------------------------------------------------------------------------------------
def render_mosaic(view, load, t):
    """A: every region a solid tile, separated by hairline gaps in the background colour."""
    gap = t["bg"]
    parts = [HEAD.replace("/>", f' fill="{t["base"]}"/>')]
    half = ""
    for d in neutral(view):
        half += f'<path d="{d}" fill="{t["base"]}" opacity="0.55"/>'
    for g, d in regions(view).items():
        c, a = fill_for(g, load, t, t["base"])
        if a < 1:  # composite the tint over the base so gaps stay crisp
            half += f'<path d="{d}" fill="{t["base"]}"/>'
        half += f'<path d="{d}" fill="{c}" fill-opacity="{a}"/>'
    parts.append(mirrored(half))
    body = "".join(parts)
    return f'<g stroke="{gap}" stroke-width="2.6" stroke-linejoin="round">{body}</g>'


def union(view, color, width):
    shapes = "".join(f'<path d="{d}"/>' for d in list(regions(view).values()) + neutral(view))
    return (f'<g fill="{color}" stroke="{color}" stroke-width="{width}" stroke-linejoin="round">'
            f'{HEAD}{mirrored(shapes)}</g>')


def render_silhouette(view, load, t):
    """B: one soft, undivided body; only trained muscles appear, as glowing shapes inside it."""
    out = union(view, t["base"], 5.5)
    half = ""
    for g, d in regions(view).items():
        s = step(load.get(g, 0))
        if s:
            half += f'<path d="{d}" fill="{t["o"][s-1]}" fill-opacity="{t["a"][s-1]}"/>'
    out += f'<g stroke="{t["base"]}" stroke-width="1.6" stroke-linejoin="round">{mirrored(half)}</g>'
    return out


def render_lineart(view, load, t):
    """C: a drawn figure — continuous outline plus hairline muscle contours; trained muscles filled."""
    out = union(view, t["line"], 12) + union(view, t["bg"], 8)
    half = ""
    for g, d in regions(view).items():
        c, a = fill_for(g, load, t, "none")
        f = f'fill="{c}" fill-opacity="{a}"' if c != "none" else 'fill="none"'
        half += f'<path d="{d}" {f} stroke="{t["hair"] if c == "none" else t["o"][0]}" stroke-width="1.1"/>'
    for d in neutral(view):
        half += f'<path d="{d}" fill="none" stroke="{t["hair"]}" stroke-width="1.1"/>'
    out += f'<g stroke-linejoin="round">{mirrored(half)}</g>'
    return out


# D: capsules — a different, abstract geometry in the icon's rounded-stroke vocabulary.
PILLS_FRONT = {
    "traps": [((110, 70), (128, 76), 9)],
    "chest": [((111, 98), (131, 100), 26)],
    "frontDelts": [((147, 89), (152, 106), 15)],
    "sideDelts": [((163, 98), (164, 116), 8)],
    "biceps": [((157, 133), (163, 160), 13)],
    "forearms": [((167, 186), (177, 228), 11)],
    "abs": [((108, 140), (108, 150), 10), ((108, 164), (108, 174), 10), ((108, 188), (108, 200), 10)],
    "obliques": [((130, 145), (128, 192), 11)],
    "quads": [((130, 230), (128, 290), 24)],
    "adductors": [((108, 240), (110, 272), 8)],
    "calves": [((127, 336), (128, 372), 15)],
}
PILLS_BACK = {
    "traps": [((100, 66), (100, 128), 12), ((108, 70), (128, 78), 9)],
    "rearDelts": [((148, 89), (152, 106), 15)],
    "sideDelts": PILLS_FRONT["sideDelts"],
    "upperBack": [((118, 100), (128, 118), 14)],
    "lats": [((130, 140), (120, 186), 18)],
    "lowerBack": [((109, 160), (109, 202), 9)],
    "triceps": PILLS_FRONT["biceps"],
    "forearms": PILLS_FRONT["forearms"],
    "glutes": [((122, 226), (122, 238), 30)],
    "hamstrings": [((124, 266), (126, 296), 22)],
    "calves": [((127, 332), (128, 360), 20)],
}
PILL_NEUTRAL = [((180, 250), (181, 264), 12), ((128, 314), (128, 316), 12), ((130, 392), (136, 402), 10)]


def render_pills(view, load, t):
    pills = PILLS_FRONT if view == "front" else PILLS_BACK
    half = ""
    for (a, b, w) in PILL_NEUTRAL:
        half += (f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="{t["base"]}" '
                 f'stroke-width="{w}" opacity="0.6"/>')
    for g, caps in pills.items():
        c, al = fill_for(g, load, t, t["base"])
        for (a, b, w) in caps:
            if al < 1:
                half += (f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="{t["base"]}" '
                         f'stroke-width="{w}"/>')
            half += (f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="{c}" '
                     f'stroke-opacity="{al}" stroke-width="{w}"/>')
    head = f'<circle cx="100" cy="32" r="19" fill="{t["base"]}"/>'
    return f'{head}<g stroke-linecap="round">{mirrored(half)}</g>'


CONCEPTS = {
    "a-mosaic": ("A · Mosaic", "Every muscle a solid tile with hairline gaps; untrained ones stay grey.", render_mosaic),
    "b-silhouette": ("B · Silhouette", "One soft, undivided body; only trained muscles appear.", render_silhouette),
    "c-line-art": ("C · Line art", "A drawn outline with hairline muscle contours; trained muscles filled.", render_lineart),
    "d-capsules": ("D · Capsules", "Abstract rounded strokes, the icon's vocabulary; legible at Watch size.", render_pills),
}


def figure_pair(render, load, t, x, y, scale):
    """Front and back next to each other, 200 x 420 each, 24 apart."""
    g = f'<g transform="translate({x},{y}) scale({scale})">'
    g += render("front", load, t)
    g += f'<g transform="translate(224,0)">{render("back", load, t)}</g></g>'
    return g


def text(x, y, s, size, color, weight=400, anchor="start"):
    return (f'<text x="{x}" y="{y}" font-family="-apple-system, SF Pro Text, Helvetica, Arial" '
            f'font-size="{size}" font-weight="{weight}" fill="{color}" text-anchor="{anchor}">{s}</text>')


def sheet(key, title, blurb, render):
    W, H = 1240, 1160
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">']
    for row, (tname, t) in enumerate(THEMES.items()):
        y0 = row * 580
        out.append(f'<rect x="0" y="{y0}" width="{W}" height="580" fill="{t["bg"]}"/>')
        if row == 0:
            out.append(text(32, 44, title, 26, t["ink"], 700))
            out.append(text(32, 70, blurb, 15, t["sub"]))
        out.append(text(W - 32, y0 + 44, tname.title(), 13, t["sub"], 600, "end"))
        # Three Workouts at full size
        for i, (name, load) in enumerate([("Push Day", PUSH), ("Pull Day", PULL), ("Leg Day", LEGS)]):
            x = 32 + i * 400
            out.append(text(x, y0 + 108, name, 15, t["ink"], 600))
            out.append(figure_pair(render, load, t, x, y0 + 122, 0.8))
        # Small sizes: list row (~44 pt tall) and Watch (~80 pt tall)
        out.append(text(32, y0 + 520, "Small sizes →", 13, t["sub"]))
        for i, load in enumerate([PUSH, PULL, LEGS]):
            out.append(figure_pair(render, load, t, 140 + i * 70, y0 + 494, 0.13))
        for i, load in enumerate([PUSH, PULL, LEGS]):
            out.append(figure_pair(render, load, t, 380 + i * 130, y0 + 472, 0.24))
    out.append("</svg>")
    with open(os.path.join(OUT, f"{key}.svg"), "w") as f:
        f.write("".join(out))


for key, (title, blurb, render) in CONCEPTS.items():
    sheet(key, title, blurb, render)
print("ok")
