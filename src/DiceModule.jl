module DiceModule

# External Modules
#
# Internal Modules
#
# Exports
export Dice
export roll

struct Dice
    faces::Vector{String}
end

function roll(d::Dice)
    r = 1 + floor(Int, (rand() * (length(d.faces) - 1)))
    return r
end

end
