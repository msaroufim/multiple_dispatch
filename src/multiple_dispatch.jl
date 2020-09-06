### A Pluto.jl notebook ###
# v0.11.12

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ d9d1d190-f083-11ea-3820-17ade8ad913e
using Measurements

# ╔═╡ c70bcc90-f084-11ea-1b25-f39e6baa1c0b
using DifferentialEquations

# ╔═╡ 6ba08520-f085-11ea-17d6-556a42ca7ce7
using Plots

# ╔═╡ 38e50b00-f086-11ea-39bd-0f814d49b254
using PlutoUI

# ╔═╡ d90b8ea0-f073-11ea-1e38-3dbed8d0a254
md"# Writing Composable Software with Multiple Dispatch"

# ╔═╡ a3ed04f2-f079-11ea-3c88-9bdb95688687
md"If you've ever dabbled in Julia you may have heard the term multiple dispatch. The claim is that multiple dispatch allows you to easily write highly composable code.

I'd ask Chris Rackauckas something along the lines of 'Does Julia have a differentiable physics engine?' to which he'd answer 'well we have a physics engine and we have an autodiff library so because of multiple dispatch it just works, we just need to write a tutorial for it'.

I would nod my head in approval 'yes yes multiple dispatch of course'"

# ╔═╡ e0731fae-f081-11ea-3fd8-77e7c07829b2
md"## Game and Physics Engines"

# ╔═╡ 19382380-f079-11ea-1ae6-3110ff67c346
md"I decided to go to Wikipedia for help and found the below example"

# ╔═╡ 3081e670-f079-11ea-18a1-cbd7e0c38b4e
collide_with(x::Asteroid, y::Asteroid) = ... # deal with asteroid hitting asteroid
collide_with(x::Asteroid, y::Spaceship) = ... # deal with asteroid hitting spaceship
collide_with(x::Spaceship, y::Asteroid) = ... # deal with spaceship hitting asteroid
collide_with(x::Spaceship, y::Spaceship) = ... # deal with spaceship hitting spaceship

# ╔═╡ b50b57ee-f079-11ea-1fc1-d303920ecaeb
md"A few things crossed my mind when I saw this example
1. Ok so I can have the same function ```collide_with``` defined with various types - can't do this with Python
2. Why is this pseudocode?
3. Who the heck cares about asteroids?

So I decided to ask the Julia Slack channel for their favorite multiple dispatch tutorials and that comment generated over 120 reponses from the Julia community that taught me a lot about how multiple dispatch actually lets you write composable code.

I thought I'd summarize that thread in this blog post"

# ╔═╡ 3d57ebf0-f07a-11ea-1239-4ff6c5b83886
md" The first answer came from [Mose Giordano who fleshed out the Asteroid example by implementing Rock Paper Scissors](https://giordano.github.io/blog/2017-11-03-rock-paper-scissors/)"

# ╔═╡ 145558ce-f07c-11ea-2b75-4f446ab88dbd
# First create types for Rock, Paper and Scissors
abstract type Shape end

# ╔═╡ 20252e60-f07c-11ea-2e3f-d958b4be4844
struct Rock     <: Shape end

# ╔═╡ 202618c0-f07c-11ea-38d2-7b79d7258c1d
struct Paper    <: Shape end

# ╔═╡ 202a3770-f07c-11ea-1cb1-610a101e4fa4
struct Scissors <: Shape end

# ╔═╡ 202e7d30-f07c-11ea-1b05-c5948272a36d
begin
	# These first 3 plays define the rules we all know and love
	play(::Type{Paper}, ::Type{Rock})     = "Paper wins"
	play(::Type{Paper}, ::Type{Scissors}) = "Scissors wins"
	play(::Type{Rock},  ::Type{Scissors}) = "Rock wins"
	
	# Instead of having a seperate function to tie each shape we can just have 1
	play(::Type{T},     ::Type{T}) where {T<: Shape} = "Tie, try again"
	
	# Nice huh!
	play(a::Type{<:Shape}, b::Type{<:Shape}) = play(b, a) # Commutativity
end

# ╔═╡ 3e4b6c50-f07d-11ea-0aa5-0f2debd0f8d0
# An example from the first 3 rules
play(Rock, Scissors)

# ╔═╡ 49c6e050-f07d-11ea-2476-ef12a8cfe411
# An example of a tie
play(Rock, Rock)

# ╔═╡ 80933250-f07d-11ea-1726-afbb54269143
# An example of Commutativity 
# Remember we didn't actually define a function for this explictly
play(Scissors, Rock)

# ╔═╡ 48665b60-f07c-11ea-356e-113a7e553d78
md"What I personally found fascinating about this example is that it gives a glimpse as to how you could create a physics engine or game engine with Julia. For example:

