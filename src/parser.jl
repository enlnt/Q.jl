const _openers = b"([{"
const _closers = b")]}"
"""
    chkparens(cmd) -> 0 | -1 | pos

Return the position of a misbalanced parenthesis or 0 if the given string
is balanced, and -1 if there are more open parentheses than closed.
"""
function chkparens(cmd::Array{UInt8})
    stack = UInt8[]
    for (pos, x) in enumerate(cmd)
        i = findnext(_openers, x, 1)
        if i > 0
            push!(stack, x)
            continue
        end
        i = findnext(_closers, x, 1)
        if i > 0 && (isempty(stack) || pop!(stack) != _openers[i])
            return pos
        end
    end
    isempty(stack) ? 0 : -1
end
chkparens(cmd::AbstractString) = chkparens(transcode(UInt8, cmd))
