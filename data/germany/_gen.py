import json, os

OUT = r'D:\项目\godot\大战略01\data\germany'

# ============================================================
# 1. 武器数据库
# ============================================================
WEAPONS = {}

def w(id, name, wtype, dmg, pen, rmin, rmax, bs, sup, cqb, ammo, sc=1,
      aa=False, aa_dmg=0, aa_rng=0, aa_bs=0, tier=0):
    WEAPONS[id] = {
        "id":id,"name":name,"type":wtype,"nation":"germany",
        "tech_tier":tier,
        "base_damage":dmg,"penetration":pen,
        "range_min":rmin,"range_max":rmax,
        "bs_bonus":bs,"suppression":sup,"cqb_rating":cqb,
        "anti_air":aa,"aa_damage":aa_dmg,"aa_range_max":aa_rng,"aa_bs_bonus":aa_bs,
        "ammo":ammo,"max_ammo":ammo,"supply_cost":sc
    }

# 步枪类
w("kar98k","Kar98k","rifle",22,1,0,1,0,10,1,10,2,tier=0)
w("g43","G43","rifle",22,1,0,1,0,10,1,10,2,tier=2)
w("gewehr98","Gewehr98","rifle",22,1,0,1,0,10,1,10,2,tier=0)
# 冲锋枪
w("mp40","MP40","smg",15,0,0,0,5,8,3,30,1,tier=0)
w("mp38","MP38","smg",15,0,0,0,5,8,3,30,1,tier=0)
# 突击步枪
w("stg44","StG44","assault_rifle",20,1,0,1,3,8,2,20,2,tier=3)
# 机枪
w("mg34","MG34","mg",18,2,0,1,-5,20,1,50,2,tier=0)
w("mg42","MG42","mg",20,2,0,1,-5,22,1,50,2,tier=2)
# 反坦克步枪
w("ptrb_38","PzB 38","at_rifle",30,4,0,1,-5,15,0,5,3,tier=0)
w("ptrb_39","PzB 39","at_rifle",30,4,0,1,-5,15,0,5,3,tier=1)
# 坦克炮
w("kwk30_2cm","2cm KwK30","tank_gun",20,3,0,1,0,12,0,20,3,tier=1)
w("kwk36_37mm","3.7cm KwK36","tank_gun",25,4,0,1,0,12,0,20,3,tier=1)
w("kwk39_50mm","5cm KwK39","tank_gun",30,5,0,1,0,12,0,20,3,tier=2)
w("kwk40_75mm_L43","7.5cm KwK40 L43","tank_gun",40,7,0,1,0,12,0,20,3,tier=2)
w("kwk40_75mm_L48","7.5cm KwK40 L48","tank_gun",42,7,0,1,0,12,0,20,3,tier=2)
w("kwk42_75mm_L70","7.5cm KwK42 L70","tank_gun",45,9,0,1,0,12,0,20,3,tier=3)
w("kwk36_88mm","8.8cm KwK36","tank_gun",50,10,0,1,0,12,0,20,3,tier=2)
w("kwk43_88mm","8.8cm KwK43","tank_gun",55,12,0,1,0,12,0,20,3,tier=3)
w("stuk_40_75mm","7.5cm StuK40","tank_gun",42,7,0,1,0,12,0,20,3,tier=2)
w("stuk_42_75mm_L70","7.5cm StuK42 L70","tank_gun",45,9,0,1,0,12,0,20,3,tier=3)
# 火炮
w("lefh18","10.5cm leFH18","artillery",35,4,2,3,-10,15,0,10,4,tier=0)
w("sfh18","15cm sFH18","artillery",45,6,2,4,-10,15,0,10,4,tier=2)
w("grw34","8cm GrW34","mortar",25,1,1,2,-5,12,0,15,3,tier=0)
w("nebelwerfer42","15cm Nebelwerfer 42","rocket",40,5,3,5,-15,25,0,5,5,tier=3)
# 防空炮
w("flak38_20mm","2cm Flak38","aa_gun",25,3,0,1,5,10,0,20,3,
   aa=True,aa_dmg=15,aa_rng=1,aa_bs=10,tier=1)
w("flak36_88mm","8.8cm Flak36","aa_gun",45,7,0,1,0,10,0,20,3,
   aa=True,aa_dmg=20,aa_rng=3,aa_bs=5,tier=1)
w("flak37_37mm","3.7cm Flak37","aa_gun",30,4,0,1,5,10,0,20,3,
   aa=True,aa_dmg=15,aa_rng=1,aa_bs=8,tier=2)
