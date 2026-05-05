import json, os

# ============================================================
# Common framework for nation data generation
# ============================================================
WEAPONS = {}
UNITS = []
RAW_NODES = []
EQUIPMENT = []

def w(id, name, wtype, nation, dmg, pen, rmin, rmax, bs, sup, cqb, ammo, sc=1,
      aa=False, aa_dmg=0, aa_rng=0, aa_bs=0, tier=0):
    WEAPONS[id] = {
        "id":id,"name":name,"type":wtype,"nation":nation,"tech_tier":tier,
        "base_damage":dmg,"penetration":pen,
        "range_min":rmin,"range_max":rmax,
        "bs_bonus":bs,"suppression":sup,"cqb_rating":cqb,
        "anti_air":aa,"aa_damage":aa_dmg,"aa_range_max":aa_rng,"aa_bs_bonus":aa_bs,
        "ammo":ammo,"max_ammo":ammo,"supply_cost":sc
    }

def u(id, name, utype, nation, tier, cost, mtype, init, vision, members, fuel=0, needs_airfield=False):
    entry = {
        "id":id,"name":name,"nation":nation,"type":utype,
        "tech_tier":tier,"cost":cost,
        "move_type":mtype,"initiative":init,"vision":vision,"members":members
    }
    if fuel > 0:
        entry["fuel"] = fuel
        entry["max_fuel"] = fuel
    if needs_airfield:
        entry["needs_airfield"] = True
    UNITS.append(entry)

def mem(role, count, hp, bs, arm, eva, conc, weps):
    return {"role":role,"count":count,"hp":hp,"bs":bs,
        "armor":arm,"evasion":eva,"conceal":conc,
        "weapons":list(weps) if isinstance(weps,(list,tuple)) else [weps]}

def mv(id, name, tier, cost, init, vis, armor, eva, crew_hp, crew_bs, weps, nation="germany", mtype="track", utype="vehicle"):
    u(id,name,utype,nation,tier,cost,mtype,init,vis,[
        mem("车组",3,crew_hp,crew_bs,armor,eva,0,weps)])

def tn(branch, tier, xp, puid, uid, equip=False):
    RAW_NODES.append((branch,tier,xp,puid,uid,equip))

def tnb(branch, tier, xp, puid, uid):
    tn(branch,tier,xp,puid,uid,False)

def tne(branch, tier, xp, puid, uid):
    tn(branch,tier,xp,puid,uid,uid)

def eq(id, name, rarity, nation, branches, replaces, formula, source):
    EQUIPMENT.append({
        "id":id,"name":name,"rarity":rarity,"nation":nation,
        "applicable_branches":branches,
        "replaces_unit_type":replaces,"cost_formula":formula,"source":source
    })

def output(out_dir, nation="germany"):
    os.makedirs(out_dir, exist_ok=True)
    # Build tree nodes
    nodes = []
    all_uids = set()
    for (_,_,_,_,uid,_) in RAW_NODES:
        all_uids.add(uid)
    for (branch,tier,xp,puid,uid,equip) in RAW_NODES:
        parent = puid if puid in all_uids else None
        nodes.append({
            "id":uid,"nation":nation,"branch":branch,
            "tech_tier_required":tier,"unlock_xp":xp,
            "parent_id":parent,"unit_type_id":uid,"equipment":equip
        })
    json.dump(list(WEAPONS.values()), open(os.path.join(out_dir,"weapons.json"),'w',encoding='utf-8'),
        ensure_ascii=False, indent=2)
    json.dump(UNITS, open(os.path.join(out_dir,"units.json"),'w',encoding='utf-8'),
        ensure_ascii=False, indent=2)
    json.dump(nodes, open(os.path.join(out_dir,"tree.json"),'w',encoding='utf-8'),
        ensure_ascii=False, indent=2)
    json.dump(EQUIPMENT, open(os.path.join(out_dir,"equipment.json"),'w',encoding='utf-8'),
        ensure_ascii=False, indent=2)
    _validate_output(list(WEAPONS.values()), UNITS, nodes, EQUIPMENT, out_dir)
    WEAPONS.clear(); UNITS.clear(); RAW_NODES.clear(); EQUIPMENT.clear()

# ============================================================
# 自动验证系统
# ============================================================
EXPECTED_PEN = {
    "kwk30_2cm":3,"kwk36_37mm":5,"kwk39_50mm":6,
    "kwk40_75mm_L43":9,"kwk40_75mm_L48":9,
    "kwk42_75mm_L70":11,"kwk36_88mm":12,"kwk43_88mm":13,
    "stuk40_75mm":9,"stuk42_75mm_L70":11,
    "l11_76mm":7,"f34_76mm":8,"zis5_76mm":8,
    "d5t_85mm":10,"zis_s53_85mm":10,
    "d25t_122mm":12,"ml20s_152mm":11,"d10_100mm":10,
}

def _validate_output(weapons, units, nodes, equipment, label):
    errors = []
    w_ids = [x['id'] for x in weapons]
    u_ids = [x['id'] for x in units]
    t_ids = [x['id'] for x in nodes]
    e_ids = [x['id'] for x in equipment]
    
    # Check PEN
    pen_ok = 0; pen_bad = 0
    for w in weapons:
        gid = w['id']
        if gid in EXPECTED_PEN:
            if w['penetration'] == EXPECTED_PEN[gid]:
                pen_ok += 1
            else:
                pen_bad += 1
                errors.append('PEN %s: got %d want %d' % (gid, w['penetration'], EXPECTED_PEN[gid]))
    
    # Check weapon references
    ref_ok = 0; ref_bad = 0
    for u in units:
        for m in u.get('members', []):
            for wep in m.get('weapons', []):
                if wep in w_ids: ref_ok += 1
                else: ref_bad += 1; errors.append('%s: missing weapon %s' % (u['id'], wep))
    
    # Check tree references
    for n in nodes:
        if n['unit_type_id'] not in u_ids: errors.append('%s: bad unit' % n['id'])
        if n['parent_id'] and n['parent_id'] not in t_ids: errors.append('%s: bad parent' % n['id'])
        eqid = n.get('equipment')
        if eqid and eqid not in e_ids and eqid is not False: errors.append('%s: bad equip' % n['id'])
    
    # Check equipment
    for e in equipment:
        if e['replaces_unit_type'] not in u_ids: errors.append('%s: bad replace' % e['id'])
    
    # Build summary
    summary = '%s %dw %du %dt %de' % (os.path.basename(label), len(weapons), len(units), len(nodes), len(equipment))
    if pen_ok + pen_bad > 0:
        summary += ' | PEN:%d/%d' % (pen_ok, pen_ok + pen_bad)
    if ref_ok + ref_bad > 0:
        summary += ' refs:%d%%' % (ref_ok * 100 // (ref_ok + ref_bad) if (ref_ok + ref_bad) > 0 else 100)
    
    if errors:
        summary += ' FAIL(%d)' % len(errors)
        for e in errors[:3]:
            summary += '\n  - ' + e
    else:
        summary += ' OK'
    print(summary)

# ============================================================
# GERMANY
# ============================================================
print("=== Generating Germany ===")
# ---- Weapons (29) ----
w("kar98k","Kar98k","rifle","germany",22,1,0,1,0,10,1,10,2,tier=0)
w("g43","G43","rifle","germany",22,1,0,1,0,10,1,10,2,tier=2)
w("gewehr98","Gewehr98","rifle","germany",22,1,0,1,0,10,1,10,2,tier=0)
w("mp40","MP40","smg","germany",15,0,0,0,5,8,3,30,1,tier=0)
w("mp38","MP38","smg","germany",15,0,0,0,5,8,3,30,1,tier=0)
w("stg44","StG44","assault_rifle","germany",20,1,0,1,3,8,2,20,2,tier=3)
w("mg34","MG34","mg","germany",18,2,0,1,-5,20,1,50,2,tier=0)
w("mg42","MG42","mg","germany",20,2,0,1,-5,22,1,50,2,tier=2)
w("ptrb38","PzB 38","at_rifle","germany",30,4,0,1,-5,15,0,5,3,tier=0)
w("ptrb39","PzB 39","at_rifle","germany",30,4,0,1,-5,15,0,5,3,tier=1)
w("kwk30_2cm","2cm KwK30","tank_gun","germany",20,3,0,1,0,12,0,20,3,tier=1)
w("kwk36_37mm","3.7cm KwK36","tank_gun","germany",25,5,0,1,0,12,0,20,3,tier=1)
w("kwk39_50mm","5cm KwK39","tank_gun","germany",30,6,0,1,0,12,0,20,3,tier=2)
w("kwk40_75mm_L43","7.5cm KwK40 L43","tank_gun","germany",40,9,0,1,0,12,0,20,3,tier=2)
w("kwk40_75mm_L48","7.5cm KwK40 L48","tank_gun","germany",42,9,0,1,0,12,0,20,3,tier=2)
w("kwk42_75mm_L70","7.5cm KwK42 L70","tank_gun","germany",45,11,0,1,0,12,0,20,3,tier=3)
w("stuk40_75mm","7.5cm StuK40","tank_gun","germany",42,9,0,1,0,12,0,20,3,tier=2)
w("stuk42_75mm_L70","7.5cm StuK42 L70","tank_gun","germany",45,11,0,1,0,12,0,20,3,tier=3)
w("lefh18","10.5cm leFH18","artillery","germany",35,4,2,3,-10,15,0,10,4,tier=0)
w("sfh18","15cm sFH18","artillery","germany",45,6,2,4,-10,15,0,10,4,tier=2)
w("grw34","8cm GrW34","mortar","germany",25,1,1,2,-5,12,0,15,3,tier=0)
w("nebelwerfer42","15cm Nebelwerfer 42","rocket","germany",40,5,3,5,-15,25,0,5,5,tier=3)
w("flak38_20mm","2cm Flak38","aa_gun","germany",25,3,0,1,5,10,0,20,3,
   aa=True,aa_dmg=15,aa_rng=1,aa_bs=10,tier=1)
w("flak36_88mm","8.8cm Flak36","aa_gun","germany",45,7,0,1,0,10,0,20,3,
   aa=True,aa_dmg=20,aa_rng=3,aa_bs=5,tier=1)
w("flak37_37mm","3.7cm Flak37","aa_gun","germany",30,4,0,1,5,10,0,20,3,
   aa=True,aa_dmg=15,aa_rng=1,aa_bs=8,tier=2)
w("kwk36_88mm","8.8cm KwK36","tank_gun","germany",50,12,0,1,0,12,0,20,3,tier=2)
w("kwk43_88mm","8.8cm KwK43","tank_gun","germany",55,13,0,1,0,12,0,20,3,tier=3)

w("flammenwerfer35","Flammenwerfer 35","flamethrower","germany",20,0,0,0,10,30,3,5,3,tier=0)
w("mg34_coaxial","MG34(同轴)","mg","germany",18,2,0,1,-5,20,1,50,2,tier=0)
w("panzerschreck","Panzerschreck","at_rifle","germany",35,6,0,0,-10,18,0,3,3,tier=2)
w("panzerfaust","Panzerfaust","at_rifle","germany",30,5,0,0,0,10,0,1,1,tier=3)

# ---- Infantry units (12+6) ----
u("ger_inf_sq39","步兵班39型","infantry","germany",0,150,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,"kar98k"),mem("机枪手",1,10,60,0,0,0,"mg34")])
u("ger_inf_sq41","步兵班41型","infantry","germany",1,200,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,"kar98k"),mem("机枪手",1,10,60,0,0,0,"mg34")])
u("ger_smg_sq","冲锋枪班","infantry","germany",1,200,"foot",5,2,[
    mem("冲锋枪手",6,10,60,0,0,0,"mp40")])
