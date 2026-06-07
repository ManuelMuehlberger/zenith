import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "achievements"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def mat(name, color, metallic=0.0, roughness=0.35):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return material


def cylinder(
    name,
    radius,
    depth,
    z,
    material,
    vertices=128,
    rotation_z=0,
    bevel_width=0.025,
):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=(0, 0, z),
        rotation=(0, 0, rotation_z),
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bevel = obj.modifiers.new(name="soft beveled edge", type="BEVEL")
    bevel.width = bevel_width
    bevel.segments = 5
    obj.modifiers.new(name="weighted normals", type="WEIGHTED_NORMAL")
    return obj


def prism(name, points, depth, z, material, bevel_width=0.02):
    top_z = z + depth / 2
    bottom_z = z - depth / 2
    verts = [(x, y, bottom_z) for x, y in points] + [(x, y, top_z) for x, y in points]
    count = len(points)
    faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, count * 2))]
    for i in range(count):
        faces.append((i, (i + 1) % count, (i + 1) % count + count, i + count))

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bevel = obj.modifiers.new(name="soft prism bevel", type="BEVEL")
    bevel.width = bevel_width
    bevel.segments = 4
    obj.modifiers.new(name="weighted normals", type="WEIGHTED_NORMAL")
    return obj


def rounded_box(name, width, height, depth, z, material, bevel_width=0.035):
    obj = prism(
        name,
        [
            (-width / 2, -height / 2),
            (width / 2, -height / 2),
            (width / 2, height / 2),
            (-width / 2, height / 2),
        ],
        depth,
        z,
        material,
        bevel_width=bevel_width,
    )
    return obj


def regular_points(count, radius, rotation=0):
    return [
        (
            math.cos(rotation + math.tau * i / count) * radius,
            math.sin(rotation + math.tau * i / count) * radius,
        )
        for i in range(count)
    ]


def star_points(points, outer, inner, rotation=math.pi / 2):
    result = []
    for i in range(points * 2):
        radius = outer if i % 2 == 0 else inner
        angle = rotation + math.tau * i / (points * 2)
        result.append((math.cos(angle) * radius, math.sin(angle) * radius))
    return result


