#### Mondrian Tree as in https://arxiv.org/abs/1406.2673
#### Lakshminarayanan, B., Roy, D.M. and Teh, Y.W., 2014. Mondrian forests: Efficient online random forests. In Advances in neural information processing systems (pp. 3140-3148).
#### Alogrithm numbers (e.g A1) are as in the above paper
using Distributions
# for mondrian process
include("Axis_Aligned_Box.jl");
type Mondrian_Node
    parent::Nullable{Mondrian_Node}
    left::Nullable{Mondrian_Node}
    right::Nullable{Mondrian_Node}
    τ::Float64                      # split time
    node_type::Array{Bool,1}        # node,leaf,root
    δ::Nullable{Int}                # split dimension
    ζ::Nullable{Float64}            # split position
    Θ::Nullable{Axis_Aligned_Box}   # data boxes B
    tab::Array{Int}                 # tables serving dish k Chinese restaurant process (CRP)
    c::Array{Int}                   # customers eating dish k, tab[k] = min(c[k],1) IKN approx
    Gₚ::Array{Float64}              # posterior mean (predictive probability)
    indices::Array{Int}             # data within the boxes Θ
end

# some construction options

function Mondrian_Node(τ, node_type, tab, c, Gₚ)
    N = Mondrian_Node(Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      τ,node_type,
                      Nullable{Int}(),
                      Nullable{Float64}(),
                      Nullable{Axis_Aligned_Box}(),
                      tab,
                      c,
                      Gₚ,
                      Array{Int}())
    return N
end

function Mondrian_Node()
    N = Mondrian_Node(Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      0,[true,false,false],
                      Nullable{Int}(),
                      Nullable{Float64}(),
                      Nullable{Axis_Aligned_Box}(),
                      Array{Int}(),
                      Array{Int}(),
                      Array{Float64}(),
                      Array{Int}())
    return N
end

function Mondrian_Node(τ::Float64)
    N = Mondrian_Node(Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      τ,[true,false,false],
                      Nullable{Int}(),
                      Nullable{Float64}(),
                      Nullable{Axis_Aligned_Box}(),
                      Array{Int}(),
                      Array{Int}(),
                      Array{Float64}(),
                      Array{Int}(1))
    return N
end

function Mondrian_Node(τ::Float64, node_type::Array{Bool,1})
    N = Mondrian_Node(Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      Nullable{Mondrian_Node}(),
                      τ,
                      node_type,
                      Nullable{Int}(),
                      Nullable{Float64}(),
                      Nullable{Axis_Aligned_Box}(),
                      Array{Int}(),
                      Array{Int}(),
                      Array{Float64}(),
                      Array{Int}())
    return N
end

# only really need leaves + root directly
type Mondrian_Tree
    root::Nullable{Mondrian_Node}
    leaves::Array{Mondrian_Node,1}
    number_of_nodes::Int
end

function Mondrian_Tree()
    T = Mondrian_Tree(Nullable{Mondrian_Node}(),Array{Mondrian_Node,1}(),0)
end

function Mondrian_Tree(N::Mondrian_Node)
    T = Mondrian_Tree(N,Array{Mondrian_Node,1}(),0)
end


function Sample_Mondrian_Tree!(MT,λ,D)
    # initialise the tree
    e = Mondrian_Node(0.0,[false,false,true])
    MT.root = e
    Θ = Axis_Aligned_Box(get_intervals(D[1]))
    e.Θ = Θ
    e.tab = zeros(size(unique(D[2]),1))
    e.c = zeros(size(unique(D[2]),1))
    e.Gₚ = zeros(size(unique(D[2]),1))
    e.indices = collect(1:size(D[1],1))
    k=[0]
    Sample_Mondrian_Block!(e, Θ, λ, MT, D[1],k)
    MT.number_of_nodes = k[1]
end

function Sample_Mondrian_Block!(j, Θ, λ, tree, Data,k)
    k[1] += 1
    # sample the time
    E = rand(Exponential(1/Linear_dimension(Θ)))
    if j.node_type[3]==true
        τₚ = 0
    else
        τₚ = (get(j.parent)).τ
    end
    # if split occured in time
    if τₚ + E < λ
        # get split dimension and cut position
        # A2 -> lines 6,7
        d,x = sample_split_dimension(Θ)
        # update node j's data
        j.δ = d
        j.ζ = x
        j.τ = τₚ+E
        Θᴸ = copy(Θ)
        # look at this copy
        Θᴿ = copy(Θ)
        # Left and Right children have constricted boxes
        Θᴸ.Intervals[d,2]=x
        Θᴿ.Intervals[d,1]=x+1e-6
        # check there is actually data here
        Dᴿ = get_data_indices(Θᴿ,Data)
        Dᴸ = get_data_indices(Θᴸ,Data)
        # strictly binary tree
        if (size(Dᴿ,1)>0 && size(Dᴸ,1)>0)
            right = Mondrian_Node(0.0, [true,false,false])
            right.parent = j
            # data changes A2 -> lines 8,9,10
            right.Θ = Axis_Aligned_Box(get_intervals(Data[Dᴿ,:]))
            right.tab = zeros(size(j.tab))
            right.c = zeros(size(j.tab))
            right.Gₚ=zeros(size(j.c,1))
            j.right = right

            left = Mondrian_Node(0.0, [true,false,false])
            left.parent = j
            left.Θ = Axis_Aligned_Box(get_intervals(Data[Dᴸ,:]))
            left.tab = zeros(size(j.tab))
            left.c = zeros(size(j.tab))
            left.Gₚ = zeros(size(j.c,1))
            j.left = left

            # recurse
            Sample_Mondrian_Block!(left, get(left.Θ), λ, tree, Data[Dᴸ,:],k)
            Sample_Mondrian_Block!(right,get(right.Θ),λ, tree, Data[Dᴿ,:],k)
        # set j as a leaf for no data/ not binary
        else
            j.τ = λ
            j.node_type = [false,true,false]
            push!(tree.leaves,j)
            return
        end
    # set j as leaf for time out
    else
        j.τ = λ
        j.node_type = [false,true,false]
        push!(tree.leaves,j)
        return
    end
