"""Copy into a project job folder, then replace the sample model with the requested scene."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

try:
    import bpy
    from mathutils import Vector
except ModuleNotFoundError as exc:
    if "--help" in sys.argv:
        print("Run inside Blender. Script arguments: --output-dir PATH [--name NAME]")
        raise SystemExit(0)
    raise SystemExit("This script must be executed by Blender's Python runtime.") from exc


def script_arguments() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--name", default="agent-blender-scene")
    return parser.parse_args(script_arguments())


def clear_scene() -> None:
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def material(name: str, color: tuple[float, float, float, float], roughness: float) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    if mat.node_tree is None:  # Blender 4.x needs this; 5.2 creates the tree automatically.
        mat.use_nodes = True
    nodes = mat.node_tree.nodes
    shader = nodes.get("Principled BSDF") or nodes.new("ShaderNodeBsdfPrincipled")
    output = nodes.get("Material Output") or nodes.new("ShaderNodeOutputMaterial")
    if not shader.outputs["BSDF"].is_linked:
        mat.node_tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = roughness
    return mat


def point_camera(camera: bpy.types.Object, target: tuple[float, float, float]) -> None:
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


def add_sample_model() -> None:
    bpy.ops.mesh.primitive_cube_add(location=(0.0, 0.0, 0.8), scale=(1.5, 1.0, 0.8))
    body = bpy.context.object
    body.name = "AGENT_Model"
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = body.modifiers.new("Bevel", "BEVEL")
    bevel.width = 0.12
    bevel.segments = 4
    body.data.materials.append(material("AGENT_Material", (0.12, 0.36, 0.72, 1.0), 0.32))

    bpy.ops.mesh.primitive_plane_add(size=14.0, location=(0.0, 0.0, 0.0))
    ground = bpy.context.object
    ground.name = "AGENT_Ground"
    ground.data.materials.append(material("AGENT_GroundMaterial", (0.18, 0.18, 0.18, 1.0), 0.8))


def add_camera_and_lights() -> None:
    bpy.ops.object.camera_add(location=(5.2, -6.2, 4.2))
    camera = bpy.context.object
    camera.name = "AGENT_Camera"
    camera.data.lens = 52
    point_camera(camera, (0.0, 0.0, 0.8))
    bpy.context.scene.camera = camera

    for name, location, energy, size in (
        ("AGENT_Key", (4.0, -3.0, 6.0), 900.0, 4.0),
        ("AGENT_Fill", (-4.0, -1.0, 3.0), 450.0, 3.0),
    ):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        point_camera(light, (0.0, 0.0, 0.8))


def configure_render(preview_path: Path) -> None:
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(preview_path)
    scene.world.color = (0.035, 0.035, 0.035)


def object_summary() -> list[dict]:
    rows = []
    for obj in sorted(bpy.context.scene.objects, key=lambda item: item.name):
        rows.append({
            "name": obj.name,
            "type": obj.type,
            "location": [round(value, 5) for value in obj.location],
            "dimensions": [round(value, 5) for value in obj.dimensions],
        })
    return rows


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    safe_name = "".join(char if char.isalnum() or char in "-_" else "-" for char in args.name).strip("-")
    safe_name = safe_name or "agent-blender-scene"
    blend_path = output_dir / f"{safe_name}.blend"
    preview_path = output_dir / f"{safe_name}-preview.png"
    report_path = output_dir / "report.json"

    clear_scene()
    add_sample_model()
    add_camera_and_lights()
    configure_render(preview_path)

    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), check_existing=False)
    bpy.ops.render.render(write_still=True)
    report = {
        "ok": True,
        "blender_version": bpy.app.version_string,
        "blend": str(blend_path),
        "preview": str(preview_path),
        "render_engine": bpy.context.scene.render.engine,
        "objects": object_summary(),
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"AGENT_BLENDER_REPORT={report_path}")


if __name__ == "__main__":
    main()
