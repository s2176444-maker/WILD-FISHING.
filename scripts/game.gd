extends Node3D

# WILD FISHING — ранний мобильный прототип на Godot 4.
# Вся графика создаётся процедурно, без внешних ассетов.

const SAVE_PATH := "user://wild_fishing_save.cfg"

var money: int = 350
var fish_bag: Array[Dictionary] = []
var selected_rod: int = 0
var selected_reel: int = 0
var selected_line: int = 0
var selected_hook: int = 0
var selected_bait: int = 0
var bait_stock: Array[int] = [15, 0, 0, 0, 0, 0, 0]
var current_region: int = 0
var fish_count: int = 0

var rods := [
    {"name":"Старая удочка", "power":1.0, "price":0, "desc":"Для небольшой рыбы"},
    {"name":"Поплавочная 2.7 м", "power":1.35, "price":260, "desc":"Увереннее держит крупную рыбу"},
    {"name":"Спиннинг River Pro", "power":1.8, "price":720, "desc":"Для сильной рыбы и дальнего заброса"},
    {"name":"Carp Master", "power":2.5, "price":1600, "desc":"Мощная снасть для трофеев"},
    {"name":"Lake Pro 3.6 м", "power":2.72, "price":4800, "desc":"Дорогая удочка, небольшой запас мощности"},
    {"name":"Legend Tournament", "power":2.95, "price":12500, "desc":"Премиальная снасть, но рыба всё равно требует навыка"}
]
var reels := [
    {"name":"Простая катушка", "power":1.0, "price":0},
    {"name":"Катушка 3000", "power":1.25, "price":180},
    {"name":"Катушка Pro 5000", "power":1.65, "price":540},
    {"name":"Aero 6000", "power":1.78, "price":2100},
    {"name":"Tournament X", "power":1.92, "price":6500}
]
var lines := [
    {"name":"Леска 0.18 мм", "strength":1.0, "price":0},
    {"name":"Леска 0.25 мм", "strength":1.35, "price":90},
    {"name":"Леска 0.35 мм", "strength":1.8, "price":240},
    {"name":"Флюорокарбон 0.40 мм", "strength":1.95, "price":850},
    {"name":"Трофейная 0.50 мм", "strength":2.1, "price":1900}
]
var hooks := [
    {"name":"Крючок №8", "quality":1.0, "price":0},
    {"name":"Крючок №6", "quality":1.2, "price":60},
    {"name":"Крючок усиленный", "quality":1.5, "price":170},
    {"name":"Кованый премиум", "quality":1.62, "price":620}
]
var baits := [
    {"name":"Червь", "price":8, "bonus":1.25},
    {"name":"Опарыш", "price":12, "bonus":1.15},
    {"name":"Кукуруза", "price":15, "bonus":1.05},
    {"name":"Блесна", "price":22, "bonus":1.35},
    {"name":"Тесто", "price":18, "bonus":1.18},
    {"name":"Бойлы", "price":35, "bonus":1.32},
    {"name":"Живец", "price":45, "bonus":1.42}
]

var species := [
    {"name":"Плотва", "min":0.08, "max":0.65, "base":32, "rarity":0.34, "fight":0.55, "bait":[0,1,2,4]},
    {"name":"Окунь", "min":0.10, "max":1.8, "base":48, "rarity":0.27, "fight":0.9, "bait":[0,1,3]},
    {"name":"Карась", "min":0.15, "max":2.4, "base":55, "rarity":0.19, "fight":0.75, "bait":[0,2,4,5]},
    {"name":"Лещ", "min":0.25, "max":4.5, "base":72, "rarity":0.10, "fight":1.05, "bait":[0,1,2,4,5]},
    {"name":"Щука", "min":0.45, "max":9.0, "base":110, "rarity":0.065, "fight":1.65, "bait":[3,6]},
    {"name":"Судак", "min":0.5, "max":7.5, "base":135, "rarity":0.045, "fight":1.8, "bait":[3,6]},
    {"name":"Карп", "min":0.4, "max":14.0, "base":95, "rarity":0.035, "fight":2.1, "bait":[2,0,4,5]},
    {"name":"Трофейный сом", "min":2.0, "max":28.0, "base":180, "rarity":0.012, "fight":3.0, "bait":[0,2,5,6]},
    {"name":"Линь", "min":0.2, "max":3.8, "base":86, "rarity":0.075, "fight":1.0, "bait":[0,1,2,4]},
    {"name":"Язь", "min":0.25, "max":4.2, "base":92, "rarity":0.06, "fight":1.25, "bait":[0,1,3]},
    {"name":"Форель", "min":0.2, "max":5.0, "base":150, "rarity":0.028, "fight":1.8, "bait":[1,3,6]},
    {"name":"Голавль", "min":0.15, "max":3.2, "base":105, "rarity":0.05, "fight":1.3, "bait":[1,3,4]}
]

var fishing_state := "idle" # idle, waiting, bite, fight
var wait_time := 0.0
var bite_window := 0.0
var fight_time := 0.0
var tension := 0.18
var fish_strength := 1.0
var fish_weight := 0.0
var hooked_fish: Dictionary = {}
var hooked_name := ""
var fish_distance := 1.0
var is_reeling := false
var cast_power := 0.7

var player: CharacterBody3D
var camera: Camera3D
var camera_third := true
var hud: CanvasLayer
var status_label: Label
var money_label: Label
var inventory_label: Label
var fight_bar: ProgressBar
var tension_bar: ProgressBar
var shop_panel: Panel
var shop_text: Label
var shop_items_container: VBoxContainer
var catch_log_panel: Panel
var catch_log_text: Label
var shop_kind := "rods"
var touch_dir := Vector2.ZERO
var world_root: Node3D
var lake_mesh: MeshInstance3D
var sun_light: DirectionalLight3D
var rain_particles: GPUParticles3D
var weather_name := "Ясно"
var weather_timer := 0.0
var weather_index := 0
var weather_label: Label
var region_objects: Array[Node3D] = []
var fishing_float: MeshInstance3D
var fishing_line: MeshInstance3D
var line_immediate: ImmediateMesh
var line_material: StandardMaterial3D
var game_clock := 0.0

