using Distributions

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

function sample_split_dimension(Θ)
    p_k = zeros(Θ.D)
    for i in 1:Θ.D
        p_k[i] = Θ.Intervals[i,2]-Θ.Intervals[i,1]
    end
    p_k = p_k ./ Linear_dimension(Θ)
    d = rand(Categorical(p_k))
    x = rand(Uniform(Θ.Intervals[d,1][1],Θ.Intervals[d,2][1]))
    return d,x
end

function get_intervals(X)
    intervals = zeros(size(X,2),2)
    for i in 1:size(X,2)
        l = minimum(X[:,i])
        u = maximum(X[:,i])
        intervals[i,:] = [l,u]
    end
    return intervals
end