u("ger_mg_sq","机枪班","infantry","germany",1,250,"foot",4,2,[
    mem("机枪手",2,10,60,0,0,0,"mg34"),mem("步枪手",1,10,60,0,0,0,"kar98k")])
u("ger_eng_sq","工兵班","infantry","germany",1,200,"foot",4,2,[
    mem("工兵",5,10,60,0,0,0,"kar98k"),mem("工兵班长",1,10,65,0,0,0,"mp40")])
u("ger_at_sq","AT班(PTRD)","infantry","germany",1,280,"foot",3,2,[
    mem("反坦克手",3,10,60,0,0,0,"ptrb38"),mem("步枪手",1,10,60,0,0,0,"kar98k")])
u("ger_inf_sq42","步兵班42型","infantry","germany",2,220,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,"g43"),mem("机枪手",1,10,60,0,0,0,"mg42")])
u("ger_mg_sq43","机枪班43型","infantry","germany",2,350,"foot",4,2,[
    mem("机枪手",2,10,60,0,0,0,"mg42"),mem("步枪手",1,10,60,0,0,0,"g43")])
u("ger_eng_sq43","工兵班43型","infantry","germany",2,280,"foot",4,2,[
    mem("工兵",5,10,60,0,0,0,"g43"),mem("工兵班长",1,10,65,0,0,0,"mp40")])
u("ger_at_sq43","AT班43型","infantry","germany",2,350,"foot",3,2,[
    mem("反坦克手",2,10,60,0,0,0,"ptrb39"),mem("步枪手",2,10,60,0,0,0,"g43")])
u("ger_inf_sq44","步兵班44型","infantry","germany",3,250,"foot",5,2,[
    mem("突击手",3,10,65,0,0,0,"stg44"),mem("步枪手",2,10,60,0,0,0,"g43"),mem("机枪手",1,10,60,0,0,0,"mg42")])
u("ger_smg_sq44","冲锋枪班44型","infantry","germany",3,280,"foot",5,2,[
    mem("冲锋枪手",5,10,60,0,0,0,"mp40"),mem("机枪手",1,10,60,0,0,0,"mg42")])
u("ger_sniper_sq","狙击班","infantry","germany",1,300,"foot",5,4,[
    mem("狙击手",2,10,75,0,0,3,"kar98k"),mem("观察员",2,10,60,0,0,2,"mp40")])
u("ger_mountain_inf","山地猎兵","infantry","germany",1,300,"foot",5,2,[
    mem("山地步兵",6,10,65,0,0,1,"g43")])
u("ger_airborne","空降猎兵","infantry","germany",2,300,"foot",5,2,[
    mem("伞兵",5,10,65,0,0,0,"g43"),mem("机枪手",1,10,60,0,0,0,"mg42")])
u("ger_panzerschreck_sq","坦克杀手班","infantry","germany",2,300,"foot",3,2,[
    mem("反坦克手",3,10,60,0,0,0,"panzerschreck"),mem("护卫",2,10,60,0,0,0,"mp40")])
u("ger_stormtrooper","风暴突击队","infantry","germany",3,350,"foot",6,2,[
    mem("突击兵",4,12,70,0,0,0,"stg44"),mem("冲锋枪手",2,12,65,0,0,0,"mp40")])
u("ger_volkssturm","国民冲锋队","infantry","germany",3,60,"foot",2,1,[
    mem("民兵(铁拳)",4,7,35,0,0,0,["gewehr98","panzerfaust"]),mem("民兵",4,7,35,0,0,0,"gewehr98")])

# ---- Vehicle base units (15) ----
mv("ger_pz1a","一号坦克A型",1,800,4,2,3,6,20,60,"mg34_coaxial")
mv("ger_pz35t","35t",1,850,5,2,4,5,20,60,["kwk36_37mm","mg34_coaxial"])
mv("ger_pz2f","二号F型",1,800,5,2,5,5,20,60,["kwk30_2cm","mg34_coaxial"])
mv("ger_pz38t","38t",1,1000,5,2,5,5,20,65,["kwk36_37mm","mg34_coaxial"])
mv("ger_pz3e","三号E型",1,1100,6,2,6,4,25,65,["kwk36_37mm","mg34_coaxial"])
mv("ger_pz4d","四号D型",1,1200,6,2,7,3,25,65,["kwk40_75mm_L43","mg34_coaxial"])
mv("ger_stug3b","StuG III B(短)",1,1000,5,2,7,3,25,65,"stuk40_75mm")
mv("ger_pz3j","三号J型",2,1300,6,2,7,3,25,70,["kwk39_50mm","mg34_coaxial"])
mv("ger_pz4g","四号G型(长)",2,1500,6,2,8,3,25,70,["kwk40_75mm_L43","mg34_coaxial"])
mv("ger_stug3g","StuG III G(长)",2,1400,5,2,8,3,25,70,"stuk40_75mm")
mv("ger_pz5d","豹式D型",3,1800,7,2,10,4,30,75,["kwk42_75mm_L70","mg34_coaxial"])
mv("ger_jagdpanther","猎豹",3,2000,6,2,12,3,30,75,["kwk42_75mm_L70","mg34_coaxial"])
mv("ger_pz6b","虎王",3,2400,6,2,14,2,35,75,["kwk43_88mm","mg34_coaxial"])
mv("ger_pz6e","虎式E型",2,2000,6,2,12,2,35,75,["kwk36_88mm","mg34_coaxial"])
mv("ger_ostwind","东风37mm",2,1500,5,2,7,3,25,65,["flak37_37mm","mg34_coaxial"])
mv("ger_grille","Grille(蟋蟀)",1,1100,4,2,4,4,20,60,["sfh18"])

# ---- Vehicle equipment variants ----
mv("ger_marder3","黄鼠狼III",1,950,5,2,4,5,15,65,["kwk40_75mm_L43"])
mv("ger_flammpz3","喷火坦克III",2,1000,5,2,6,4,25,60,["flammenwerfer35"])
mv("ger_nashorn","犀牛88mm",2,1700,5,2,5,3,20,70,["flak36_88mm"])
mv("ger_jagdtiger","猎虎128mm",3,2600,5,2,14,2,35,75,["kwk43_88mm"])
mv("ger_stuh42","StuH 42",2,1300,5,2,7,3,25,65,"lefh18")
mv("ger_maus","鼠式",3,3000,5,2,16,1,40,80,["kwk43_88mm","mg34_coaxial"])
mv("ger_wirbelwind","东风四联20mm",2,1400,5,2,7,3,25,65,["flak38_20mm","mg34_coaxial"])
mv("ger_sturmtiger","突击虎380mm",3,2200,3,2,12,1,30,60,["sfh18"])
mv("ger_bison_spg","野牛自行火炮",1,1000,3,2,2,5,15,55,"sfh18")

# ---- Additional vehicle equipment ----
mv("ger_jagdpanzer38t","追猎者38(t)",2,1100,5,2,5,4,20,65,"kwk40_75mm_L43")
mv("ger_jagdpanzer_iv","Jagdpanzer IV",2,1300,5,2,8,3,25,70,"kwk40_75mm_L48")
mv("ger_brummbar","灰熊突击炮",2,1400,4,2,8,3,25,65,"sfh18")
mv("ger_kugelblitz","球形闪电",3,1500,5,2,7,3,25,70,["flak38_20mm","mg34_coaxial"])
mv("ger_hummel","胡蜂150mm自行炮",2,1300,4,2,5,3,20,60,"sfh18")
mv("ger_wespe","黄蜂105mm自行炮",2,1100,4,2,4,4,20,60,"lefh18")
mv("ger_panther_ii","豹II原型车",3,2200,6,2,12,4,30,80,["kwk42_75mm_L70","mg34_coaxial"])
mv("ger_tiger_p","虎(P)式",2,2100,5,2,12,2,35,70,["kwk36_88mm","mg34_coaxial"])
mv("ger_elefant","象式重坦歼",3,2400,5,2,14,2,30,75,["flak36_88mm"])

