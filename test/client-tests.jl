@testset "Communications" begin
  server() do port
    @test port isa Int32
    @test hget(("", port), "1 2 3") == [1, 2, 3]
    @test 42 == hopen(port) do h
      hget(h, "42")
    end
    @test_throws KdbException hget(("", port), "(..")
    @test "type" == try
      hget(("", port), "1+`")
    catch e
      e.s
    end
    hopen(port) do h
      auto_r0(k, h, "42") do x
        @test xj(x) == 42
      end
      auto_r0(k, h, "{y}", kj(1), kj(42)) do x
        @test xj(x) == 42
      end
      auto_r0(k, h, "{z}", kj(1), kj(2), kj(42)) do x
        @test xj(x) == 42
      end
      auto_r0(k, h, "{[a;b;c;d]d}", kj(1), kj(2), kj(3), kj(42)) do x
        @test xj(x) == 42
      end
      auto_r0(k, h, "{[a;b;c;d;e]e}",
              kj(1), kj(2), kj(3), kj(4), kj(42)) do x
        @test xj(x) == 42
      end
      auto_r0(k, h, "{[a;b;c;d;e;f]f}",
              kj(1), kj(2), kj(3), kj(4), kj(5), kj(42)) do x
        @test xj(x) == 42
      end
      auto_r0(k, h, "{[a;b;c;d;e;f;g]g}",
              kj(1), kj(2), kj(3), kj(4), kj(5), kj(6), kj(42)) do x
        @test xj(x) == 42
      end
      auto_r0(k, h, "{[a;b;c;d;e;f;g;h]h}",
              kj(1), kj(2), kj(3), kj(4), kj(5), kj(6), kj(7), kj(42)) do x
        @test xj(x) == 42
      end
      @test 0 == hget(h, "0")
      @test 1 == hget(h, "{[a]a}", 1)
      @test 2 == hget(h, "{[a;b]b}", 1, 2)
      @test 3 == hget(h, "{[a;b;c]c}", 1, 2, 3)
      @test 4 == hget(h, "{[a;b;c;d]d}", 1, 2, 3, 4)
      @test 5 == hget(h, "{[a;b;c;d;e]e}", 1, 2, 3, 4, 5)
      @test 6 == hget(h, "{[a;b;c;d;e;f]f}", 1, 2, 3, 4, 5, 6)
      @test 7 == hget(h, "{[a;b;c;d;e;f;g]g}", 1, 2, 3, 4, 5, 6, 7)
      @test 8 == hget(h, "{[a;b;c;d;e;f;g;h]h}", 1, 2, 3, 4, 5, 6, 7, 8)
    end
  end # server()
  server(user="star:shine") do port
    @test 0 < (h = khpu("", port, "star:shine"); hclose(h); h)
    @test 0 < (h = khpun("", port, "star:shine", 10); hclose(h); h)
    @test 42 == hopen(port=port, user="star:shine") do h
      hget(h, "42")
    end
    @test 42 == hopen(port=port, user="star:shine", timeout=1) do h
      hget(h, "42")
    end
  end
end