func _ready() -> void:
    _load_game()
    _build_world()
    _build_player()
    _build_ui()
    _refresh_ui()
    _set_status("Добро пожаловать на Озеро Тихое. Подготовь снасть и забрасывай!")

func _process(delta: float) -> void:
    game_clock += delta
    _move_player(delta)
    _update_fishing(delta)
    _update_fishing_visuals()
    if rain_particles and player:
        rain_particles.global_position = player.global_position + Vector3(0, 9, 0)
    if camera and player:
        if camera_third:
            camera.global_position = player.global_position + Vector3(0, 3.2, 6.2)
            camera.look_at(player.global_position + Vector3(0, 1.0, -1.0))
        else:
            camera.global_position = player.global_position + Vector3(0, 1.55, 0)
            camera.rotation = player.rotation
    _update_bars()

func _build_world() -> void:
    world_root = Node3D.new()
    add_child(world_root)
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.12, 0.30, 0.52)
    sky_material.sky_horizon_color = Color(0.62, 0.75, 0.82)
    sky_material.ground_bottom_color = Color(0.12, 0.18, 0.13)
    sky_material.ground_horizon_color = Color(0.38, 0.43, 0.36)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.82, 0.95)
    environment.ambient_light_energy = 0.7
    env.environment = environment
    add_child(env)

    _make_box("Ground", Vector3(0,-0.35,0), Vector3(100,0.6,100), Color(0.22,0.34,0.18))
    lake_mesh = _make_box("Lake", Vector3(0,-0.05,-13), Vector3(54,0.12,38), Color(0.08,0.34,0.48))
    _make_box("Pier", Vector3(0,0.25,-3), Vector3(4,0.5,13), Color(0.38,0.24,0.12))
    for i in range(12):
        var x := randf_range(-34,34)
        var z := randf_range(-30,30)
        if abs(x) < 5 and z < 4 and z > -12:
            continue
        _make_tree(Vector3(x,0,z))
    for i in range(18):
        var rock := _make_box("Rock", Vector3(randf_range(-38,38),0.35,randf_range(-36,34)), Vector3(randf_range(0.5,1.8),randf_range(0.5,1.2),randf_range(0.5,1.8)), Color(0.30,0.32,0.30))
    _make_box("Shop hut", Vector3(8,1.1,5), Vector3(4,2.2,3), Color(0.43,0.25,0.12))
    _make_box("Shop roof", Vector3(8,2.5,5), Vector3(4.8,0.5,3.8), Color(0.22,0.12,0.08))
    _make_box("Far hill", Vector3(-22,2,-38), Vector3(32,4,10), Color(0.18,0.29,0.17))
    _make_box("Far hill 2", Vector3(23,2,-40), Vector3(28,4,12), Color(0.20,0.32,0.18))
    # Fishing village: cabins, boathouse, fence and sign.
    _make_box("Cabin 1", Vector3(-8,1.1,8), Vector3(4.5,2.2,4), Color(0.48,0.30,0.16))
    _make_box("Cabin 1 roof", Vector3(-8,2.55,8), Vector3(5.1,0.55,4.6), Color(0.25,0.13,0.09))
    _make_box("Boathouse", Vector3(13,1.2,-2), Vector3(5,2.4,4), Color(0.34,0.27,0.18))
    _make_box("Boathouse roof", Vector3(13,2.75,-2), Vector3(5.6,0.5,4.6), Color(0.18,0.16,0.13))
    _make_box("Cabin 2", Vector3(-15,0.9,-1), Vector3(3.5,1.8,3), Color(0.40,0.25,0.14))
    _make_box("Cabin 2 roof", Vector3(-15,2.1,-1), Vector3(4.1,0.45,3.6), Color(0.22,0.12,0.08))
    _make_box("Fence", Vector3(8,0.55,9), Vector3(12,1.1,0.18), Color(0.32,0.20,0.11))
    _make_box("Shop sign", Vector3(8,2.0,2.9), Vector3(2.8,0.7,0.15), Color(0.12,0.22,0.16))
    _make_box("Footpath", Vector3(1,0.02,6), Vector3(14,0.06,1.6), Color(0.48,0.39,0.25))
    var lantern := OmniLight3D.new()
    lantern.position = Vector3(8,2.5,2.6)
    lantern.light_color = Color(1.0,0.68,0.34)
    lantern.light_energy = 0.7
    lantern.omni_range = 8
    world_root.add_child(lantern)
    _make_box("Shop sign", Vector3(8,2.0,2.9), Vector3(2.8,0.7,0.15), Color(0.12,0.22,0.16))
    _make_box("Footpath", Vector3(1,0.02,6), Vector3(14,0.06,1.6), Color(0.48,0.39,0.25))
    _make_box("Campfire stones", Vector3(-12,0.12,11), Vector3(1.6,0.25,1.6), Color(0.25,0.24,0.20))
    

    # Distinctive objects for the three fishing zones.
    var rock_marker := _make_box("Rocky shore marker", Vector3(22,1.1,-17), Vector3(3,2.2,2.5), Color(0.35,0.36,0.34))
    var reed_marker := _make_box("Reed shore marker", Vector3(-20,1.0,-17), Vector3(4,2,1.2), Color(0.42,0.48,0.18))
    region_objects = [rock_marker, reed_marker]
    _build_weather()

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.name = label
    instance.mesh = mesh
    instance.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    if label == "Lake":
        mat.roughness = 0.18
        mat.metallic = 0.15
    instance.material_override = mat
    world_root.add_child(instance)
    return instance

func _make_tree(pos: Vector3) -> void:
    var trunk := _make_box("Tree trunk", pos + Vector3(0,1.1,0), Vector3(0.45,2.2,0.45), Color(0.28,0.16,0.08))
    var crown := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = randf_range(1.0,1.7)
    mesh.height = mesh.radius * 2.0
    crown.mesh = mesh
    crown.position = pos + Vector3(0,3.0,0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.12, randf_range(0.25,0.38), 0.13)
    crown.material_override = mat
    world_root.add_child(crown)



