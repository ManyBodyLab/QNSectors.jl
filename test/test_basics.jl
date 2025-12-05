using QNSectors
using Test

@testset "QNSectors" begin
    @testset "Species" begin
        @testset "Basic constructor" begin
            # Empty species
            sp_empty = Species(String[], Tuple[], Symbol[])
            @test length(sp_empty) == 1
            @test sp_empty[1] == ""

            # Single label species
            sp_single = Species(["spin"], [(1, -1)], [:U1])
            @test length(sp_single) == 2
            @test "spin=1" in sp_single.tags
            @test "spin=-1" in sp_single.tags

            sp_single = Species(["valley"=> (1, -1)], [:U1])
            @test sp_single == Species([:valley => (1, -1)], [:U1])
        end

        @testset "Convenience constructor" begin
            # No species
            sp_none = Species(; Sz = false, val = false)
            @test length(sp_none) == 1

            # Spin only
            sp_spin = Species(; Sz = true, val = false)
            @test length(sp_spin) == 2
            @test standard_spin_label() in labels(sp_spin)

            # Valley only
            sp_val = Species(; Sz = false, val = true)
            @test length(sp_val) == 2
            @test standard_valley_label() in labels(sp_val)

            # Both
            sp_both = Species(; Sz = true, val = true)
            @test length(sp_both) == 4
            @test standard_spin_label() in labels(sp_both)
            @test standard_valley_label() in labels(sp_both)
        end

        @testset "Symbol constructor" begin
            sp_sym = Species([:a, :b], [(0, 1), (0, 1)], [:U1, :U1])
            @test length(sp_sym) == 4
        end

        @testset "Species iteration and indexing" begin
            sp = Species(["spin"], [(1, -1)], [:U1])
            @test sp[1] == "spin=1"
            @test sp[2] == "spin=-1"
            @test collect(eachindex(sp)) == [1, 2]

            # Test iterate
            iter_result = iterate(sp)
            @test iter_result !== nothing
            @test iter_result[1] == "spin=1"
        end

        @testset "Species copy" begin
            sp = Species(["spin"], [(1, -1)], [:U1])
            sp_copy = copy(sp)
            @test tags(sp_copy) == tags(sp)
            @test labels(sp_copy) == labels(sp)
            @test symmetry_groups(sp_copy) == symmetry_groups(sp)
        end

        @testset "species_values" begin
            sp = Species(["a", "b"], [(0, 1), (0, 1, 2)], [:U1, :U1])
            vals = species_values(sp)
            @test length(vals) == 6
            @test (0, 0) in vals
            @test (1, 2) in vals
        end

        @testset "abelian_species" begin
            sp = Species(["spin", "other"], [(1, -1), (0, 1)], [:SU2, :U1])
            sp_ab = abelian_species(sp)
            # SU2 should be restricted to first component
            @test length(sp_ab) == 2  # 1 * 2
        end

        @testset "valleys function" begin
            # Without valley
            sp_no_val = Species(["spin"], [(1, -1)], [:U1])
            @test all(valleys(sp_no_val) .== 1)

            # With valley
            sp_val = Species(; Sz = false, val = true)
            v = valleys(sp_val)
            @test 1 in v
            @test -1 in v
        end

        @testset "distinguish_valley_from_spins" begin
            # Without valley
            sp_no_val = Species(["spin"], [(1, -1)], [:U1])
            allv, whichv = distinguish_valley_from_spins(sp_no_val)
            @test allv == [1]
            @test 1 in keys(whichv)

            # With valley
            sp_val = Species(; Sz = false, val = true)
            allv, whichv = distinguish_valley_from_spins(sp_val)
            @test length(allv) == 2
            @test 1 in allv
            @test -1 in allv
        end

        @testset "species hdf5" begin 
            mktempdir() do tmpdir
                sp = Species(["spin", "valley"], [(1, -1), (1, -1)], [:U1, :U1])
                filename = joinpath(tmpdir, "species_test.h5")

                h5open(filename, "w") do f
                    HDF5.write(f, "species", sp)
                end

                sp_read = h5open(filename, "r") do f
                    HDF5.read(f, "species", Species)
                end
                @test sp == sp_read
            end
        end
    end
end
