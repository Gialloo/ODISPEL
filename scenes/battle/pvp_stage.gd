class_name PvpStage
extends BattleStage

# Palco del PvP: lo stesso della battaglia contro il boss (sfondo, ombre, anelli, targhette, scatti e colpi), ma con due
# squadre di operatori che si guardano: la tua (e gli alleati) a sinistra, gli avversari a destra.

var side_left: Array = []       # id dei giocatori a sinistra (tu per primo)
var side_right: Array = []


func set_state(new_state: Dictionary) -> void:
	state = new_state
	if not state.is_empty() and _bg_boss != "pvp":
		_bg_boss = "pvp"
		_bg_layers = ArtLibrary.background_layers("")
		if _bg_static != null:
			_bg_static.visible = _bg_layers.is_empty() and static_background
	_split_sides()
	_layout()


func _split_sides() -> void:
	side_left = []
	side_right = []
	if state.is_empty():
		return
	var mine: Dictionary = BattleState.player(state, local_player_id)
	var team: String = str(mine.get("team", ""))
	for p in state["players"]:
		if str(p["id"]) == local_player_id:
			side_left.push_front(str(p["id"]))
		elif team != "" and str(p["team"]) == team:
			side_left.append(str(p["id"]))
		else:
			side_right.append(str(p["id"]))
	if side_left.is_empty() and not side_right.is_empty():
		side_left.append(side_right.pop_front())     # spettatore: uno per lato


func pose_of(pid: String) -> Vector3:
	var i: int = side_left.find(pid)
	if i >= 0:
		return Vector3(215.0 + float(i) * _spacing(side_left.size()), 494.0 - party_lift, 0.82)
	var j: int = side_right.find(pid)
	return Vector3(1065.0 - float(maxi(0, j)) * _spacing(side_right.size()), 494.0 - party_lift, 0.82)


func _spacing(n: int) -> float:
	return minf(150.0, 560.0 / float(maxi(1, n)))


func party_pose(index: int, _count: int) -> Vector3:
	# usata dalla schermata per il ventaglio: il giocatore di sinistra numero `index`
	return pose_of(str(side_left[index])) if index < side_left.size() else Vector3(215.0, 494.0, 0.82)


func _layout() -> void:
	_positions.clear()
	if state.is_empty():
		return
	for p in state["players"]:
		var pose: Vector3 = pose_of(str(p["id"]))
		_positions[str(p["active"])] = _map(Vector2(pose.x, GEO_FLOOR - 120.0), pose.x, pose.z, pose.y)


func flash(uid: String) -> void:
	hit_flash[uid] = 1.0


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / DW, size.y / DH))
	if not static_background and _bg_layers.is_empty():
		_paint_procedural_background(self)
	_draw_background()
	_draw_motes()
	_flip_sprite = false
	_draw_team(side_left, false)
	_flip_sprite = true
	_draw_team(side_right, true)
	_flip_sprite = false
	_draw_markers()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_team(ids: Array, mirrored: bool) -> void:
	if state.is_empty():
		return
	var dir: float = -1.0 if mirrored else 1.0
	var n: int = ids.size()
	for k in n:
		var i: int = n - 1 - k
		var p: Dictionary = BattleState.player(state, str(ids[i]))
		if p.is_empty():
			continue
		var pose: Vector3 = pose_of(str(p["id"]))
		var u: Dictionary = BattleState.unit(state, str(p["active"]))
		if u.is_empty():
			continue
		var gx: float = pose.x
		_pose_sx = 1.0
		_pose_sy = 1.0
		_pose_rot = 0.0
		_pose_ghosts = 0.0
		if _anim_on and BattleState.is_alive(u):
			var idle: Vector3 = _idle_pose(u, float(i) * 1.9 + (3.0 if mirrored else 0.0))
			_pose_sx = idle.x
			_pose_sy = idle.y
			_pose_rot = idle.z * dir
		if _lunge_who == str(p["active"]):
			var lp: Vector4 = _lunge_pose(70.0 * pose.z)
			gx += lp.x * dir
			_pose_sx *= 1.0 + lp.y
			_pose_sy *= 1.0 - lp.y
			_pose_rot = lp.z * dir
			_pose_ghosts = lp.w
		elif _anim_on:
			var recoil: float = float(hit_flash.get(str(u["id"]), 0.0))
			gx -= recoil * 16.0 * pose.z * dir
			_pose_rot -= recoil * 0.07 * dir
		_entity_transform(gx, pose.z, pose.y)
		_draw_fighter(u, Vector2(gx, GEO_FLOOR - 120.0), i + (1 if mirrored else 0), str(p["id"]) == select_slot)
		_pose_sx = 1.0
		_pose_sy = 1.0
		_pose_rot = 0.0
		_pose_ghosts = 0.0
		_draw_summons(p, gx)
