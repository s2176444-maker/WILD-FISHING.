
extends Node3D

# РЫБАЛКА С СЕМЁНОМ
# Godot 4.3 — одиночная 3D-игра

const SAVE_PATH = "user://sem_yon_fishing.cfg"

var money: int = 500
var keepnet: Array[Dictionary] = []
var journal: Array[Dictionary] = []

var fishing_state: String = "idle"
var bite_timer: float = 0.0
var camera_first_person: bool = false
var camera_yaw: float = 0.0
var camera_pitch: float = -0.12
var camera_dragging: bool = false
var last_touch: Vector2 = Vector2.ZERO
var move_direction: Vector2 = Vector2.ZERO

var player: Node3D
var camera: Camera3D
var rod: MeshInstance3D
var float_object: MeshInstance3D

var hud_label: Label
var status_label: Label
var money_label: Label
var popup_panel: PanelContainer
var popup_content: VBoxContainer

var fish_names = [
    "Карась",
    "Карп",
    "Щука",
    "Окунь",
    "Лещ",
    "Плотва",
    "Сом",
    "Линь",
    "Язь",
    "Судак"
]

var fish_prices = [80, 180, 350, 100, 140, 60, 600, 220, 170, 400]

var fish_colors = [
    Color("c9a46b"),
    Color("d4a35c"),
    Color("779b65"),
    Color("b77b43"),
    Color("a9a9a0"),
    Color("c1a875"),
    Color("454d54"),
    Color("7d8d62"),
    Color("b58c60"),
    Color("9b9b85")
]

var equipment_level: int = 1
var weather: String = "Солнечно"
var day_time: float = 12.0


func _ready():
    randomize()
    _build_world()
    _build_player()
    _build_ui()
    _load_game()
    _update_hud()
    _set_status("Добро пожаловать на рыбалку!")


func _process(delta):
    day_time += delta * 0.025
    if day_time >= 24.0:
        day_time = 0.0

    _update_sky()

    if fishing_state == "waiting":
        bite_timer -= delta
        if bite_timer <= 0.0:
            fishing_state = "bite"
            _set_status("ПОКЛЁВКА! Нажми «Подсечь»!")

    if player != null:
        var forward = -player.global_transform.basis.z
        var right = player.global_transform.basis.x
        var movement = right * move_direction.x + forward * move_direction.y
        if movement.length() > 0.01:
            player.position += movement.normalized() * 3.0 * delta


func _build_world():
    var environment = WorldEnvironment.new()
    var env = Environment.new()
    env.background_mode = Environment.BG_SKY

    var sky = Sky.new()
    var sky_material = ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("3675ad")
    sky_material.sky_horizon_color = Color("b5d8e8")
    sky_material.ground_bottom_color = Color("354b35")
    sky_material.ground_horizon_color = Color("849b7c")
    sky.sky_material = sky_material

    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("b9cce0")
    env.ambient_light_energy = 0.8
    environment.environment = env
    add_child(environment)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -35, 0)
    sun.light_energy = 1.4
    sun.shadow_enabled = true
    add_child(sun)

    _add_box(
        Vector3(100, 1, 100),
        Vector3(0, -1.0, 0),
        Color("567747")
    )

    _add_box(
        Vector3(100, 0.5, 65),
        Vector3(0, -0.45, -25),
        Color("347fa0")
    )

    _add_box(
        Vector3(100, 0.5, 30),
        Vector3(0, -0.45, 45),
        Color("c2ae7b")
    )

    # Берег
    _add_box(
        Vector3(100, 0.25, 8),
        Vector3(0, -0.2, 8),
        Color("bca477")
    )

    # Деревянный причал
    for i in range(8):
        _add_box(
            Vector3(1.1, 0.25, 1.2),
            Vector3(0, 0.1, -3 + i * 1.2),
            Color("795333")
        )

    for x in [-1.2, 1.2]:
        _add_box(
            Vector3(0.18, 1.2, 0.18),
            Vector3(x, -0.4, -2.5),
            Color("593d28")
        )

    # Камни
    for i in range(18):
        var rock = MeshInstance3D.new()
        var mesh = SphereMesh.new()
        mesh.radius = randf_range(0.25, 0.65)
        mesh.height = mesh.radius * 1.4
        rock.mesh = mesh
        rock.position = Vector3(
            randf_range(-35, 35),
            -0.15,
            randf_range(8, 35)
        )
        rock.scale = Vector3(1.2, 0.65, 1.0)

        var material = StandardMaterial3D.new()
        material.albedo_color = Color("77796d")
        rock.material_override = material
        add_child(rock)

    # Деревья
    for i in range(35):
        var x = randf_range(-45, 45)
        var z = randf_range(12, 45)
        if abs(x) < 5.0:
            continue
        _make_tree(Vector3(x, 0, z))

    # Домик рыбака
    _add_box(
        Vector3(5, 3, 4),
        Vector3(10, 1.5, 12),
        Color("8b6746")
    )
    _add_box(
        Vector3(5.8, 0.5, 4.8),
        Vector3(10, 3.3, 12),
        Color("573c32")
    )


