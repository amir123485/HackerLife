extends Node3D
## Procedurally builds the 3D apartment for the prototype:
## room, furniture, night city outside the window, cinematic lights.
## Everything is generated from primitives => 100% original assets.

var player: CharacterBody3D
var lights: Array = []
var env: Environment
var dir_light: DirectionalLight3D

const ROOM_W := 5.0
const ROOM_D := 4.0
const WALL_H := 2.7

func _ready() -> void:
        add_to_group("world")
        _build_environment()
        _build_room()
        _build_city()
        _build_furniture()
        _build_lights()
        _spawn_player()

# ---------------------------------------------------------------- helpers
func _mat(color: Color, rough := 0.9, metal := 0.0, emis := Color(0, 0, 0), emis_energy := 0.0) -> StandardMaterial3D:
        var m := StandardMaterial3D.new()
        m.albedo_color = color
        m.roughness = rough
        m.metallic = metal
        if emis_energy > 0.0:
                m.emission_enabled = true
                m.emission = emis
                m.emission_energy_multiplier = emis_energy
        return m

func _mesh_box(size: Vector3, pos: Vector3, mat: Material, cast_shadow := true) -> MeshInstance3D:
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = size
        mi.mesh = bm
        mi.material_override = mat
        mi.position = pos
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(mi)
        return mi

func _solid(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
        var body := StaticBody3D.new()
        body.collision_layer = 1
        body.collision_mask = 0
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        body.add_child(cs)
        body.position = pos
        add_child(body)
        var mi := _mesh_box(size, pos, mat)
        body.set_meta("mesh", mi)
        return body

func _interactable(id: String, action: String, prompt: String, pos: Vector3, size: Vector3) -> void:
        var body := StaticBody3D.new()
        body.collision_layer = 4
        body.collision_mask = 0
        body.add_to_group("interactable")
        body.set_meta("action", action)
        body.set_meta("prompt", prompt)
        body.set_meta("id", id)
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        body.add_child(cs)
        body.position = pos
        add_child(body)

func _omni(pos: Vector3, color: Color, energy: float, dist: float, shadow := false) -> OmniLight3D:
        var l := OmniLight3D.new()
        l.position = pos
        l.light_color = color
        l.light_energy = energy
        l.omni_range = dist
        l.shadow_enabled = shadow
        l.shadow_bias = 0.05
        add_child(l)
        lights.append(l)
        return l

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
        env = Environment.new()
        env.background_mode = Environment.BG_SKY
        var sky := Sky.new()
        var sky_mat := ProceduralSkyMaterial.new()
        sky_mat.sky_top_color = Color(0.03, 0.04, 0.10)
        sky_mat.sky_horizon_color = Color(0.10, 0.09, 0.18)
        sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.05)
        sky_mat.ground_horizon_color = Color(0.08, 0.08, 0.14)
        sky_mat.sun_angle_max = 10.0
        sky.sky_material = sky_mat
        env.sky = sky
        env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        env.ambient_light_color = Color(0.25, 0.28, 0.40)
        env.ambient_light_energy = 0.72
        env.tonemap_mode = Environment.TONE_MAPPER_ACES
        env.glow_enabled = true
        env.glow_intensity = 0.55
        env.glow_bloom = 0.05
        env.glow_hdr_threshold = 1.1
        env.fog_enabled = true
        env.fog_light_color = Color(0.05, 0.06, 0.12)
        env.fog_density = 0.008
        var we := WorldEnvironment.new()
        we.environment = env
        add_child(we)

func apply_shadows(on: bool) -> void:
        for l in lights:
                if l is OmniLight3D:
                        l.shadow_enabled = on and l.get_meta("want_shadow", false)
                elif l is DirectionalLight3D:
                        l.shadow_enabled = on

func apply_glow(on: bool) -> void:
        env.glow_enabled = on

