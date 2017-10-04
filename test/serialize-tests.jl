function roundtrip(x)
    io = IOBuffer()
    serialize(io, x)
    deserialize(seekstart(io)) == x
end

@testset "serialisation" begin
    @testset "basic types" for x in [
            true, 'x', 1, [1, 2],
        ]
        @test roundtrip(K(x))
    end
    @testset "tables" begin
        @test roundtrip(K_Table(a=1:5))
        @test roundtrip(K_KeyTable(1;a=[:a,:b], b=[1,2]))
    end
end