func _build_weather() -> void:
    sun_light = DirectionalLight3D.new()
    sun_light.rotation_degrees = Vector3(-48, -30, 0)
    sun_light.light_energy = 1.15
    add_child(sun_light)
    rain_particles = GPUParticles3D.new()
    rain_particles.amount = 500
    rain_particles.lifetime = 1.5
    rain_particles.position = Vector3(0, 9, 0)
    var particle_mesh := BoxMesh.new()
    particle_mesh.size = Vector3(0.025, 0.45, 0.025)
    var particle_mat := StandardMaterial3D.new()
    particle_mat.albedo_color = Color(0.65, 0.78, 0.9, 0.65)
    particle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    particle_mesh.material = particle_mat
    rain_particles.draw_pass_1 = particle_mesh
    var process := ParticleProcessMaterial.new()
    process.direction = Vector3(0.05, -1.0, 0.02)
    process.initial_velocity_min = 15.0
    process.initial_velocity_max = 21.0
    process.gravity = Vector3(0, -9.8, 0)
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(24, 5, 24)
    rain_particles.process_material = process
    rain_particles.emitting = false
    add_child(rain_particles)
    _apply_weather(false)

func _change_weather() -> void:
    weather_index = (weather_index + 1) % 4
    _apply_weather(true)
    _save_game()

func _apply_weather(show_message: bool) -> void:
    var weather := ["Ясно", "Облачно", "Дождь", "Ветер"]
    weather_name = weather[weather_index]
    match weather_index:
        0:
            sun_light.light_energy = 1.15
            rain_particles.emitting = false
        1:
            sun_light.light_energy = 0.78
            rain_particles.emitting = false
        2:
            sun_light.light_energy = 0.58
            rain_particles.emitting = true
        3:
            sun_light.light_energy = 0.9
            rain_particles.emitting = false
    if show_message:
        _set_status("Погода изменилась: " + weather_name + ". Рыба может вести себя иначе.")
    if weather_label:
        weather_label.text = "Погода: " + weather_name

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.position = Vector3(0,1,5)
    add_child(player)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.7
    body.mesh = capsule
    body.position.y = 0.85
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.18,0.28,0.42)
    body.material_override = mat
    player.add_child(body)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.7
    collision.shape = shape
    collision.position.y = 0.85
    player.add_child(collision)

    var rod_visual := MeshInstance3D.new()
    var rod_mesh := CylinderMesh.new()
    rod_mesh.top_radius = 0.025
    rod_mesh.bottom_radius = 0.045
    rod_mesh.height = 2.6
    rod_visual.mesh = rod_mesh
    rod_visual.position = Vector3(0.42, 1.05, -0.35)
    rod_visual.rotation_degrees = Vector3(72, 0, -12)
    var rod_mat := StandardMaterial3D.new()
    rod_mat.albedo_color = Color(0.12,0.10,0.07)
    rod_visual.material_override = rod_mat
    player.add_child(rod_visual)

    fishing_float = MeshInstance3D.new()
    var float_mesh := SphereMesh.new()
    float_mesh.radius = 0.12
    float_mesh.height = 0.34
    fishing_float.mesh = float_mesh
    var float_mat := StandardMaterial3D.new()
    float_mat.albedo_color = Color(0.95,0.20,0.08)
    float_mat.roughness = 0.3
    fishing_float.material_override = float_mat
    fishing_float.visible = false
    world_root.add_child(fishing_float)

    line_immediate = ImmediateMesh.new()
    fishing_line = MeshInstance3D.new()
    fishing_line.mesh = line_immediate
    line_material = StandardMaterial3D.new()
    line_material.albedo_color = Color(0.86,0.88,0.78)
    line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fishing_line.material_override = line_material
    fishing_line.visible = false
    world_root.add_child(fishing_line)

    camera = Camera3D.new()
    camera.current = true
    add_child(camera)

func _build_ui() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(root)

    money_label = _label(root, "₽ " + str(money), Vector2(18,14), Vector2(220,45), 24)
    status_label = _label(root, "Готов к рыбалке", Vector2(18,62), Vector2(650,52), 18)
    inventory_label = _label(root, "", Vector2(18,116), Vector2(520,52), 15)
    weather_label = _label(root, "Погода: " + weather_name, Vector2(18,174), Vector2(260,34), 16)

    var cast_btn := _button(root, "ЗАБРОСИТЬ", Vector2(-190,-92), Vector2(170,58), Vector2(1,1), _cast_line)
    var hook_btn := _button(root, "ПОДСЕЧЬ", Vector2(-190,-158), Vector2(170,58), Vector2(1,1), _hook_fish)
    var reel_btn := _button(root, "ТЯНУТЬ", Vector2(-190,-224), Vector2(170,58), Vector2(1,1), _set_reeling)
    var cam_btn := _button(root, "КАМЕРА", Vector2(-190,-290), Vector2(170,52), Vector2(1,1), _toggle_camera)
    var shop_btn := _button(root, "МАГАЗИН", Vector2(18,-92), Vector2(150,54), Vector2(0,1), _open_shop)
    var sell_btn := _button(root, "ПРОДАТЬ УЛОВ", Vector2(178,-92), Vector2(190,54), Vector2(0,1), _sell_fish)
    var bait_btn := _button(root, "СМЕНИТЬ НАЖИВКУ", Vector2(18,-154), Vector2(240,50), Vector2(0,1), _next_bait)
    var stop_btn := _button(root, "СТОП", Vector2(92,-42), Vector2(64,38), Vector2(0,1), _stop_moving)
    var region_btn := _button(root, "ЛОКАЦИЯ", Vector2(270,-92), Vector2(150,54), Vector2(0,1), _next_region)
    var weather_btn := _button(root, "ПОГОДА", Vector2(430,-92), Vector2(140,54), Vector2(0,1), _change_weather)
    var log_btn := _button(root, "САДОК", Vector2(590,-92), Vector2(130,54), Vector2(0,1), _open_catch_log)

    _make_move_button(root, "▲", Vector2(92,-250), Vector2(64,58), Vector2(0,1), Vector2(0,-1))
    _make_move_button(root, "▼", Vector2(92,-112), Vector2(64,58), Vector2(0,1), Vector2(0,1))
    _make_move_button(root, "◀", Vector2(20,-180), Vector2(64,58), Vector2(0,1), Vector2(-1,0))
    _make_move_button(root, "▶", Vector2(164,-180), Vector2(64,58), Vector2(0,1), Vector2(1,0))

    fight_bar = ProgressBar.new()
    fight_bar.position = Vector2(18,180)
    fight_bar.size = Vector2(280,22)
    fight_bar.max_value = 100
    fight_bar.value = 0
    root.add_child(fight_bar)
    tension_bar = ProgressBar.new()
    tension_bar.position = Vector2(18,210)
    tension_bar.size = Vector2(280,22)
    tension_bar.max_value = 100
    tension_bar.value = 18
    root.add_child(tension_bar)

    shop_panel = Panel.new()
    shop_panel.position = Vector2(350,90)
    shop_panel.size = Vector2(560,500)
    shop_panel.visible = false
    root.add_child(shop_panel)
    var shop_v := VBoxContainer.new()
    shop_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shop_v.add_theme_constant_override("separation", 8)
    shop_v.offset_left = 14
    shop_v.offset_top = 14
    shop_v.offset_right = -14
    shop_v.offset_bottom = -14
    shop_panel.add_child(shop_v)
    shop_text = Label.new()
    shop_text.text = "МАГАЗИН СНАРЯЖЕНИЯ"
    shop_text.add_theme_font_size_override("font_size", 22)
    shop_v.add_child(shop_text)
    var row := HBoxContainer.new()
    shop_v.add_child(row)
    for entry in [["Удочки","rods"],["Катушки","reels"],["Леска","lines"],["Крючки","hooks"],["Наживка","baits"]]:
        var b := Button.new()
        b.text = entry[0]
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(func(): _show_shop_kind(entry[1]))
        row.add_child(b)
    var list_scroll := ScrollContainer.new()
    list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shop_v.add_child(list_scroll)
    shop_items_container = VBoxContainer.new()
    shop_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_scroll.add_child(shop_items_container)
    var close := Button.new()
    close.text = "Закрыть"
    close.pressed.connect(func(): shop_panel.visible = false)
    shop_v.add_child(close)
    _show_shop_kind("rods")

    catch_log_panel = Panel.new()
    catch_log_panel.position = Vector2(360,130)
    catch_log_panel.size = Vector2(540,420)
    catch_log_panel.visible = false
    root.add_child(catch_log_panel)
    var log_v := VBoxContainer.new()
    log_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    log_v.offset_left = 14
    log_v.offset_top = 14
    log_v.offset_right = -14
    log_v.offset_bottom = -14
    catch_log_panel.add_child(log_v)
    catch_log_text = Label.new()
    catch_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
    catch_log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    log_v.add_child(catch_log_text)
    var log_close := Button.new()
    log_close.text = "Закрыть садок"
    log_close.pressed.connect(func(): catch_log_panel.visible = false)
    log_v.add_child(log_close)