end

# returns any data from D contained in the boxes of Θ
function get_data_indices(Θ::Axis_Aligned_Box, D::Array{Float64,2})
    # this function cause large memory allocation according
    # to @time but the system does not record any
    # large memory allocation -> ram does not get increased
    # at all!
    indices = []
    include = false
    for i in 1:size(D,1)
        for j in 1:size(Θ.Intervals,1)
            if (D[i,j] < Θ.Intervals[j,1] || D[i,j] > Θ.Intervals[j,2])
                include = false
                break
            end
            include = true
        end
        if (include)
            push!(indices, i)
        end
    end
    return indices
end

# counts the proportion of each label in
# the data contained within the leaf nodes
# Θ
function initialize_posterior_leaf_counts!(Tree, D)
    X = D[1]
    Y = D[2]
    for leaf in Tree.leaves
        indices = get_data_indices(get(leaf.Θ),X)
        if length(indices)>0
            y = Y[indices]
            for k in 1:length(leaf.c)
                leaf.c[k] = length(y[y.==k])
                leaf.tab[k] = min(leaf.c[k],1)
            end
        end
    end
end

# uses the leaf node counts to get the internal node counts
function initialize_posterior_counts!(Tree,D)
    initialize_posterior_leaf_counts!(Tree,D)
    for leaf in Tree.leaves
        j = leaf
        while true
            if j.node_type[2]==false
                for k in 1:length(j.c)
                    j.c[k] = get(j.left).tab[k]+get(j.right).tab[k]
                end
            end
            for k in 1:length(j.c)
                j.tab[k] = min(j.c[k],1)
            end
            if j.node_type[3]==true
                break
            else
                j = get(j.parent)
            end
        end
    end
end

# gamma is usually set to 10*dimensionality
# which is done above somewhere
function compute_predictive_posterior_distribution!(Tree, γ=1)
    J = [get(Tree.root)]
    while (size(J,1) != 0)
        j = shift!(J)
        if (j.node_type[3]==true)
            p = ones(length(j.c))./length(j.c)
            d = exp(-γ*(j.τ))
        else
            d = exp(-γ*(j.τ-get(j.parent).τ))
            p = get(j.parent).Gₚ
        end
        for k in 1:length(j.c)
            j.Gₚ[k] = (1/(sum(j.c)))*(j.c[k]-d*j.tab[k]+sum(j.tab)*p[k])
        end
        if sum(j.node_type)==0
            break
        end
        if j.node_type[2] == false
            push!(J, get(j.left))
            push!(J, get(j.right))
        end
    end
end

# the algorithm requires computing an expectation
# empirically
function expected_discount(nⱼ, Δⱼ,γ=1)
    Δ = rand(Truncated(Exponential(1/nⱼ),0,Δⱼ),10000)
    return mean(exp.(-γ*Δ))
end

# predict te class probs
function predict!(T,x, γ=1)
    j = get(T.root)
    not_sep = 1
    s = zeros(size(j.c,1))
    while true
        if (sum(j.node_type)==0)
            break
        end
        if (j.node_type[3] == true)
            Δⱼ = j.τ
        else
            Δⱼ = j.τ - get(j.parent).τ
        end
        nⱼ=0
        for d in size(x,1)
            nⱼ += max(x[d]-get(j.Θ).Intervals[d,2],0) + max(get(j.Θ).Intervals[d,1]-x[d],0)
        end
        pⱼ = 1-exp(Δⱼ*nⱼ)
        # yes this part does add nodes to the tree!
        # although i've never seen it called...
        if pⱼ > 0
            # x branches
            jₓ = Mondrian_Node()
            if (j == get(j.parent).left)
                get(j.parent).left = jₓ
            else
                get(j.parent).right = jₓ
            end
            jₓ.parent = get(j.parent)
            j.parent = jₓ
            jₓ.left = j
            jₓ.right = Mondrian_Node()
            d = expected_discount(nⱼ, Δⱼ, γ)
            for k in 1:length(j.c)
                jₓ.c[k] = min(j.c[k],1)
            end
            jₓ.tab = jₓ.c
            for k in 1:length(jₓ.c)
                jₓ.Gₚ[k] = 1/(sum(jₓ.c)+1)*(jₓ.c[k] - d*jₓ.tab[k]+d*sum(jₓ.tab)*get(jₓ.parent).Gₚ[k])
            end
            for k in 1:length(s)
                s[k] += not_sep*(1-pⱼ)*jₓ.Gₚ[k]
            end
        end
        if j.node_type[2] == true
            for k in 1:length(s)
                s[k] += not_sep*(1-pⱼ)*j.Gₚ[k]
            end
            return s
        else
            not_sep = not_sep*(1-pⱼ)
            if x[get(j.δ)] <= get(j.ζ)
                j = get(j.left)
            else
                j = get(j.right)
            end
        end
    end
end
