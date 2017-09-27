function roundtrip(x)
    io = IOBuffer()
    serialize(io, x)
    deserialize(seekstart(io)) == x
end

@testset "serialisation" for x in [
        1, [1, 2],
    ]
    @test roundtrip(K(x))
end