# 喷火器
w("flammenwerfer35","Flammenwerfer 35","flamethrower",20,0,0,0,10,30,3,5,3,tier=0)
# 车载机枪 (辅助武器)
w("mg34_coaxial","MG34(同轴)","mg",18,2,0,1,-5,20,1,50,2)

print("Weapons defined: %d" % len(WEAPONS))

# ============================================================
# 2. 编制数据库
# ============================================================
UNITS = []

def u(id, name, utype, tier, cost, mtype, init, vision, members):
    UNITS.append({
        "id":id,"name":name,"nation":"germany","type":utype,
        "tech_tier":tier,"cost":cost,
        "move_type":mtype,"initiative":init,"vision":vision,
        "members":members
    })

def mem(role, count, hp, bs, armor, eva, conc, weapons):
    return {
        "role":role,"count":count,"hp":hp,"bs":bs,
        "armor":armor,"evasion":eva,"conceal":conc,
        "weapons":list(weapons) if isinstance(weapons,(list,tuple)) else [weapons]
    }

# --- 步兵系 ---
u("ger_inf_sq39","步兵班39型","infantry",0,150,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,["kar98k"]),
    mem("机枪手",1,10,60,0,0,0,["mg34"])])
u("ger_inf_sq41","步兵班41型","infantry",1,200,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,["kar98k"]),
    mem("机枪手",1,10,60,0,0,0,["mg34"])])
u("ger_smg_sq","冲锋枪班","infantry",1,200,"foot",5,2,[
    mem("冲锋枪手",6,10,60,0,0,0,["mp40"])])
u("ger_mg_sq","机枪班","infantry",1,250,"foot",4,2,[
    mem("机枪手",2,10,60,0,0,0,["mg34"]),
    mem("步枪手",1,10,60,0,0,0,["kar98k"])])
u("ger_eng_sq","工兵班","infantry",1,200,"foot",4,2,[
    mem("工兵",5,10,60,0,0,0,["kar98k"]),
    mem("工兵班长",1,10,65,0,0,0,["mp40"])])
u("ger_at_sq","AT班(PTRD)","infantry",1,280,"foot",3,2,[
    mem("反坦克手",3,10,60,0,0,0,["ptrb_38"]),
    mem("步枪手",1,10,60,0,0,0,["kar98k"])])
u("ger_inf_sq42","步兵班42型","infantry",2,220,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,["g43"]),
    mem("机枪手",1,10,60,0,0,0,["mg42"])])
u("ger_mg_sq43","机枪班43型","infantry",2,350,"foot",4,2,[
    mem("机枪手",2,10,60,0,0,0,["mg42"]),
    mem("步枪手",1,10,60,0,0,0,["g43"])])
u("ger_eng_sq43","工兵班43型","infantry",2,280,"foot",4,2,[
    mem("工兵",5,10,60,0,0,0,["g43"]),
    mem("工兵班长",1,10,65,0,0,0,["mp40"])])
u("ger_at_sq43","AT班43型","infantry",2,350,"foot",3,2,[
    mem("反坦克手",2,10,60,0,0,0,["ptrb_39"]),
    mem("步枪手",2,10,60,0,0,0,["g43"])])
u("ger_inf_sq44","步兵班44型","infantry",3,250,"foot",5,2,[
    mem("突击手",3,10,65,0,0,0,["stg44"]),
    mem("步枪手",2,10,60,0,0,0,["g43"]),
    mem("机枪手",1,10,60,0,0,0,["mg42"])])
u("ger_smg_sq44","冲锋枪班44型","infantry",3,280,"foot",5,2,[
    mem("冲锋枪手",5,10,60,0,0,0,["mp40"]),
    mem("机枪手",1,10,60,0,0,0,["mg42"])])

# --- 步兵系道具 ---
u("ger_recce_inf","侦察步兵","infantry",1,250,"foot",6,4,[
    mem("侦察兵",2,10,65,0,0,2,["kar98k"]),
    mem("步枪手",2,10,60,0,0,0,["kar98k"])])
u("ger_sniper_sq","狙击班","infantry",1,300,"foot",5,4,[
    mem("狙击手",2,10,75,0,0,3,["kar98k"]),
    mem("观察员",2,10,60,0,0,2,["mp40"])])
