using JuMP

# file to create .dat file for the opl model

for i=1:9
    str = "../data/tests/test0$(i).txt"
    println(str)

    A = readdlm(str, ' ')

    B = A[1:size(A,1)-1,:]

    str = "../data/tests/test0$(i).dat"

    open(str, "w") do io
        writedlm(io, B, ' ')
    end

    open("../data/dat/test0$(i).dat", "w") do io
        o=open(str)
        string = "n=$(size(B,1));\n"
        write(io, string)
        string = "a=[\n"
        write(io, string)
        for i=1:size(B,1)
            temp=readline(o)
            string = "\u005B" * temp * "\u005D,\n"
            write(io, string)
        end
        close(o)
        string = "\u005D;"
        write(io, string)
        close(io)
    end

end