func _label(parent: Control, text_value: String, pos: Vector2, size: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = pos
    label.size = size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(label)
    return label

func _button(parent: Control, caption: String, offset: Vector2, size: Vector2, anchor: Vector2, action: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.size = size
    button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    if anchor == Vector2(1,1):
        button.anchor_left = 1
        button.anchor_top = 1
        button.anchor_right = 1
        button.anchor_bottom = 1
    elif anchor == Vector2(0,1):
        button.anchor_top = 1
        button.anchor_bottom = 1
    button.position = offset
    button.pressed.connect(action)
    parent.add_child(button)
    return button

func _stop_moving() -> void:
    touch_dir = Vector2.ZERO

func _next_region() -> void:
    current_region = (current_region + 1) % 4
    var names := ["Озеро Тихое", "Скалистая бухта", "Карповый залив", "Лесная речка"]
    var colors := [Color(0.08,0.34,0.48), Color(0.10,0.27,0.39), Color(0.12,0.38,0.34), Color(0.10,0.42,0.38)]
    if lake_mesh:
        var lake_mat := StandardMaterial3D.new()
        lake_mat.albedo_color = colors[current_region]
        lake_mat.roughness = 0.18
        lake_mat.metallic = 0.15
        lake_mesh.material_override = lake_mat
    if region_objects.size() == 2:
        region_objects[0].visible = current_region == 1
        region_objects[1].visible = current_region == 2
    player.global_position = Vector3(0,1,5)
    _set_status("Локация: " + names[current_region] + ". Здесь отличаются виды и шансы поклёвки.")
    _refresh_ui()
    _save_game()

func _make_move_button(parent: Control, caption: String, offset: Vector2, size: Vector2, anchor: Vector2, direction: Vector2) -> void:
    var button := _button(parent, caption, offset, size, anchor, func(): touch_dir = direction)
    button.button_down.connect(func(): touch_dir = direction)
    button.button_up.connect(func(): touch_dir = Vector2.ZERO)

func _update_fishing_visuals() -> void:
    if not fishing_float or not fishing_line or not player:
        return
    var active := fishing_state in ["waiting", "bite", "fight"]
    fishing_float.visible = active
    fishing_line.visible = active
    if not active:
        return
    var target := player.global_position + Vector3(0.0, 0.12 + sin(game_clock * 2.6) * 0.035, -10.0)
    fishing_float.global_position = target
    line_immediate.clear_surfaces()
    line_immediate.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
    var rod_tip := player.global_position + Vector3(0.42, 2.25, -1.05)
    line_immediate.surface_add_vertex(rod_tip)
    line_immediate.surface_add_vertex(target)
    line_immediate.surface_end()

func _move_player(delta: float) -> void:
    if not player or shop_panel.visible:
        return
    var dir := Vector3.ZERO
    dir.x = touch_dir.x
    dir.z = touch_dir.y
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.z -= 1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.z += 1
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
    if dir.length() > 1: dir = dir.normalized()
    player.velocity.x = dir.x * 4.0
    player.velocity.z = dir.z * 4.0
    player.velocity.y = 0
    player.move_and_slide()
    if dir.length() > 0.1:
        player.rotation.y = atan2(dir.x, dir.z)

func _cast_line() -> void:
    if fishing_state != "idle":
        _set_status("Сначала закончи текущую рыбалку.")
        return
    if bait_stock[selected_bait] <= 0:
        _set_status("Эта наживка закончилась. Купи новую в магазине или выбери ту, что есть.")
        return
    bait_stock[selected_bait] -= 1
    fishing_state = "waiting"
    var weather_factor := 1.0
    if weather_index == 1: weather_factor = 0.92
    elif weather_index == 2: weather_factor = 0.78
    elif weather_index == 3: weather_factor = 1.12
    wait_time = randf_range(5.0, 18.0) * weather_factor
    cast_power = randf_range(0.65, 1.0)
    _set_status("Заброс! Поплавок на воде. Ждём поклёвку…")

func _update_fishing(delta: float) -> void:
    if fishing_state == "waiting":
        wait_time -= delta
        if wait_time <= 0:
            fishing_state = "bite"
            bite_window = randf_range(1.6, 3.2)
            _set_status("ПОКЛЁВКА! Быстро нажми «ПОДСЕЧЬ»!")
    elif fishing_state == "bite":
        bite_window -= delta
        if bite_window <= 0:
            fishing_state = "idle"
            _set_status("Рыба ушла. Попробуй снова или смени наживку.")
    elif fishing_state == "fight":
        fight_time += delta
        var fish_pull := fish_strength * randf_range(0.15, 0.9)
        if is_reeling:
            tension += delta * (0.20 + fish_pull * 0.13) / max(0.65, lines[selected_line].strength)
            fish_distance -= delta * (0.07 + rods[selected_rod].power * reels[selected_reel].power * 0.035) / max(0.7, fish_strength)
        else:
            tension -= delta * 0.23
            fish_distance += delta * fish_pull * 0.012
        if tension > 0.93:
            fishing_state = "idle"
            _set_status("Леска не выдержала натяжение! Ослабь фрикцион или поставь более прочную леску.")
            is_reeling = false
        elif tension < 0.10 and fight_time > 3.0:
            fish_distance += delta * 0.035
            if fish_distance >= 1.0:
                fishing_state = "idle"
                is_reeling = false
                _set_status("Слишком ослабил леску — рыба освободилась.")
        elif fish_distance <= 0.05:
            _land_fish()
        elif fight_time > 90:
            fishing_state = "idle"
            _set_status("Рыба устала, но сорвалась. Попробуй менять темп подмотки.")
            is_reeling = false
        tension = clamp(tension, 0.02, 1.0)
        fish_distance = clamp(fish_distance, 0.0, 1.0)

func _hook_fish() -> void:
    if fishing_state != "bite":
        _set_status("Подсекать нужно именно в момент поклёвки.")
        return
    var bait_bonus: float = baits[selected_bait].bonus
    var hook_quality: float = hooks[selected_hook].quality
    var odds: float= clampf(0.52 + (hook_quality - 1.0) * 0.28 + (bait_bonus - 1.0) * 0.24, 0.35, 0.94)
    if randf() > odds:
        fishing_state = "idle"
        _set_status("Неудачная подсечка. В следующий раз реагируй точнее.")
        return
    hooked_fish = _choose_fish()
    hooked_name = hooked_fish.name
    fish_weight = randf_range(hooked_fish.min, hooked_fish.max)
    fish_strength = hooked_fish.fight * (0.65 + fish_weight / max(1.0, hooked_fish.max) * 0.8)
    fight_time = 0
    tension = 0.28
    fish_distance = 1.0
    fishing_state = "fight"
    is_reeling = false
    _set_status("На крючке: " + hooked_name + "! Вес примерно " + str(snapped(fish_weight,0.01)) + " кг. Держи натяжение под контролем.")

func _choose_fish() -> Dictionary:
    var total := 0.0
    var weighted: Array[Dictionary] = []
    for fish in species:
        var weight: float = fish.rarity
        if current_region == 1 and fish.name in ["Щука","Судак","Окунь"]: weight *= 1.8
        if current_region == 2 and fish.name in ["Карп","Трофейный сом","Линь"]: weight *= 2.0
        if current_region == 3 and fish.name in ["Форель","Голавль","Язь"]: weight *= 2.2
        if weather_index == 2 and fish.name in ["Щука","Окунь","Судак"]: weight *= 1.35
        if weather_index == 0 and fish.name in ["Плотва","Карась"]: weight *= 1.2
        if weather_index == 3 and fish.name in ["Лещ","Карп"]: weight *= 0.8
        if selected_bait in fish.bait: weight *= baits[selected_bait].bonus
        total += weight
        weighted.append({"fish":fish,"weight":weight})
    var roll := randf() * total
    for item in weighted:
        roll -= item.weight
        if roll <= 0:
            return item.fish
    return species[0]

func _set_reeling() -> void:
    if fishing_state == "fight":
        is_reeling = not is_reeling
        _set_status("Вываживание: " + ("подматываешь леску" if is_reeling else "отпускаешь, чтобы снизить натяжение") + ".")
    else:
        _set_status("Сначала нужна поклёвка и успешная подсечка.")

func _land_fish() -> void:
    fishing_state = "idle"
    is_reeling = false
    var quality_bonus: float = hooks[selected_hook].quality
    var value := int(hooked_fish.base * pow(fish_weight, 0.82) * (0.8 + quality_bonus * 0.2))
    var size_text := _fish_size_class(fish_weight, float(hooked_fish.max))
    var record := {"name":hooked_name,"weight":fish_weight,"value":value,"size":size_text,"region":_region_name()}
    fish_bag.append(record)
    fish_count += 1
    _set_status("Поймано: " + size_text + " " + hooked_name + " — " + str(snapped(fish_weight,0.01)) + " кг! Цена у торговца: " + str(value) + " ₽.")
    _refresh_ui()
    _save_game()

func _fish_size_class(weight: float, species_max: float) -> String:
    var ratio := weight / maxf(0.1, species_max)
    if ratio >= 0.88:
        return "ТРОФЕЙ"
    if ratio >= 0.62:
        return "Крупная"
    if ratio >= 0.30:
        return "Средняя"
    return "Маленькая"

func _sell_fish() -> void:
    if fish_bag.is_empty():
        _set_status("В садке пока пусто. Сначала поймай рыбу.")
        return
    var total := 0
    for fish in fish_bag:
        total += int(fish.value)
    money += total
    var amount := fish_bag.size()
    fish_bag.clear()
    _set_status("Продано " + str(amount) + " рыб на " + str(total) + " ₽. Деньги зачислены!")
    _refresh_ui()
    _save_game()

func _open_shop() -> void:
    catch_log_panel.visible = false
    shop_panel.visible = true
    _show_shop_kind(shop_kind)

func _open_catch_log() -> void:
    shop_panel.visible = false
    catch_log_panel.visible = true
    if fish_bag.is_empty():
        catch_log_text.text = "САДОК ПУСТ\nПойманная рыба будет отображаться здесь."
        return
    var lines_text := ["МОЙ САДОК — " + str(fish_bag.size()) + " рыб", ""]
    for i in range(fish_bag.size()):
        var fish: Dictionary = fish_bag[i]
        lines_text.append(str(i+1) + ". " + str(fish.get("size","")) + " " + str(fish.get("name","Рыба")) + " — " + str(snapped(float(fish.get("weight",0.0)),0.01)) + " кг — " + str(fish.get("value",0)) + " ₽")
    lines_text.append("")
    lines_text.append("Кнопка «ПРОДАТЬ УЛОВ» продаст весь садок.")
    catch_log_text.text = "\n".join(lines_text)

func _show_shop_kind(kind: String) -> void:
    shop_kind = kind
    if not shop_text:
        return
    var data: Array = []
    match kind:
        "rods": data = rods
        "reels": data = reels
        "lines": data = lines
        "hooks": data = hooks
        "baits": data = baits
    var text_lines := ["МАГАЗИН — " + kind.to_upper(), "Баланс: " + str(money) + " ₽", ""]
    for i in range(data.size()):
        var item: Dictionary = data[i]
        var price := int(item.price)
        var owned := false
        match kind:
            "rods": owned = i <= selected_rod
            "reels": owned = i <= selected_reel
            "lines": owned = i <= selected_line
            "hooks": owned = i <= selected_hook
            "baits": owned = true
        if kind == "baits":
            text_lines.append(str(i+1) + ". " + item.name + " — " + str(bait_stock[i]) + " шт. | 10 шт. за " + str(price) + " ₽")
        else:
            text_lines.append(str(i+1) + ". " + item.name + " — " + ("КУПЛЕНО / доступно" if owned else str(price) + " ₽"))
    text_lines.append("")
    text_lines.append("Нажми на номер товара внизу, чтобы купить/выбрать.")
    shop_text.text = "\n".join(text_lines)
    for child in shop_items_container.get_children():
        child.queue_free()
    for i in range(data.size()):
        var item: Dictionary = data[i]
        var b := Button.new()
        b.name = "Item" + str(i)
        if kind == "baits":
            b.text = str(i+1) + ". Купить 10 × " + item.name + " — " + str(item.price) + " ₽"
        else:
            b.text = str(i+1) + ". " + item.name + " — " + str(item.price) + " ₽"
        b.custom_minimum_size = Vector2(0, 46)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(func(): _buy_or_select(kind, i))
        shop_items_container.add_child(b)

func _buy_or_select(kind: String, index: int) -> void:
    var data: Array = []
    var current := 0
    match kind:
        "rods": data = rods; current = selected_rod
        "reels": data = reels; current = selected_reel
        "lines": data = lines; current = selected_line
        "hooks": data = hooks; current = selected_hook
        "baits": data = baits; current = selected_bait
    var item: Dictionary = data[index]
    var price := int(item.price)
    if kind == "baits":
        if money < price:
            _set_status("Не хватает денег на наживку.")
            return
        money -= price
        bait_stock[index] += 10
        selected_bait = index
        _set_status("Куплено 10 шт. наживки: " + item.name)
    elif index <= current:
        match kind:
            "rods": selected_rod = index
            "reels": selected_reel = index
            "lines": selected_line = index
            "hooks": selected_hook = index
        _set_status("Выбрано: " + item.name)
    else:
        if money < price:
            _set_status("Не хватает денег. Продай улов и возвращайся!")
            return
        money -= price
        match kind:
            "rods": selected_rod = index
            "reels": selected_reel = index
            "lines": selected_line = index
            "hooks": selected_hook = index
        _set_status("Куплено и установлено: " + item.name)
    _refresh_ui()
    _save_game()
    _show_shop_kind(kind)

func _next_bait() -> void:
    for step in range(1, baits.size() + 1):
        var candidate := (selected_bait + step) % baits.size()
        if bait_stock[candidate] > 0:
            selected_bait = candidate
            _set_status("Выбрана наживка: " + baits[selected_bait].name + ". Осталось: " + str(bait_stock[selected_bait]) + " шт.")
            _refresh_ui()
            _save_game()
            return
    _set_status("Наживка закончилась. Загляни в магазин.")

func _toggle_camera() -> void:
    camera_third = not camera_third
    _set_status("Камера: " + ("от третьего лица" if camera_third else "от первого лица"))

func _region_name() -> String:
    return ["Озеро Тихое","Скалистая бухта","Карповый залив","Лесная речка"][current_region]

func _refresh_ui() -> void:
    if money_label:
        money_label.text = "₽ " + str(money)
    if inventory_label:
        inventory_label.text = "Садок: " + str(fish_bag.size()) + " рыб | Удочка: " + rods[selected_rod].name + "\nНаживка: " + baits[selected_bait].name + " (" + str(bait_stock[selected_bait]) + ") | Локация: " + _region_name()
        if weather_label:
            weather_label.text = "Погода: " + weather_name

func _update_bars() -> void:
    if fight_bar:
        fight_bar.value = (1.0 - fish_distance) * 100.0 if fishing_state == "fight" else 0
    if tension_bar:
        tension_bar.value = tension * 100.0 if fishing_state == "fight" else 18

func _set_status(message: String) -> void:
    if status_label:
        status_label.text = message

func _save_game() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("player","money",money)
    cfg.set_value("player","selected_rod",selected_rod)
    cfg.set_value("player","selected_reel",selected_reel)
    cfg.set_value("player","selected_line",selected_line)
    cfg.set_value("player","selected_hook",selected_hook)
    cfg.set_value("player","selected_bait",selected_bait)
    cfg.set_value("player","bait_stock",bait_stock)
    cfg.set_value("player","current_region",current_region)
    cfg.set_value("player","weather_index",weather_index)
    cfg.set_value("player","fish_bag",fish_bag)
    cfg.set_value("player","fish_count",fish_count)
    cfg.save(SAVE_PATH)

func _load_game() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    money = int(cfg.get_value("player","money",money))
    selected_rod = clampi(int(cfg.get_value("player","selected_rod",0)),0,rods.size()-1)
    selected_reel = clampi(int(cfg.get_value("player","selected_reel",0)),0,reels.size()-1)
    selected_line = clampi(int(cfg.get_value("player","selected_line",0)),0,lines.size()-1)
    selected_hook = clampi(int(cfg.get_value("player","selected_hook",0)),0,hooks.size()-1)
    selected_bait = clampi(int(cfg.get_value("player","selected_bait",0)),0,baits.size()-1)
    current_region = clampi(int(cfg.get_value("player","current_region",0)),0,3)
    weather_index = clampi(int(cfg.get_value("player","weather_index",0)),0,3)
    var loaded_stock: Array = cfg.get_value("player","bait_stock",[15,0,0,0])
    for i in range(min(loaded_stock.size(), bait_stock.size())):
        bait_stock[i] = max(0, int(loaded_stock[i]))
    fish_bag = cfg.get_value("player","fish_bag",[])
    fish_count = int(cfg.get_value("player","fish_count",0))

func _setup_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = player_position
	add_child(player)

	var camera_pivot := Node3D.new()
	camera_pivot.name = "CameraPivot"
	player.add_child(camera_pivot)

	var camera := Camera3D.new()
	camera.name = "MainCamera"
	camera.position = Vector3(0, 2.5, camera_distance)
	camera.look_at(Vector3.ZERO)
	camera_pivot.add_child(camera)

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "GameUI"
	add_child(canvas)

	var background := ColorRect.new()
	background.color = Color(0.02, 0.05, 0.08, 0.45)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)

	var main := VBoxContainer.new()
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.position = Vector2(20, 20)
	main.custom_minimum_size = Vector2(300, 160)
	canvas.add_child(main)

	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 24)
	main.add_child(money_label)

	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 18)
	main.add_child(hud_label)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.text = "Добро пожаловать на рыбалку!"
	main.add_child(status_label)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 10)
	buttons.add_theme_constant_override("v_separation", 10)
	buttons.position = Vector2(20, 220)
	buttons.custom_minimum_size = Vector2(320, 300)
	canvas.add_child(buttons)

	_add_button(buttons, "Забросить", _cast_line)
	_add_button(buttons, "Подсечь", _hook_fish)
	_add_button(buttons, "Подмотать", _reel_fish)
	_add_button(buttons, "Камера", _change_camera)
	_add_button(buttons, "Магазин", _open_shop)
	_add_button(buttons, "Продать улов", _sell_fish)
	_add_button(buttons, "Садок", _open_keepnet)
	_add_button(buttons, "Журнал", _open_fish_journal)
	_add_button(buttons, "Эхолот", _use_sonar)
	_add_button(buttons, "Погода", _change_weather)
	_add_button(buttons, "Локация", _change_region)
	_add_button(buttons, "Сохранить", _save_game)

	var hint := Label.new()
	hint.text = "Проводи пальцем по экрану, чтобы вращать камеру"
	hint.position = Vector2(20, 580)
	hint.add_theme_font_size_override("font_size", 16)
	canvas.add_child(hint)

