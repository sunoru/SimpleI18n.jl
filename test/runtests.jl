using Test
using Internationalization

@testset "Internationalization.jl" begin
    locales_dir = joinpath(@__DIR__, "locales")

    setup_i18n(
        "zh-Hans",
        locales_dir = locales_dir,
        fallback = "en"
    )
    @test i"hello-world" == "你好世界！"

    setup_i18n("en")
    @test i18n("hello-world") == "Hello world!"

    setup_i18n("sv")
    @test i"hello-world" == "Hej världen!"

    setup_i18n("???")
    @test i"hello-world" == "Hello world!"
end