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

return module