u("ger_assault_eng","突击工兵","infantry",2,350,"foot",5,2,[
    mem("突击工兵",5,10,65,0,0,0,["mp40"]),
    mem("喷火兵",1,12,60,0,0,0,["flammenwerfer35"])])
u("ger_navy_inf","海军步兵","infantry",1,220,"foot",4,2,[
    mem("步兵",6,10,60,0,0,0,["kar98k"])])
u("ger_tractor_militia","拖拉机民兵","infantry",0,80,"foot",2,1,[
    mem("民兵",6,8,40,0,0,0,["gewehr98"])])
u("ger_guard_inf","近卫步兵","infantry",3,320,"foot",5,2,[
    mem("警卫",4,12,70,0,0,0,["stg44"]),
    mem("机枪手",1,12,65,0,0,0,["mg42"])])
u("ger_airborne","空降猎兵","infantry",2,300,"foot",5,2,[
    mem("伞兵",5,10,65,0,0,0,["g43"]),
    mem("机枪手",1,10,60,0,0,0,["mg42"])])
u("ger_recce_cav","侦察骑兵","infantry",2,280,"foot",6,5,[
    mem("骑兵侦察",2,10,65,0,0,2,["kar98k"]),
    mem("步枪手",2,10,60,0,0,0,["kar98k"])])

# --- 载具系 ---
def mk_vehicle(id, name, tier, cost, init, vis, armor, eva, crew_hp, crew_bs, weapons, mtype="track"):
    u(id,name,"vehicle",tier,cost,mtype,init,vis,[
        mem("车组",3,crew_hp,crew_bs,armor,eva,0,weapons)])

mk_vehicle("ger_pz1a","一号坦克A型",1,800,4,2,3,6,20,60,["mg34_coaxial"])
mk_vehicle("ger_pz35t","35t",1,850,5,2,4,5,20,60,["kwk36_37mm","mg34_coaxial"])
mk_vehicle("ger_pz2f","二号F型",1,800,5,2,5,5,20,60,["kwk30_2cm","mg34_coaxial"])
mk_vehicle("ger_pz38t","38t",1,1000,5,2,5,5,20,65,["kwk36_37mm","mg34_coaxial"])
mk_vehicle("ger_pz3e","三号E型",1,1100,6,2,6,4,25,65,["kwk36_37mm","mg34_coaxial"])
mk_vehicle("ger_pz4d","四号D型",1,1200,6,2,7,3,25,65,["kwk40_75mm_L43","mg34_coaxial"])
mk_vehicle("ger_stug3b","StuG III B(短)",1,1000,5,2,7,3,25,65,["stuk_40_75mm"])
mk_vehicle("ger_pz3j","三号J型",2,1300,6,2,7,3,25,70,["kwk39_50mm","mg34_coaxial"])
mk_vehicle("ger_pz4g","四号G型(长)",2,1500,6,2,8,3,25,70,["kwk40_75mm_L43","mg34_coaxial"])
mk_vehicle("ger_stug3g","StuG III G(长)",2,1400,5,2,8,3,25,70,["stuk_40_75mm"])
mk_vehicle("ger_pz5d","豹式D型",3,1800,7,2,10,4,30,75,["kwk42_75mm_L70","mg34_coaxial"])
mk_vehicle("ger_jagdpanther","猎豹",3,2000,6,2,12,3,30,75,["kwk42_75mm_L70","mg34_coaxial"])
mk_vehicle("ger_pz6b","虎王",3,2400,6,2,14,2,35,75,["kwk43_88mm","mg34_coaxial"])
mk_vehicle("ger_pz6e","虎式E型",2,2000,6,2,12,2,35,75,["kwk36_88mm","mg34_coaxial"])
mk_vehicle("ger_ostwind","东风37mm",2,1500,5,2,7,3,25,65,["flak37_37mm","mg34_coaxial"])

# --- 火炮系 ---
u("ger_mortar81","81mm迫击炮班","artillery",0,350,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,["grw34"])])
u("ger_lefh18","105mm leFH18","artillery",0,600,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,["lefh18"])])
u("ger_flak38_20mm","20mm防空班","artillery",1,280,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,["flak38_20mm"])])
u("ger_pak38_50mm","50mm Pak38","artillery",1,400,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,["kwk39_50mm"])])
u("ger_flak36_88mm","88mm Flak18","artillery",1,700,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,["flak36_88mm"])])
u("ger_pak40_75mm","75mm Pak40","artillery",2,500,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,["kwk40_75mm_L43"])])
u("ger_sfh18","150mm sFH18","artillery",2,800,"foot",2,2,[
    mem("炮组",5,10,55,0,0,0,["sfh18"])])