func _add_button(parent: Control, text_value: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(145, 55)
	button.add_theme_font_size_override("font_size", 17)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.22, 0.30, 0.95)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(2)
	normal.border_color = Color(0.2, 0.65, 0.75)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.38, 0.48, 1.0)
	hover.set_corner_radius_all(12)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(callback)
	parent.add_child(button)

func _update_player(delta: float) -> void:
	pass

func _update_camera() -> void:
	var player := get_node_or_null("Player")
	if player == null:
		return

	var pivot := player.get_node_or_null("CameraPivot")
	if pivot == null:
		return

	pivot.rotation.y = camera_rotation.x
	pivot.rotation.x = camera_rotation.y

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		camera_rotation.x -= event.relative.x * 0.004
		camera_rotation.y -= event.relative.y * 0.004
		camera_rotation.y = clampf(camera_rotation.y, -0.8, 0.8)

func _update_fishing(delta: float) -> void:
	if is_waiting:
		bite_timer -= delta
		if bite_timer <= 0.0:
			is_waiting = false
			fish_biting = true
			status_label.text = "ПОКЛЁВКА! Нажми «Подсечь»!"

	if fish_fighting:
		fight_timer -= delta
		if fight_timer <= 0.0:
			_finish_fight()

func _cast_line() -> void:
	if is_casting or is_waiting or fish_fighting:
		status_label.text = "Сначала закончи текущую рыбалку"
		return

	is_casting = true
	is_waiting = true
	fish_biting = false
	bite_timer = randf_range(5.0, 14.0)
	status_label.text = "Поплавок на воде. Ждём поклёвку..."

