extends RefCounted

var commander_name: String = ""
var level: int = 1
var _exp: int = 0

# 初始化技能
var background_skill: String = ""   # 背景技能(固定1个)
var talent_skill: String = ""       # 天赋技能(固定1个)
var quality_skills: Array = []      # 品质技能(0-3个)
var level_skills: Array = []        # 升级获得的技能

var assigned_squad = null

const EXP_PER_LEVEL = [0, 100, 200, 350, 550, 800, 1100, 1500, 2000, 3000]

var backgrounds = ["装甲学校", "步兵教导", "炮术训练", "侦察出身", "工兵训练", "防空训练"]
var talents = ["冷静", "敏锐", "坚韧", "果断", "细致", "威严"]

var quality_levels = ["新兵", "老兵", "英雄"]

func _init():
	_random_generate()

func _random_generate():
	commander_name = _random_name()
	background_skill = backgrounds[randi() % backgrounds.size()]
	talent_skill = talents[randi() % talents.size()]
	# 品质技能
	var ql = quality_levels[randi() % quality_levels.size()]
	var qcount = 0
	match ql:
		"新兵": qcount = 1 if randi() % 100 < 50 else 0
		"老兵": qcount = 2 if randi() % 100 < 20 else 0
		"英雄": qcount = 3 if randi() % 100 < 5 else 0
	quality_skills = _random_quality_skills(qcount)

func _random_name() -> String:
	var first = ["弗里茨", "汉斯", "库特", "维尔纳", "埃里希", "沃尔夫冈", "海因里希", "卡尔"]
	var last = ["缪勒", "施密特", "费舍尔", "韦伯", "瓦格纳", "贝克尔", "霍夫曼", "舒尔茨"]
	return first[randi() % first.size()] + "·" + last[randi() % last.size()]

func _random_quality_skills(count: int) -> Array:
	var pool = ["应急治疗", "弹药调配", "战场抢修", "快速侦察", "战术撤退", "火力压制"]
	var result = []
	var used = {}
	while result.size() < count and result.size() < pool.size():
		var s = pool[randi() % pool.size()]
		if not used.has(s):
			used[s] = true
			result.append(s)
	return result

func gain_exp(amount: int):
	_exp += amount
	while level < 10 and _exp >= EXP_PER_LEVEL[level]:
		_exp -= EXP_PER_LEVEL[level]
		level += 1

func get_level_skill_options() -> Array:
	var pool = ["鼓舞士气", "精确射击", "战术规划", "弹药管理", "急行军", "铁壁防御", "战场侦查"]
	if level >= 3: pool.append("精准指挥")
	if level >= 5: pool.append("火力压制")
	if level >= 7: pool.append("领导力光环")
	var opts = []
	var used = {}
	used[background_skill] = true
	used[talent_skill] = true
	for s in level_skills: used[s] = true
	# 已有技能可以选强化(升级到Lv2)
	var upgrades = []
	for s in level_skills:
		if not s.ends_with("(Lv2)"):
			upgrades.append(s + "(Lv2)")
	# 从池中选3个
	var candidates = upgrades + pool
	candidates.shuffle()
	for c in candidates:
		if opts.size() >= 3: break
		if not used.has(c.replace("(Lv2)", "")):
			opts.append(c)
			used[c.replace("(Lv2)", "")] = true
	# 补满3个
	while opts.size() < 3:
		opts.append("经验累积")
	return opts

func learn_skill(skill_name: String):
	if skill_name.ends_with("(Lv2)"):
		var base = skill_name.replace("(Lv2)", "")
		if base in level_skills:
			level_skills.erase(base)
			level_skills.append(skill_name)
	else:
		level_skills.append(skill_name)

func get_all_skills() -> Array:
	var r = [background_skill, talent_skill]
	r += quality_skills
	r += level_skills
	return r

func get_skill_summary() -> String:
	var all = get_all_skills()
	if all.is_empty(): return "无技能"
	return ", ".join(all)
