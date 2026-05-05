import re

with open(r'D:\项目\godot\大战略01\data\_gen_all.py', 'r', encoding='utf-8') as f:
    c = f.read()

# German tank guns
german_guns = {
    'kwk36_37mm': 5,   # was 4
    'kwk39_50mm': 6,   # was 5
    'kwk40_75mm_L43': 9,  # was 7
    'kwk40_75mm_L48': 9,  # was 7
    'stuk40_75mm': 9,   # was 7
    'kwk42_75mm_L70': 11, # was 9
    'kwk36_88mm': 12,  # was 10
    'kwk43_88mm': 13,  # was 12
    'stuk42_75mm_L70': 11, # was 9
}

# Soviet tank guns
soviet_guns = {
    'l11_76mm': 7,    # was 5
    'f34_76mm': 8,    # was 6
    'zis5_76mm': 8,   # was 6
    'd5t_85mm': 10,   # was 8
    'zis_s53_85mm': 10, # was 8
    'd25t_122mm': 12, # was 10
    'ml20s_152mm': 11, # was 9
    'd10_100mm': 10,  # was 9
}

# Soviet AA/AT guns used as tank guns in some vehicles
# zis3_76mm: for SU-76, keep at 8 (was 6)
# 52k_85mm: for AA use, keep

all_changes = {}
all_changes.update(german_guns)
all_changes.update(soviet_guns)

# Apply changes
changes_made = 0
for gun_id, new_pen in all_changes.items():
    # Pattern: w("gun_id","name","tank_gun",...,PEN,...)
    pattern = r'(w\("' + gun_id + r'"[^)]+\bpenetration\b:\d+)'
    simple_pattern = '"' + gun_id + '"[^;]*?penetration[' ']*[' ',]*(\d+)'
    
    # Try simpler approach - find the w() call and replace pen value
    idx = c.find('"' + gun_id + '"')
    if idx < 0:
        idx = c.find('"' + gun_id)
    if idx >= 0:
        # Find "penetration":XX in this w() call context
        # w() uses positional args: w(id,name,type,nation,dmg,pen,...)
        # Find the w( before this ID
        start = c.rfind('w("', 0, idx)
        if start < 0:
            continue
        # Find the matching closing )
        # Count brackets
        paren_count = 0
        end = start
        for j in range(start, len(c)):
            if c[j] == '(':
                paren_count += 1
            elif c[j] == ')':
                paren_count -= 1
                if paren_count == 0:
                    end = j
                    break
        w_call = c[start:end+1]
        # w() positional: id,name,type,nation,dmg,pen,...
        parts = w_call.split(',')
        if len(parts) >= 6:
            # 5th positional arg (0-indexed) = penetration
            # account for string values with commas in them
            # Actually simpler: just find the call and regex replace the 6th comma-separated value
            # w("id","name","type","nation",dmg,pen,rmin,rmax,bs,sup,cqb,ammo,sc)
            # pen is the 6th parameter (index 5)
            old_call = c[start:end+1]
            # split by commas but respect quoted strings
            params = []
            current = ''
            in_quote = False
            for ch in old_call[2:-1]:  # skip w( and )
                if ch == '"':
                    in_quote = not in_quote
                    current += ch
                elif ch == ',' and not in_quote:
                    params.append(current.strip())
                    current = ''
                else:
                    current += ch
            if current:
                params.append(current.strip())
            
            if len(params) >= 6:
                old_pen = params[5]
                if old_pen.isdigit():
                    old_val = int(old_pen)
                    if old_val != new_pen:
                        params[5] = str(new_pen)
                        new_call = 'w(' + ','.join(params) + ')'
                        c = c[:start] + new_call + c[end+1:]
                        changes_made += 1
                        print('Updated %s: PEN %d -> %d' % (gun_id, old_val, new_pen))

print('\nTotal changes: %d' % changes_made)

with open(r'D:\项目\godot\大战略01\data\_gen_all.py', 'w', encoding='utf-8') as f:
    f.write(c)
