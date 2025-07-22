export type Vector3 = {X: number, Y: number, Z: number}

export type HeatType = "good" | "bad" | "egg"

export type HeatSource = {
	part: Part,
	heatType: HeatType,
	value: number,
	position: Vector3,
	id: string,
}

export type EggRarity = "common" | "uncommon" | "rare" | "epic" | "legendary"

export type PlayerData = {
	money: number,
	rebirthTokens: number,
	rebirthLevel: number,
	eggsFound: number,
	upgrades: {[string]: boolean},
	totalMoneyCollected: number,
	lastDailyReward: number,
}

export type Temperature = {
	distance: number,
	heatType: HeatType?,
	intensity: number,
}

export type Predator = {
	model: Model,
	tier: number,
	speed: number,
	damage: number,
	target: Player?,
	state: "idle" | "chasing" | "attacking",
}

export type Upgrade = {
	name: string,
	cost: number,
	description: string,
	effect: (player: Player) -> (),
}

export type EggData = {
	rarity: EggRarity,
	moneyReward: {min: number, max: number},
	tokenReward: number,
	spawnRate: number,
	color: Color3,
}

return {}