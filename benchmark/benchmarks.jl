using RootHitFiles, BenchmarkTools

const eventpath = realpath(joinpath(dirname(pathof(RootHitFiles)), "..", "test", "test.root.hits"))

SUITE = BenchmarkGroup()

SUITE["construct"] = @benchmarkable RootHitFile($eventpath)

SUITE["read"] = @benchmarkable read(RootHitFile($eventpath))

SUITE["collect"] = @benchmarkable collect(RootHitFile($eventpath))