# ---------------------------------------------------------------- room shell
func _build_room() -> void:
        var floor_mat := _mat(Color(0.32, 0.22, 0.14), 0.85)
        var wall_mat := _mat(Color(0.16, 0.18, 0.23), 0.95)
        var ceil_mat := _mat(Color(0.12, 0.13, 0.17), 0.95)
        var frame_mat := _mat(Color(0.08, 0.08, 0.10), 0.6, 0.3)

        _solid(Vector3(ROOM_W + 0.4, 0.1, ROOM_D + 0.4), Vector3(0, -0.05, 0), floor_mat)
        _solid(Vector3(ROOM_W + 0.4, 0.1, ROOM_D + 0.4), Vector3(0, WALL_H + 0.05, 0), ceil_mat)
        # side walls
        _solid(Vector3(0.1, WALL_H, ROOM_D), Vector3(-ROOM_W / 2 - 0.05, WALL_H / 2, 0), wall_mat)
        _solid(Vector3(0.1, WALL_H, ROOM_D), Vector3(ROOM_W / 2 + 0.05, WALL_H / 2, 0), wall_mat)
        # back wall (desk side)
        _solid(Vector3(ROOM_W, WALL_H, 0.1), Vector3(0, WALL_H / 2, -ROOM_D / 2 - 0.05), wall_mat)
        # front wall with window: bottom, top, left, right
        _solid(Vector3(2.4, 0.9, 0.1), Vector3(0, 0.45, ROOM_D / 2 + 0.05), wall_mat)
        _solid(Vector3(2.4, 0.5, 0.1), Vector3(0, WALL_H - 0.25, ROOM_D / 2 + 0.05), wall_mat)
        _solid(Vector3(1.3, WALL_H, 0.1), Vector3(-ROOM_W / 2 + 0.65, WALL_H / 2, ROOM_D / 2 + 0.05), wall_mat)
        _solid(Vector3(1.3, WALL_H, 0.1), Vector3(ROOM_W / 2 - 0.65, WALL_H / 2, ROOM_D / 2 + 0.05), wall_mat)
        # window frame + glass
        var glass := StandardMaterial3D.new()
        glass.albedo_color = Color(0.5, 0.65, 0.85, 0.08)
        glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        glass.emission_enabled = true
        glass.emission = Color(0.10, 0.14, 0.24)
        glass.emission_energy_multiplier = 0.4
        glass.cull_mode = BaseMaterial3D.CULL_DISABLED
        var gm := MeshInstance3D.new()
        var gbm := BoxMesh.new()
        gbm.size = Vector3(2.4, 1.3, 0.02)
        gm.mesh = gbm
        gm.material_override = glass
        gm.position = Vector3(0, 1.55, ROOM_D / 2)
        gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(gm)
        for bx in [-1.2, 0.0, 1.2]:
                _mesh_box(Vector3(0.06, 1.3, 0.08), Vector3(bx, 1.55, ROOM_D / 2), frame_mat)
        _mesh_box(Vector3(2.4, 0.06, 0.08), Vector3(0, 2.2, ROOM_D / 2), frame_mat)
        _mesh_box(Vector3(2.4, 0.06, 0.08), Vector3(0, 0.9, ROOM_D / 2), frame_mat)
        # neon strip inside, above window
        _mesh_box(Vector3(1.8, 0.05, 0.05), Vector3(0, 2.35, ROOM_D / 2 - 0.06), _mat(Color(0.3, 0.1, 0.5), 0.4, 0.0, Color(0.9, 0.3, 1.0), 2.2), false)
        # skirting board
        _mesh_box(Vector3(ROOM_W, 0.08, 0.03), Vector3(0, 0.04, -ROOM_D / 2 + 0.03), frame_mat, false)
        _mesh_box(Vector3(0.03, 0.08, ROOM_D), Vector3(-ROOM_W / 2 + 0.03, 0.04, 0), frame_mat, false)
        _mesh_box(Vector3(0.03, 0.08, ROOM_D), Vector3(ROOM_W / 2 - 0.03, 0.04, 0), frame_mat, false)

