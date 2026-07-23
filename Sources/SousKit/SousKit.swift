// SousKit is the umbrella module. It re-exports the faithful layer from SousCore, and from
// v0.6 it will add the semantic layer (reference data, identity, durations, and the units a
// target may be stated in) on top of it. Importing SousKit therefore makes every SousCore
// symbol available without a separate import.
@_exported import SousCore
