module RootHitFiles

import Base, Tables

using Mmap: mmap
using Parsers
using StaticArrays

export RootHitFile

"""
    RootHitFile(file::Union{IOStream, AbstractString})

represents a `.root.hits` file, which can be iterated or read to yield events, which are tables of
hits.
"""
struct RootHitFile
    stream::IOBuffer
end

RootHitFile(stream::IOStream) = RootHitFile(IOBuffer(mmap(stream)))
RootHitFile(path::AbstractString) = occursin(r".root.hits$", path) ? RootHitFile((open(path))) :
    throw(ArgumentError("$path is not a .root.hits file"))

EventTuple = NamedTuple{
    (:eventnum, :pos, :E, :time, :particleID, :trkID, :trkparentID, :volumeID),
    Tuple{
        Vector{Int32}, Vector{SVector{3, Float32}}, Vector{Float32}, Vector{Float32},
        Vector{Int32}, Vector{Int32}, Vector{Int32}, Vector{String}
    }
}

function Base.read(f::RootHitFile)
    eventnum  = Parsers.parse(Int32, f.stream)
    hitcount  = Parsers.parse(Int32, f.stream)
    primcount = Parsers.parse(Int32, f.stream)

    # skip newline
    skip(f.stream, 1)

    pos         = Vector{SVector{3, Float32}}(undef, hitcount)
    E           = Vector{            Float32}(undef, hitcount)
    time        = Vector{            Float32}(undef, hitcount)
    particleID  = Vector{              Int32}(undef, hitcount)
    trkID       = Vector{              Int32}(undef, hitcount)
    trkparentID = Vector{              Int32}(undef, hitcount)
    volumeID    = Vector{             String}(undef, hitcount)

    @inbounds for i in 1:hitcount
        pos[i] = SVector{3, Float32}(
            Parsers.parse(Float32, f.stream),
            Parsers.parse(Float32, f.stream),
            Parsers.parse(Float32, f.stream)
        )
        E[i]           = Parsers.parse(Float32, f.stream)
        time[i]        = Parsers.parse(Float32, f.stream)
        particleID[i]  = Parsers.parse(Int32, f.stream)
        trkID[i]       = Parsers.parse(Int32, f.stream)
        trkparentID[i] = Parsers.parse(Int32, f.stream)
        volumeID[i]    = String(readuntil(f.stream, UInt8('\n')))
    end

    return EventTuple((
        fill(eventnum, (hitcount,)), pos, E, time,
        particleID, trkID, trkparentID, volumeID
    ))
end

Base.eof(f::RootHitFile) = eof(f.stream)

function Base.iterate(f::RootHitFile, state = nothing)
    eof(f) && return nothing
    return read(f), nothing
end

Base.IteratorSize(::Type{RootHitFile}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{RootHitFile}) = Base.HasEltype()
Base.eltype(f::RootHitFile) = EventTuple

Tables.partitions(f::RootHitFile) = f

end # RootHitFiles