# ---- Artillery (10+5) ----
u("ger_mortar81","81mm迫击炮班","artillery","germany",0,350,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,"grw34")])
u("ger_lefh18","105mm leFH18","artillery","germany",0,600,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,"lefh18")])
u("ger_flak38_20mm","20mm防空班","artillery","germany",1,280,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,"flak38_20mm")])
u("ger_pak38_50mm","50mm Pak38","artillery","germany",1,400,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,"kwk39_50mm")])
u("ger_flak36_88mm","88mm Flak18","artillery","germany",1,700,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,"flak36_88mm")])
u("ger_pak40_75mm","75mm Pak40","artillery","germany",2,500,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,"kwk40_75mm_L43")])
u("ger_sfh18","150mm sFH18","artillery","germany",2,800,"foot",2,2,[
    mem("炮组",5,10,55,0,0,0,"sfh18")])
u("ger_flak37_37mm","37mm防空","artillery","germany",2,450,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,"flak37_37mm")])
u("ger_rocket_mlrs","火箭炮","artillery","germany",2,700,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,"nebelwerfer42")])
u("ger_mortar120","120mm重迫击炮","artillery","germany",3,450,"foot",2,2,[
    mem("炮组",3,10,55,0,0,0,"grw34")])
u("ger_quad20mm","四联20mm防空","artillery","germany",2,500,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,"flak38_20mm")])
u("ger_nw42_210mm","Nebelwerfer 42 210mm","artillery","germany",3,900,"foot",2,2,[
    mem("炮组",5,10,55,0,0,0,"nebelwerfer42")])
u("ger_pak43_88mm","88mm Pak43","artillery","germany",3,650,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,"flak36_88mm")])
u("ger_mrs18_210mm","210mm Mrs18","artillery","germany",3,1000,"foot",2,2,[
    mem("炮组",5,10,55,0,0,0,"nebelwerfer42")])
u("ger_pak44_128mm","128mm Pak44","artillery","germany",3,800,"foot",2,2,[
    mem("炮组",4,10,55,0,0,0,"kwk43_88mm")])

# ---- Support (7) ----
mv("ger_sdkfz221","Sd.Kfz 221侦察车",0,850,6,4,3,6,15,60,"mg34_coaxial",utype="support")
mv("ger_sdkfz222","Sd.Kfz 222",1,1000,6,4,4,6,15,60,["kwk30_2cm","mg34_coaxial"],utype="support")
mv("ger_sdkfz234_2","Sd.Kfz 234/2美洲狮",2,1700,7,4,6,5,20,70,["kwk39_50mm","mg34_coaxial"],utype="support")
u("ger_horse_supply","骡马补给","support","germany",0,120,"foot",2,2,[mem("后勤",2,10,50,0,0,0,"kar98k")])
u("ger_truck_supply","卡车补给","support","germany",1,250,"wheel",2,2,[mem("后勤",3,10,50,0,0,0,"kar98k")])
u("ger_halftrack_supply","半履带补给","support","germany",2,400,"track",2,2,[mem("后勤",3,10,50,0,0,0,"kar98k")])
u("ger_heavy_truck_supply","重型补给卡车","support","germany",3,500,"wheel",2,2,[mem("后勤",4,10,50,0,0,0,"kar98k")])

# ---- German Air Weapons (8) ----
w("mg151_20mm","MG151/20","mg","germany",25,3,0,1,5,10,1,30,3,aa=True,aa_dmg=25,aa_rng=1,aa_bs=10,tier=1)
w("mg131_13mm","MG131","mg","germany",18,2,0,1,0,8,1,40,2,aa=True,aa_dmg=18,aa_rng=1,aa_bs=8,tier=1)
w("mk108_30mm","MK108 30mm","tank_gun","germany",45,5,0,1,-5,12,0,15,3,aa=True,aa_dmg=40,aa_rng=1,aa_bs=5,tier=3)
w("sc250_bomb","SC250炸弹","artillery","germany",55,2,0,0,-10,5,0,1,5,tier=1)
w("sc500_bomb","SC500炸弹","artillery","germany",70,3,0,0,-15,5,0,1,5,tier=2)
w("wgr21_rocket","WGr21火箭弹","rocket","germany",40,4,0,0,-15,20,0,2,5,tier=2)
w("mg81z","MG81Z","mg","germany",15,1,0,1,0,8,1,50,2,aa=True,aa_dmg=15,aa_rng=1,aa_bs=5,tier=1)
w("mk103_30mm","MK103 30mm","tank_gun","germany",48,6,0,1,-5,12,0,12,3,aa=True,aa_dmg=42,aa_rng=1,aa_bs=5,tier=3)

# ---- German Air units (29 total: 14 base + 15 equip) ----
def air(id, name, tier, cost, init, vis, hp, bs, armor, eva, weps, fuel=20):
    u(id,name,"air","germany",tier,cost,"flight",init,vis,
      [mem("飞行员",1,hp,bs,armor,eva,0,weps)], fuel=fuel, needs_airfield=True)

# Fighters
air("ger_bf109e3","Bf109E-3",1,500,10,2,12,65,2,8,["mg151_20mm","mg131_13mm"])
air("ger_bf109f4","Bf109F-4",2,600,10,2,12,70,2,9,["mg151_20mm","mg131_13mm"])
air("ger_fw190a5","Fw190A-5",3,700,10,2,14,70,3,9,["mg151_20mm","mg151_20mm"])
air("ger_me262","Me262",3,900,10,2,16,75,4,10,["mk108_30mm","mk108_30mm"], fuel=15)
# Bombers
air("ger_ju87b2","Ju87B-2斯图卡",1,400,4,2,14,60,2,5,["mg81z","sc250_bomb"])
air("ger_ju88a4","Ju88A-4",2,550,4,2,18,60,3,4,["mg81z","mg81z","sc500_bomb"])
air("ger_do217e4","Do217E-4",2,600,4,2,20,60,3,4,["mg81z","mg81z","sc500_bomb"])
air("ger_he177a5","He177A-5",3,800,4,2,24,65,3,4,["mg81z","mg81z","sc500_bomb","sc500_bomb"])
# Heavy fighters
air("ger_bf110c4","Bf110C-4",1,550,6,2,16,60,3,6,["mg151_20mm","mg151_20mm","sc250_bomb"])
air("ger_bf110g2","Bf110G-2",2,650,6,2,18,65,3,6,["mg151_20mm","mg151_20mm","sc500_bomb"])
air("ger_me410a1","Me410A-1",3,750,6,2,20,70,4,7,["mk108_30mm","mk108_30mm","sc500_bomb"])
# Recon
air("ger_fi156","Fi156斯多奇",0,200,4,5,8,55,1,6,["mg81z"], fuel=25)
air("ger_fw189a1","Fw189A-1",1,300,4,5,10,60,2,5,["mg81z","mg81z"], fuel=25)
air("ger_fw189a2","Fw189A-2",2,350,4,5,10,65,2,5,["mg81z","mg81z"], fuel=25)

# German air equipment
air("ger_hs123a","Hs123A",0,350,4,2,12,55,2,5,["sc250_bomb"])
air("ger_do17z","Do17Z",1,450,4,2,16,55,3,4,["mg81z","sc250_bomb"])
air("ger_he111h","He111H",2,550,4,2,20,60,3,4,["mg81z","mg81z","sc500_bomb"])
air("ger_ju87d","Ju87D-3",2,450,4,2,15,65,2,6,["mg81z","sc500_bomb"])
air("ger_ju87g","Ju87G-3",3,500,4,2,16,65,3,6,["mg81z","wgr21_rocket"])
air("ger_hs129b","Hs129B-2",2,500,4,2,16,60,4,5,["mg151_20mm","sc250_bomb"])
air("ger_fw190f","Fw190F",3,600,8,2,14,70,3,8,["mg151_20mm","sc500_bomb"])
air("ger_he219","He219",3,750,8,2,18,70,4,8,["mk108_30mm","mk108_30mm"])
air("ger_bf109k4","Bf109K-4",3,800,10,2,14,75,3,10,["mk108_30mm","mg151_20mm"])
air("ger_ta152h","Ta152H",3,850,10,2,14,75,3,10,["mk108_30mm","mk108_30mm"])
air("ger_me163","Me163彗星",3,700,10,2,12,70,3,11,["mk108_30mm"], fuel=6)
air("ger_he162","He162",3,650,10,2,12,70,3,9,["mg151_20mm","mg151_20mm"], fuel=12)
air("ger_ar234b","Ar234B",3,750,6,2,18,70,3,6,["sc500_bomb"], fuel=18)
air("ger_ju288","Ju288",3,700,4,2,22,65,4,4,["mg81z","mg81z","sc500_bomb","sc500_bomb"])
air("ger_ju52","Ju52/3m运输机",1,300,2,2,16,50,2,3,["mg81z","mg81z","mg81z"], fuel=30)
mv("ger_sdkfz250_9","Sd.Kfz 250/9侦察",2,900,7,5,4,6,15,65,["kwk30_2cm","mg34_coaxial"],utype="support")
mv("ger_sdkfz234_4","Sd.Kfz 234/4美洲狮",2,1600,6,5,6,5,20,70,["kwk40_75mm_L43"],utype="support")
u("ger_bridge_eng","架桥工兵","infantry","germany",2,300,"foot",4,2,[mem("工兵",6,10,60,0,0,0,"kar98k")])
u("ger_heavy_bridge_eng","重型架桥工兵","infantry","germany",3,400,"foot",4,2,[mem("工兵",6,10,60,0,0,0,"kar98k")])
u("ger_heavy_engineer","重型工兵","infantry","germany",3,400,"foot",5,3,[
    mem("重工兵",6,12,65,0,0,0,"g43")])