1. ```collide_with``` can work over any combination of shapes to implement a fully featured collision engine
2. ```play``` can work over any combination of game entities to implement the rules of a larger game

Great I thought! What else can I do?"

# ╔═╡ eea04630-f081-11ea-3c23-7f18452e4a9f
md" ## Matrix Multiplication"

# ╔═╡ a8da79d0-f07d-11ea-3f5a-fddcec33487d
md"Lyndon White responded with his own take is his article [JuliaLang: The Ingredients for a Composable Programming Language](https://www.oxinabox.net/2020/02/09/whycompositionaljulia.html)

Where I found a fascinating table.

The running time for matrix multiplication is not O(n^3) or O(n^2.something) it's actually dependent on not just the size of the two matrices but also their type
"


# ╔═╡ c0355e4e-f07e-11ea-12c1-cdc89b529787
#=
*(::Dense, ::Dense):
multiply rows by columns and sum.
Takes O(n3) time
*(::Dense, ::Diagonal) or *(::Diagonal, ::Dense):
column-wise/row-wise scaling.
O(n2) time.
*(::OneHot, ::Dense) or *(::Dense, ::OneHot):
column-wise/row-wise slicing.
O(n) time.
*(::Identity, ::Dense) or *(::Dense, ::Identity):
no change.
O(1) time.
=#

# ╔═╡ 6cd88230-f080-11ea-239e-0337317018dc
md"There are 2 big benefits to this approach
1. You don't have to muddy your code with ```if``` conditions to take into account special cases - try taking a look at the Keras codebase for how things are done there
2. If you come up with a new matrix with some unique properties you can make it multipliable without changing anyone elses code
"

# ╔═╡ 92c32a20-f082-11ea-21f2-976338a8ebcb
md"A more advanced example was also proposed by Chris Rackaukas showing how [Flux.jl](https://github.com/FluxML/Flux.jl) Julia's Machine Learning library does CUDA."

# ╔═╡ 64bbb7a0-f082-11ea-320c-c3066a327460
begin
	(m::CuRNN{T})(h::CuArray{T}, x) where T <: Union{Float32,Float64} = m(h, CuArray{T}(x))
	(m::CuGRU{T})(h::CuArray{T}, x) where T <: Union{Float32,Float64} = m(h, CuArray{T}(x))
	(m::CuLSTM{T})(h::NTuple{2,CuArray{T}}, x) where T <: Union{Float32,Float64} = m(h, CuArray{T}(x))
end

# ╔═╡ 798db940-f081-11ea-16b1-79d3205202ca
md"## Dealing with Uncertainty"

# ╔═╡ 0ac70010-f082-11ea-3633-2d5ad12da9af
md"This next example was proposed by Chris and Mose [Handling Uncertainty in SciML](https://tutorials.sciml.ai/html/type_handling/02-uncertainties.html)

* Julia has package called Measurements to handle uncertainty
* Julia has a differential equation solvers that weren't designed with uncertainty in mind

But as you guessed it, multiple dispatch adds support with no additional effort
"

# ╔═╡ bd816fa0-f083-11ea-0926-41923dee7334
import Pkg

# ╔═╡ d6831bc0-f083-11ea-1d72-a75b1e7c5db2
Pkg.add("Measurements")

# ╔═╡ 59ee9a20-f084-11ea-0ea4-693c7d882e4d
# An uncertain measurement
2 ± 0.1

# ╔═╡ 7731e790-f084-11ea-2462-f3c9e719f3b9
# Measurements have their own algebraic rules
(2 ± 0.1) - (1 ± 0.2) 

# ╔═╡ 95b2be10-f084-11ea-3742-bf52099fe62f
md"How would this ever work with an existing library?"

# ╔═╡ 51927210-f085-11ea-3c1c-ab3b7a445578
Pkg.add("DifferentialEquations")

# ╔═╡ 675e4790-f085-11ea-0e20-51b293a86faf
Pkg.add("Plots")

# ╔═╡ 89705b22-f085-11ea-1052-215a1b8b2f5f
md"We've set the uncertainties to 0 initially, feel free to increase them and see what happens. This notebook made with Pluto.jl which is reactive so you don't need click run anywhere after changing the values" 

# ╔═╡ b8e34480-f085-11ea-1e70-81530ed89fab
Pkg.add("PlutoUI")

# ╔═╡ c0931510-f086-11ea-017f-33e69b342fb6
md"Go ahead change these from 0 and see what happens!"

# ╔═╡ 3bdffb80-f086-11ea-00df-afa163290213
@bind g_err Slider(0.0:0.001:0.02, default=0.0)

