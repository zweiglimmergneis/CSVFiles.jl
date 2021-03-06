using CSVFiles
using IteratorInterfaceExtensions
using TableTraits
using FileIO
using DataValues
using Test

@testset "CSVFiles" begin

@testset "basic" begin
    array = collect(load(joinpath(@__DIR__, "data.csv")))
    @test length(array) == 3
    @test array == [(Name="John",Age=34.,Children=2),(Name="Sally",Age=54.,Children=1),(Name="Jim",Age=23.,Children=0)]

    output_filename = tempname() * ".csv"

    try
        array |> save(output_filename)

        array2 = collect(load(output_filename))

        @test array == array2
    finally
        GC.gc()
        rm(output_filename)
    end
end

@testset "traits" begin
    csvf = load(joinpath(@__DIR__, "data.csv"))

    @test IteratorInterfaceExtensions.isiterable(csvf) == true
    @test TableTraits.isiterabletable(csvf) == true
    @test TableTraits.supports_get_columns_copy_using_missing(csvf) == true
end

@testset "missing values" begin
    array3 = [(a=DataValue(3),b="df\"e"),(a=DataValue{Int}(),b="something")]

    @testset "default" begin
        output_filename2 = tempname() * ".csv"

        try
            array3 |> save(output_filename2)
        finally
            rm(output_filename2)
        end
    end

    @testset "alternate" begin
        output_filename2 = tempname() * ".csv"

        try
            array3 |> save(output_filename2, nastring="")
        finally
            rm(output_filename2)
        end
    end
end

@testset "Column interface" begin
    csvf2 = load(joinpath(@__DIR__, "data.csv"))
    @test TableTraits.supports_get_columns_copy_using_missing(csvf2) == true
    data = TableTraits.get_columns_copy_using_missing(csvf2)
    @test data == (Name=["John", "Sally", "Jim"], Age=[34.,54.,23.], Children=[2,1,0])
end

@testset "Less Basic" begin
    array = [(Name="John",Age=34.,Children=2),(Name="Sally",Age=54.,Children=1),(Name="Jim",Age=23.,Children=0)]
    @testset "remote loading" begin
        rem_array = collect(load("https://raw.githubusercontent.com/queryverse/CSVFiles.jl/v0.2.0/test/data.csv"))
        @test length(rem_array) == 3
        @test rem_array == array
    end

    @testset "can round trip TSV" begin
        output_filename3 = tempname() * ".tsv"
        
        try
            array |> save(output_filename3)
            
            array4 = collect(load(output_filename3))
            @test length(array4) == 3
            @test array4 == array
        finally
            GC.gc()
            rm(output_filename3)
        end
    end
    
    @testset "no quote" begin
        output_filename4 = tempname() * ".csv"

        try
            @show output_filename4
            array |> save(output_filename4, quotechar=nothing)

        finally
            GC.gc()
            rm(output_filename4)
        end
    end
end

@testset "Streams" begin
    data = [(Name="John",Age=34.,Children=2),(Name="Sally",Age=54.,Children=1),(Name="Jim",Age=23.,Children=0)]

    @testset "CSV"  begin
        stream = IOBuffer()
        mark(stream)
        fileiostream = FileIO.Stream(FileIO.format"CSV", stream)
        save(fileiostream, data)
        reset(stream)
        mark(stream)
        csvstream = load(fileiostream)
        reloaded_data = collect(csvstream)
        @test IteratorInterfaceExtensions.isiterable(csvstream)        
        @test TableTraits.isiterabletable(csvstream)
        @test TableTraits.supports_get_columns_copy_using_missing(csvstream)
        @test reloaded_data == data

        reset(stream)
        csvstream = load(fileiostream)
        reloaded_data2 = TableTraits.get_columns_copy_using_missing(csvstream)
        @test reloaded_data2 == (Name=["John", "Sally", "Jim"], Age=[34., 54., 23.], Children=[2, 1, 0])
    end

    @testset "TSV" begin
        stream = IOBuffer()
        mark(stream)
        fileiostream = FileIO.Stream(FileIO.format"TSV", stream)
        save(fileiostream, data)
        reset(stream)
        mark(stream)
        csvstream = load(fileiostream)
        reloaded_data = collect(csvstream)
        @test IteratorInterfaceExtensions.isiterable(csvstream)
        @test TableTraits.isiterabletable(csvstream)
        @test TableTraits.supports_get_columns_copy_using_missing(csvstream)
        @test reloaded_data == data

        reset(stream)
        csvstream = load(fileiostream)
        reloaded_data2 = TableTraits.get_columns_copy_using_missing(csvstream)
        @test reloaded_data2 == (Name=["John", "Sally", "Jim"], Age=[34., 54., 23.], Children=[2, 1, 0])
    end
end

end # Outer-most testset