# ---------------------------------------------------------------- night city
func _build_city() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = 20260919
        var body_mat := _mat(Color(0.05, 0.05, 0.09), 0.95)
        var win_colors := [Color(1.0, 0.75, 0.35), Color(0.5, 0.8, 1.0), Color(1.0, 0.5, 0.6), Color(0.6, 1.0, 0.75)]
        for i in range(34):
                var bx := rng.randf_range(-26.0, 26.0)
                var bz := rng.randf_range(9.0, 34.0)
                var bh := rng.randf_range(5.0, 19.0)
                var bw := rng.randf_range(1.6, 3.6)
                var bd := rng.randf_range(1.6, 3.0)
                _mesh_box(Vector3(bw, bh, bd), Vector3(bx, bh / 2.0, bz), body_mat, false)
                # emissive window strips (city lights)
                var strips := rng.randi_range(5, 9)
                for s in range(strips):
                        var wc: Color = win_colors[rng.randi_range(0, win_colors.size() - 1)]
                        var sm := _mat(Color(0.1, 0.1, 0.12), 0.8, 0.0, wc, rng.randf_range(3.0, 6.5))
                        var sy := rng.randf_range(1.0, bh - 0.6)
                        var sx := bx + rng.randf_range(-bw * 0.28, bw * 0.28)
                        _mesh_box(Vector3(bw * 0.62, rng.randf_range(0.2, 0.42), 0.02), Vector3(sx, sy, bz - bd / 2 - 0.01), sm, false)
        # rooftop antennas for silhouette flavor
        for i in range(6):
                var ax := rng.randf_range(-22.0, 22.0)
                var az := rng.randf_range(12.0, 30.0)
                _mesh_box(Vector3(0.06, 2.2, 0.06), Vector3(ax, 8.6, az), body_mat, false)
                var tip := _mat(Color(0.6, 0.1, 0.1), 0.6, 0.0, Color(1.0, 0.15, 0.15), 3.0)
                _mesh_box(Vector3(0.1, 0.1, 0.1), Vector3(ax, 9.75, az), tip, false)
        # distant ground plane (street glow)
        var ground := MeshInstance3D.new()
        var pm := PlaneMesh.new()
        pm.size = Vector2(120, 120)
        ground.mesh = pm
        ground.material_override = _mat(Color(0.02, 0.02, 0.04), 1.0)
        ground.position = Vector3(0, -0.02, 18)
        ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(ground)

