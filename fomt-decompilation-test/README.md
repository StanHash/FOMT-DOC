This was a tentative for some matching decompilation of HM-FOMT (U):

- `Tool.cpp` matches.
- `DMASet.cpp` is a disaster.

(This was all done back in april 2018)

# story time!

Since the game was (probably) written in C++; I couldn't just re-use [the compiler](https://github.com/pret/agbcc) used in [`pokeruby`](https://github.com/pret/pokeruby) and [`fireemblem8u`](https://github.com/FireEmblemUniverse/fireemblem8u). My first (naïve) assumption was that the compiler used for this game was the same except the g++ variant.

So I [forked `agbcc`](https://github.com/StanHash/agbcc/tree/cxx) in attempt to restore the C++ compiler that was removed from the main branch ages ago (I think). And I got it to work. I even managed to match `Tool.cpp` (although with pretty wierd workarounds). But then I got to try something less trivial (`DMASet.cpp`) and everything went wrong.

I didn't try too hard to get this all to work. I quickly came to the assumption that this isn't actually the compiler that was used. When I looked at the code a bit more I found myself encoutering lots of things that I just wouldn't see in FE8U (most notably perhaps abundant use of the `ldmia`/`stmia` opcodes for smaller operation; but also some notable delayed register transfers or whatever terms idk).

A lot of the internals make me think this likes to use its own stuff instead of "standard" stuff. With some hand-written version of `rand` that can be found in the middle of the decompression routines, and the new handler pointer being in the middle of the IWRAM functions, the div and mod libgcc functions using `svc 6` for signed divisions and what not. This makes me think that the team behind this game was into tinkering with the toolset and stuff (and it would make sense for them to have used an "updated" version of GCC). Heck, `crt0` is broken! (`init_array` handling more specifically; which isn't really a problem since said array is empty).

(My guess is that this used some kind of early GCC 3 (for reference, the first game of the family came out April 18, 2003)).

# dependencies

in a `tools` folder:
- "[`agbcxx`](https://github.com/StanHash/agbcc/tree/cxx)"

in a `roms` folder:
- `base.gba` (HM-FOMT (U) ROM; sha1: `a2fc3574f0a65a4fcf7682fb274b9d7eebdef963`; you'll need to dump it yourself)
