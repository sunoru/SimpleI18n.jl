using Test
using SimpleI18n

# Use in a module
module Foo

using SimpleI18n

const Font = Ref("font-1")

function __init__()
    # Setup locale with one file containing data for all languages.
    SimpleI18n.setup(joinpath(@__DIR__, "../test/locales-2.yaml"), "en")
    # We can change the font when locale is changed
    SimpleI18n.on_language_changed() do value, previous
        Font[] = startswith(value, "zh") ? "font-2" : "font-1"
    end
    nothing
end

f1() = i"hello-world"
f2() = i18n("ttt")

end

@testset "Internationalization.jl" begin
    # Initial set-up with a folder containing locales.
    locales_dir = joinpath(@__DIR__, "locales")
    SimpleI18n.setup(locales_dir, "zh-Hans")

    set_language("sv")
    # Use `@i_str` to translate strings
    @test i"hello-world" == "Hej världen!"

    # Change language
    set_language("en")
    @test i18n("hello-world") == "Hello world!"
    # "en_US" will also use "en" automatically if not present
    set_language("en_US")
    @test i"hello-world" == "Hello world!"

    # Similarly, language codes such as "zh" will also use "zh-Hans".
    set_language("zh", "en")
    @test i"hello-world" == "你好世界！"
    # Use dot to access nested data
    @test i"nested.nested2" == "嵌套内容"
    # Should fall back to "en"
    @test i"nested.nested2.nested3" == "Some nested text"

    set_language("???")
    # Unknown language would also fall back to "en"
    @test i"hello-world" == "Hello world!"

    using .Foo
    @test Foo.f1() == "Hello, world!"
    @test Foo.Font[] == "font-1"
    set_language("zh")
    @test Foo.f1() == "你好，世界！"
    @test Foo.f2() == "繁體中文"
    @test Foo.Font[] == "font-2"

end