func _add_box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
    var obj = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    obj.mesh = mesh
    obj.position = pos

    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    obj.material_override = material

    add_child(obj)
    return obj


func _make_tree(pos: Vector3):
    var trunk = MeshInstance3D.new()
    var trunk_mesh = CylinderMesh.new()
    trunk_mesh.top_radius = 0.15
    trunk_mesh.bottom_radius = 0.3
    trunk_mesh.height = 3.0
    trunk.mesh = trunk_mesh
    trunk.position = pos + Vector3(0, 1.5, 0)

    var trunk_mat = StandardMaterial3D.new()
    trunk_mat.albedo_color = Color("62442d")
    trunk.material_override = trunk_mat
    add_child(trunk)

    var leaves = MeshInstance3D.new()
    var leaves_mesh = SphereMesh.new()
    leaves_mesh.radius = 1.6
    leaves_mesh.height = 3.2
    leaves.mesh = leaves_mesh
    leaves.position = pos + Vector3(0, 3.5, 0)

    var leaf_mat = StandardMaterial3D.new()
    leaf_mat.albedo_color = Color(
        randf_range(0.08, 0.18),
        randf_range(0.25, 0.42),
        0.12
    )
    leaves.material_override = leaf_mat
    add_child(leaves)


func _build_player():
    player = Node3D.new()
    player.position = Vector3(0, 0, 5)
    add_child(player)

    var body = MeshInstance3D.new()
    var body_mesh = CapsuleMesh.new()
    body_mesh.radius = 0.35
    body_mesh.height = 1.7
    body.mesh = body_mesh
    body.position.y = 0.85

    var body_mat = StandardMaterial3D.new()
    body_mat.albedo_color = Color("344d70")
    body.material_override = body_mat
    player.add_child(body)

    camera = Camera3D.new()
    camera.position = Vector3(0, 1.6, 4.5)
    camera.current = true
    player.add_child(camera)

    rod = MeshInstance3D.new()
    var rod_mesh = CylinderMesh.new()
    rod_mesh.top_radius = 0.025
    rod_mesh.bottom_radius = 0.055
    rod_mesh.height = 2.2
    rod.mesh = rod_mesh
    rod.position = Vector3(0.55, 1.0, -0.8)
    rod.rotation_degrees.x = -35

    var rod_mat = StandardMaterial3D.new()
    rod_mat.albedo_color = Color("493321")
    rod.material_override = rod_mat
    camera.add_child(rod)

    float_object = MeshInstance3D.new()
    var float_mesh = SphereMesh.new()
    float_mesh.radius = 0.12
    float_mesh.height = 0.24
    float_object.mesh = float_mesh
    float_object.position = Vector3(0, -0.4, -5)

    var float_mat = StandardMaterial3D.new()
    float_mat.albedo_color = Color("f04430")
    float_object.material_override = float_mat
    add_child(float_object)

    _update_camera()


