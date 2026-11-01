extends Node
## 全局游戏状态:flag、背包、血量、检查点、存档。

signal hp_changed
signal inventory_changed
signal flag_changed(flag_name)

const MAX_HP := 5
const SAVE_PATH := "user://veronica_save.json"

var flags: Dictionary = {}
var items: Array = []
var hp: int = MAX_HP
var checkpoint: Dictionary = {}

const ITEMS := {
	"tweezers": {"name": "镊子", "desc": "从修女雕像手里拿到的细长镊子。能夹出卡在窄处的东西。"},
	"mirror_shard": {"name": "镜子碎片", "desc": "一块锋利的镜子碎片。里面映着的你,好像比你慢了一点。"},
	"lab_keycard": {"name": "实验室门禁卡", "desc": "从修女头顶掉出来的门禁卡。印着:CLICHÉ LAB · 持卡人:博士。"},
	"photo_pieces": {"name": "撕碎的合照", "desc": "厕所隔间地上的照片碎片。也许能拼回去。", "verb": "拼合"},
	"photo_whole": {"name": "拼好的合照", "desc": "一对笑得很甜的男女。背面有字。", "verb": "查看"},
	"hair_key_dirty": {"name": "缠满头发的钥匙", "desc": "裹着污垢和头发的钥匙。得找水龙头冲一冲。"},
	"office_key": {"name": "办公室钥匙", "desc": "冲干净的钥匙,柄上刻着“博士办公室”。"},
	"doctor_diary": {"name": "博士的日记", "desc": "从保险箱里取出的日记。字迹越往后越潦草。", "verb": "阅读"},
	"hollow_revolver": {"name": "空枪", "desc": "弹仓是空的,扣动扳机只会发出清脆的咔哒声。按 Q 可以制造声响,引开注意。"},
	"hair_tonic_spray": {"name": "草本生发喷雾", "desc": "气味诡异,但喷一下居然让人精神一振。成分表第一行:米诺地尔。恢复 2 点状态。", "verb": "使用"},
	"water_report": {"name": "水样检测报告", "desc": "你自己写的报告。附录 B 解释了一件怪事:为什么让人长头发的药,会让全镇秃头。", "verb": "阅读"},
	"town_letters": {"name": "镇民来信", "desc": "镇上的人寄给实验室的信。一直没人拆,也没人回。", "verb": "阅读"},
	"perfect_hair_tonic": {"name": "完美生发剂", "desc": "按正确配比调出的生发剂,在瓶里泛着金色。\n这一瓶,能让他放下一切。"},
}

func has_flag(f: String) -> bool:
	return flags.get(f, false)

func set_flag(f: String, v: bool = true) -> void:
	flags[f] = v
	flag_changed.emit(f)

func has_item(id: String) -> bool:
	return items.has(id)

func add_item(id: String) -> void:
	if id == "hair_tonic_spray" or not items.has(id):
		items.append(id)
	inventory_changed.emit()

func remove_item(id: String) -> void:
	items.erase(id)
	inventory_changed.emit()

func damage(n: int) -> void:
	hp = max(0, hp - n)
	hp_changed.emit()

func heal(n: int) -> void:
	hp = min(MAX_HP, hp + n)
	hp_changed.emit()

func reset() -> void:
	flags = {}
	items = []
	hp = MAX_HP
	checkpoint = {}
	hp_changed.emit()
	inventory_changed.emit()

func save_checkpoint(pos: Vector3, yaw: float) -> void:
	checkpoint = {"flags": flags.duplicate(), "items": items.duplicate(), "pos": pos, "yaw": yaw}
	_write_disk(pos, yaw)

func restore_checkpoint() -> bool:
	if checkpoint.is_empty():
		return false
	flags = checkpoint["flags"].duplicate()
	items = checkpoint["items"].duplicate()
	hp = MAX_HP
	hp_changed.emit()
	inventory_changed.emit()
	return true

func _write_disk(pos: Vector3, yaw: float) -> void:
	var data := {"flags": flags, "items": items, "pos": [pos.x, pos.y, pos.z], "yaw": yaw}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_disk() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	flags = d.get("flags", {})
	items = d.get("items", [])
	var p = d.get("pos", [0, 0, 11])
	checkpoint = {"flags": flags.duplicate(), "items": items.duplicate(), "pos": Vector3(p[0], p[1], p[2]), "yaw": d.get("yaw", 0.0)}
	hp = MAX_HP
	hp_changed.emit()
	inventory_changed.emit()
	return true

func objective() -> String:
	if has_flag("game_completed"):
		return "THE END"
	if has_item("perfect_hair_tonic") and has_flag("valve_closed"):
		return "把完美生发剂交给弟子1号。"
	if has_item("perfect_hair_tonic"):
		return "还差一步:关掉后门旁边的排污阀。"
	if has_flag("boss_intro_done") and has_flag("valve_closed"):
		return "调出完美的生发剂。他有了头发,就再也没有理由往河里排废液了。"
	if has_flag("boss_intro_done"):
		return "趁弟子1号离开时:关掉后门旁边的排污阀,再调出完美的生发剂。"
	if has_flag("lab_unlocked"):
		return "进入实验室,查明真相。"
	if has_flag("safe_opened"):
		return "打开走廊尽头的实验室。门上还有一把日期密码锁——日记里也许有答案。"
	if has_flag("office_unlocked"):
		return "调查博士的办公室。保险箱的密码在哪?"
	if has_flag("got_lab_keycard") and has_flag("lab_card_ok") and not has_flag("office_unlocked"):
		return "实验室的门锁还需要密码。去博士的办公室找找——钥匙也许在厕所里。"
	if has_flag("got_lab_keycard"):
		return "找到办公室的钥匙。厕所里也许有线索。"
	if has_flag("statue_defeated"):
		return "修女的头顶有个机关。"
	if has_flag("got_tweezers"):
		if not has_flag("mirror_event_done"):
			if has_flag("hid_from_statue"):
				return "她在门外徘徊。趁现在,把厕所仔细搜一遍——镜子好像不太对劲。"
			return "跑进右边的厕所,找个地方躲起来!"
		if not has_flag("got_mirror_shard"):
			return "捡起镜子碎片。"
		return "用镜子碎片对付修女雕像!"
	return "查明是谁导致了这一切,以及他的目的。先调查大厅。"