func _hook_fish() -> void:
	if not fish_biting:
		status_label.text = "Пока нет поклёвки"
		return

	fish_biting = false
	is_casting = false
	is_waiting = false
	fish_fighting = true
	fight_timer = randf_range(3.0, 8.0)

	var fish: Dictionary = fish_species.pick_random()
	caught_fish_name = str(fish["name"])
	caught_fish_weight = randf_range(0.2, float(fish["weight"]) * 1.8)
	caught_fish_length = caught_fish_weight * randf_range(2.0, 4.0)

	status_label.text = "На крючке: " + caught_fish_name + "! Вываживай!"

func _reel_fish() -> void:
	if fish_fighting:
		fight_timer -= 2.0
		status_label.text = "Подматываем леску..."

func _finish_fight() -> void:
	fish_fighting = false
	is_casting = false

	var record := {
		"name": caught_fish_name,
		"weight": caught_fish_weight,
		"length": caught_fish_length,
		"date": Time.get_datetime_string_from_system()
	}

	fish_bag.append(record)
	status_label.text = "Пойман " + caught_fish_name + "! Он в садке."
	_update_hud()
	_save_game()

func _change_camera() -> void:
	current_camera = 1 - current_camera
	var camera := get_node_or_null("Player/CameraPivot/MainCamera") as Camera3D
	if camera != null:
		camera.position = Vector3(0, 1.7, 0) if current_camera == 1 else Vector3(0, 2.5, camera_distance)
		camera.look_at(Vector3(0, 0, -1))
	status_label.text = "Режим камеры изменён"