u("ger_flak37_37mm","37mm防空","artillery",2,450,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,["flak37_37mm"])])
u("ger_rocket_mlrs","火箭炮","artillery",2,700,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,["nebelwerfer42"])])
u("ger_mortar120","120mm重迫击炮","artillery",3,450,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,["grw34"])])
# 道具火炮
u("ger_quad20mm","四联20mm防空","artillery",2,500,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,["flak38_20mm"])])
u("ger_nw42_210mm","Nebelwerfer 42 210mm","artillery",3,900,"foot",2,2,[
    mem("炮组",5,10,55,0,0,0,["nebelwerfer42"])])
u("ger_pak43_88mm","88mm Pak43","artillery",3,650,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,["flak36_88mm"])])
u("ger_mrs18_210mm","210mm Mrs18","artillery",3,1000,"foot",2,2,[
    mem("炮组",5,10,55,0,0,0,["nebelwerfer42"])])
u("ger_pak44_128mm","128mm Pak44","artillery",3,800,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,["kwk43_88mm"])])

# --- 支援系 ---
mk_vehicle("ger_sdkfz221","Sd.Kfz 221侦察车",0,850,6,4,3,6,15,60,["mg34_coaxial"])
mk_vehicle("ger_sdkfz222","Sd.Kfz 222",1,1000,6,4,4,6,15,60,["kwk30_2cm","mg34_coaxial"])
mk_vehicle("ger_sdkfz234_2","Sd.Kfz 234/2美洲狮",2,1700,7,4,6,5,20,70,["kwk39_50mm","mg34_coaxial"])
u("ger_horse_supply","骡马补给","support",0,120,"foot",2,2,[
    mem("后勤",2,10,50,0,0,0,["kar98k"])])
u("ger_truck_supply","卡车补给","support",1,250,"wheel",2,2,[
    mem("后勤",3,10,50,0,0,0,["kar98k"])])
u("ger_halftrack_supply","半履带补给","support",2,400,"track",2,2,[
    mem("后勤",3,10,50,0,0,0,["kar98k"])])
u("ger_heavy_truck_supply","重型补给卡车","support",3,500,"wheel",2,2,[
    mem("后勤",4,10,50,0,0,0,["kar98k"])])

# 空中系暂跳过（需要air unit特殊处理）

# ============================================================
# 3. 编制树节点
# ============================================================
NODES = []
# Collect raw definitions first
RAW_NODES = []

def tn(branch, tier, xp, parent_uid, uid, equip=False):
    RAW_NODES.append((branch, tier, xp, parent_uid, uid, equip))

def tn_base(branch, tier, xp, parent_uid, uid):
    tn(branch, tier, xp, parent_uid, uid, False)

def tn_equip(branch, tier, xp, parent_uid, uid):
    tn(branch, tier, xp, parent_uid, uid, uid)

def nd_base(branch, tier, xp, parent_uid, uid):
    nd(branch, tier, xp, parent_uid, uid, False)

def nd_equip(branch, tier, xp, parent_uid, uid, equip_id):
    nd(branch, tier, xp, parent_uid, uid, equip_id)

# 步兵系树
tn_base("infantry",0,0,None,"ger_inf_sq39")
tn_base("infantry",1,10,"ger_inf_sq39","ger_inf_sq41")
tn_base("infantry",1,15,"ger_inf_sq39","ger_smg_sq")
tn_base("infantry",1,20,"ger_inf_sq39","ger_mg_sq")
tn_base("infantry",1,25,"ger_inf_sq39","ger_eng_sq")
tn_base("infantry",1,30,"ger_inf_sq39","ger_at_sq")
tn_base("infantry",2,35,"ger_inf_sq41","ger_inf_sq42")
tn_base("infantry",2,40,"ger_mg_sq","ger_mg_sq43")
tn_base("infantry",2,45,"ger_eng_sq","ger_eng_sq43")
tn_base("infantry",2,50,"ger_at_sq","ger_at_sq43")
tn_base("infantry",3,55,"ger_inf_sq42","ger_inf_sq44")
tn_base("infantry",3,60,"ger_smg_sq","ger_smg_sq44")

