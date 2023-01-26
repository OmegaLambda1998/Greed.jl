export MinScore 

struct MinScore <: GreedAlgorithm
    min_score :: Int64
end

function MinScore(options::Dict)
    min_score = options["MIN_SCORE"]
    return MinScore(min_score)
end

function get_name(algorithm::MinScore, i::Int64)
    return "MinScore$(algorithm.min_score)"
end

function deepcopy(algorithm::MinScore)
    return MinScore(algorithm.min_score)
end

function choose(algorithm::MinScore, player::Player, opts::OrderedDict{Vector{Int}, Vector{Int}}, rules::OrderedDict{Vector{Int}, Int}, min_score::Int64)
    if length(opts) == 0
        return (1, false)
    end
    scores = Dict(score(rules, opt[1]) => i for (i, opt) in enumerate(opts))
    best_score = maximum(keys(scores))
    choice = scores[best_score] + 1
    if !player.scoring
        reroll = best_score < min_score
    else
        reroll = best_score < algorithm.min_score
    end
    return (choice, reroll)
end
