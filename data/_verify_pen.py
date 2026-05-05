import json

def arm(data, vid):
    return [x for x in data if x['id'] == vid][0]['members'][0]['armor']

def pen(db, gid):
    return db[gid]['penetration']

gv, gtg, _ = [None]*3
sv, stg, _ = [None]*3

def load(nation):
    u = json.load(open('D:/项目/godot/大战略01/data/%s/units.json' % nation, encoding='utf-8'))
    w = json.load(open('D:/项目/godot/大战略01/data/%s/weapons.json' % nation, encoding='utf-8'))
    tg = {x['id']: x for x in w if x['type'] == 'tank_gun'}
    return u, tg

gv, gtg = load('germany')
sv, stg = load('soviet')

def prob(p, a):
    d = p - a
    if d >= 3: return 100
    if d == 2: return 90
    if d == 1: return 70
    if d == 0: return 50
    if d == -1: return 20
    if d == -2: return 5
    return 0

print('=== REVISED MATRIX ===')
print()

matchups = [
    ('PzIV L43 vs T-34/76',   pen(gtg,'kwk40_75mm_L43'), arm(gv,'ger_pz4g'), pen(stg,'f34_76mm'), arm(sv,'sov_t34_76_42')),
    ('F-34 vs PzIV',          pen(stg,'f34_76mm'), arm(sv,'sov_t34_76_42'), pen(gtg,'kwk40_75mm_L43'), arm(gv,'ger_pz4g')),
    ('Panther L70 vs T-34/85',pen(gtg,'kwk42_75mm_L70'), arm(gv,'ger_pz5d'), pen(stg,'zis_s53_85mm'), arm(sv,'sov_t34_85')),
    ('85mm vs Panther',       pen(stg,'zis_s53_85mm'), arm(sv,'sov_t34_85'), pen(gtg,'kwk42_75mm_L70'), arm(gv,'ger_pz5d')),
    ('88mm vs IS-2',          pen(gtg,'kwk36_88mm'), arm(gv,'ger_pz6e'), pen(stg,'d25t_122mm'), arm(sv,'sov_is2')),
    ('122mm vs Tiger',        pen(stg,'d25t_122mm'), arm(sv,'sov_is2'), pen(gtg,'kwk36_88mm'), arm(gv,'ger_pz6e')),
    ('88mm vs KV-1S',         pen(gtg,'kwk36_88mm'), arm(gv,'ger_pz6e'), pen(stg,'zis5_76mm'), arm(sv,'sov_kv1s')),
]

for name, p_atk, a_atk, p_def, a_def in matchups:
    atk_prob = prob(p_atk, a_def)
    def_prob = prob(p_def, a_atk)
    print('%s: %.30s' % (name, ''))
    print('  Attacker PEN=%d vs Defender armor=%d → %d%%' % (p_atk, a_def, atk_prob))
    print('  Defender PEN=%d vs Attacker armor=%d → %d%%' % (p_def, a_atk, def_prob))
    print()

# Quick check: all guns correct?
print('=== VERIFY PEN VALUES ===')
for gid, name in [('kwk36_37mm','37mm'),('kwk39_50mm','50mm'),('kwk40_75mm_L43','L43'),
                  ('kwk42_75mm_L70','L70'),('kwk36_88mm','88mm Tiger'),
                  ('kwk43_88mm','88mm TigerII'),('f34_76mm','F-34'),('zis_s53_85mm','85mm'),
                  ('d25t_122mm','122mm')]:
    db = gtg if gid in gtg else stg
    print('  %s: PEN=%d' % (name, pen(db, gid)))
