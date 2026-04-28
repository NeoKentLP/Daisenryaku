enum TerrainType {
	PLAIN,       # 平地
	FOREST,      # 森林
	MOUNTAIN,    # 山地
	RIVER,       # 河流
	ROAD,        # 道路
	CITY,        # 城市
	HQ,          # 指挥部
	FACTORY,     # 工厂
	AIRPORT,     # 机场
	PORT,        # 港口
	RUINS,       # 废墟
}

enum UnitType {
	INFANTRY,         # 步兵
	MECHANIZED,       # 机械化步兵
	TANK,             # 坦克
	ARTILLERY,        # 火炮
	RECON,            # 侦察车
	ANTI_AIR,         # 防空单位
	TRANSPORT,        # 运输车
}

enum Team {
	PLAYER,
	ENEMY,
}

enum ActionState {
	IDLE,
	SELECTED,
	MOVING,
	ATTACKING,
	DONE,
}

enum Phase {
	PLAYER_TURN,
	ENEMY_TURN,
	GAME_OVER,
	VICTORY,
}