# 步兵道具节点
tn_equip("infantry",1,10,"ger_inf_sq39","ger_recce_inf")
tn_equip("infantry",1,15,"ger_inf_sq39","ger_sniper_sq")
tn_equip("infantry",2,30,"ger_eng_sq","ger_assault_eng")
tn_equip("infantry",1,20,"ger_inf_sq39","ger_navy_inf")
tn_equip("infantry",0,5,"ger_inf_sq39","ger_tractor_militia")
tn_equip("infantry",3,65,"ger_inf_sq44","ger_guard_inf")
tn_equip("infantry",2,40,"ger_eng_sq","ger_airborne")
tn_equip("infantry",2,35,"ger_recce_inf","ger_recce_cav")

# 载具系树
tn_base("vehicle",1,0,None,"ger_pz1a")
order_veh = ["ger_pz35t","ger_pz2f","ger_pz38t","ger_pz3e","ger_pz4d","ger_stug3b"]
for i, vid in enumerate(order_veh):
    tn_base("vehicle",1,5+i*5,"ger_pz1a",vid)
tn_base("vehicle",2,30,"ger_pz3e","ger_pz3j")
tn_base("vehicle",2,35,"ger_pz4d","ger_pz4g")
tn_base("vehicle",2,40,"ger_stug3b","ger_stug3g")
tn_base("vehicle",2,45,"ger_pz2f","ger_ostwind")
tn_base("vehicle",3,50,"ger_pz4g","ger_pz5d")
tn_base("vehicle",3,55,"ger_pz4g","ger_jagdpanther")
tn_base("vehicle",2,60,"ger_pz4g","ger_pz6e")
tn_base("vehicle",3,70,"ger_pz6e","ger_pz6b")

# 火炮系树
tn_base("artillery",0,0,None,"ger_mortar81")
tn_base("artillery",0,5,"ger_mortar81","ger_lefh18")
tn_base("artillery",1,10,"ger_mortar81","ger_flak38_20mm")
tn_base("artillery",1,15,"ger_mortar81","ger_pak38_50mm")
tn_base("artillery",1,20,"ger_lefh18","ger_flak36_88mm")
tn_base("artillery",2,25,"ger_flak38_20mm","ger_pak40_75mm")
tn_base("artillery",2,30,"ger_lefh18","ger_sfh18")
tn_base("artillery",2,35,"ger_flak38_20mm","ger_flak37_37mm")
tn_base("artillery",2,40,"ger_lefh18","ger_rocket_mlrs")
tn_base("artillery",3,45,"ger_mortar81","ger_mortar120")
# 道具
tn_equip("artillery",2,35,"ger_flak38_20mm","ger_quad20mm")
tn_equip("artillery",3,50,"ger_rocket_mlrs","ger_nw42_210mm")
tn_equip("artillery",3,55,"ger_flak36_88mm","ger_pak43_88mm")
tn_equip("artillery",3,60,"ger_sfh18","ger_mrs18_210mm")
tn_equip("artillery",3,65,"ger_flak36_88mm","ger_pak44_128mm")

# 支援系树
tn_base("support",0,0,None,"ger_sdkfz221")
tn_base("support",0,5,"ger_sdkfz221","ger_horse_supply")
tn_base("support",1,10,"ger_sdkfz221","ger_sdkfz222")
tn_base("support",1,15,"ger_horse_supply","ger_truck_supply")
tn_base("support",2,20,"ger_sdkfz222","ger_sdkfz234_2")
tn_base("support",2,25,"ger_truck_supply","ger_halftrack_supply")
tn_base("support",3,30,"ger_halftrack_supply","ger_heavy_truck_supply")

# --- 生成节点（两遍：先建ID索引，再建节点）---
ALL_UIDS = set()
for (_, _, _, _, uid, _) in RAW_NODES:
    ALL_UIDS.add(uid)
for (branch, tier, xp, puid, uid, equip) in RAW_NODES:
    parent = puid if puid in ALL_UIDS else None
    NODES.append({
        "id":uid, "nation":"germany", "branch":branch,
        "tech_tier_required":tier, "unlock_xp":xp,
        "parent_id":parent, "unit_type_id":uid,
        "equipment":equip
    })

