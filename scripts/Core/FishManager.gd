extends Node
class_name FishManager

# 存储鱼类资源，key: fish_name, value: FishData
var fish_dict: Dictionary = {}

# 自动扫描的文件夹路径
@export var fish_folder: String = "res://resources/FishTres/"

func _ready():
    _load_all_fish()
    print("✅ FishManager 初始化完成，已加载 ", fish_dict.size(), " 条鱼")

# --- 扫描文件夹并加载所有FishData.tres ---
func _load_all_fish():
    var dir = DirAccess.open(fish_folder)
    if not dir:
        push_error("❌ 无法打开鱼资源文件夹: " + fish_folder)
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        if dir.current_is_dir():
            file_name = dir.get_next()
            continue

        if file_name.ends_with(".tres"):
            var path = fish_folder + "/" + file_name   # <-- 改这里
            var fish_res: FishData = load(path)
            if fish_res:
                fish_dict[fish_res.fish_name] = fish_res
            else:
                push_error("❌ 无法加载鱼资源: " + path)

        file_name = dir.get_next()
    dir.list_dir_end()

# --- 根据鱼名获取FishData ---
func get_fish(fish_name: String) -> FishData:
    if fish_name in fish_dict:
        return fish_dict[fish_name]
    push_error("⚠️ FishManager 找不到鱼: " + fish_name)
    return null

# --- 获取所有鱼名列表 ---
func get_all_fish_names() -> Array:
    return fish_dict.keys()