# ---- German Tree ----
tnb("infantry",0,0,None,"ger_inf_sq39")
tnb("infantry",1,10,"ger_inf_sq39","ger_inf_sq41")
tnb("infantry",1,15,"ger_inf_sq39","ger_smg_sq")
tnb("infantry",1,20,"ger_inf_sq39","ger_mg_sq")
tnb("infantry",1,25,"ger_inf_sq39","ger_at_sq")
tnb("infantry",2,30,"ger_inf_sq41","ger_inf_sq42")
tnb("infantry",2,35,"ger_mg_sq","ger_mg_sq43")
tnb("infantry",2,40,"ger_at_sq","ger_at_sq43")
tnb("infantry",3,45,"ger_inf_sq42","ger_inf_sq44")
tnb("infantry",3,50,"ger_smg_sq","ger_smg_sq44")
tne("infantry",1,15,"ger_inf_sq39","ger_sniper_sq")       # 狙击班
tne("infantry",1,18,"ger_inf_sq39","ger_mountain_inf")    # 山地猎兵
tne("infantry",2,40,"ger_inf_sq39","ger_airborne")        # 空降猎兵
tne("infantry",2,55,"ger_at_sq43","ger_panzerschreck_sq") # 坦克杀手班
tne("infantry",3,65,"ger_inf_sq44","ger_stormtrooper")    # 风暴突击队
tne("infantry",3,70,"ger_inf_sq44","ger_volkssturm")      # 国民冲锋队

tnb("vehicle",0,0,None,"ger_pz1a")              # T0: 一号坦克A型
tnb("vehicle",0,5,"ger_pz1a","ger_pz35t")        # T0: 35t
tnb("vehicle",1,10,"ger_pz1a","ger_pz2f")        # T1: 二号F型
tnb("vehicle",1,12,"ger_pz35t","ger_pz38t")      # T1: 38t
tnb("vehicle",1,14,"ger_pz35t","ger_pz3e")       # T1: 三号E型
tnb("vehicle",1,16,"ger_pz2f","ger_pz4d")        # T1: 四号D型
tnb("vehicle",1,18,"ger_pz2f","ger_stug3b")      # T1: StuG III B(短)
tnb("vehicle",1,20,"ger_pz2f","ger_grille")        # T1: Grille蟋蟀
tnb("vehicle",2,30,"ger_pz3e","ger_pz3j")
tnb("vehicle",2,35,"ger_pz4d","ger_pz4g")
tnb("vehicle",2,40,"ger_stug3b","ger_stug3g")
tnb("vehicle",2,45,"ger_pz2f","ger_ostwind")
tnb("vehicle",3,50,"ger_pz4g","ger_pz5d")
tnb("vehicle",3,55,"ger_pz4g","ger_jagdpanther")
tnb("vehicle",2,60,"ger_pz4g","ger_pz6e")
tnb("vehicle",3,70,"ger_pz6e","ger_pz6b")
# Vehicle equipment nodes
tne("vehicle",1,25,"ger_pz38t","ger_marder3")          # 黄鼠狼III T1道具
tne("vehicle",1,28,"ger_pz1a","ger_bison_spg")         # 野牛自行火炮 T1道具
tne("vehicle",2,30,"ger_pz38t","ger_jagdpanzer38t")     # 追猎者38(t)
tne("vehicle",2,35,"ger_pz3e","ger_flammpz3")           # 喷火坦克III
tne("vehicle",2,40,"ger_pz4d","ger_hummel")             # 胡蜂150mm
tne("vehicle",2,40,"ger_pz2f","ger_wespe")              # 黄蜂105mm
tne("vehicle",2,45,"ger_stug3b","ger_stuh42")           # StuH 42
tne("vehicle",2,45,"ger_pz4d","ger_jagdpanzer_iv")      # Jagdpanzer IV
tne("vehicle",2,50,"ger_pz4d","ger_brummbar")           # 灰熊突击炮
tne("vehicle",2,50,"ger_pz4d","ger_wirbelwind")         # 东风四联20mm
tne("vehicle",2,55,"ger_pz4g","ger_nashorn")            # 犀牛88mm T2道具
tne("vehicle",2,65,"ger_pz6e","ger_tiger_p")            # 虎(P)式
tne("vehicle",3,65,"ger_ostwind","ger_kugelblitz")      # 球形闪电
tne("vehicle",3,65,"ger_pz5d","ger_jagdtiger")          # 猎虎128mm
tne("vehicle",3,70,"ger_pz6e","ger_sturmtiger")         # 突击虎380mm
tne("vehicle",3,70,"ger_pz5d","ger_panther_ii")         # 豹II原型车
tne("vehicle",3,75,"ger_pz6e","ger_elefant")            # 象式重坦歼
tne("vehicle",3,80,"ger_pz6b","ger_maus")               # 鼠式

tnb("artillery",0,0,None,"ger_mortar81")
tnb("artillery",0,5,"ger_mortar81","ger_lefh18")
tnb("artillery",1,10,"ger_mortar81","ger_flak38_20mm")
tnb("artillery",1,15,"ger_mortar81","ger_pak38_50mm")
tnb("artillery",1,20,"ger_lefh18","ger_flak36_88mm")
tnb("artillery",2,25,"ger_flak38_20mm","ger_pak40_75mm")
tnb("artillery",2,30,"ger_lefh18","ger_sfh18")
tnb("artillery",2,35,"ger_flak38_20mm","ger_flak37_37mm")
tnb("artillery",2,40,"ger_lefh18","ger_rocket_mlrs")
tnb("artillery",3,45,"ger_mortar81","ger_mortar120")
tne("artillery",2,35,"ger_flak38_20mm","ger_quad20mm")
tne("artillery",3,50,"ger_rocket_mlrs","ger_nw42_210mm")
tne("artillery",3,55,"ger_flak36_88mm","ger_pak43_88mm")
tne("artillery",3,60,"ger_sfh18","ger_mrs18_210mm")
tne("artillery",3,65,"ger_flak36_88mm","ger_pak44_128mm")

tnb("support",0,0,None,"ger_sdkfz221")
tnb("support",0,5,"ger_sdkfz221","ger_horse_supply")
tnb("support",1,10,"ger_sdkfz221","ger_sdkfz222")
tnb("support",1,15,"ger_horse_supply","ger_truck_supply")
tnb("support",2,20,"ger_sdkfz222","ger_sdkfz234_2")
tnb("support",1,12,"ger_sdkfz221","ger_eng_sq")          # 工兵班(自步兵系移入)
tnb("support",2,18,"ger_truck_supply","ger_halftrack_supply")
tnb("support",2,22,"ger_eng_sq","ger_eng_sq43")           # 工兵班43型(自步兵系移入)
tnb("support",3,25,"ger_halftrack_supply","ger_heavy_truck_supply")
tne("support",2,28,"ger_sdkfz222","ger_sdkfz234_4")
tne("support",3,35,"ger_eng_sq43","ger_heavy_engineer")    # 重型工兵