func _build_ui():
    var layer = CanvasLayer.new()
    add_child(layer)

    var root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)

    # Верхняя панель
    var top = PanelContainer.new()
    top.position = Vector2(12, 12)
    top.size = Vector2(260, 100)
    root.add_child(top)

    var top_box = VBoxContainer.new()
    top.add_child(top_box)

    var title = Label.new()
    title.text = "🎣 РЫБАЛКА С СЕМЁНОМ"
    title.add_theme_font_size_override("font_size", 19)
    top_box.add_child(title)

    money_label = Label.new()
    top_box.add_child(money_label)

    hud_label = Label.new()
    top_box.add_child(hud_label)

    status_label = Label.new()
    status_label.position = Vector2(0, 115)
    status_label.size = Vector2(350, 55)
    root.add_child(status_label)

    # Правая панель управления
    var right = VBoxContainer.new()
    right.position = Vector2(-170, 125)
    right.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
    right.add_theme_constant_override("separation", 8)
    root.add_child(right)

    _make_button(right, "🎣 Забросить", _cast_line)
    _make_button(right, "⚡ Подсечь", _hook_fish)
    _make_button(right, "🛒 Магазин", _open_shop)
    _make_button(right, "🎒 Садок", _open_keepnet)
    _make_button(right, "🏆 Журнал", _open_journal)
    _make_button(right, "💰 Продать рыбу", _sell_fish)
    _make_button(right, "🎥 Камера", _change_camera)
    _make_button(right, "🌦 Погода", _change_weather)

    # Левая панель движения
    var movement = VBoxContainer.new()
    movement.position = Vector2(20, -155)
    movement.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    movement.add_theme_constant_override("separation", 5)
    root.add_child(movement)

    var up = _make_button(movement, "▲", func(): move_direction.y = 1.0)
    up.button_up.connect(func(): move_direction.y = 0.0)

    var middle = HBoxContainer.new()
    movement.add_child(middle)

    var left = _make_button(middle, "◀", func(): move_direction.x = -1.0)
    left.button_up.connect(func(): move_direction.x = 0.0)

    var stop = _make_button(middle, "●", func(): move_direction = Vector2.ZERO)

    var right_button = _make_button(middle, "▶", func(): move_direction.x = 1.0)
    right_button.button_up.connect(func(): move_direction.x = 0.0)

    var down = _make_button(movement, "▼", func(): move_direction.y = -1.0)
    down.button_up.connect(func(): move_direction.y = 0.0)

    # Окно меню
    popup_panel = PanelContainer.new()
    popup_panel.set_anchors_preset(Control.PRESET_CENTER)
    popup_panel.position = Vector2(-190, -190)
    popup_panel.size = Vector2(380, 380)
    popup_panel.visible = false
    root.add_child(popup_panel)

    popup_content = VBoxContainer.new()
    popup_panel.add_child(popup_content)


func _make_button(parent: Node, text_value: String, callback: Callable) -> Button:
    var button = Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(145, 48)
    button.add_theme_font_size_override("font_size", 16)

    var normal = StyleBoxFlat.new()
    normal.bg_color = Color("244b60")
    normal.corner_radius_top_left = 12
    normal.corner_radius_top_right = 12
    normal.corner_radius_bottom_left = 12
    normal.corner_radius_bottom_right = 12
    normal.content_margin_left = 8
    normal.content_margin_right = 8
    button.add_theme_stylebox_override("normal", normal)

    var hover = StyleBoxFlat.new()
    hover.bg_color = Color("347a91")
    hover.corner_radius_top_left = 12
    hover.corner_radius_top_right = 12
    hover.corner_radius_bottom_left = 12
    hover.corner_radius_bottom_right = 12
    button.add_theme_stylebox_override("hover", hover)

    button.pressed.connect(callback)
    parent.add_child(button)
    return button


func _cast_line():
    if fishing_state != "idle":
        _set_status("Сначала закончи предыдущую рыбалку!")
        return

    fishing_state = "waiting"
    bite_timer = randf_range(5.0, 12.0)
    float_object.visible = true
    float_object.position = Vector3(
        randf_range(-2.0, 2.0),
        -0.2,
        -12
    )
    _set_status("Заброс! Ждём поклёвку...")


func _hook_fish():
    if fishing_state == "waiting":
        _set_status("Пока нет поклёвки. Подожди!")
        return

    if fishing_state == "bite":
        fishing_state = "idle"
        _catch_fish()
        return

    _set_status("Сначала забрось удочку!")


func _catch_fish():
    var index = randi_range(0, fish_names.size() - 1)
    var size = snapped(randf_range(0.3, 8.0) * equipment_level, 0.1)

    var fish = {
        "name": fish_names[index],
        "size": size,
        "price": int(fish_prices[index] * size / 1.5),
        "index": index
    }

    keepnet.append(fish)

    float_object.visible = false
    _update_hud()
    _save_game()

    _set_status(
        "Поймана рыба: %s, %.1f кг!" % [
            fish.name,
            fish.size
        ]
    )


func _open_keepnet():
    _show_popup("🎒 МОЙ САДОК")

    if keepnet.is_empty():
        _add_popup_label("Садок пока пуст.")
    else:
        for i in range(keepnet.size()):
            var fish = keepnet[i]
            var fish_index = i
            var line = "%s — %.1f кг" % [
                fish.name,
                fish.size
            ]

            _add_popup_label(line)

            var button = Button.new()
            button.text = "🏆 Перенести в журнал"
            button.pressed.connect(
                func(): _move_to_journal(fish_index)
            )
            popup_content.add_child(button)

    _add_popup_button("Закрыть", _close_popup)


func _move_to_journal(index: int):
    if index < 0 or index >= keepnet.size():
        return

    var fish = keepnet[index]
    journal.append(fish.duplicate(true))
    keepnet.remove_at(index)

    _save_game()
    _open_keepnet()
    _update_hud()
    _set_status("Рыба добавлена в журнал трофеев!")


