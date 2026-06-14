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

return module