# ╔═╡ 865f0700-f086-11ea-0ade-5d12bec09984
@bind L_err Slider(0.0:0.001:0.02, default=0.0)

# ╔═╡ 829c0b90-f086-11ea-1ff7-73120eefcf8e
@bind pi_err Slider(0.0:0.001:0.02, default=0.0)

# ╔═╡ 108dc880-f087-11ea-30a4-cd7758cae66c
md"We're going to be solving pendulum differential equation

1. If you're familiar with differential equations, notice how close the code is to the math you're used to
2. If you're not familiar with differential equations, it doesn't really matter - enjoy the pretty picture and move on!

"

# ╔═╡ ec111d92-f086-11ea-3752-09fef4495cc3
md"Error bars for free is not something you'd expect to work but because of multiple dispatch, it just does"

# ╔═╡ 0a34ab20-f082-11ea-1dae-296d0eb8aa53
md"## Automatic Differentiation"

# ╔═╡ 420c6590-f075-11ea-03d5-87c97de506a5
md"Here's an example by David Sanders of Forward Mode Automatic Differentiation that's so tiny [it fits in a single Tweet!](https://twitter.com/marksaroufim/status/1302301588925472768)"


# ╔═╡ 5c2f1210-f075-11ea-1c4b-712b39db582f
# This is a dual number 
# They are defined as p + εd  where ε^2 = 0
struct D <: Number
    p
    d
end

# ╔═╡ ca8d7710-f075-11ea-3c57-f365db5cb648
begin
	import Base: +, *
	# Addition and Multiplication are dispatched to dual numbers
	+(a::D, b::D) = D(a.p + b.p, a.d + b.d)
	
	# Multiplication is defined on 2 dual numbers
	*(a::D, b::D) = D(a.p * b.p, a.p * b.d + a.d * b.p)
	
	# And over two reals
	*(b::Real, a::D) = D(b * a.p, b * a.d)
end

# ╔═╡ 7f051ea0-f085-11ea-33ce-d30920fc310a
begin
	g = 9.79 ± g_err; # Gravitational constants
	L = 1.00 ± L_err; # Length of the pendulum
	
	#Initial Conditions
	u₀ = [0 ± 0, π / 3 ± pi_err] # Initial speed and initial angle
	tspan = (0.0, 6.3)
	
	#Define the problem
	function simplependulum(du,u,p,t)
	    θ  = u[1]
	    dθ = u[2]
	    du[1] = dθ
	    du[2] = -(g/L) * sin(θ)
	end
	
	#Pass to solvers
	prob = ODEProblem(simplependulum, u₀, tspan)
	sol = solve(prob, Tsit5(), reltol = 1e-6)
	
	plot(sol.t, getindex.(sol.u, 2), label = "Numerical")
end

# ╔═╡ 64438d50-f075-11ea-0649-7d93c13ca8f3
∂(f, x) = f(D(x, 1)).d

# ╔═╡ 3308937e-f088-11ea-2ac6-4bf150c5d9aa
md"And that's it! Let's try out a few functions. You can validate the results by hand if this sounds too good to be true"

# ╔═╡ 3bc27680-f088-11ea-13fa-59ce8a744abb
@bind val NumberField(0:100, default=2)

# ╔═╡ 3b8b60f0-f088-11ea-1ae4-f9512039564b
∂(x -> x^2 + 2x, val)

# ╔═╡ ca5ca870-f088-11ea-26f3-ddbc14ef241d
∂(x -> x^3 + 100x + - 2x, val)

# ╔═╡ cc305700-f088-11ea-118c-15bbe612f0ff
∂(x -> x^3, val)

# ╔═╡ 3b4e57f0-f088-11ea-1129-457606f2f119
∂(x -> x, val)

# ╔═╡ 664c7780-f087-11ea-3094-f185ce4a5d25
md"If you're interested there are larger more robust automatic differentiation packages you can browse on Github such as [Zygote.jl](https://github.com/FluxML/Zygote.jl) which uses similar ideas but is obviously much faster and more feature complete

