export NumRoll 

mutable struct NumRoll <: GreedAlgorithm
    num_roll :: Int64
    num_rolled ::Int64
end

function NumRoll(options::Dict)
    num_roll = options["num_roll"]
    return NumRoll(num_roll, 0)
end

function get_name(algorithm::NumRoll, i::Int64)
    return "NumRoll$(algorithm.num_roll)"
end

function deepcopy(algorithm::NumRoll)
    return NumRoll(algorithm.num_roll, algorithm.num_rolled)
end

function choose(algorithm::NumRoll, player::Player, opts::OrderedDict{Vector{Int}, Vector{Int}}, rules::OrderedDict{Vector{Int}, Int}, min_score::Int64)
    algorithm.num_rolled += 1
    if length(opts) == 0
        algorithm.num_rolled = 0
        return (1, false)
    end
    scores = Dict(score(rules, opt[1]) => i for (i, opt) in enumerate(opts))
    best_score = maximum(keys(scores))
    choice = scores[best_score] + 1
    if !player.scoring
        reroll = best_score < min_score
    else
        reroll = algorithm.num_rolled < algorithm.num_roll
    end
    if !reroll
        algorithm.num_rolled = 0
    end
    return (choice, reroll)
end