# ---------------------------------------------------------------- furniture
func _build_furniture() -> void:
        var wood := _mat(Color(0.38, 0.26, 0.16), 0.8)
        var dark := _mat(Color(0.10, 0.10, 0.13), 0.7, 0.1)
        var metal := _mat(Color(0.35, 0.37, 0.42), 0.35, 0.9)
        var fabric := _mat(Color(0.15, 0.22, 0.38), 1.0)
        var white := _mat(Color(0.75, 0.76, 0.78), 0.5)

        # --- desk setup (against back wall, z = -1.7)
        _mesh_box(Vector3(2.0, 0.06, 0.8), Vector3(-0.6, 0.74, -1.65), wood)
        _mesh_box(Vector3(0.06, 0.72, 0.7), Vector3(-1.55, 0.36, -1.65), dark)
        _mesh_box(Vector3(0.06, 0.72, 0.7), Vector3(0.35, 0.36, -1.65), dark)
        # monitor (screen faces +z toward player)
        _mesh_box(Vector3(0.9, 0.52, 0.05), Vector3(-0.6, 1.25, -1.78), dark)
        var screen := _mat(Color(0.02, 0.05, 0.08), 0.4, 0.0, Color(0.16, 0.5, 0.75), 1.5)
        _mesh_box(Vector3(0.82, 0.44, 0.01), Vector3(-0.6, 1.25, -1.745), screen, false)
        _mesh_box(Vector3(0.08, 0.18, 0.08), Vector3(-0.6, 0.88, -1.78), dark)
        _mesh_box(Vector3(0.3, 0.03, 0.2), Vector3(-0.6, 0.78, -1.76), dark)
        # keyboard & mouse
        _mesh_box(Vector3(0.62, 0.02, 0.2), Vector3(-0.6, 0.78, -1.45), dark)
        var kmat := _mat(Color(0.14, 0.16, 0.2), 0.6, 0.0, Color(0.2, 0.9, 0.7), 0.35)
        _mesh_box(Vector3(0.58, 0.008, 0.16), Vector3(-0.6, 0.792, -1.45), kmat, false)
        _mesh_box(Vector3(0.07, 0.03, 0.11), Vector3(-0.15, 0.785, -1.45), dark)
        # PC tower with power LED under desk
        _mesh_box(Vector3(0.22, 0.5, 0.5), Vector3(0.65, 0.26, -1.7), metal)
        _mesh_box(Vector3(0.02, 0.02, 0.02), Vector3(0.65, 0.44, -1.44), _mat(Color(0.1, 0.4, 0.3), 0.4, 0.0, Color(0.0, 1.0, 0.7), 2.0), false)
        # office chair
        _mesh_box(Vector3(0.44, 0.07, 0.44), Vector3(-0.6, 0.45, -1.05), fabric)
        _mesh_box(Vector3(0.42, 0.5, 0.07), Vector3(-0.6, 0.72, -0.83), fabric)
        _mesh_box(Vector3(0.08, 0.4, 0.08), Vector3(-0.6, 0.22, -1.05), dark)

        # --- bed (along +x wall)
        _mesh_box(Vector3(1.1, 0.22, 2.1), Vector3(1.85, 0.16, 0.4), wood)
        _mesh_box(Vector3(1.02, 0.14, 2.0), Vector3(1.85, 0.33, 0.4), _mat(Color(0.55, 0.58, 0.66), 1.0))
        _mesh_box(Vector3(1.02, 0.08, 1.2), Vector3(1.85, 0.42, 0.75), _mat(Color(0.2, 0.3, 0.55), 1.0))
        _mesh_box(Vector3(0.5, 0.1, 0.32), Vector3(1.85, 0.45, -0.35), white)
        _mesh_box(Vector3(1.2, 0.5, 0.08), Vector3(2.45, 0.5, -0.6), wood)

        # --- shelf with books (+x wall above bed area)
        _mesh_box(Vector3(0.25, 0.04, 1.2), Vector3(2.38, 1.7, -1.1), wood)
        _mesh_box(Vector3(0.25, 0.04, 1.2), Vector3(2.38, 1.2, -1.1), wood)
        var book_colors := [Color(0.7, 0.2, 0.2), Color(0.2, 0.4, 0.7), Color(0.75, 0.6, 0.2), Color(0.25, 0.55, 0.3), Color(0.5, 0.3, 0.6)]
        for shelf_y in [1.7, 1.2]:
                var zz := -1.6
                for b in range(5):
                        var bw := rng_read() * 0.05 + 0.05
                        _mesh_box(Vector3(0.2, 0.26, bw), Vector3(2.38, shelf_y + 0.15, zz + bw / 2), _mat(book_colors[(b + int(shelf_y)) % 5], 0.9))
                        zz += bw + 0.015

        # --- kitchenette corner (-x, +z)
        _mesh_box(Vector3(0.6, 0.9, 1.6), Vector3(-2.2, 0.45, 1.15), dark)
        _mesh_box(Vector3(0.64, 0.04, 1.64), Vector3(-2.2, 0.92, 1.15), metal)
        # fridge
        var fridge := _solid(Vector3(0.6, 1.5, 0.6), Vector3(-2.2, 0.75, 0.3), white)
        fridge.get_meta("mesh").material_override = white
        _mesh_box(Vector3(0.03, 0.5, 0.04), Vector3(-1.89, 0.95, 0.12), metal)

        # --- rug
        var rug := MeshInstance3D.new()
        var rpm := PlaneMesh.new()
        rpm.size = Vector2(2.0, 1.4)
        rug.mesh = rpm
        rug.material_override = _mat(Color(0.25, 0.16, 0.30), 1.0)
        rug.position = Vector3(0.2, 0.005, 0.2)
        rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(rug)

        # --- poster (emissive, on back wall above desk)
        _mesh_box(Vector3(0.6, 0.8, 0.02), Vector3(0.9, 1.7, -1.98), _mat(Color(0.05, 0.1, 0.2), 0.6, 0.0, Color(0.1, 0.45, 0.8), 0.9))

        # --- door on -x wall
        _mesh_box(Vector3(0.06, 2.0, 0.9), Vector3(-2.48, 1.0, -1.3), _mat(Color(0.30, 0.20, 0.12), 0.8))
        _mesh_box(Vector3(0.02, 0.02, 0.12), Vector3(-2.44, 1.0, -0.95), metal)

        # --- small lamp on shelf (warm)
        _mesh_box(Vector3(0.12, 0.2, 0.12), Vector3(2.35, 1.85, -0.55), dark)

        # --- interactables (invisible hotspots)
        _interactable("computer", "computer", "Use computer  [E]", Vector3(-0.6, 1.1, -1.55), Vector3(1.3, 1.0, 0.9))
        _interactable("bed", "bed", "Sleep until morning  [E]", Vector3(1.85, 0.4, 0.4), Vector3(1.2, 0.6, 2.2))
        _interactable("fridge", "fridge", "Grab a snack  [E]", Vector3(-2.2, 0.8, 0.3), Vector3(0.8, 1.6, 0.8))
        _interactable("door", "door", "Leave for school  [E]", Vector3(-2.42, 1.1, -1.3), Vector3(0.3, 2.0, 1.0))
        _interactable("books", "books", "Read a book  [E]", Vector3(2.32, 1.5, -1.1), Vector3(0.35, 0.9, 1.3))

