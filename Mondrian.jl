
using Distributions
using Plots
include("Axis_Aligned_Box.jl")

function Mondrian_process(Θ::Axis_Aligned_Box, Tₗ = 5)
    cuts = []
    M = Mondrian_started_at(Θ::Axis_Aligned_Box,0, cuts, Tₗ)
    a = []
    for i in 1:length(cuts)
        push!(a,cuts[i][4])
    end
    cuts = cuts[sortperm(a)]
    return M,cuts
end

function Mondrian_started_at(Θ::Axis_Aligned_Box,t₀,cuts, Tₗ = 5)
    LD = Linear_dimension(Θ)
    T = rand(Exponential(1/LD))
    d,x = sample_split_dimension(Θ)
    if(T+t₀ >= Tₗ)
        return (t₀,t₀+T,d,x)
    end
    c=(x,d,Θ.Intervals,t₀+T)
    push!(cuts,c)
    Θᴸ = copy(Θ)
    Θᴿ = copy(Θ)
    Θᴸ.Intervals[d,2]=x
    Θᴿ.Intervals[d,1]=x
    Mᴸ = Mondrian_started_at(Θᴸ,t₀+T,cuts,Tₗ)
    Mᴿ = Mondrian_started_at(Θᴿ,t₀+T,cuts,Tₗ)
end

function show_mondrian_split_2d(split, times=false)
    plot()
    for i in 1:size(split,1)
        d = split[i][2]
        int = split[i][3]
        if times
            label = round(c[i][end],3)
        else
            label = ""
        end
        if (d == 1)
            x = linspace(int[2,1],int[2,2],10)
            plot!(fill(split[i][1],length(x)),x,show=true, label="")
            annotate!([(split[i][1], median(x), text(label,6))])
        else
            x = linspace(int[1,1],int[1,2],10)
            plot!(x,fill(split[i][1],length(x)),show=true, label="")
            annotate!([(median(x),split[i][1], text(label,6))])
        end
    end
    xlims!(split[1][3][1,1],split[1][3][1,2])
    ylims!(split[1][3][2,1],split[1][3][2,2])
    title!("Mondrian Process splits")
    xlabel!("Box dimension 1")
    ylabel!("Box dimension 2")
end

function create_gif(split)
    plot()
    xlims!(split[1][3][1,1],split[1][3][1,2])
    ylims!(split[1][3][2,1],split[1][3][2,2])
    times=true
    anim = @animate for i in 1:size(split,1)
        d = split[i][2]
        int = split[i][3]
        if times
            label = round(c[i][end],3)
        else
            label = ""
        end
        if (d == 1)
            x = linspace(int[2,1],int[2,2],10)
            plot!(fill(split[i][1],length(x)),x,show=true, label="")
            annotate!([(split[i][1], median(x), text(label,6))])
        else
            x = linspace(int[1,1],int[1,2],10)
            plot!(x,fill(split[i][1],length(x)),show=true, label="")
            annotate!([(median(x),split[i][1], text(label,6))])
        end
    end
    gif(anim,"mondrian.gif",fps=1)
end
