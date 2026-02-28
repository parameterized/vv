add_slide {
    code_hidden = read_file("demo_code/setup.lua"),
}

add_slide {
    h1 = "computing",
    pre = [[
how do i do computing?

is it like a turing machine?
    ]],
    code = read_file("demo_code/tm.lua"),
}

add_slide {
    h1 = "no",
    pre = [[
thats a bad way to describe what my body does

i dont put my atoms in a line,
look through them one at a time,
and decide how that one should change
    ]],
}

add_slide {
    h1 = "like cellular automata then?",
    spacer = "300px",
    code = read_file("demo_code/ca.lua"),
}

add_slide {
    h1 = "better",
    pre = [[
but still not really

good:
- does more than 1 thing at a time

bad:
- update style
    - all neighbors have to update before a cell can update again
        - one broken cell causes a chain reaction of waiting
        - (i dont think my cells do that)
    - makes it hard to move things without duplicating or erasing
- grid
    - neighbor connection pattern has to be the same everywhere
    - makes it hard to add things to small patterns
    ]],
}

add_slide {
    h1 = "the movable feast machine",
    pre = [[
good:
- update style
    - nonoverlapping event windows are randomly chosen
    - makes it easy to move things without duplicating or erasing
    - updating is a continuous-time thing
    ]],
    spacer = "420px",
    code = read_file("demo_code/mfm.lua"),
}

add_slide {
    pre = [[
the grid still seems restrictive

it can be useful for implementation on modern hardware,
but i want to make small things without strict position rules,
and i dont want to assume the computer is structured like a crystal

im mostly not a crystal
    ]],
}

add_slide {
    h1 = "maybe im like interaction nets",
    spacer = "300px",
    code = read_file("demo_code/inet.lua"),
}

add_slide {
    h1 = "interaction nets are cool",
    pre = [[
rewrites happen in continuous space and time

but they could be applied in a more continuous way

restricting rewrites to cells connected by principal ports:
- makes it easy to apply them in a nonoverlapping way,
- and to guarantee that some structures have a unique reduced form,
    ]],
}

add_slide {
    h1 = "but i want determinism to be more opt-in",
    pre = [[
i want some unconnected cells to interact when they're close

and to have different ways they can interact

and why are the rules always in some metaphysical place,
omnipotently applying themselves when they recognize their pattern?

im not a dualist so i dont think my selves work like that

instructions and data are the same thing

clip their wings
    ]],
}

add_slide {
    h1 = "interaction machines",
    pre = "(code in progress)",
    spacer = "300px",
    code = read_file("demo_code/im.lua"),
}

add_slide {
    h1 = "math",
    pre = [[
<b>Definition 1.</b>  An <i>interaction machine</i> is a vertex-labeled simple graph.
We refer to vertices as $\tb{\textit{atoms}}$ and edges as $\tg{\textit{bonds}}$.

Atoms each have a $\tb{\textit{type}}$, and each type $\tb{t} \in \tb{\Sigma}$ has a complement $\tb{t'} \in \tb{\Sigma}$.
The set of types $\tb{\Sigma}$ contains two special types: $\tb{<>}$ (input) and $\tb{>>}$ (output).
    ]],
}

add_slide {
    h1 = "math",
    pre = [[
<b>Definition 2.</b>  A $\tm{\textit{rule}}$ consists of two bonded atoms (either $\tb{<>} \tm{-} \tb{>>}$ or $\tb{<>'} \tm{-} \tb{>>'}$),
and any other directly bonded atoms.

A rule's $\tm{\textit{input subgraph}}$ contains rule atoms bonded to the input atom,
excluding the corresponding output atom(s). The $\tm{\textit{output subgraph}}$ is defined similarly.

$\tm{\textit{Alignment bonds}}$ (and lack of these bonds) between atoms in the input and output subgraphs
denote $\tgrey{\textrm{preservation}}$, $\tb{\textrm{creation}}$, $\tr{\textrm{deletion}}$, $\tg{\textrm{splitting}}$, and $\tg{\textrm{merging}}$ operations during rule application.

When a rule's input subgraph is close to a matching complement pattern
(for some chosen threshold distance), atoms may be removed or split such that
there is one per alignment bond, and these bonds are copied to the resulting atoms.

If an input atom is also an output atom, it is treated as if it has an alignment bond to itself.
    ]],
}

add_slide {
    h1 = "math",
    pre = [[
If a rule output atom $\tb{a_o}$ is bonded to an atom $\tb{a}$, and $\tb{a}$ isn't bonded
to either the rule input or output, then $\tb{a} \tg{-} \tb{a_o}$ is a $\tg{\textit{rewrite bond}}$.

When a rule has active rewrite bonds, they should be contracted until
all are short enough (chosen threshold).
During this process, the matching process should be disabled.

At the end of the rewrite process, creation and merge operations are applied,
resulting in the matched pattern being replaced with the complement
of the rule's output subgraph.



you could <a href="https://www.todepond.com/wikiblogarden/better-computing/just/">just</a> do the whole replacement at match-time but thats less cool
    ]],
}

add_slide {
    h1 = "why vv?",
    pre = [[
$\vee \vee$  <>  >>  vivi

also u need a rule with a 3-atom input subgraph for some kinds of actions

you could draw them as $\vee \rightarrow \vee$ shaped diagrams

and vibes say you can reduce more complicated rules to vv rulesets
    ]],
}