# ============================================================
# 4. 道具配置
# ============================================================
EQUIPMENT = [
    {"id":"ger_recce_inf","name":"侦察步兵","rarity":"green",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_recce_inf","cost_formula":"base × 1.5","source":"market"},
    {"id":"ger_sniper_sq","name":"狙击班","rarity":"purple",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_sniper_sq","cost_formula":"base × 3.0","source":"market"},
    {"id":"ger_assault_eng","name":"突击工兵","rarity":"green",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_assault_eng","cost_formula":"base × 1.5","source":"market"},
    {"id":"ger_navy_inf","name":"海军步兵","rarity":"purple",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_navy_inf","cost_formula":"base × 3.0","source":"market"},
    {"id":"ger_tractor_militia","name":"拖拉机民兵","rarity":"green",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_tractor_militia","cost_formula":"base × 1.5","source":"market"},
    {"id":"ger_guard_inf","name":"近卫步兵","rarity":"orange",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_guard_inf","cost_formula":"base × 6.0","source":"loot"},
    {"id":"ger_airborne","name":"空降猎兵","rarity":"purple",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_airborne","cost_formula":"base × 3.0","source":"market"},
    {"id":"ger_recce_cav","name":"侦察骑兵","rarity":"green",
     "nation":"germany","applicable_branches":["infantry"],
     "replaces_unit_type":"ger_recce_cav","cost_formula":"base × 1.5","source":"market"},
    {"id":"ger_quad20mm","name":"四联20mm防空","rarity":"purple",
     "nation":"germany","applicable_branches":["artillery"],
     "replaces_unit_type":"ger_quad20mm","cost_formula":"base × 3.0","source":"loot"},
    {"id":"ger_nw42_210mm","name":"Nebelwerfer 42 210mm","rarity":"green",
     "nation":"germany","applicable_branches":["artillery"],
     "replaces_unit_type":"ger_nw42_210mm","cost_formula":"base × 1.5","source":"market"},
    {"id":"ger_pak43_88mm","name":"88mm Pak43","rarity":"orange",
     "nation":"germany","applicable_branches":["artillery"],
     "replaces_unit_type":"ger_pak43_88mm","cost_formula":"base × 6.0","source":"loot"},
    {"id":"ger_mrs18_210mm","name":"210mm Mrs18","rarity":"purple",
     "nation":"germany","applicable_branches":["artillery"],
     "replaces_unit_type":"ger_mrs18_210mm","cost_formula":"base × 3.0","source":"market"},
    {"id":"ger_pak44_128mm","name":"128mm Pak44","rarity":"orange",
     "nation":"germany","applicable_branches":["artillery"],
     "replaces_unit_type":"ger_pak44_128mm","cost_formula":"base × 6.0","source":"loot"},
]

# ============================================================
# 5. 输出
# ============================================================
def sort_keys(obj, order):
    if isinstance(obj, dict):
        return {k: sort_keys(obj[k], order) for k in order if k in obj}
    return obj

weapon_order = ["id","name","type","nation","tech_tier",
    "base_damage","penetration","range_min","range_max",
    "bs_bonus","suppression","cqb_rating",
    "anti_air","aa_damage","aa_range_max","aa_bs_bonus",
    "ammo","max_ammo","supply_cost"]

unit_order = ["id","name","nation","type","tech_tier","cost",
    "move_type","initiative","vision","members"]

member_order = ["role","count","hp","bs","armor","evasion","conceal","weapons"]

tree_order = ["id","nation","branch","tech_tier_required","unlock_xp",
    "parent_id","unit_type_id","equipment"]

equip_order = ["id","name","rarity","nation","applicable_branches",
    "replaces_unit_type","cost_formula","source"]

weapons_out = [sort_keys(w, weapon_order) for w in WEAPONS.values()]
units_out = [sort_keys(u, unit_order) for u in UNITS]
# Sort unit members keys too
for u in units_out:
    u["members"] = [sort_keys(m, member_order) for m in u["members"]]
nodes_out = [sort_keys(n, tree_order) for n in NODES]
equip_out = [sort_keys(e, equip_order) for e in EQUIPMENT]

json.dump(weapons_out, open(os.path.join(OUT,"weapons.json"),'w',encoding='utf-8'),
    ensure_ascii=False, indent=2)
json.dump(units_out, open(os.path.join(OUT,"units.json"),'w',encoding='utf-8'),
    ensure_ascii=False, indent=2)
json.dump(nodes_out, open(os.path.join(OUT,"tree.json"),'w',encoding='utf-8'),
    ensure_ascii=False, indent=2)
json.dump(equip_out, open(os.path.join(OUT,"equipment.json"),'w',encoding='utf-8'),
    ensure_ascii=False, indent=2)

print("=== Germany Data Generated ===")
print("Weapons: %d" % len(weapons_out))
print("Units: %d" % len(units_out))
print("Tree nodes: %d" % len(nodes_out))
print("Equipment: %d" % len(equip_out))
