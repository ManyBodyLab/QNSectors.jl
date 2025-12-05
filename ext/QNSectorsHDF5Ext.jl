module QNSectorsHDF5Ext

using HDF5
using QNSectors: Species

function HDF5.write(
        parent::Union{HDF5.File, HDF5.Group}, name::AbstractString, species::Species
    )
    g = create_group(parent, name)
    HDF5.attributes(g)["type"] = "Species"
    HDF5.attributes(g)["version"] = 1
    write(g, "labels", species.labels)
    write(g, "symmetry_group", string.(species.symmetry_group))

    # write values as a subgroup with numbered datasets for portability
    vals_grp = create_group(g, "values")
    HDF5.attributes(vals_grp)["length"] = length(species.values)
    for (i, v) in enumerate(species.values)
        # write each tuple as a plain integer vector dataset
        write(vals_grp, "v$(i)", collect(v))
    end
    close(vals_grp)
    close(g)
    return nothing
end

function HDF5.read(
        parent::Union{HDF5.File, HDF5.Group}, name::AbstractString, ::Type{Species}
    )
    g = open_group(parent, name)
    if read(HDF5.attributes(g)["type"]) != "Species"
        @warn "HDF5 group or file does not contain Species data"
    end
    labels = read(g, "labels")
    symmetry_group = Symbol.(read(g, "symmetry_group"))

    vals_grp = open_group(g, "values")
    nvals = read(HDF5.attributes(vals_grp)["length"])
    values = Vector{Tuple}(undef, nvals)
    for i in 1:nvals
        arr = read(vals_grp, "v$(i)")
        values[i] = Tuple(arr)
    end
    close(vals_grp)
    close(g)

    return Species(labels, values, symmetry_group)
end
end
