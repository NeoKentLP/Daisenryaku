extends RefCounted

var commander_name: String = ""
var nation: String = "germany"
var level: int = 1
var xp: int = 0

var rarity: String = "菜鸟"
var background_skill: String = ""
var talent_skill: String = ""
var talent_level: int = 1
var quality_skills: Array = []
var level_skills: Array = []

var assigned_squad = null

const EXP_TABLE = [0, 100, 200, 350, 550, 800, 1100, 1500, 2000, 3000]
const MAX_LEVEL = 10

var nation_backgrounds = {
	"germany": {
		"infantry": ["步兵指挥", "精锐步兵", "突击步兵", "山地步兵", "城市作战专家", "机枪指挥官"],
		"vehicle": ["装甲指挥", "精锐装甲", "坦克工程师", "重型装甲", "坦克炮术专家", "装甲突击专家"],
		"artillery": ["炮术指挥", "精锐炮术", "迫击炮专家", "反坦克炮专家"],
		"support": ["工程指挥", "爆破专家", "筑城专家", "侦察指挥", "精锐侦察", "渗透专家", "后勤指挥", "运输专家", "军需官"],
		"air": ["空战指挥官", "俯冲轰炸专家", "高空格斗专家", "护航专家"],
	},
	"soviet": {
		"infantry": ["步兵政委", "精锐步兵", "突击步兵", "山地步兵", "城市作战专家", "机枪指挥官"],
		"vehicle": ["装甲指挥", "精锐装甲", "坦克工程师", "重型装甲", "坦克炮术专家", "装甲突击专家"],
		"artillery": ["炮术指挥", "精锐炮术", "迫击炮专家", "反坦克炮专家"],
		"support": ["工程指挥", "爆破专家", "筑城专家", "侦察指挥", "精锐侦察", "渗透专家", "后勤指挥", "运输专家", "军需官"],
		"air": ["空战指挥官", "俯冲轰炸专家", "高空格斗专家", "护航专家"],
	}
}

var talent_list = [
	{"name": "胆怯", "levels": ["胆怯", "沉着", "英勇"]},
	{"name": "鲁莽", "levels": ["鲁莽", "果断", "精准"]},
	{"name": "倦怠", "levels": ["倦怠", "勤勉", "铁血"]},
	{"name": "短视", "levels": ["短视", "清醒", "洞察"]},
	{"name": "孤僻", "levels": ["孤僻", "信赖", "领袖"]},
	{"name": "粗心", "levels": ["粗心", "谨慎", "诡诈"]},
	{"name": "吝啬", "levels": ["吝啬", "节俭", "慷慨"]},
	{"name": "莽撞", "levels": ["莽撞", "沉着", "磐石"]},
	{"name": "虚弱", "levels": ["虚弱", "强健", "铁骨"]},
	{"name": "迟钝", "levels": ["迟钝", "敏锐", "先知"]},
	{"name": "散漫", "levels": ["散漫", "严明", "铁律"]},
	{"name": "轻敌", "levels": ["轻敌", "警惕", "铁壁"]},
	{"name": "固执", "levels": ["固执", "开放", "远见"]},
	{"name": "懦弱", "levels": ["懦弱", "坚韧", "不屈"]},
	{"name": "贪婪", "levels": ["贪婪", "务实", "无私"]},
	{"name": "恐高", "levels": ["恐高", "适应", "空霸"]},
]

var quality_pool = [
	"穿甲专精", "掩体利用", "隐蔽行动", "弹药管理", "强壮",
	"压制抵抗", "先发制人", "快速响应", "硬汉", "致命一击",
	"稳定射击", "韧性防御", "稳定阵型",
]

var german_names_first = ["弗里茨", "汉斯", "库特", "维尔纳", "埃里希", "沃尔夫冈", "海因里希", "卡尔", "奥托", "赫尔穆特"]
var german_names_last = ["缪勒", "施密特", "费舍尔", "韦伯", "瓦格纳", "贝克尔", "霍夫曼", "舒尔茨", "科赫", "鲍尔"]
var soviet_names_first = ["伊万", "德米特里", "尼古拉", "亚历山大", "弗拉基米尔", "米哈伊尔", "鲍里斯", "谢尔盖", "阿列克谢", "康斯坦丁"]
var soviet_names_last = ["伊万诺夫", "彼得罗夫", "斯米尔诺夫", "库兹涅佐夫", "波波夫", "瓦西里耶夫", "扎伊采夫", "索科洛夫", "列别杰夫", "科兹洛夫"]

func _init(nat: String = "germany", bg_type: String = "infantry"):
	nation = nat
	_random_name()
	random_background(bg_type)
	random_talent()
	var qcount = get_quality_slot_count()
	if qcount > 0:
		random_quality_skills(qcount)

func random_background(bg_type: String = "infantry"):
	var bg_pool = nation_backgrounds.get(nation, nation_backgrounds["germany"]).get(bg_type, nation_backgrounds["germany"]["infantry"])
	background_skill = bg_pool[randi() % bg_pool.size()]

func setup(nat: String = "germany", bg_type: String = "infantry"):
	nation = nat
	_random_name()
	random_background(bg_type)
	random_talent()

func _random_name():
	var first_pool = german_names_first if nation == "germany" else soviet_names_first
	var last_pool = german_names_last if nation == "germany" else soviet_names_last
	commander_name = first_pool[randi() % first_pool.size()] + "·" + last_pool[randi() % last_pool.size()]

func set_name(new_name: String):
	if new_name and new_name != "":
		commander_name = new_name

func set_rarity(r: String):
	rarity = r

func random_talent():
	var talent = talent_list[randi() % talent_list.size()]
	var roll = randi() % 100
	if roll < 60:
		talent_level = 1
	elif roll < 90:
		talent_level = 2
	else:
		talent_level = 3
	talent_skill = talent.levels[talent_level - 1]

func get_talent_base_name() -> String:
	for t in talent_list:
		if t.levels[0] == talent_skill or t.levels[1] == talent_skill or t.levels[2] == talent_skill:
			return t.levels[0]
	return talent_skill

func random_quality_skills(count: int):
	quality_skills = []
	var used = {}
	var pool = quality_pool.duplicate()
	pool.shuffle()
	for s in pool:
		if quality_skills.size() >= count: break
		if not used.has(s):
			used[s] = true
			quality_skills.append(s)

func get_quality_slot_count() -> int:
	match rarity:
		"菜鸟": return 0
		"预备军官": return 1
		"老兵": return 2
		"英雄": return 3
	return 0

func gain_exp(amount: int):
	xp += amount
	while level < MAX_LEVEL and xp >= EXP_TABLE[level]:
		xp -= EXP_TABLE[level]
		level += 1

func get_all_skills() -> Array:
	var r = [background_skill, talent_skill]
	r += quality_skills
	r += level_skills
	return r

func get_skill_summary() -> String:
	var all = get_all_skills()
	if all.is_empty(): return "无技能"
	return ", ".join(all)

func duplicate():
	var c = get_script().new()
	c.commander_name = commander_name
	c.nation = nation
	c.level = level
	c.xp = xp
	c.rarity = rarity
	c.background_skill = background_skill
	c.talent_skill = talent_skill
	c.talent_level = talent_level
	c.quality_skills = quality_skills.duplicate()
	c.level_skills = level_skills.duplicate()
	c.assigned_squad = assigned_squad
	return c
