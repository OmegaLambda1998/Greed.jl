export Nominal 

struct Nominal <: GreedAlgorithm
end

function Nominal(options::Dict)
    return Nominal()
end

function get_name(algorithm::Nominal, i::Int64)
    return "Nominal"
end

function deepcopy(algorithm::Nominal)
    return Nominal()
end

function choose(algorithm::Nominal, player::Player, opts::OrderedDict{Vector{Int}, Vector{Int}}, rules::OrderedDict{Vector{Int}, Int}, min_score::Int64)
    if length(opts) == 0
        return (1, false)
    end
    scores = Dict(score(rules, opt[1]) => i for (i, opt) in enumerate(opts))
    best_score = maximum(keys(scores))
    if !player.scoring
        choice = scores[best_score] + 1
        reroll = best_score < min_score
    else
        choice = floor(Int64, rand() * (length(opts) + 1)) + 1
        if choice == 1
            reroll = false
        else
            reroll = rand(Bool)
        end
    end
    return (choice, reroll)
end