# ---- German Equipment items (21: 8 infantry + 13 vehicle) ----
eq("ger_sniper_sq","狙击班","purple","germany",["infantry"],"ger_sniper_sq","base × 3.0","market")
eq("ger_mountain_inf","山地猎兵","green","germany",["infantry"],"ger_mountain_inf","base × 1.5","market")
eq("ger_airborne","空降猎兵","purple","germany",["infantry"],"ger_airborne","base × 3.0","market")
eq("ger_panzerschreck_sq","坦克杀手班","green","germany",["infantry"],"ger_panzerschreck_sq","base × 1.5","market")
eq("ger_stormtrooper","风暴突击队","purple","germany",["infantry"],"ger_stormtrooper","base × 3.0","loot")
eq("ger_volkssturm","国民冲锋队","green","germany",["infantry"],"ger_volkssturm","base × 1.5","loot")
eq("ger_marder3","黄鼠狼III","green","germany",["vehicle"],"ger_marder3","base × 1.5","market")
eq("ger_bison_spg","野牛自行火炮","green","germany",["vehicle"],"ger_bison_spg","base × 1.5","market")
eq("ger_flammpz3","喷火坦克III","purple","germany",["vehicle"],"ger_flammpz3","base × 3.0","loot")
eq("ger_wirbelwind","东风四联20mm","purple","germany",["vehicle"],"ger_wirbelwind","base × 3.0","market")
eq("ger_nashorn","犀牛88mm","purple","germany",["vehicle"],"ger_nashorn","base × 3.0","market")
eq("ger_sturmtiger","突击虎380mm","orange","germany",["vehicle"],"ger_sturmtiger","base × 6.0","loot")
eq("ger_jagdtiger","猎虎128mm","orange","germany",["vehicle"],"ger_jagdtiger","base × 6.0","loot")
eq("ger_stuh42","StuH 42","green","germany",["vehicle"],"ger_stuh42","base × 1.5","market")
eq("ger_maus","鼠式","orange","germany",["vehicle"],"ger_maus","base × 6.0","loot")
eq("ger_jagdpanzer38t","追猎者38(t)","green","germany",["vehicle"],"ger_jagdpanzer38t","base × 1.5","market")
eq("ger_jagdpanzer_iv","Jagdpanzer IV","green","germany",["vehicle"],"ger_jagdpanzer_iv","base × 1.5","market")
eq("ger_brummbar","灰熊突击炮","green","germany",["vehicle"],"ger_brummbar","base × 1.5","market")
eq("ger_kugelblitz","球形闪电","purple","germany",["vehicle"],"ger_kugelblitz","base × 3.0","loot")
eq("ger_hummel","胡蜂150mm自行炮","green","germany",["vehicle"],"ger_hummel","base × 1.5","market")
eq("ger_wespe","黄蜂105mm自行炮","green","germany",["vehicle"],"ger_wespe","base × 1.5","market")
eq("ger_panther_ii","豹II原型车","purple","germany",["vehicle"],"ger_panther_ii","base × 3.0","loot")
eq("ger_tiger_p","虎(P)式","purple","germany",["vehicle"],"ger_tiger_p","base × 3.0","loot")
eq("ger_elefant","象式重坦歼","orange","germany",["vehicle"],"ger_elefant","base × 6.0","loot")
eq("ger_quad20mm","四联20mm防空","purple","germany",["artillery"],"ger_quad20mm","base × 3.0","loot")
eq("ger_nw42_210mm","Nebelwerfer 42 210mm","green","germany",["artillery"],"ger_nw42_210mm","base × 1.5","market")
eq("ger_pak43_88mm","88mm Pak43","orange","germany",["artillery"],"ger_pak43_88mm","base × 6.0","loot")
eq("ger_mrs18_210mm","210mm Mrs18","purple","germany",["artillery"],"ger_mrs18_210mm","base × 3.0","market")
eq("ger_pak44_128mm","128mm Pak44","orange","germany",["artillery"],"ger_pak44_128mm","base × 6.0","loot")
eq("ger_sdkfz234_4","Sd.Kfz 234/4美洲狮","purple","germany",["support"],"ger_sdkfz234_4","base × 3.0","market")
eq("ger_heavy_engineer","重型工兵","purple","germany",["support"],"ger_heavy_engineer","base × 3.0","loot")

# ---- German Air Tree ----
tnb("air",1,0,None,"ger_bf109e3")
tnb("air",2,15,"ger_bf109e3","ger_bf109f4")
tnb("air",3,30,"ger_bf109f4","ger_fw190a5")
tnb("air",3,45,"ger_fw190a5","ger_me262")
tnb("air",1,5,None,"ger_ju87b2")
tnb("air",2,20,"ger_ju87b2","ger_ju88a4")
tnb("air",2,25,"ger_ju88a4","ger_do217e4")
tnb("air",3,40,"ger_do217e4","ger_he177a5")
tnb("air",1,10,None,"ger_bf110c4")
tnb("air",2,25,"ger_bf110c4","ger_bf110g2")
tnb("air",3,40,"ger_bf110g2","ger_me410a1")
tnb("air",0,0,None,"ger_fi156")
tnb("air",1,5,"ger_fi156","ger_fw189a1")
tnb("air",2,10,"ger_fw189a1","ger_fw189a2")
tnb("air",1,12,None,"ger_ju52")                       # 运输机线(自道具移入)
# Air equipment
tne("air",0,3,"ger_fi156","ger_hs123a")
tne("air",1,8,"ger_ju87b2","ger_do17z")
tne("air",2,20,"ger_ju88a4","ger_he111h")
tne("air",2,25,"ger_ju87b2","ger_ju87d")
tne("air",3,35,"ger_ju87d","ger_ju87g")
tne("air",2,25,"ger_ju87b2","ger_hs129b")
tne("air",3,35,"ger_fw190a5","ger_fw190f")
tne("air",3,40,"ger_bf110g2","ger_he219")
tne("air",3,50,"ger_bf109f4","ger_bf109k4")
tne("air",3,55,"ger_fw190a5","ger_ta152h")
tne("air",3,60,"ger_me262","ger_me163")
tne("air",3,50,"ger_me262","ger_he162")
tne("air",3,45,"ger_he177a5","ger_ar234b")
tne("air",3,45,"ger_he177a5","ger_ju288")
# ---- German Air Equipment items ----
eq("ger_hs123a","Hs123A","green","germany",["air"],"ger_hs123a","base × 1.5","market")
eq("ger_do17z","Do17Z","green","germany",["air"],"ger_do17z","base × 1.5","market")
eq("ger_he111h","He111H","purple","germany",["air"],"ger_he111h","base × 3.0","market")
eq("ger_ju87d","Ju87D-3","green","germany",["air"],"ger_ju87d","base × 1.5","market")
eq("ger_ju87g","Ju87G-3","green","germany",["air"],"ger_ju87g","base × 1.5","market")
eq("ger_hs129b","Hs129B-2","purple","germany",["air"],"ger_hs129b","base × 3.0","market")
eq("ger_fw190f","Fw190F","green","germany",["air"],"ger_fw190f","base × 1.5","market")
eq("ger_he219","He219","purple","germany",["air"],"ger_he219","base × 3.0","loot")
eq("ger_bf109k4","Bf109K-4","purple","germany",["air"],"ger_bf109k4","base × 3.0","loot")
eq("ger_ta152h","Ta152H","purple","germany",["air"],"ger_ta152h","base × 3.0","loot")
eq("ger_me163","Me163彗星","orange","germany",["air"],"ger_me163","base × 6.0","loot")
eq("ger_he162","He162","purple","germany",["air"],"ger_he162","base × 3.0","market")
eq("ger_ar234b","Ar234B","purple","germany",["air"],"ger_ar234b","base × 3.0","loot")
eq("ger_ju288","Ju288","purple","germany",["air"],"ger_ju288","base × 3.0","loot")
eq("ger_fw189a2","Fw189A-2","green","germany",["air"],"ger_fw189a2","base × 1.5","market")

output(r'D:\项目\godot\大战略01\data\germany', nation="germany")

# ============================================================
# SOVIET UNION
# ============================================================
print("=== Generating Soviet Union ===")

# ---- Weapons (25) ----
w("mosin_nagant","Mosin-Nagant 1891/30","rifle","soviet",22,1,0,1,0,10,1,10,2,tier=0)
w("svt40","SVT-40","rifle","soviet",22,1,0,1,0,10,1,10,2,tier=1)
w("ppsh41","PPSh-41","smg","soviet",15,0,0,0,5,8,3,30,1,tier=1)
w("pps43","PPS-43","smg","soviet",14,0,0,0,5,8,3,30,1,tier=2)
w("dp27","DP-27","mg","soviet",18,2,0,1,-5,20,1,50,2,tier=0)
w("sg43","SG-43","mg","soviet",19,2,0,1,-5,20,1,50,2,tier=2)
w("ptrd41","PTRD-41","at_rifle","soviet",30,4,0,1,-5,15,0,5,3,tier=1)
w("ptrs41","PTRS-41","at_rifle","soviet",32,7,0,1,-5,15,0,5,3,tier=2)
# Soviet tank guns
w("l11_76mm","76mm L-11","tank_gun","soviet",35,7,0,1,0,12,0,20,3,tier=1)
w("f34_76mm","76mm F-34","tank_gun","soviet",38,8,0,1,0,12,0,20,3,tier=2)
w("zis5_76mm","76mm ZiS-5","tank_gun","soviet",38,8,0,1,0,12,0,20,3,tier=2)
w("ml20s_152mm","152mm ML-20S","tank_gun","soviet",55,11,0,1,0,12,0,10,4,tier=3)

w("d5t_85mm","85mm D-5T","tank_gun","soviet",42,10,0,1,0,12,0,20,3,tier=2)
w("zis_s53_85mm","85mm ZiS-S-53","tank_gun","soviet",44,10,0,1,0,12,0,20,3,tier=3)
w("d25t_122mm","122mm D-25T","tank_gun","soviet",50,12,0,1,0,12,0,20,3,tier=3)
w("d10_100mm","100mm D-10","tank_gun","soviet",46,10,0,1,0,12,0,15,3,tier=3)
# Artillery
w("m30_122mm","122mm M-30","artillery","soviet",38,4,2,3,-10,15,0,10,4,tier=1)
w("d1_152mm","152mm D-1","artillery","soviet",48,6,2,4,-10,15,0,10,4,tier=3)
w("pm37_82mm","82mm PM-37","mortar","soviet",25,1,1,2,-5,12,0,15,3,tier=0)
w("pm120_120mm","120mm PM-120","mortar","soviet",28,2,1,2,-5,12,0,15,3,tier=2)
w("bm13","BM-13喀秋莎","rocket","soviet",40,5,3,5,-15,25,0,5,5,tier=2)
w("bm31","BM-31","rocket","soviet",42,6,3,5,-15,25,0,5,5,tier=3)
# AA
w("zis3_76mm","76mm ZiS-3","aa_gun","soviet",38,6,0,1,0,10,0,20,3,
   aa=True,aa_dmg=18,aa_rng=2,aa_bs=5,tier=2)
w("61k_37mm","37mm 61-K","aa_gun","soviet",30,4,0,1,5,10,0,20,3,
   aa=True,aa_dmg=15,aa_rng=1,aa_bs=8,tier=1)
w("52k_85mm","85mm 52-K","aa_gun","soviet",42,7,0,1,0,10,0,20,3,
   aa=True,aa_dmg=20,aa_rng=2,aa_bs=5,tier=2)