And if you'd like to better understand the basics of Automatic Differentiation I've written a seperate beginner friendly article [Automatic Differentiation Step by Step](https://medium.com/@marksaroufim/automatic-differentiation-step-by-step-24240f97a6e6) 
"

# ╔═╡ fd3fe820-f082-11ea-0571-39b3c5ab0d0a
md"## Acknowledgements

This article would not be possible without the Julia community. I'm continuously surprised how much I learn about Math, Science and Programming just hanging out there.

Considering how I started out thinking multiple dispatch is only useful for something to do with asteroids, we ended up covering
1. Game/Physics Engines
2. Matrix Multiplication
3. Dealing with Uncertainty
4. Automatic Differentiation

If you enjoyed this post, you'll enjoy Julia even more so make your way to [JuliaLang.org](https://julialang.org/), it's a lot easier to build in Julia relative to other languages because of multiple dispatch and an amazing community.

"

# ╔═╡ Cell order:
# ╟─d90b8ea0-f073-11ea-1e38-3dbed8d0a254
# ╟─a3ed04f2-f079-11ea-3c88-9bdb95688687
# ╟─e0731fae-f081-11ea-3fd8-77e7c07829b2
# ╟─19382380-f079-11ea-1ae6-3110ff67c346
# ╠═3081e670-f079-11ea-18a1-cbd7e0c38b4e
# ╠═b50b57ee-f079-11ea-1fc1-d303920ecaeb
# ╟─3d57ebf0-f07a-11ea-1239-4ff6c5b83886
# ╠═145558ce-f07c-11ea-2b75-4f446ab88dbd
# ╠═20252e60-f07c-11ea-2e3f-d958b4be4844
# ╠═202618c0-f07c-11ea-38d2-7b79d7258c1d
# ╠═202a3770-f07c-11ea-1cb1-610a101e4fa4
# ╠═202e7d30-f07c-11ea-1b05-c5948272a36d
# ╠═3e4b6c50-f07d-11ea-0aa5-0f2debd0f8d0
# ╠═49c6e050-f07d-11ea-2476-ef12a8cfe411
# ╠═80933250-f07d-11ea-1726-afbb54269143
# ╟─48665b60-f07c-11ea-356e-113a7e553d78
# ╟─eea04630-f081-11ea-3c23-7f18452e4a9f
# ╠═a8da79d0-f07d-11ea-3f5a-fddcec33487d
# ╠═c0355e4e-f07e-11ea-12c1-cdc89b529787
# ╟─6cd88230-f080-11ea-239e-0337317018dc
# ╟─92c32a20-f082-11ea-21f2-976338a8ebcb
# ╠═64bbb7a0-f082-11ea-320c-c3066a327460
# ╟─798db940-f081-11ea-16b1-79d3205202ca
# ╟─0ac70010-f082-11ea-3633-2d5ad12da9af
# ╠═bd816fa0-f083-11ea-0926-41923dee7334
# ╠═d6831bc0-f083-11ea-1d72-a75b1e7c5db2
# ╠═d9d1d190-f083-11ea-3820-17ade8ad913e
# ╠═59ee9a20-f084-11ea-0ea4-693c7d882e4d
# ╠═7731e790-f084-11ea-2462-f3c9e719f3b9
# ╟─95b2be10-f084-11ea-3742-bf52099fe62f
# ╠═51927210-f085-11ea-3c1c-ab3b7a445578
# ╠═675e4790-f085-11ea-0e20-51b293a86faf
# ╠═c70bcc90-f084-11ea-1b25-f39e6baa1c0b
# ╠═6ba08520-f085-11ea-17d6-556a42ca7ce7
# ╟─89705b22-f085-11ea-1052-215a1b8b2f5f
# ╠═b8e34480-f085-11ea-1e70-81530ed89fab
# ╠═38e50b00-f086-11ea-39bd-0f814d49b254
# ╟─c0931510-f086-11ea-017f-33e69b342fb6
# ╠═3bdffb80-f086-11ea-00df-afa163290213
# ╠═865f0700-f086-11ea-0ade-5d12bec09984
# ╠═829c0b90-f086-11ea-1ff7-73120eefcf8e
# ╟─108dc880-f087-11ea-30a4-cd7758cae66c
# ╠═7f051ea0-f085-11ea-33ce-d30920fc310a
# ╟─ec111d92-f086-11ea-3752-09fef4495cc3
# ╠═0a34ab20-f082-11ea-1dae-296d0eb8aa53
# ╟─420c6590-f075-11ea-03d5-87c97de506a5
# ╠═5c2f1210-f075-11ea-1c4b-712b39db582f
# ╠═ca8d7710-f075-11ea-3c57-f365db5cb648
# ╠═64438d50-f075-11ea-0649-7d93c13ca8f3
# ╟─3308937e-f088-11ea-2ac6-4bf150c5d9aa
# ╠═3bc27680-f088-11ea-13fa-59ce8a744abb
# ╠═3b8b60f0-f088-11ea-1ae4-f9512039564b
# ╠═ca5ca870-f088-11ea-26f3-ddbc14ef241d
# ╠═cc305700-f088-11ea-118c-15bbe612f0ff
# ╠═3b4e57f0-f088-11ea-1129-457606f2f119
# ╟─664c7780-f087-11ea-3094-f185ce4a5d25
# ╠═fd3fe820-f082-11ea-0571-39b3c5ab0d0a
