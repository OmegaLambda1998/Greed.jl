module RunModule

# External Packages
using OrderedCollections

# Internal Packages
include("DiceModule.jl")
using .DiceModule
include("PlayerModule.jl")
using .PlayerModule
include("GameModule.jl")
using .GameModule

# Exports
export run_Greed

function parse_rules(rules::Dict)
    parsed = OrderedDict{Vector{Int},Int}()
    for key in sort(collect(keys(rules)), lt = (x, y) -> (length(x) + rules[x]) < (length(y) + rules[y]), rev=true)
        k = parse.(Int, split(key, ""))
        parsed[k] = rules[key]
    end
    return parsed
end

function get_game(config::Dict, players::Vector{Player}, global_config::Dict)
    rules = parse_rules(config["rules"])
    start_score = config["start_score"]
    end_score = config["end_score"]
    return Game(rules, start_score, end_score, players)
end

function run_Greed(toml::Dict)
    global_config = toml["global"]
    players = get_players(toml["players"], global_config)
    @info "Players: $(join([p.name for p in players], ", ", " and "))\n"
    game = get_game(toml["game"], players, global_config)
    run_game(game)
    #for i in 1:10
    #    roll!(player)
    #    println("$(player.draw) => $([d6.faces[d] for d in player.draw])")
    #    opts = options(rules, player)
    #    s = score(rules, player.bank)
    #    println("Options:")
    #    println("[1]: Bank => $(player.bank), Score => $s")
    #    for (i, opt) in enumerate(opts)
    #        s = score(rules, opt[1])
    #        println("[$(i + 1)]: Bank => $(opt[1]), Score => $s")
    #    end
    #end

end

end
