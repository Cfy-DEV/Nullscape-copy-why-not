local module = {}

export type Timer =
{
	Time: number,
	Threshold: number,
	Done: any,
	Loop: any,
	Trove: any,
	RuntimeTrove: any,
	CurrentValue: NumberValue?,
	CurrentThreshold: number,
	Started: boolean,

	Resume: (self: Timer) -> (),
	Pause: (self: Timer) -> (),
	Destroy: (self: Timer) -> (),
	Reset: (self: Timer, time: number) -> (),
	BindToValue: (self: Timer, value: NumberValue) -> (),
	UnbindFromValue: (self: Timer) -> (),
}

export type Chunk = {
	WorldCenter: Vector3,
	Size: Vector3,

	Chunks: {
		[string]: {BasePart}
	},

	NodeToChunk: {
		[BasePart]: string
	},

	NodeIndex: {
		[BasePart]: number
	},

	RebuildChunks: (self: Chunk) -> {[string]: {BasePart}},
	SetWorldCenter: (self: Chunk, center: Vector3) -> (),
	GetChunksInRadius: (self: Chunk, centerPos: Vector3, radius: number) -> {string},
	AddNode: (self: Chunk, node: BasePart) -> string,
	GetPartsInRadius: (self: Chunk, pos: Vector3, radius: number) -> {BasePart},
	GetAllParts: (self: Chunk) -> {BasePart},
	GetChunkAtPosition: (self: Chunk, pos: Vector3) -> (string, boolean),
	GetPartsInChunk: (self: Chunk, key: string) -> {BasePart}?,
	RemoveNode: (self: Chunk, node: BasePart) -> (),
	Cleanup: (self: Chunk) -> (),
	Destroy: (self: Chunk) -> (),
}

export type WeightedRNG = {
	RemoveItemOnRoll: boolean,
	TotalWeight: number,
	Items: { [string]: number },

	AddItem: (self: WeightedRNG, item: string, weight: number) -> (),
	RemoveItem: (self: WeightedRNG, item: string) -> boolean,
	Clean: (self: WeightedRNG) -> (),
	Roll: (self: WeightedRNG) -> string?,
}

export type PercentageItem = {
	Name: string,
	Chance: number,
}

export type PercentageRNG = {
	RemoveItemOnRoll: boolean,
	Range: number,
	ReturnNilWhenNone: boolean,
	Items: {
		Info: { PercentageItem },
		Names: { [string]: number },
	},

	AddItem: (self: PercentageRNG, item: string, percentage: number) -> (),
	RemoveItem: (self: PercentageRNG, item: string) -> boolean,
	Clean: (self: PercentageRNG) -> (),
	Roll: (self: PercentageRNG) -> string?,
}

export type RNGModule = {
	NewWeightedRNG: () -> WeightedRNG,
	NewPercentualRNG: () -> PercentageRNG,
}

return module