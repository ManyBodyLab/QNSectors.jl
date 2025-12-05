## TODO: Use TensorKitSectors.jl in the future.
"""
    Species

Struct for tracking quantum numbers (e.g., spin, valley) in a many-body system.
Enumerates all combinations of quantum number values with string tags.

Constructors:
- `Species(labels, values, symmetry_group)`: From label names, value tuples, and symmetry groups.
- `Species(pairs)`: From `Vector{Pair{String,Tuple}}`.
- `Species(; Sz=false, val=false)`: Convenience for spin/valley species.
"""
struct Species{N, T}
    labels::Vector{String}
    symmetry_group::Vector{Symbol}
    values::Vector{NTuple{N, T}}
    tag_dict::Dict{String, Int}
    dict::Dict{Int, NTuple{N, T}}
    inv_dict::Dict{NTuple{N, T}, Int}
end

function Base.:(==)(sp1::Species, sp2::Species)
    return sp1.labels == sp2.labels &&
        sp1.symmetry_group == sp2.symmetry_group &&
        sp1.values == sp2.values && sp1.tags == sp2.tags
end

function Base.copy(sp::Species)
    return Species(copy(sp.labels), copy(sp.symmetry_group), copy(sp.values), copy(sp.tags), copy(sp.tag_dict), copy(sp.dict), copy(sp.inv_dict))
end
function tags(sp::Species)
    return sp.tags
end
function labels(sp::Species)
    return sp.labels
end
function symmetry_groups(sp::Species)
    return sp.symmetry_group
end
function Base.iterate(sp::Species)
    return iterate(sp.tags)
end

function species_values(sp::Species)
    return vec(collect(Iterators.product(sp.values...)))
end

""" 
    abelian_species(sp::Species)
Return a new `Species` instance where all non-abelian quantum numbers are reduced to a single component.
"""
function abelian_species(sp::Species)
    abelian_qns = findall(x -> x == :U1 || string(x)[1] == 'Z', sp.symmetry_group)
    values_new = map(i -> i in abelian_qns ? sp.values[i] : tuple(sp.values[i][1]), eachindex(sp.values))
    return Species(
        copy(sp.labels),
        values_new,
        copy(sp.symmetry_group)
    )
end

function Species(x::Vector{Pair{String, X}}, symmetry_group::Vector{Symbol} = fill(:U1, length(x))) where {X}
    return Species(first.(x), last.(x), symmetry_group)
end
function Species(x::Vector{Pair{Symbol, X}}, symmetry_group::Vector{Symbol} = fill(:U1, length(x))) where {X}
    return Species(first.(x), last.(x), symmetry_group)
end
function Species(labels::Vector{Symbol}, values::Vector{X}, symmetry_group::Vector{Symbol} = fill(:U1, length(labels))) where {X}
    return Species(String.(labels), values, symmetry_group)
end
function Species(labels::Vector{String}, values::Vector{X}, symmetry_group::Vector{Symbol} = fill(:U1, length(labels))) where {X}
    values = Tuple.(values)
    if isempty(labels) && isempty(values)
        return Species(
            [""], [:U1], [tuple(0)], [""], Dict("" => 1), Dict(1 => tuple(0)), Dict(tuple(0) => 1)
        )
    end
    @assert length(labels) == length(values) == length(symmetry_group)

    tags = Vector{String}(undef, prod(length(values[i]) for i in eachindex(values); init = 1))
    counter = 1
    for i in Iterators.product([eachindex(values[k]) for k in eachindex(values)]...)
        tags[counter] = prod(
            string(labels[j]) * "=" * string(values[j][i[j]]) * "," for
                j in eachindex(labels)
        )[1:(end - 1)]
        counter += 1
    end
    @assert length(tags) == prod(length(values[i]) for i in eachindex(values); init = 1)
    dict = Dict(zip(1:length(tags), Iterators.product(values...)))
    tag_dict = Dict(zip(tags, 1:length(tags)))
    inv_dict = Dict(zip(Iterators.product(values...), 1:length(tags)))
    return Species(labels, symmetry_group, values, tags, tag_dict, dict, inv_dict)
end

function Base.length(sp::Species)
    return length(sp.tags) ## This is the total dimension of the multicomponent space
end

function Base.getindex(sp::Species, i::Int)
    return sp.tags[i]
end
function Base.eachindex(sp::Species)
    return eachindex(sp.tags)
end

## This is a constructor for the most common species
function Species(; Sz::Bool = false, val::Bool = false)
    labels = String[]
    symmetry_groups = Symbol[]
    Sz && push!(labels, standard_spin_label())
    Sz && push!(symmetry_groups, :U1)  ## TODO: Should be switched to :SU2 when non-abelian symmetries are supported
    val && push!(labels, standard_valley_label())
    val && push!(symmetry_groups, :U1)

    values = Tuple[]
    Sz && push!(values, (1, -1))
    val && push!(values, (1, -1))

    return Species(labels, values, symmetry_groups)
end

function valleys(sp::Species)
    whereisval = findfirst(isequal(standard_valley_label()), sp.labels)
    if isnothing(whereisval)
        return fill(1, length(sp))
    else
        return [sp.dict[i][whereisval] for i in eachindex(sp)]
    end
end
function distinguish_valley_from_spins(specie::Species)::Tuple{Vector{Int64}, Dict{Int64, Vector{Int64}}}
    # Check if valley is present, and form a dict of all valleys
    whereisval = findfirst(isequal(standard_valley_label()), specie.labels)
    if isnothing(whereisval)
        allvalleys = [1]
        whichvalleys = Dict(1 => [x for x in eachindex(specie.tags)])
    else
        allvalleys = unique([v[whereisval] for (i, v) in specie.dict])
        whichvalleys = Dict(
            val => [i for (i, v) in specie.dict if v[whereisval] == val]
                for val in allvalleys
        )
    end
    return allvalleys, whichvalleys
end
