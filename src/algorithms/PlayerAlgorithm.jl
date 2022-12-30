export PlayerAlgorithm

struct PlayerAlgorithm <: GreedAlgorithm end

function PlayerAlgorithm(options::Dict)
    return PlayerAlgorithm()
end

function get_name(algorithm::PlayerAlgorithm, i::Int64)
    return "Player $i"
end

function deepcopy(algorithm::PlayerAlgorithm)
    return PlayerAlgorithm()
end

function choose(algorithm::PlayerAlgorithm, player::Player, opts::OrderedDict{Vector{Int}, Vector{Int}}, rules::OrderedDict{Vector{Int}, Int}, min_score::Int64)
    if length(opts) == 0
        return (1, false)
    end
    choices = string.(collect(1:length(opts) + 1))
    choice_str = "[1]"
    for (i, opt) in enumerate(opts)
        if i == length(opts)
            choice_str *= ", or [$(i + 1)]"
        else
            choice_str *= ", [$(i + 1)]"
        end
    end
    println("$(player.name) what choice would you like to make? $choice_str")
    choice = nothing
    while !(choice in choices)
        if !isnothing(choice)
            println("Sorry, I didn't understand $choice, please pick from $choice_str")
        end
        choice = readline()
    end
    choice = parse(Int64, choice)
    if choice == 1
        reroll = false
    else
        reroll = nothing
        b = collect(keys(opts))[choice - 1]
        num_banked = length(b)
        println("Would you like to reroll $(length(player.dice.faces) - num_banked) dice? (y), or (n)")
        while !(reroll in ["y", "n"])
            if !isnothing(reroll)
                println("Sorry, I didn't understand $reroll, please pick from (y) or (n)")
            end
            reroll = readline()
        end
        if reroll == "y"
            reroll = true
        else
            reroll = false
        end
    end
    return choice, reroll
end