var _book_seed := 0
func rng_read() -> float:
        _book_seed += 1
        return float((_book_seed * 37) % 10) / 10.0

# ---------------------------------------------------------------- lights
func _build_lights() -> void:
        # moonlight through window
        dir_light = DirectionalLight3D.new()
        dir_light.rotation_degrees = Vector3(-38, 148, 0)
        dir_light.light_color = Color(0.55, 0.62, 0.9)
        dir_light.light_energy = 0.35
        dir_light.shadow_enabled = true
        add_child(dir_light)
        lights.append(dir_light)
        # warm ceiling lamp
        var l1 := _omni(Vector3(0, 2.5, 0), Color(1.0, 0.85, 0.65), 0.9, 4.5, true)
        l1.set_meta("want_shadow", true)
        # monitor glow
        _omni(Vector3(-0.6, 1.3, -1.3), Color(0.35, 0.75, 1.0), 0.8, 2.2)
        # neon spill near window
        _omni(Vector3(0, 2.0, 1.4), Color(0.85, 0.35, 1.0), 0.5, 2.6)
        # lamp accent
        _omni(Vector3(2.2, 1.9, -0.55), Color(1.0, 0.8, 0.5), 0.4, 1.6)

# ---------------------------------------------------------------- player
func _spawn_player() -> void:
        var PlayerScript := load("res://scripts/player/player.gd")
        player = PlayerScript.new()
        player.position = Vector3(0.4, 0.1, 0.6)
        add_child(player)

func get_player() -> CharacterBody3D:
        return player

func get_save_state() -> Dictionary:
        if player == null:
                return {}
        return {
                "pos": [player.position.x, player.position.y, player.position.z],
                "yaw": player.get_yaw(),
        }

func set_load_state(d: Dictionary) -> void:
        if player == null or d.is_empty():
                return
        var pos: Array = d.get("pos", [0.4, 0.1, 0.6])
        player.position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
        player.set_yaw(float(d.get("yaw", 0.0)))