def torus(name, major, minor, z, material):
    bpy.ops.mesh.primitive_torus_add(
        major_segments=144,
        minor_segments=16,
        major_radius=major,
        minor_radius=minor,
        location=(0, 0, z),
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return obj


def tube(name, points, material, width=0.028, z=0.15, closed=False):
    if closed and points and points[0] == points[-1]:
        points = points[:-1]
    curve = bpy.data.curves.new(name, type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 3
    curve.bevel_depth = width
    curve.bevel_resolution = 5
    curve.use_fill_caps = True
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    spline.use_cyclic_u = closed
    for point, (x, y) in zip(spline.points, points):
        point.co = (x, y, z, 1)

    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    return obj


def cubic_points(p0, p1, p2, p3, steps=14):
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = (
            u * u * u * p0[0]
            + 3 * u * u * t * p1[0]
            + 3 * u * t * t * p2[0]
            + t * t * t * p3[0]
        )
        y = (
            u * u * u * p0[1]
            + 3 * u * u * t * p1[1]
            + 3 * u * t * t * p2[1]
            + t * t * t * p3[1]
        )
        points.append((x, y))
    return points


def extend_without_duplicate(points, more):
    if points and more and points[-1] == more[0]:
        points.extend(more[1:])
    else:
        points.extend(more)


def arc(name, center, radius, start, end, material, width=0.026, steps=36, z=0.15):
    points = []
    for i in range(steps + 1):
        t = start + (end - start) * i / steps
        points.append((center[0] + math.cos(t) * radius, center[1] + math.sin(t) * radius))
    return tube(name, points, material, width=width, z=z)


def raised_triangle(name, points, material, z=0.145, thickness=0.025):
    verts = [(x, y, z) for x, y in points] + [(x, y, z + thickness) for x, y in points]
    faces = [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    bevel = obj.modifiers.new(name="triangle bevel", type="BEVEL")
    bevel.width = 0.01
    bevel.segments = 2
    obj.modifiers.new(name="weighted normals", type="WEIGHTED_NORMAL")
    return obj


def setup_world():
    bpy.context.scene.world = bpy.data.worlds.new("achievement world")
    bpy.context.scene.world.color = (0.03, 0.035, 0.045)
    bpy.ops.object.light_add(type="AREA", location=(0, -3.0, 3.5))
    key = bpy.context.object
    key.name = "large softbox"
    key.data.energy = 550
    key.data.size = 4.0
    bpy.ops.object.camera_add(location=(0, -3.25, 1.25), rotation=(math.radians(69), 0, 0))
    bpy.context.scene.camera = bpy.context.object


def make_base(face, rim, ring, accent):
    cylinder("single circular award footprint", 1.0, 0.16, 0, rim)
    cylinder("slightly inset enamel face", 0.83, 0.045, 0.095, face)
    torus("outer raised rim", 0.92, 0.055, 0.11, rim)
    torus("inner activity ring", 0.66, 0.025, 0.145, ring)
    torus("fine highlight ring", 0.45, 0.012, 0.155, accent)


def make_hex_strength_base(face, rim, ring, accent):
    cylinder(
        "octagonal iron award frame",
        1.0,
        0.18,
        0,
        rim,
        vertices=8,
        rotation_z=math.radians(22.5),
        bevel_width=0.035,
    )
    cylinder(
        "deep inset training plate",
        0.78,
        0.055,
        0.11,
        face,
        vertices=8,
        rotation_z=math.radians(22.5),
        bevel_width=0.02,
    )
    torus("green machined outer groove", 0.72, 0.025, 0.145, ring)
    torus("inner machined groove", 0.43, 0.012, 0.16, accent)


def make_crystal_time_base(face, rim, ring, accent):
    cylinder(
        "round sapphire time medal",
        0.95,
        0.18,
        0,
        rim,
        vertices=128,
        bevel_width=0.035,
    )
    cylinder(
        "inset blue glass dial",
        0.75,
        0.055,
        0.11,
        face,
        vertices=128,
        bevel_width=0.022,
    )
    torus("cool outer time ring", 0.8, 0.035, 0.09, ring)


def capsule_bar(name, left, right, material, width=0.038, z=0.138):
    start_x = left[0] + width * 0.55
    end_x = right[0] - width * 0.55
    tube(name, [(start_x, left[1]), (end_x, right[1])], material, width=width, z=z)


def make_completion_star_base(face, rim, ring, accent):
    prism("purple starburst medal", star_points(14, 1.0, 0.84), 0.16, 0, rim, 0.022)
    cylinder("inset violet core", 0.72, 0.06, 0.11, face, vertices=96, bevel_width=0.025)
    torus("completion glow ring", 0.58, 0.025, 0.15, ring)
    torus("small check halo", 0.36, 0.012, 0.165, accent)


def cup_emblem(rim, light):
    tube("cup bowl", [(-0.32, 0.2), (-0.24, -0.17), (0.24, -0.17), (0.32, 0.2)], light, 0.032)
    tube("cup lip", [(-0.36, 0.22), (0.36, 0.22)], light, 0.034)
    tube("cup stem", [(0, -0.18), (0, -0.39)], light, 0.034)
    tube("cup base", [(-0.23, -0.42), (0.23, -0.42)], light, 0.036)
    arc("left handle", (-0.32, 0.02), 0.18, math.radians(85), math.radians(265), rim, 0.025)
    arc("right handle", (0.32, 0.02), 0.18, math.radians(-85), math.radians(95), rim, 0.025)


def barbell_emblem(light, accent):
    objects_before = set(bpy.data.objects)
    tube("knurled steel grip", [(-0.52, 0), (0.52, 0)], light, 0.038, z=0.205)
    for x in (-0.28, -0.14, 0, 0.14, 0.28):
        tube("short grip knurl", [(x - 0.035, -0.048), (x + 0.035, 0.048)], accent, 0.006, z=0.25)
    tube("handle highlight", [(-0.36, 0.04), (0.36, 0.04)], light, 0.006, z=0.252)
    iron = accent
    shadow = bpy.data.materials.get("dark iron shadow") or accent
    collar = bpy.data.materials.get("brushed steel collar") or light
    for side in (-1, 1):
        for index, (offset, radius, depth) in enumerate(((0.5, 0.2, 0.08), (0.66, 0.28, 0.09))):
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6,
                radius=radius,
                depth=depth,
                location=(side * offset, 0, 0.205 + index * 0.006),
                rotation=(0, 0, math.radians(30)),
            )
            plate = bpy.context.object
            plate.name = "dark hex dumbbell head"
            plate.scale.y = 0.92
            plate.data.materials.append(iron if index else shadow)
            plate.modifiers.new(name="beveled rubberized edge", type="BEVEL").width = 0.022
            plate.modifiers.new(name="weighted normals", type="WEIGHTED_NORMAL")
            tube(
                "head bevel highlight",
                [
                    (side * (offset - 0.08), radius * 0.42),
                    (side * (offset + 0.08), radius * 0.42),
                ],
                collar,
                0.006,
                z=0.265 + index * 0.006,
            )
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=48,
            radius=0.075,
            depth=0.05,
            location=(side * 0.39, 0, 0.215),
        )
        collar_obj = bpy.context.object
        collar_obj.name = "steel dumbbell collar"
        collar_obj.data.materials.append(collar)
        collar_obj.modifiers.new(name="collar bevel", type="BEVEL").width = 0.007
        collar_obj.modifiers.new(name="weighted normals", type="WEIGHTED_NORMAL")
    for obj in [o for o in bpy.data.objects if o not in objects_before]:
        obj.rotation_euler[2] += math.radians(-18)


def hourglass_emblem(light, accent):
    top_left = (-0.36, 0.46)
    top_right = (0.36, 0.46)
    waist = (0.0, 0.0)
    bottom_left = (-0.36, -0.46)
    bottom_right = (0.36, -0.46)
    relief_z = 0.138
    right_upper = cubic_points(top_right, (0.36, 0.4), (0.12, 0.11), waist)
    right_lower = cubic_points(waist, (0.1, -0.09), (0.34, -0.34), bottom_right)
    left_lower = cubic_points(bottom_left, (-0.34, -0.34), (-0.1, -0.09), waist)
    left_upper = cubic_points(waist, (-0.12, 0.11), (-0.36, 0.4), top_left)
    upper_sand_right = right_upper[5]
    upper_sand_left = left_upper[-6]
    lower_sand_right = right_lower[9]
    lower_sand_left = left_lower[5]
    outline = [top_left, top_right]
    extend_without_duplicate(outline, right_upper)
    extend_without_duplicate(outline, right_lower)
    outline.append(bottom_left)
    extend_without_duplicate(outline, left_lower)
    extend_without_duplicate(
        outline,
        cubic_points(waist, (-0.12, 0.11), (-0.36, 0.4), top_left),
    )

    tube(
        "continuous glass hourglass outline",
        outline,
        light,
        0.024,
        z=relief_z,
        closed=True,
    )
    prism(
        "top sand chamber",
        [
            upper_sand_left,
            upper_sand_right,
            (0.125, 0.125),
            (0.042, 0.042),
            waist,
            (-0.042, 0.042),
            (-0.125, 0.125),
        ],
        0.022,
        relief_z,
        accent,
        bevel_width=0.007,
    )
    prism(
        "bottom sand pile",
        [
            bottom_left,
            bottom_right,
            right_lower[-3],
            lower_sand_right,
            (0.135, -0.215),
            (0.0, -0.19),
            (-0.135, -0.215),
            lower_sand_left,
            left_lower[2],
        ],
        0.022,
        relief_z,
        accent,
        bevel_width=0.007,
    )


def check_emblem(light, accent):
    tube("raised check", [(-0.38, -0.02), (-0.12, -0.27), (0.42, 0.28)], light, 0.055)


def export(name):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / name
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        export_yup=True,
        export_materials="EXPORT",
        export_apply=True,
    )


