@testset "temporal" begin
    let x = Q.TimeStamp(2001, 1, 2, 3, 4, 5, 123, 456, 789)
        @test Dates.days(x) == Dates.value(Date(2001, 1, 2))
        @test Dates.year(x) == 2001
        @test Dates.month(x) == 1
        @test Dates.day(x) == 2
        @test Dates.hour(x) == 3
        @test Dates.minute(x) == 4
        @test Dates.second(x) == 5
        @test Dates.millisecond(x) == 123
        @test Dates.microsecond(x) == 456
        @test Dates.nanosecond(x) == 789
        @test string(x) == show_to_string(x) ==
            "2001.01.02D03:04:05.123456789"
    end
    let x = Q.Month(2012, 3)
        @test Dates.year(x) == 2012
        @test Dates.month(x) == 3
        @test string(x) == show_to_string(x) == "2012.03m"
    end
    let x = Q.Minute(1, 2)
        @test Dates.hour(x) == 1
        @test Dates.minute(x) == 2
        @test Dates.second(x) == 0
        @test Dates.millisecond(x) == 0
        @test Dates.microsecond(x) == 0
        @test Dates.nanosecond(x) == 0
        @test string(x) == show_to_string(x) == "01:02"
    end
    let x = Q.Second(1, 2, 3)
        @test Dates.hour(x) == 1
        @test Dates.minute(x) == 2
        @test Dates.second(x) == 3
        @test Dates.millisecond(x) == 0
        @test Dates.microsecond(x) == 0
        @test Dates.nanosecond(x) == 0
        @test string(x) == show_to_string(x) == "01:02:03"
    end
    let x = Q.Time(1, 2, 3, 123)
        @test Dates.hour(x) == 1
        @test Dates.minute(x) == 2
        @test Dates.second(x) == 3
        @test Dates.millisecond(x) == 123
        @test Dates.microsecond(x) == 0
        @test Dates.nanosecond(x) == 0
        @test string(x) == show_to_string(x) == "01:02:03.123"
    end
end
