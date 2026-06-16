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
	Chunks: { [string]: { Instance } },

	GetChunksInRadius: (self: Chunk, centerPos: Vector3, radius: number) -> { string },
	AddNode: (self: Chunk, node: Instance) -> (),
	GetPartsInRadius: (self: Chunk, pos: Vector3, radius: number) -> { Instance },
	GetAllParts: (self: Chunk) -> { Instance },
	GetChunkAtPosition: (self: Chunk, pos: Vector3) -> { Instance }?,
	GetPartsInChunk: (self: Chunk, pos: Vector3) -> { Instance },
	RemoveNode: (self: Chunk, node: Instance) -> (),
	Destroy: (self: Chunk) -> (),
	Cleanup: (self: Chunk) -> (),
}

return module