def render_thumbnail(name):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.engine = "BLENDER_EEVEE_NEXT"
    bpy.context.scene.eevee.taa_render_samples = 64
    bpy.context.scene.render.resolution_x = 128
    bpy.context.scene.render.resolution_y = 128
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.view_settings.view_transform = "Filmic"
    bpy.context.scene.view_settings.look = "Medium High Contrast"
    camera = bpy.context.scene.camera
    camera.location = (0, 0, 4.0)
    direction = Vector((0, 0, 0.08)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.2
    bpy.context.scene.render.filepath = str(OUT_DIR / name.replace(".glb", ".png"))
    bpy.ops.render.render(write_still=True)


def build_award(name, palette, emblem, base_builder=make_base):
    clear_scene()
    setup_world()
    rim = mat("brushed warm metal", palette["rim"], metallic=0.85, roughness=0.22)
    face = mat("deep enamel", palette["face"], metallic=0.12, roughness=0.3)
    ring = mat("activity ring", palette["ring"], metallic=0.45, roughness=0.2)
    accent = mat(
        "raised accent",
        palette["accent"],
        metallic=0.25 if name == "achievement_dumbbell.glb" else 0.55,
        roughness=0.68 if name == "achievement_dumbbell.glb" else 0.22,
    )
    light = mat("soft ivory relief", palette["light"], metallic=0.25, roughness=0.24)
    if name == "achievement_dumbbell.glb":
        mat("dark iron shadow", palette["shadow"], metallic=0.45, roughness=0.5)
        mat("brushed steel collar", palette["steel"], metallic=0.8, roughness=0.22)
    base_builder(face, rim, ring, accent)
    emblem(rim if name == "achievement_cup.glb" else light, accent)
    render_thumbnail(name)
    export(name)


PALETTES = {
    "achievement_cup.glb": {
        "rim": (1.0, 0.62, 0.12, 1),
        "face": (0.38, 0.13, 0.02, 1),
        "ring": (1.0, 0.83, 0.22, 1),
        "accent": (1.0, 0.96, 0.65, 1),
        "light": (1.0, 0.9, 0.42, 1),
    },
    "achievement_dumbbell.glb": {
        "rim": (0.05, 0.34, 0.28, 1),
        "face": (0.015, 0.08, 0.075, 1),
        "ring": (0.2, 0.88, 0.54, 1),
        "accent": (0.028, 0.03, 0.034, 1),
        "shadow": (0.012, 0.013, 0.015, 1),
        "steel": (0.62, 0.66, 0.68, 1),
        "light": (0.78, 0.84, 0.84, 1),
    },
    "achievement_hourglass.glb": {
        "rim": (0.28, 0.58, 1.0, 1),
        "face": (0.02, 0.12, 0.26, 1),
        "ring": (0.46, 0.86, 1.0, 1),
        "accent": (0.84, 0.89, 0.96, 1),
        "light": (0.85, 0.96, 1.0, 1),
    },
    "achievement_medal.glb": {
        "rim": (0.86, 0.48, 1.0, 1),
        "face": (0.18, 0.05, 0.28, 1),
        "ring": (1.0, 0.46, 0.84, 1),
        "accent": (1.0, 0.78, 0.96, 1),
        "light": (1.0, 0.94, 1.0, 1),
    },
}


def main():
    build_award("achievement_cup.glb", PALETTES["achievement_cup.glb"], cup_emblem)
    build_award(
        "achievement_dumbbell.glb",
        PALETTES["achievement_dumbbell.glb"],
        barbell_emblem,
        make_hex_strength_base,
    )
    build_award(
        "achievement_hourglass.glb",
        PALETTES["achievement_hourglass.glb"],
        hourglass_emblem,
        make_crystal_time_base,
    )
    build_award(
        "achievement_medal.glb",
        PALETTES["achievement_medal.glb"],
        check_emblem,
        make_completion_star_base,
    )


if __name__ == "__main__":
    main()