func _open_journal():
    _show_popup("🏆 ЖУРНАЛ ТРОФЕЕВ")

    if journal.is_empty():
        _add_popup_label("Пока нет сохранённых трофеев.")
    else:
        for fish in journal:
            _add_popup_label(
                "%s — %.1f кг (НЕ ПРОДАЁТСЯ)" % [
                    fish.name,
                    fish.size
                ]
            )

    _add_popup_button("Закрыть", _close_popup)


func _sell_fish():
    if keepnet.is_empty():
        _set_status("В садке нет рыбы для продажи.")
        return

    var total = 0

    for fish in keepnet:
        total += int(fish.price)

    money += total
    keepnet.clear()

    _save_game()
    _update_hud()
    _set_status("Продано рыбы на %d монет!" % total)


func _open_shop():
    _show_popup("🛒 МАГАЗИН СНАРЯЖЕНИЯ")

    _add_popup_label("Уровень снастей: %d" % equipment_level)
    _add_popup_label("Деньги: %d монет" % money)

    var price = equipment_level * 400

    _add_popup_button(
        "Улучшить снасти — %d монет" % price,
        _buy_equipment
    )

    _add_popup_button("Закрыть", _close_popup)


func _buy_equipment():
    var price = equipment_level * 400

    if money < price:
        _set_status("Недостаточно денег!")
        return

    money -= price
    equipment_level += 1

    _save_game()
    _update_hud()
    _open_shop()
    _set_status("Снасти улучшены!")


func _show_popup(title_text: String):
    popup_panel.visible = true

    for child in popup_content.get_children():
        child.queue_free()

    var title = Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 21)
    popup_content.add_child(title)


func _add_popup_label(text_value: String):
    var label = Label.new()
    label.text = text_value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    popup_content.add_child(label)


func _add_popup_button(text_value: String, callback: Callable):
    var button = Button.new()
    button.text = text_value
    button.custom_minimum_size.y = 42
    button.pressed.connect(callback)
    popup_content.add_child(button)


func _close_popup():
    popup_panel.visible = false


func _change_camera():
    camera_first_person = not camera_first_person

    if camera_first_person:
        camera.position = Vector3(0, 1.6, 0)
        _set_status("Вид от первого лица")
    else:
        camera.position = Vector3(0, 1.6, 4.5)
        _set_status("Вид от третьего лица")

    _update_camera()


func _update_camera():
    if player == null or camera == null:
        return

    player.rotation.y = camera_yaw
    camera.rotation.x = camera_pitch


func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            last_touch = event.position
            camera_dragging = true
        else:
            camera_dragging = false

    elif event is InputEventScreenDrag:
        if camera_dragging and popup_panel != null and not popup_panel.visible:
            var difference = event.position - last_touch
            camera_yaw -= difference.x * 0.005
            camera_pitch -= difference.y * 0.004
            camera_pitch = clamp(camera_pitch, -1.0, 0.7)
            last_touch = event.position
            _update_camera()

    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            camera_dragging = event.pressed
            last_touch = event.position

    elif event is InputEventMouseMotion:
        if camera_dragging and popup_panel != null and not popup_panel.visible:
            var difference = event.position - last_touch
            camera_yaw -= difference.x * 0.005
            camera_pitch -= difference.y * 0.004
            camera_pitch = clamp(camera_pitch, -1.0, 0.7)
            last_touch = event.position
            _update_camera()


func _change_weather():
    if weather == "Солнечно":
        weather = "Облачно"
    elif weather == "Облачно":
        weather = "Дождь"
    else:
        weather = "Солнечно"

    _set_status("Погода: " + weather)
    _save_game()
    _update_hud()


func _update_sky():
    if not is_instance_valid(get_node_or_null("WorldEnvironment")):
        return


func _update_hud():
    if money_label != null:
        money_label.text = "💰 Деньги: %d" % money

    if hud_label != null:
        hud_label.text = "🎒 Садок: %d | 🏆 Трофеи: %d" % [
            keepnet.size(),
            journal.size()
        ]


func _set_status(message: String):
    if status_label != null:
        status_label.text = message


func _save_game():
    var config = ConfigFile.new()

    config.set_value("player", "money", money)
    config.set_value("player", "equipment_level", equipment_level)
    config.set_value("player", "keepnet", keepnet)
    config.set_value("player", "journal", journal)
    config.set_value("world", "weather", weather)

    config.save(SAVE_PATH)


func _load_game():
    var config = ConfigFile.new()

    if config.load(SAVE_PATH) != OK:
        return

    money = int(config.get_value("player", "money", 500))
    equipment_level = int(
        config.get_value("player", "equipment_level", 1)
    )

    keepnet = config.get_value("player", "keepnet", [])
    journal = config.get_value("player", "journal", [])
    weather = config.get_value("world", "weather", "Солнечно")