# Flamethrower
w("roks3","ROKS-3","flamethrower","soviet",20,0,0,0,10,30,3,5,3,tier=0)
# Coaxial MG
w("dt_coaxial","DT(同轴)","mg","soviet",18,2,0,1,-5,20,1,50,2,tier=0)

# ---- Infantry squads (9+6) ----
u("sov_inf_sq39","步兵班39型","infantry","soviet",0,120,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,"mosin_nagant"),mem("机枪手",1,10,60,0,0,0,"dp27")])
u("sov_inf_sq41","步兵班41型","infantry","soviet",1,200,"foot",4,2,[
    mem("步枪手",5,10,60,0,0,0,"svt40"),mem("机枪手",1,10,60,0,0,0,"dp27")])
u("sov_smg_sq","冲锋枪班","infantry","soviet",1,200,"foot",5,2,[
    mem("冲锋枪手",6,10,60,0,0,0,"ppsh41")])
u("sov_mg_sq","机枪班","infantry","soviet",1,250,"foot",4,2,[
    mem("机枪手",2,10,60,0,0,0,"dp27"),mem("冲锋枪手",1,10,60,0,0,0,"ppsh41")])
u("sov_mobilized_sq","动员兵班","infantry","soviet",0,80,"foot",2,1,[
    mem("步枪手",8,8,40,0,0,0,"mosin_nagant")])
u("sov_at_sq","AT班(PTRD)","infantry","soviet",1,280,"foot",3,2,[
    mem("反坦克手",3,10,60,0,0,0,"ptrd41")])
u("sov_inf_sq43","步兵班43型","infantry","soviet",2,220,"foot",4,2,[
    mem("步枪手",4,10,60,0,0,0,"mosin_nagant"),mem("机枪手",1,10,60,0,0,0,"dp27"),mem("冲锋枪手",1,10,60,0,0,0,"ppsh41")])
u("sov_mg_sq43","机枪班43型","infantry","soviet",2,350,"foot",4,2,[
    mem("机枪手",2,10,60,0,0,0,"sg43"),mem("冲锋枪手",2,10,60,0,0,0,"ppsh41")])
u("sov_smg_sq44","冲锋枪班44型","infantry","soviet",3,350,"foot",5,2,[
    mem("冲锋枪手",5,10,60,0,0,0,"ppsh41"),mem("反坦克手",1,10,60,0,0,0,"ptrs41")])
# Soviet equipment infantry
u("sov_sniper_sq","狙击班","infantry","soviet",1,300,"foot",5,4,[
    mem("狙击手",2,10,75,0,0,3,"mosin_nagant"),mem("观察员",2,10,60,0,0,2,"ppsh41")])
u("sov_penal_sq","惩戒营","infantry","soviet",1,100,"foot",2,1,[
    mem("惩戒兵",6,8,35,0,0,0,"mosin_nagant")])
u("sov_guard_inf41","近卫步兵41型","infantry","soviet",1,280,"foot",4,2,[
    mem("步枪手",5,12,65,0,0,0,"svt40"),mem("机枪手",1,12,65,0,0,0,"dp27")])
u("sov_guard_inf43","近卫步兵43型","infantry","soviet",2,320,"foot",5,2,[
    mem("步枪手",4,12,70,0,0,0,"svt40"),mem("机枪手",2,12,65,0,0,0,"sg43")])
u("sov_guard_inf44","近卫步兵44型","infantry","soviet",3,380,"foot",5,2,[
    mem("突击手",4,12,70,0,0,0,"ppsh41"),mem("机枪手",2,12,65,0,0,0,"sg43")])
u("sov_marine_inf","海军步兵","infantry","soviet",1,240,"foot",4,2,[
    mem("步兵",6,10,60,0,0,0,"mosin_nagant"),mem("机枪手",1,10,60,0,0,0,"dp27")])
u("sov_airborne","空降兵","infantry","soviet",1,280,"foot",5,2,[
    mem("伞兵",5,10,65,0,0,0,"svt40"),mem("冲锋枪手",1,10,60,0,0,0,"ppsh41")])

# ---- Vehicle base (14+13) ----
mv("sov_t26","T-26",1,800,4,2,4,5,20,60,["l11_76mm","dt_coaxial"], nation="soviet")
mv("sov_bt5","BT-5",1,850,6,2,3,6,20,60,["l11_76mm","dt_coaxial"], nation="soviet")
mv("sov_bt7m","BT-7M",1,1000,6,2,4,6,20,60,["l11_76mm","dt_coaxial"], nation="soviet")
mv("sov_t34_76_41","T-34/76 M1940",1,1300,6,2,8,4,25,65,["f34_76mm","dt_coaxial"], nation="soviet")
mv("sov_kv1_41","KV-1 M1941",1,1600,5,2,11,2,30,65,["zis5_76mm","dt_coaxial"], nation="soviet")
mv("sov_t60","T-60",1,900,5,2,4,5,15,55,["f34_76mm","dt_coaxial"], nation="soviet")
mv("sov_t34_76_42","T-34/76 M1942",2,1600,6,2,9,4,25,70,["f34_76mm","dt_coaxial"], nation="soviet")
mv("sov_kv1s","KV-1S",2,1800,5,2,11,3,30,70,["zis5_76mm","dt_coaxial"], nation="soviet")
mv("sov_su76m","SU-76M",2,1200,4,2,4,5,20,60,["zis5_76mm"], nation="soviet")
mv("sov_su152","SU-152",2,2000,4,2,11,2,30,70,["ml20s_152mm"], nation="soviet")
mv("sov_t34_85","T-34/85",3,2000,6,2,10,4,25,75,["zis_s53_85mm","dt_coaxial"], nation="soviet")
mv("sov_is2","IS-2",3,2400,5,2,13,2,35,75,["d25t_122mm","dt_coaxial"], nation="soviet")
mv("sov_su85","SU-85",3,2200,5,2,8,4,25,70,["d5t_85mm"], nation="soviet")
mv("sov_t44","T-44(道具)",3,2200,6,2,11,4,30,75,["zis_s53_85mm","dt_coaxial"], nation="soviet")

# ---- Soviet vehicle equipment (13) ----
mv("sov_ot130","OT-130喷火",1,950,4,2,4,5,20,55,["roks3"], nation="soviet")
mv("sov_t28","T-28多炮塔",1,1100,4,2,5,4,25,60,["l11_76mm","dt_coaxial"], nation="soviet")
mv("sov_t35","T-35多炮塔",1,1500,3,2,5,3,30,60,["l11_76mm","dt_coaxial"], nation="soviet")
mv("sov_t70","T-70轻坦",1,900,5,2,4,5,20,60,["l11_76mm","dt_coaxial"], nation="soviet")
mv("sov_kv8","KV-8喷火",1,1700,5,2,11,2,30,65,["roks3"], nation="soviet")
mv("sov_is1","IS-1",2,2200,5,2,12,2,35,70,["d5t_85mm","dt_coaxial"], nation="soviet")
mv("sov_isu122","ISU-122",3,2300,5,2,13,2,30,70,["d25t_122mm"], nation="soviet")
mv("sov_su100","SU-100",3,2400,5,2,8,4,25,75,["d10_100mm"], nation="soviet")
mv("sov_is3","IS-3",3,2800,5,2,15,2,35,80,["d25t_122mm","dt_coaxial"], nation="soviet")
mv("sov_isu152","ISU-152",3,2500,4,2,13,2,30,70,["ml20s_152mm"], nation="soviet")
mv("sov_su5","SU-5自行炮",2,1300,3,2,3,5,15,55,"m30_122mm", nation="soviet")
mv("sov_zsu37","ZSU-37",2,1100,5,2,4,5,20,60,["61k_37mm","dt_coaxial"], nation="soviet")

# ---- Artillery (11+3) ----
u("sov_pm37","82mm迫击炮","artillery","soviet",0,350,"foot",2,2,[mem("炮组",3,10,55,0,0,0,"pm37_82mm")])
u("sov_zis3","76mm ZiS-3","artillery","soviet",0,550,"foot",2,2,[mem("炮组",4,10,55,0,0,0,"zis3_76mm")])
u("sov_61k","37mm防空","artillery","soviet",0,280,"foot",2,2,[mem("炮组",3,10,55,0,0,0,"61k_37mm")])
u("sov_45mm_at","45mm AT","artillery","soviet",1,350,"foot",2,2,[mem("炮组",3,10,55,0,0,0,"l11_76mm")])
u("sov_52k","85mm防空","artillery","soviet",1,650,"foot",2,2,[mem("炮组",4,10,55,0,0,0,"52k_85mm")])
u("sov_zis2_57mm","57mm ZiS-2 AT","artillery","soviet",2,450,"foot",2,2,[mem("炮组",3,10,55,0,0,0,"zis5_76mm")])
u("sov_m30","122mm榴弹炮","artillery","soviet",2,750,"foot",2,2,[mem("炮组",4,10,55,0,0,0,"m30_122mm")])
u("sov_bm13","BM-13喀秋莎","artillery","soviet",2,700,"foot",2,2,[mem("炮组",4,10,55,0,0,0,"bm13")])
u("sov_pm120","120mm迫击炮","artillery","soviet",2,450,"foot",2,2,[mem("炮组",3,10,55,0,0,0,"pm120_120mm")])
u("sov_100mm_at","100mm BS-3 AT","artillery","soviet",3,600,"foot",2,2,[mem("炮组",4,10,55,0,0,0,"d10_100mm")])
u("sov_d1","152mm D-1","artillery","soviet",3,1100,"foot",2,2,[mem("炮组",5,10,55,0,0,0,"d1_152mm")])
# Equipment artillery
u("sov_quad_maxim","四管Maxim","artillery","soviet",1,400,"foot",2,2,[mem("炮组",4,10,55,0,0,0,"61k_37mm")])
u("sov_bm31","BM-31","artillery","soviet",3,900,"foot",2,2,[mem("炮组",5,10,55,0,0,0,"bm31")])
u("sov_b4","203mm B-4","artillery","soviet",3,1500,"foot",2,2,[mem("炮组",6,10,55,0,0,0,"ml20s_152mm")])

