module PlayerModule

# External imports
using OrderedCollections
using Random
using TOML
using Base

# Internal imports
using ..DiceModule

# Exports
export GreedAlgorithm
export Player
export get_players
export turn!
export options
export score
export reset! 

abstract type GreedAlgorithm end

mutable struct Player
    name::String
    dice::Dice
    hand::Vector{Dice}
    bank::Vector{Int}
    draw::Vector{Int}
    score::Int
    scoring::Bool
    algorithm::GreedAlgorithm
end

function Base.deepcopy(player::Player)
    return Player(player.name, player.dice, copy(player.hand), copy(player.bank), copy(player.draw), player.score, player.scoring, deepcopy(player.algorithm))
end

# Load in all algorithms 
# All algorithms must export themselves
algorithms_path = joinpath(@__DIR__, "algorithms")
algorithms = Vector{String}() 
for path in readdir(algorithms_path, join=true)
    if isfile(path)
        include(path)
        push!(algorithms, splitpath(splitext(path)[1])[end])
    end
end

function get_algorithm(algorithm_details::Dict)
    type = algorithm_details["name"]
    try
        algorithm = getfield(PlayerModule, Symbol(type))
    catch e
        @error "Can not find algorithm named $type, options include $algorithms"
    end
end

function get_players(config::Dict, global_config::Dict)
    dice_rules = config["dice"]
    dice = Dice(dice_rules)
    hand = [dice for i in 1:length(dice.faces)]
    if "algorithm_file" in keys(config)
        algorithm_path = joinpath(global_config["base_path"], config["algorithm_file"])
        @info "Loading in algorithms from $algorithm_path"
        algorithm_dict = TOML.parsefile(algorithm_path)["algorithms"]
        config["algorithms"] = algorithm_dict
    end
    algorithms = [get_algorithm(a)(get(a, "options", Dict())) for a in config["algorithms"]]
    names = get(config, "names", nothing)
    if isnothing(names)
        names = [get_name(algorithms[i], i) for i in 1:length(algorithms)]
    end
    players = [Player(names[i], dice, hand, Vector{Int}(), Vector{Int}(), 0, false, algorithms[i]) for i in 1:length(algorithms)]
    return players
end

function roll!(p::Player)
    if length(p.hand) == 0
        @warn "Can't roll empty hand"
    else
        draw = Vector{Int}()
        for d in p.hand
            f = roll(d)
            push!(draw, f)
        end
        p.draw = sort!(draw)
    end
end

function turn!(p::Player, rules::OrderedDict{Vector{Int}, Int}, min_score::Int64)
    dice = p.dice
    roll!(p)
    @info "$(p.name) rolled $([dice.faces[d] for d in p.draw])"
    opts = options(rules, p)
    if length(opts) == 0
        @info "Bad luck $(p.name), you didn't roll any options\n"
    end
    s = score(rules, p.bank)
    @info "$(p.name) has options:"
    @info "[1]: Bank => $([dice.faces[d] for d in p.bank]), Score => $s"
    for (i, opt) in enumerate(opts)
        s = score(rules, opt[1])
        @info "[$(i + 1)]: Bank => $([dice.faces[d] for d in opt[1]]), Score => $s, $(length(p.dice.faces) - length(opt[1])) dice leftover"
    end
    choice, reroll = choose(p.algorithm, p, opts, rules, min_score)
    if choice != 1
        p.bank = collect(keys(opts))[choice - 1]
        p.hand = [dice for i in 1:(length(p.dice.faces) - length(p.bank))]
    end
    if length(p.hand) == 0
        @info "You've run out of dice, you're all done!"
        reroll = false
    end
    s = score(rules, p.bank)
    if reroll
        turn!(p, rules, min_score)
    else
        if (p.score >= min_score) || (s >= min_score)
            p.scoring = true
            p.score += s
            @info "$(p.name) has gained $s points, bringing them up to $(p.score) points total\n"
        else
            @info "Sorry $(p.name) you need to earn at least $min_score in a single turn to start earning points\n"
        end
    end
end

function isgreedsubset(key, bank)
    flag = false
    for (i, d) in enumerate(bank)
        if !flag
            if d == key[1]
                if length(bank) - i + 1 >= length(key)
                    if bank[i:i+length(key)-1] == key
                        flag = true
                    end
                end
            end
        end
    end
    return flag
end

# Assumed key and bank are appropriately ordered
function greeddiff(key::Vector{Int}, bank::Vector{Int})
    if !isgreedsubset(key, bank)
        @warn "Can't find diff of $bank and $key; they are not a subset"
        return bank
    end
    removed = false
    for (i, d) in enumerate(bank)
        # If you've found the start of the key 
        if !removed
            if d == key[1]
                bank = vcat(bank[1:i-1], bank[i+length(key):end]) 
                removed = true
            end
        end
    end
    return bank
end

function score(rules::OrderedDict{Vector{Int}, Int}, bank::Vector{Int})
    total = 0
    bank = copy(bank)
    for key in keys(rules)
        while isgreedsubset(key, bank)
            total += rules[key]
            bank = greeddiff(key, bank)
        end
    end
    return total
end

function options(rules::OrderedDict{Vector{Int}, Int}, bank::Vector{Int}, draw::Vector{Int}, dice::Dice, opts::OrderedDict{Vector{Int}, Vector{Int}}=OrderedDict{Vector{Int}, Vector{Int}}())
    # Options is a list of the bank and draw that the option will produce
    for (i, key) in enumerate(keys(rules))
        d = copy(draw)
        b = copy(bank)
        if isgreedsubset(key, d)
            d = greeddiff(key, d)
            b = vcat(b, key)
            opts[b] = d
            new_rules = OrderedDict(k => rules[k] for k in collect(keys(rules))[i:end])
            opts = options(new_rules, b, d, dice, opts)
        end
    end
    return opts
end

function options(rules::OrderedDict{Vector{Int}, Int}, player::Player)
    return options(rules, player.bank, player.draw, player.hand[1])
end

function choose(algorithm::GreedAlgorithm, player::Player, options::OrderedDict{Vector{Int}, Vector{Int}}, rules::OrderedDict{Vector{Int}, Int})
    @error "No choose function defined for algorithm of type $(typeof(algorithm))"
end

function reset!(player::Player)
    player.hand = [player.dice for i in 1:length(player.dice.faces)]
    player.bank = Vector{Int}()
    player.draw = Vector{Int}()
end

end