func _change_weather() -> void:
	current_weather = weather_types.pick_random()
	status_label.text = "Погода: " + current_weather
	_update_hud()

func _change_region() -> void:
	current_region = (current_region + 1) % regions.size()
	status_label.text = "Локация: " + regions[current_region]
	_update_hud()

func _use_sonar() -> void:
	status_label.text = "Эхолот: рыба обнаруживается под водой"

func _open_shop() -> void:
	var panel := _show_message_panel("МАГАЗИН")
	_add_panel_label(panel, "Удочки, леска, наживки и снасти")
	_add_panel_button(panel, "Купить наживку — 30 ₽", func():
		if money >= 30:
			money -= 30
			inventory.append({"name": "Наживка", "count": 1})
			status_label.text = "Наживка куплена"
		else:
			status_label.text = "Недостаточно денег"
		_update_hud()
	)
	_add_panel_button(panel, "Закрыть", func(): panel.queue_free())

func _open_keepnet() -> void:
	_show_catch_log(false)

func _open_fish_journal() -> void:
	_show_catch_log(true)

func _show_catch_log(show_journal: bool) -> void:
	var panel := _show_message_panel("ЖУРНАЛ РЫБАЛКИ" if show_journal else "САДОК")

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 280)
	panel.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var fish_list: Array[Dictionary] = fish_journal if show_journal else fish_bag

	if fish_list.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Пока здесь пусто"
		list.add_child(empty_label)

	for i in range(fish_list.size()):
		var fish: Dictionary = fish_list[i]
		var row := HBoxContainer.new()
		list.add_child(row)

		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = "%s — %.2f кг — %.1f см" % [
			str(fish.get("name", "Рыба")),
			float(fish.get("weight", 0.0)),
			float(fish.get("length", 0.0))
		]
		row.add_child(info)

		if not show_journal:
			var save_button := Button.new()
			save_button.text = "В журнал"
			save_button.pressed.connect(_add_to_journal.bind(i, panel))
			row.add_child(save_button)

	if not show_journal:
		var sell_button := Button.new()
		sell_button.text = "Продать весь садок"
		sell_button.pressed.connect(func():
			_sell_fish()
			panel.queue_free()
		)
		panel.add_child(sell_button)

	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.pressed.connect(func(): panel.queue_free())
	panel.add_child(close_button)

