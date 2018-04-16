immutable Axis_Aligned_Box
    Intervals::AbstractArray{Float64,2}
    D::Int
end

function Axis_Aligned_Box(intervals)
    Θ = Axis_Aligned_Box(intervals, size(intervals,1))
    return Θ
end

function copy(Θ::Axis_Aligned_Box)
    return Axis_Aligned_Box(Base.copy(Θ.Intervals))
end

function Linear_dimension(Θ::Axis_Aligned_Box)
    s = 0
    for i in 1:Θ.D
        s += Θ.Intervals[i,2]-Θ.Intervals[i,1]
    end
    return s
end