# ---- Support (9+6) ----
mv("sov_ba20","BA-20装甲车",0,800,6,4,3,6,15,60,["dt_coaxial"], nation="soviet", utype="support")
mv("sov_ba10","BA-10重装甲车",1,1000,6,4,5,5,20,60,["l11_76mm","dt_coaxial"], nation="soviet", utype="support")
mv("sov_ba64","BA-64",2,1200,7,4,4,6,15,60,["dt_coaxial"], nation="soviet", utype="support")
u("sov_horse_supply","骡马补给","support","soviet",0,120,"foot",2,2,[mem("后勤",2,10,50,0,0,0,"mosin_nagant")])
u("sov_truck_supply","卡车补给","support","soviet",1,250,"wheel",2,2,[mem("后勤",3,10,50,0,0,0,"mosin_nagant")])
u("sov_halftrack_supply","半履带补给","support","soviet",2,400,"track",2,2,[mem("后勤",3,10,50,0,0,0,"mosin_nagant")])
u("sov_heavy_truck_supply","重型补给卡车","support","soviet",3,500,"wheel",2,2,[mem("后勤",4,10,50,0,0,0,"mosin_nagant")])
u("sov_eng_sq40","工兵班40型","infantry","soviet",1,180,"foot",4,2,[
    mem("工兵",5,10,60,0,0,0,"mosin_nagant")])
u("sov_eng_sq43","工兵班43型","infantry","soviet",2,280,"foot",4,2,[
    mem("工兵",5,10,65,0,0,0,"svt40")])
# Support equipment
u("sov_assault_eng","突击工兵","infantry","soviet",2,320,"foot",5,2,[
    mem("突击工兵",5,10,65,0,0,0,"ppsh41"),mem("喷火兵",1,12,60,0,0,0,"roks3")])
u("sov_bridge_eng","架桥工兵","infantry","soviet",2,300,"foot",4,2,[mem("工兵",6,10,60,0,0,0,"mosin_nagant")])
u("sov_mot_recce","摩托化侦察队","support","soviet",2,600,"wheel",7,5,[mem("车组",3,15,60,4,6,0,"dt_coaxial")])
u("sov_heavy_bridge","重型架桥工兵","support","soviet",3,400,"foot",4,2,[mem("工兵",6,10,60,0,0,0,"mosin_nagant")])
u("sov_arv_recovery","ARV回收","support","soviet",2,800,"track",3,2,[mem("车组",3,20,60,5,3,0,"dt_coaxial")])
u("sov_btr40","BTR-40","support","soviet",2,1000,"wheel",7,5,[mem("车组",3,20,60,5,5,0,"dt_coaxial")])

# ---- Soviet Air Weapons (6) ----
w("shvak_20mm","ShVAK 20mm","mg","soviet",23,3,0,1,5,10,1,30,3,aa=True,aa_dmg=23,aa_rng=1,aa_bs=10,tier=1)
w("ubs_12_7mm","UBS 12.7mm","mg","soviet",17,2,0,1,0,8,1,40,2,aa=True,aa_dmg=17,aa_rng=1,aa_bs=8,tier=1)
w("fab100_bomb","FAB-100炸弹","artillery","soviet",50,2,0,0,-10,5,0,1,5,tier=1)
w("fab250_bomb","FAB-250炸弹","artillery","soviet",65,3,0,0,-15,5,0,1,5,tier=2)
w("rs82_rocket","RS-82火箭弹","rocket","soviet",38,4,0,0,-15,20,0,2,5,tier=2)
w("shkas_7_62mm","ShKAS 7.62mm","mg","soviet",14,1,0,1,0,8,1,50,2,aa=True,aa_dmg=14,aa_rng=1,aa_bs=5,tier=1)

# ---- Soviet Air units (23 total: 13 base + 10 equip) ----
def sov_air(id, name, tier, cost, init, vis, hp, bs, armor, eva, weps, fuel=20):
    u(id,name,"air","soviet",tier,cost,"flight",init,vis,
      [mem("飞行员",1,hp,bs,armor,eva,0,weps)], fuel=fuel, needs_airfield=True)

# Fighters
sov_air("sov_i16","I-16",0,400,8,2,10,55,2,8,["shkas_7_62mm","shkas_7_62mm"])
sov_air("sov_lagg3","LaGG-3",1,500,8,2,12,60,3,8,["shvak_20mm","ubs_12_7mm"])
sov_air("sov_yak9","Yak-9",2,600,9,2,12,65,3,9,["shvak_20mm","ubs_12_7mm"])
sov_air("sov_la7","La-7",3,700,9,2,14,70,3,10,["shvak_20mm","shvak_20mm"])
# Attack / Bombers
sov_air("sov_sb2","SB-2",0,400,4,2,16,55,3,4,["shkas_7_62mm","shkas_7_62mm","fab100_bomb"])
sov_air("sov_il2","IL-2",2,500,4,2,18,60,5,5,["shvak_20mm","shkas_7_62mm","fab250_bomb"])
sov_air("sov_il2m3","IL-2M3",2,550,4,2,20,65,6,5,["shvak_20mm","shkas_7_62mm","rs82_rocket"])
# Heavy fighters
sov_air("sov_pe2","Pe-2",1,500,6,2,16,60,3,5,["shkas_7_62mm","shkas_7_62mm","fab100_bomb"])
sov_air("sov_pe3","Pe-3",2,550,6,2,16,60,3,5,["shvak_20mm","shvak_20mm","fab100_bomb"])
# Recon
sov_air("sov_r5","R-5",0,200,4,4,8,50,1,5,["shkas_7_62mm"], fuel=25)
sov_air("sov_u2","U-2",0,150,3,3,8,45,1,4,[], fuel=28)
sov_air("sov_tb3","TB-3",0,500,3,2,24,50,3,2,["shkas_7_62mm","shkas_7_62mm","fab100_bomb","fab100_bomb"])
sov_air("sov_yak9r","Yak-9R侦察型",2,450,8,5,12,65,3,9,["shvak_20mm"], fuel=22)
# Soviet air equipment
sov_air("sov_i153","I-153",0,350,8,2,10,55,2,8,["shkas_7_62mm","shkas_7_62mm"])
sov_air("sov_mig3","MiG-3",1,550,9,2,12,65,3,9,["ubs_12_7mm","ubs_12_7mm"])
sov_air("sov_il4","IL-4",2,500,4,2,20,60,3,4,["shkas_7_62mm","shkas_7_62mm","fab250_bomb","fab250_bomb"])
sov_air("sov_yak1b","Yak-1B",1,500,9,2,12,65,3,9,["shvak_20mm","ubs_12_7mm"])
sov_air("sov_la5fn","La-5FN",2,600,9,2,14,65,3,9,["shvak_20mm","shvak_20mm"])
sov_air("sov_tu2","Tu-2",3,600,5,2,20,65,3,5,["shvak_20mm","fab250_bomb","fab250_bomb"])
sov_air("sov_yak3","Yak-3",3,650,10,2,12,70,3,10,["shvak_20mm","shvak_20mm"])
sov_air("sov_la7b","La-7B",3,700,10,2,14,70,3,10,["shvak_20mm","shvak_20mm","shvak_20mm"])
sov_air("sov_il10","IL-10",3,600,5,2,22,65,6,5,["shvak_20mm","shvak_20mm","fab250_bomb"])
sov_air("sov_li2","Li-2运输机",1,300,2,2,16,50,2,3,[], fuel=30)

# ---- Soviet Air Tree ----
tnb("air",0,0,None,"sov_i16")
tnb("air",1,10,"sov_i16","sov_lagg3")
tnb("air",2,20,"sov_lagg3","sov_yak9")
tnb("air",3,30,"sov_yak9","sov_la7")
tnb("air",0,5,None,"sov_sb2")
tnb("air",2,15,"sov_sb2","sov_il2")
tnb("air",2,20,"sov_il2","sov_il2m3")
tnb("air",1,10,None,"sov_pe2")
tnb("air",2,20,"sov_pe2","sov_pe3")
tnb("air",0,0,None,"sov_r5")
tnb("air",0,3,"sov_r5","sov_u2")
tnb("air",2,22,"sov_u2","sov_yak9r")
tnb("air",0,5,None,"sov_tb3")
# Air equipment
tne("air",0,5,"sov_i16","sov_i153")
tne("air",1,15,"sov_lagg3","sov_mig3")
tne("air",2,20,"sov_il2","sov_il4")
tne("air",1,15,"sov_lagg3","sov_yak1b")
tne("air",2,25,"sov_yak9","sov_la5fn")
tne("air",3,35,"sov_il2m3","sov_tu2")
tne("air",3,35,"sov_yak9","sov_yak3")
tne("air",3,40,"sov_la7","sov_la7b")
tne("air",3,35,"sov_il2m3","sov_il10")
tne("air",1,10,"sov_sb2","sov_li2")