func _add_to_journal(index: int, panel: Control) -> void:
	if index < 0 or index >= fish_bag.size():
		return

	var fish: Dictionary = fish_bag[index]
	fish_journal.append(fish.duplicate(true))
	fish_bag.remove_at(index)

	status_label.text = "Трофей сохранён в журнале. Продать его нельзя."
	_update_hud()
	_save_game()
	panel.queue_free()
	_open_fish_journal()

func _sell_fish() -> void:
	if fish_bag.is_empty():
		status_label.text = "Садок пуст"
		return

	var total := 0
	for fish in fish_bag:
		var fish_name := str(fish.get("name", ""))
		for species in fish_species:
			if str(species["name"]) == fish_name:
				total += int(float(species["price"]) * float(fish.get("weight", 1.0)))
				break

	money += total
	fish_bag.clear()
	status_label.text = "Улов продан за %d ₽" % total
	_update_hud()
	_save_game()

func _show_message_panel(title_text: String) -> Panel:
	var canvas := get_node_or_null("GameUI") as CanvasLayer
	var panel := Panel.new()
	panel.name = "PopupPanel"
	panel.custom_minimum_size = Vector2(450, 350)
	panel.position = Vector2(250, 80)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.07, 0.11, 0.98)
	style.set_corner_radius_all(18)
	style.set_border_width_all(2)
	style.border_color = Color(0.15, 0.65, 0.8)
	panel.add_theme_stylebox_override("panel", style)

	if canvas != null:
		canvas.add_child(panel)

	var content := VBoxContainer.new()
	content.position = Vector2(16, 12)
	content.size = Vector2(410, 320)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 24)
	content.add_child(heading)

	return panel

func _add_panel_label(panel: Panel, text_value: String) -> void:
	var content := panel.get_child(0) as VBoxContainer
	if content == null:
		return

	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 18)
	content.add_child(label)

func _add_panel_button(panel: Panel, text_value: String, callback: Callable) -> void:
	var content := panel.get_child(0) as VBoxContainer
	if content == null:
		return

	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(200, 48)
	button.pressed.connect(callback)
	content.add_child(button)

func _update_hud() -> void:
	if money_label != null:
		money_label.text = "Деньги: %d ₽" % money

	if hud_label != null:
		hud_label.text = "Локация: %s | Погода: %s\nСадок: %d | Трофеи: %d" % [
			regions[current_region],
			current_weather,
			fish_bag.size(),
			fish_journal.size()
		]

func _save_game() -> void:
	var config := ConfigFile.new()

	config.set_value("player", "money", money)
	config.set_value("player", "region", current_region)
	config.set_value("player", "weather", current_weather)

	config.set_value("fish", "keepnet", fish_bag)
	config.set_value("fish", "journal", fish_journal)
	config.set_value("inventory", "items", inventory)

	var error := config.save(SAVE_PATH)
	if error == OK:
		status_label.text = "Игра сохранена"
	else:
		status_label.text = "Ошибка сохранения"

func _load_game() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error != OK:
		return

	money = int(config.get_value("player", "money", 350))
	current_region = int(config.get_value("player", "region", 0))
	current_region = clampi(current_region, 0, regions.size() - 1)

	current_weather = str(config.get_value("player", "weather", "Солнечно"))

	fish_bag.clear()
	fish_journal.clear()
	inventory.clear()

	var saved_keepnet = config.get_value("fish", "keepnet", [])
	var saved_journal = config.get_value("fish", "journal", [])
	var saved_inventory = config.get_value("inventory", "items", [])

	for fish in saved_keepnet:
		if fish is Dictionary:
			fish_bag.append(fish)

	for fish in saved_journal:
		if fish is Dictionary:
			fish_journal.append(fish)

	for item in saved_inventory:
		if item is Dictionary:
			inventory.append(item)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
		get_tree().quit()
