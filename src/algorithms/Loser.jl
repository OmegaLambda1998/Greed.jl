export Loser 

mutable struct Loser <: GreedAlgorithm
end

function Loser(options::Dict)
    return Loser()
end

function get_name(algorithm::Loser, i::Int64)
    return "Loser"
end

function deepcopy(algorithm::Loser)
    return Loser()
end

function choose(algorithm::Loser, player::Player, opts::OrderedDict{Vector{Int}, Vector{Int}}, rules::OrderedDict{Vector{Int}, Int}, min_score::Int64)
    return (1, false)
end