# ---- Soviet Air Equipment items ----
eq("sov_i153","I-153","green","soviet",["air"],"sov_i153","base × 1.5","market")
eq("sov_mig3","MiG-3","purple","soviet",["air"],"sov_mig3","base × 3.0","market")
eq("sov_il4","IL-4","purple","soviet",["air"],"sov_il4","base × 3.0","market")
eq("sov_yak1b","Yak-1B","green","soviet",["air"],"sov_yak1b","base × 1.5","market")
eq("sov_la5fn","La-5FN","green","soviet",["air"],"sov_la5fn","base × 1.5","market")
eq("sov_tu2","Tu-2","purple","soviet",["air"],"sov_tu2","base × 3.0","market")
eq("sov_yak3","Yak-3","purple","soviet",["air"],"sov_yak3","base × 3.0","market")
eq("sov_la7b","La-7B","purple","soviet",["air"],"sov_la7b","base × 3.0","market")
eq("sov_il10","IL-10","purple","soviet",["air"],"sov_il10","base × 3.0","market")
eq("sov_li2","Li-2运输机","green","soviet",["air"],"sov_li2","base × 1.5","market")

# ---- Soviet Tree ----
# Infantry
tnb("infantry",0,0,None,"sov_inf_sq39")
tnb("infantry",1,10,"sov_inf_sq39","sov_inf_sq41")
tnb("infantry",1,15,"sov_inf_sq39","sov_smg_sq")
tnb("infantry",1,20,"sov_inf_sq39","sov_mg_sq")
tnb("infantry",0,5,"sov_inf_sq39","sov_mobilized_sq")
tnb("infantry",1,25,"sov_inf_sq39","sov_at_sq")
tnb("infantry",2,30,"sov_inf_sq41","sov_inf_sq43")
tnb("infantry",2,35,"sov_mg_sq","sov_mg_sq43")
tnb("infantry",3,40,"sov_smg_sq","sov_smg_sq44")
tne("infantry",1,12,"sov_inf_sq39","sov_sniper_sq")
tne("infantry",0,3,"sov_inf_sq39","sov_penal_sq")
tne("infantry",1,15,"sov_inf_sq41","sov_guard_inf41")
tne("infantry",2,30,"sov_guard_inf41","sov_guard_inf43")
tne("infantry",3,45,"sov_guard_inf43","sov_guard_inf44")
tne("infantry",1,20,"sov_inf_sq39","sov_marine_inf")
tne("infantry",1,25,"sov_inf_sq39","sov_airborne")

# Vehicle
tnb("vehicle",0,0,None,"sov_t26")                    # T0: T-26
tnb("vehicle",0,5,"sov_t26","sov_bt5")                # T0: BT-5
tnb("vehicle",1,10,"sov_bt5","sov_bt7m")              # T1: BT-7M
tnb("vehicle",1,14,"sov_bt7m","sov_t34_76_41")        # T1: T-34/76 M1940
tnb("vehicle",1,18,"sov_t34_76_41","sov_kv1_41")      # T1: KV-1 M1941
tnb("vehicle",1,8,"sov_t26","sov_t60")                # T1: T-60
tnb("vehicle",2,25,"sov_t34_76_41","sov_t34_76_42")
tnb("vehicle",2,30,"sov_kv1_41","sov_kv1s")
tnb("vehicle",2,22,"sov_t60","sov_su76m")
tnb("vehicle",2,35,"sov_kv1s","sov_su152")
tnb("vehicle",3,40,"sov_t34_76_42","sov_t34_85")
tnb("vehicle",3,45,"sov_kv1s","sov_is2")
tnb("vehicle",3,42,"sov_su76m","sov_su85")
tne("vehicle",1,12,"sov_t26","sov_ot130")
tne("vehicle",1,15,"sov_t26","sov_t28")
tne("vehicle",1,18,"sov_t26","sov_t35")
tne("vehicle",1,10,"sov_t26","sov_t70")
tne("vehicle",1,25,"sov_kv1_41","sov_kv8")
tne("vehicle",2,35,"sov_kv1s","sov_is1")
tne("vehicle",3,50,"sov_is2","sov_isu122")
tne("vehicle",3,55,"sov_su85","sov_su100")
tne("vehicle",3,60,"sov_is2","sov_is3")
tne("vehicle",3,65,"sov_su152","sov_isu152")
tne("vehicle",2,30,"sov_t34_76_42","sov_su5")
tne("vehicle",2,28,"sov_t34_76_42","sov_zsu37")
tne("vehicle",3,65,"sov_t34_85","sov_t44")

# Artillery
tnb("artillery",0,0,None,"sov_pm37")
tnb("artillery",0,5,"sov_pm37","sov_zis3")
tnb("artillery",0,8,"sov_pm37","sov_61k")
tnb("artillery",1,12,"sov_pm37","sov_45mm_at")
tnb("artillery",1,15,"sov_zis3","sov_52k")
tnb("artillery",2,20,"sov_45mm_at","sov_zis2_57mm")
tnb("artillery",2,25,"sov_zis3","sov_m30")
tnb("artillery",2,30,"sov_m30","sov_bm13")
tnb("artillery",2,22,"sov_pm37","sov_pm120")
tnb("artillery",3,35,"sov_zis2_57mm","sov_100mm_at")
tnb("artillery",3,40,"sov_m30","sov_d1")
tne("artillery",1,15,"sov_61k","sov_quad_maxim")
tne("artillery",3,45,"sov_bm13","sov_bm31")
tne("artillery",3,50,"sov_d1","sov_b4")

# Support
tnb("support",0,0,None,"sov_ba20")
tnb("support",0,5,"sov_ba20","sov_horse_supply")
tnb("support",1,10,"sov_ba20","sov_ba10")
tnb("support",1,12,"sov_horse_supply","sov_truck_supply")
tnb("support",1,8,"sov_ba20","sov_eng_sq40")
tnb("support",2,15,"sov_ba10","sov_ba64")
tnb("support",2,16,"sov_eng_sq40","sov_eng_sq43")
tnb("support",2,18,"sov_truck_supply","sov_halftrack_supply")
tnb("support",3,20,"sov_halftrack_supply","sov_heavy_truck_supply")
tne("support",2,18,"sov_eng_sq43","sov_assault_eng")
tne("support",2,20,"sov_eng_sq43","sov_bridge_eng")
tne("support",2,22,"sov_ba64","sov_mot_recce")
tne("support",2,26,"sov_ba64","sov_btr40")

# ---- Soviet Equipment items ----
eq("sov_sniper_sq","狙击班","purple","soviet",["infantry"],"sov_sniper_sq","base × 3.0","market")
eq("sov_penal_sq","惩戒营","green","soviet",["infantry"],"sov_penal_sq","base × 1.5","market")
eq("sov_guard_inf41","近卫步兵41型","purple","soviet",["infantry"],"sov_guard_inf41","base × 3.0","market")
eq("sov_guard_inf43","近卫步兵43型","purple","soviet",["infantry"],"sov_guard_inf43","base × 3.0","market")
eq("sov_guard_inf44","近卫步兵44型","orange","soviet",["infantry"],"sov_guard_inf44","base × 6.0","loot")
eq("sov_marine_inf","海军步兵","purple","soviet",["infantry"],"sov_marine_inf","base × 3.0","market")
eq("sov_airborne","空降兵","purple","soviet",["infantry"],"sov_airborne","base × 3.0","market")
eq("sov_ot130","OT-130喷火","green","soviet",["vehicle"],"sov_ot130","base × 1.5","market")
eq("sov_t28","T-28多炮塔","green","soviet",["vehicle"],"sov_t28","base × 1.5","market")
eq("sov_t35","T-35多炮塔","purple","soviet",["vehicle"],"sov_t35","base × 3.0","market")
eq("sov_t70","T-70轻坦","green","soviet",["vehicle"],"sov_t70","base × 1.5","market")
eq("sov_kv8","KV-8喷火","purple","soviet",["vehicle"],"sov_kv8","base × 3.0","loot")
eq("sov_is1","IS-1","purple","soviet",["vehicle"],"sov_is1","base × 3.0","market")
eq("sov_isu122","ISU-122","purple","soviet",["vehicle"],"sov_isu122","base × 3.0","market")
eq("sov_su100","SU-100","purple","soviet",["vehicle"],"sov_su100","base × 3.0","market")
eq("sov_is3","IS-3","orange","soviet",["vehicle"],"sov_is3","base × 6.0","loot")
eq("sov_isu152","ISU-152","purple","soviet",["vehicle"],"sov_isu152","base × 3.0","market")
eq("sov_su5","SU-5自行炮","green","soviet",["vehicle"],"sov_su5","base × 1.5","market")
eq("sov_zsu37","ZSU-37","green","soviet",["vehicle"],"sov_zsu37","base × 1.5","market")
eq("sov_quad_maxim","四管Maxim","purple","soviet",["artillery"],"sov_quad_maxim","base × 3.0","market")
eq("sov_bm31","BM-31","purple","soviet",["artillery"],"sov_bm31","base × 3.0","market")
eq("sov_b4","203mm B-4","orange","soviet",["artillery"],"sov_b4","base × 6.0","loot")
eq("sov_assault_eng","突击工兵","green","soviet",["support","infantry"],"sov_assault_eng","base × 1.5","market")
eq("sov_bridge_eng","架桥工兵","purple","soviet",["support"],"sov_bridge_eng","base × 3.0","market")
eq("sov_mot_recce","摩托化侦察队","green","soviet",["support"],"sov_mot_recce","base × 1.5","market")
eq("sov_btr40","BTR-40","purple","soviet",["support"],"sov_btr40","base × 3.0","market")
eq("sov_t44","T-44(道具)","purple","soviet",["vehicle"],"sov_t44","base × 3.0","market")

output(r'D:\项目\godot\大战略01\data\soviet', nation="soviet")
print("=== Generation Complete ===")
