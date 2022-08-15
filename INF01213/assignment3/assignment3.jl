### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 87a51a42-1b80-11ed-2daf-ed0ffdbba2f1
using PlutoUI, PyCall, Images, DSP, ImageFiltering, HypertextLiteral

# ╔═╡ 3ac2397f-5833-4a8b-a0c9-d7a1fb220dcd
@htl("""
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Arima:wght@300;700&display=swap" rel="stylesheet">
<style>
	h1 { font-family: 'Arima', sans-serif !important; }
	h2 { font-family: 'Arima', sans-serif !important; }
	h3 { font-family: 'Arima', sans-serif !important; }
	h4 { font-family: 'Arima', sans-serif !important; }
	p { font-family: 'Arima', sans-serif !important; }
	b { font-family: 'Arima', sans-serif !important; }
    pluto-output.rich_output { overflow-x: unset; }
    .monastery img { height: 20em; }
	.jpgedimages img {height: 10em; }
	blockquote p {
		font-size: 0.8em;
		font-family: sans-serif !important;
	}
	
	blockquote { border: solid black }
	.pluto-docs-binding p {
		font-size: 0.8em !important;
		font-family: sans-serif !important;
	}
	
	.pluto-docs-binding { border: solid black !important }

	.img-show img { width: 100px }
</style>
""")

# ╔═╡ cc5d2b6a-df56-4323-b150-e38f4901ed61
@htl("""
<div style="border: solid black; padding: 10px;">
<h1 style="text-align: center">Assignment 3: Simple Image Segmentation and Compositing</h1>
<h4 style="text-align: center">Guilherme Gomes Haetinger - 00274702</h4>
</div>
""")

# ╔═╡ cb1acf84-f567-4ad3-b1e3-834270cba060
md"""
**Proposal**:
*The goal of this assignment is to familiarize the students with notions of image segmentation and image compositing. For this assignment, you will play with image segmentation using the Intelligent Scissors and the GrabCut algorithms, and with the use of Laplacian sequences and alpha compositing.*
"""

# ╔═╡ 8c852f74-80b5-4040-b253-7fa0a670e52a
md"# Image Segmentation"

# ╔═╡ d86fadda-440b-4d21-a3b0-7e3843da0df5
md"## Inteligent Scissors"

# ╔═╡ 78dec682-8a8c-4d71-b5b5-c7cc3ed75844
md""" 
Gimp's inteligent scissor is very intuitive. I applied it to these two Grêmio legends and here are the results:
"""

# ╔═╡ bf48bdc1-c394-4a80-9216-da12197a0fc3
PlutoUI.ExperimentalLayout.vbox([
	PlutoUI.ExperimentalLayout.hbox([
		load("./res/Luan.jpg"),
		load("./res/luan-only.jpg"),
		load("./res/binter.jpg")
	]),
	PlutoUI.ExperimentalLayout.hbox([
		load("./res/showza.jpg"),
		load("./res/showza-only.jpg"),
		load("./res/pp.jpg")
	])
], class="threecols", style=Dict("gap" => "1em", "text-align" => "center"  ))


# ╔═╡ 1baabb42-763c-47d5-b28f-ff1211c6b53f
md"## Scribbles"

# ╔═╡ baca2f37-0302-46ee-867d-4142c0dc660f
md"""
Using Scribbles to segment a picture is also straightforward. Using my python script *"create_segment.py"* which specializes a mask by creating a rectangle bound and checking pixel similarities, and then uses a scribble I drew to introduce user based foreground/background probability and generate better results.
"""

# ╔═╡ 6ec4a969-a7ad-4374-b539-a46be3498492
@pyinclude("./create_segment.py")

# ╔═╡ 45dc971a-96c0-4666-9903-47ef3331c9a3
md"**Result of rectangle bound segmentation**"

# ╔═╡ 63927b63-8449-4446-ba9d-9ca5677e603d
load("./res/out-luan-rect5.jpg")

# ╔═╡ 6b4b0d20-01dc-4c65-8dfb-bb1a19f0f669
md"**My scribbles**"

# ╔═╡ 1980995a-30e1-4361-989a-f492341b2170
load("./res/newluanmask.jpeg")

# ╔═╡ b20c49e5-6683-4c84-ba37-131dde8cae62
md"**Result of scribble results**"

# ╔═╡ b085d890-3ce8-43f6-9fa9-942fb043fb84
load("./res/out-luan5.jpg")

# ╔═╡ aa4d3f8a-b3d7-4f53-844a-1a3e55081637
iters = [1, 5, 10, 15, 20]

# ╔═╡ ad200eed-620a-4f12-ac2b-bf4ff3b0df0d
md"""
One of the parameters we could work with, was number of iterations on the mask approximation process. More iterations equals more precision. Below, I display (left) the rectangle segmentation result and (right) the scribble process result. The results increase number of iterations from top to bottom $[1, 5, 10, 15, 20]$.
"""

# ╔═╡ 58593f12-386f-46a9-9b60-609ca14c1668
 PlutoUI.ExperimentalLayout.vbox([
	 PlutoUI.ExperimentalLayout.hbox([
		 load("./res/out-luan-rect$(i).jpg"),
		 load("./res/out-luan$(i).jpg")
	 ]) 
		 for i ∈ iters
 ], class="twocols")

# ╔═╡ 60418d1a-2e7d-4b5b-b653-ecbf99a35b52
md"""
From these results, we don't see much of an improvement of result with the increased number of iterations. Zooming in, we might be able to see the edges of the shirt become more smooth though.
"""

# ╔═╡ f8ad71b9-2640-40ca-a336-0a8fbcd8d7e2
md"# Laplacian Compositing"

# ╔═╡ b7cb9859-3077-4f0a-b7e4-b3508d80d1c7
md"## Gaussian Sequences"

# ╔═╡ 79120528-87aa-408d-aac4-a06afbf36956
apple = load("./res/Apple.png");

# ╔═╡ cc11833e-6dd2-4bb6-874d-18dc2a64df4b
orange = load("./res/Orange.png");

# ╔═╡ dcb7a836-8795-4d58-bb54-1b91102a0b6b
PlutoUI.ExperimentalLayout.hbox([apple, orange], class="twocols")

# ╔═╡ 3b06a94f-9fa6-4529-b947-5d60294ed888
md"""
Our objective in this session is to create the proper image sequences to build a mixed picture of both images above.

To start this off, we create a function that generates a *Gaussian Sequence* for any given image. For this, aside of the image, I set two different parameters:

- $Δσ$ Step to which the σ used for the *Gaussian filters* increases over the image sequence;
- $\text{seq\_size}$ Number of filters/images generated for the sequence;

Both of these alter how frequencies that are filtered out on the image sequence.
"""

# ╔═╡ 1698fb76-bd3c-42d6-a541-bb7f1a96811c
function DSP.conv(M, I::Matrix{ColorTypes.RGB{FixedPointNumbers.N0f8}})
	channels = channelview(I)
	R = channels[1, :, :]
	G = channels[2, :, :]
	B = channels[3, :, :]
	R_ = conv(M, R)
	G_ = conv(M, G)
	B_ = conv(M, B)
	colorview(RGB, R_, G_, B_)
end

# ╔═╡ 535d10ff-921d-4fe5-a8cc-58ea42641248
function DSP.conv(M, I::Matrix{ColorTypes.Gray{FixedPointNumbers.N0f8}})
	I_F = Float64.(I)
	I_ = conv(M, I_F)
	return Gray{FixedPointNumbers.N0f8}.(I_)
end

# ╔═╡ 27a2c607-0938-43c0-98c0-02d6fb6fa996
function make_gaussian_sequence(I, Δσ, seq_size)
	filters = [Kernel.gaussian([s, s], [51, 51]) for s ∈ collect(Δσ:Δσ:(seq_size-1)*Δσ)];
	return vcat([I], [conv(collect(filters[i]), I)[26:end-25, 26:end-25] for i ∈ 1:length(filters)])
end

# ╔═╡ a31b097d-7763-400c-b7a1-2df9607f98d6
md"Below, we have the resulting *Gaussian Sequences* for both images using $Δσ = 2, \text{seq\_size} = 5$" 

# ╔═╡ 1e43e851-a63c-4778-a180-9c463e044d50
make_gaussian_sequence(apple, 2, 5)

# ╔═╡ 652ab662-ef89-422d-9cf2-28d71063d1b3
make_gaussian_sequence(orange, 2, 5)

# ╔═╡ 021b7491-d01a-45fe-94ca-6cf55768d509
md"## Mask"

# ╔═╡ 7f231b63-22d2-46ce-ae36-5d3b75df3bdb
md"Now that we have the images' *Gaussian Sequences*, we're only missing one: the mask's. First, we define a very simple mask and then apply the same function:" 

# ╔═╡ 4473310c-7b3e-47a3-8367-135f4ee6bc05
mask = let
	mask = ones(size(apple))
	mask[:, Int64(512/2):end] .= 0
	mask .|> Gray{FixedPointNumbers.N0f8}
end

# ╔═╡ 4cb2e186-3e56-4014-a36b-d722753a6820
make_gaussian_sequence(mask, 2, 5)

# ╔═╡ 63085d91-9407-442f-9106-58a5fc6a62b1
md"## Laplacian Sequences"

# ╔═╡ 8b723f2a-01c0-4d95-98d8-6587104399f9
md"""
Generating a *Laplacian Sequence* is simple once we have the respective *Gaussian Sequences* layed out. To do so, we simply copy the sequence and do the following operation until $i = |G_s|-1$:

$L_s[i] = L_s[i] - G_s[i+1]$

where $L_s$ means *Laplacian Sequence* and $G_s$ means *Gaussian Sequence*.
"""

# ╔═╡ 283ec60a-a925-431d-be49-f36a247612e9
function make_laplacian_sequence(gaussian_sequence)
	laplacian = copy(gaussian_sequence)
	for (i, gauss) ∈ enumerate(gaussian_sequence[2:end])
		laplacian[i] = laplacian[i] .- gauss
	end
	return laplacian
end

# ╔═╡ 8f298bbd-b2f8-4d11-96fc-cb5d0c0793f0
md"Example:"

# ╔═╡ b2627290-f641-4bf1-81a4-fd60acd698f6
make_laplacian_sequence(make_gaussian_sequence(apple, 2, 5))

# ╔═╡ 3e92e715-b9c4-4420-817e-385a9f47b5ae
make_laplacian_sequence(make_gaussian_sequence(apple, 2, 5))[1]

# ╔═╡ af49fc76-13bb-486c-837d-2ce9ce753dcc
md"""
We see that the sharp images are very dark because the smooth color transitions are filtered out! Zooming in like in the image above, we can see the high frequencies of the image.
"""

# ╔═╡ 86d61a95-c118-44e3-a35d-d1cab327bbd2
md"## Blending" 

# ╔═╡ ef6bcec6-3764-4103-976b-ed23870fa4cd
md"""
Finally, we can blend two sequences using a mask by following this equation:

$\sum^{N}_{i=1} M_i * A_i + (1 - M_i) * B_i$

which is what we do in the followint function.
"""

# ╔═╡ d278c9c5-0e2c-4117-be32-4deaaf7f62dc
function blend_two_lapl_sequences(A, B, M)
	M_inv = [1 .- m for m ∈ M]
	return sum([
		M[i] .* A[i] + M_inv[i] .* B[i]
		for i ∈ (1:length(A))
	])
end

# ╔═╡ 14cf1de6-8225-47ee-a54f-fce2aa9b15fe
function join_images(A, B, M, Δσ, seq_size)
	A_lapl = make_laplacian_sequence(make_gaussian_sequence(A, Δσ, seq_size))
	B_lapl = make_laplacian_sequence(make_gaussian_sequence(B, Δσ, seq_size))
	M_gauss = make_gaussian_sequence(M .|> Gray, Δσ, seq_size) .|> (m -> Float64.(m))
	blend_two_lapl_sequences(A_lapl, B_lapl, M_gauss)
end

# ╔═╡ cc7a5c65-497d-4d9c-b2a3-2d3317528b5c
md"Below, I explore changing the variables to understand what would be the best combination."

# ╔═╡ 9423537a-31e1-4966-b11b-9ca8deef5c73
PlutoUI.ExperimentalLayout.vbox([
	PlutoUI.ExperimentalLayout.hbox([
		join_images(apple, orange, mask, 2, 1),
		join_images(apple, orange, mask, 2, 5),
		join_images(apple, orange, mask, 2, 10),
		join_images(apple, orange, mask, 2, 100),
	]),
    md"$Δσ = 2, \text{sequence size} = [1, 5, 10, 100], \text{respecitvely}$",
	PlutoUI.ExperimentalLayout.hbox([
		join_images(apple, orange, mask, 1, 10),
		join_images(apple, orange, mask, 2, 10),
		join_images(apple, orange, mask, 5, 10),
		join_images(apple, orange, mask, 10, 10),
	]),
    md"$\text{sequence size} = 10, Δσ = [1, 2, 5, 10], \text{respecitvely}$"
], class="fourcols", style=Dict("gap" => "1em", "text-align" => "center"  ))


# ╔═╡ 700e2abe-3c77-4046-b14e-5149db3fcf80
md"""
It seems very clear that a larger sequence size and Δσ generate better results. However, using $\text{seq\_size} = 100$ takes around *10s* to run, which I don't think is a good amount of time to wait. Viewing the images above, I thought the best result was to use $Δσ = 5, \text{seq\_size} = 10$, the extra examples proved me wrong and showed the best results used $Δσ = 2, \text{seq\_size} = 10$.
"""

# ╔═╡ 895f4aa3-c4d6-4e58-978a-261995983fc0
md"## Other examples"

# ╔═╡ 5360c45f-88b9-4193-ade8-469a9d87cbb2
md"**First example**: Tom Hank's freaky hands"

# ╔═╡ 0c6d5f87-773e-4d58-a972-1199981855a0
begin
	hank = load("./res/hanks.jpg")
	hankeye = load("./res/hanks_eye_aligned.jpg")
	hankmask = load("./res/hanks_eye_mask.jpg") .|> Gray
	[hank, hankeye, hankmask]
end

# ╔═╡ 61e8ed0c-ae56-448f-b8b7-559a96c6300f
join_images(hankeye, hank, hankmask, 2, 10)

# ╔═╡ c33f4c84-d965-4beb-a30f-4831b1d4c18d
md"**Second Example**: Pizza or Books? That's the question..."

# ╔═╡ 18bf7a1c-8b8b-49ae-b2f8-88b5034c7e57
begin
	berkeley = load("./res/sather.jpg")
	pisa = load("./res/pisa_aligned.jpg")
	pisamask = load("./res/pisa_aligned_mask.jpg") .|> Gray
	[berkeley, pisa, pisamask]
end

# ╔═╡ 1045e45f-1d38-40b6-b914-6eaff3d04d3e
join_images(pisa, berkeley, pisamask, 2, 10)

# ╔═╡ af942307-3cd0-4c22-8dd8-a8fd3ac739c0
md"# Alpha Compositing"

# ╔═╡ 8a543f5c-610b-47e6-8cb7-511a2d593317
md"""
Starting off the Alpha Compositing section, I need to load the three images and transform the alpha image into a *floating-point* matrix.
"""

# ╔═╡ ae324f81-719f-4fd3-b627-1341a550e6aa
background = load("./res/background.png");

# ╔═╡ bcc6de80-a742-4d0e-936c-eba49a71a4fe
alpha = load("./res/GT04_alpha.png");

# ╔═╡ 94d24f8e-5b36-497a-8513-19af9c01e885
foreground = load("./res/GT04.png");

# ╔═╡ 97002a41-ce6b-4e93-a863-682173ee85ea
PlutoUI.ExperimentalLayout.hbox([foreground, alpha, background], class="threecols")

# ╔═╡ 51048d6b-7942-4d7e-b320-8cf181c749b8
alpha_float = alpha .|> Gray .|> Float64;

# ╔═╡ c6e925a3-6463-415b-8566-5d7354185b25
@htl("""
<style>
.twocols img {
   width: 50%;
}
.threecols img {
   width: 30%;
}
.fourcols img {
   width: 25%;
}
</style>
""")

# ╔═╡ 4e36a48c-a80a-4380-86f8-3f0b24eb9698
md"""
After being able to run the composting equation and putting our little friends into the background set for the assignment, they went for a few adventures:
- Went to eat some oranges in Pelotas, RS
- Played against Inter in Gauchão and beat them by 10x0, each of them scoring a hat-trick
- Decided to go study at UC Berkely, where they graduated in EECS with honors 
"""

# ╔═╡ 366d1de3-d83c-45fa-9546-978829c424c9
PlutoUI.ExperimentalLayout.vbox([
	PlutoUI.ExperimentalLayout.hbox([
		alpha_float .* foreground + (1 .- alpha_float) .* background,
		alpha_float .* foreground + (1 .- alpha_float) .* imresize(orange, size(background))
	]),
	PlutoUI.ExperimentalLayout.hbox([
		alpha_float .* foreground + (1 .- alpha_float) .* imresize(load("./res/Luan.jpg"), size(background)),
		alpha_float .* foreground + (1 .- alpha_float) .* imresize(berkeley, size(background))
	])
], class="twocols")

# ╔═╡ 2d57a0fc-7a18-474c-85ef-5dbf217ac62b
alpha_float .* foreground + (1 .- alpha_float) .* background

# ╔═╡ 0819a435-9f3c-40b2-af29-082f4aed35f6
md"""
Shown in the codeblock above, we see that Julia makes it very easy for us to use the compositing equation. 

Zooming in on the picure, however, we see there are a few artifacts on the hair of our two little friends, e. g. the left side of the red hair shows tones of green, which are clear leftovers of the original image, where they were placed in a green field. This has to be because of how hard it is to define the opacity of these very small details in the image.
"""

# ╔═╡ c45bd3e9-4166-451c-bd74-93676a32a07e
md"## Extra Picture"

# ╔═╡ 82fb768d-8a8d-4f09-8f18-582ff474fb00
md"Below, we have a picture of me and Mao Tse Tung at the SF MOMA. It looks very boring and so our colorful buddies want to fix it by being a part of it!" 

# ╔═╡ c38c09d7-8fb8-4379-ab27-b025803f250b
mao = load("./res/mao.JPG")

# ╔═╡ a33126cb-f331-492b-bb4a-a439e86e2968
md"""
To do so, we need to do the following:

1. Create a blank canvas with the resolution of my picture;
2. Scale and rotate the foreground image;
3. Fill a set of coordinates with the foreground pictures;
4. Repeat 2. and 3. for the alpha mask image;

"""

# ╔═╡ ae1d577c-920b-484c-9424-2eaa983e2749
(newforeground, newalpha) = let
	newforeground = zeros(RGB{N0f8}, size(mao))
	scaledforeground = imresize(foreground, floor.(Int64, size(foreground) .* 3.3))
	rotated_img = imrotate(scaledforeground, -π/100)
	(height, width) = size(rotated_img)
	newforeground[1500:1499+height, 800:799+width] = rotated_img
	
	newalpha = zeros(RGB{N0f8}, size(mao))
	scaledalpha = imresize(alpha, floor.(Int64, size(alpha) .* 3.3))
	rotated_alpha = imrotate(scaledalpha, -π/100)
	newalpha[1500:1499+height, 800:799+width] = rotated_alpha
	(newforeground, newalpha .|> Gray .|> Float64)
end;

# ╔═╡ 58110a88-0dc0-41e7-a6d5-9192588f0a54
md"Finally, we get the following, much more fun, image:"

# ╔═╡ 12deb10d-8f64-4372-9787-e7fd548704bf
newalpha .* newforeground + (1 .- newalpha) .* mao

# ╔═╡ 80a234ae-fcfc-42bd-b9fc-74931c127f0d
md"""
# Conclusion

This was a very fun assignment which I didn't have nearly as much time to do as the past ones. Nonetheless, it was very simple and so I didn't need as much time. I think the pictures that were achieved by this look absolutely great and this shows how simple algorithms can be very useful and generate outstanding results. Needless to say I learnt a lot.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DSP = "717857b8-e6f2-59f4-9121-6e50c889abd2"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
ImageFiltering = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"

[compat]
DSP = "~0.7.6"
HypertextLiteral = "~0.9.4"
ImageFiltering = "~0.7.1"
Images = "~0.25.2"
PlutoUI = "~0.7.39"
PyCall = "~1.93.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "1dd4d9f5beebac0c03446918741b1a03dc5e5788"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.6"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.CatIndices]]
deps = ["CustomUnitRanges", "OffsetArrays"]
git-tree-sha1 = "a0f80a09780eed9b1d106a1bf62041c2efc995bc"
uuid = "aafaddc9-749c-510e-ac4f-586e18779b91"
version = "0.2.2"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "80ca332f6dcb2508adba68f22f551adb2d00a624"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.3"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "d08c20eef1f2cbc6e60fd3612ac4340b89fea322"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.9"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "924cdca592bc16f14d2f7006754a621735280b74"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.1.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[deps.Conda]]
deps = ["Downloads", "JSON", "VersionParsing"]
git-tree-sha1 = "6e47d11ea2776bc5627421d59cdcc1296c058071"
uuid = "8f4d0f93-b110-5947-807f-2305c1781a2d"
version = "1.7.0"

[[deps.CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "681ea870b918e7cff7111da58791d7f718067a19"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.2"

[[deps.CustomUnitRanges]]
git-tree-sha1 = "1a3f97f907e6dd8983b744d2642651bb162a3f7a"
uuid = "dc8bdbbb-1ca9-579f-8c36-e416f6a65cce"
version = "1.0.2"

[[deps.DSP]]
deps = ["Compat", "FFTW", "IterTools", "LinearAlgebra", "Polynomials", "Random", "Reexport", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "3fb5d9183b38fdee997151f723da42fb83d1c6f2"
uuid = "717857b8-e6f2-59f4-9121-6e50c889abd2"
version = "0.7.6"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "5158c2b41018c5f7eb1470d558127ac274eca0c9"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.FFTViews]]
deps = ["CustomUnitRanges", "FFTW"]
git-tree-sha1 = "cbdf14d1e8c7c8aacbe8b19862e0179fd08321c2"
uuid = "4f61f5a4-77b1-5117-aa51-3ab5ef4ef0cd"
version = "0.3.2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "94f5101b96d2d968ace56f7f2db19d0a5f592e28"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.15.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "78e2c69783c9753a91cdae88a8d432be85a2ab5e"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.0+0"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "db5c7e27c0d46fd824d470a3c32a4fc6c935fa96"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "c54b581a83008dc7f292e205f4c409ab5caa0f04"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.10"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[deps.ImageContrastAdjustment]]
deps = ["ImageCore", "ImageTransformations", "Parameters"]
git-tree-sha1 = "0d75cafa80cf22026cea21a8e6cf965295003edc"
uuid = "f332f351-ec65-5f6a-b3d1-319c6670881a"
version = "0.3.10"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "acf614720ef026d38400b3817614c45882d75500"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.4"

[[deps.ImageDistances]]
deps = ["Distances", "ImageCore", "ImageMorphology", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "b1798a4a6b9aafb530f8f0c4a7b2eb5501e2f2a3"
uuid = "51556ac3-7006-55f5-8cb3-34580c88182d"
version = "0.2.16"

[[deps.ImageFiltering]]
deps = ["CatIndices", "ComputationalResources", "DataStructures", "FFTViews", "FFTW", "ImageBase", "ImageCore", "LinearAlgebra", "OffsetArrays", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "TiledIteration"]
git-tree-sha1 = "15bd05c1c0d5dbb32a9a3d7e0ad2d50dd6167189"
uuid = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
version = "0.7.1"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "342f789fd041a55166764c351da1710db97ce0e0"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.6"

[[deps.ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils", "Libdl", "Pkg", "Random"]
git-tree-sha1 = "5bc1cb62e0c5f1005868358db0692c994c3a13c6"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.2.1"

[[deps.ImageMagick_jll]]
deps = ["Artifacts", "Ghostscript_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f025b79883f361fa1bd80ad132773161d231fd9f"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.12+2"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "36cbaebed194b292590cba2593da27b34763804a"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.8"

[[deps.ImageMorphology]]
deps = ["ImageCore", "LinearAlgebra", "Requires", "TiledIteration"]
git-tree-sha1 = "e7c68ab3df4a75511ba33fc5d8d9098007b579a8"
uuid = "787d08f9-d448-5407-9aad-5290dd7ab264"
version = "0.3.2"

[[deps.ImageQualityIndexes]]
deps = ["ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "LazyModules", "OffsetArrays", "Statistics"]
git-tree-sha1 = "0c703732335a75e683aec7fdfc6d5d1ebd7c596f"
uuid = "2996bd0c-7a13-11e9-2da2-2f5ce47296a9"
version = "0.3.3"

[[deps.ImageSegmentation]]
deps = ["Clustering", "DataStructures", "Distances", "Graphs", "ImageCore", "ImageFiltering", "ImageMorphology", "LinearAlgebra", "MetaGraphs", "RegionTrees", "SimpleWeightedGraphs", "StaticArrays", "Statistics"]
git-tree-sha1 = "36832067ea220818d105d718527d6ed02385bf22"
uuid = "80713f31-8817-5129-9cf8-209ff8fb23e1"
version = "1.7.0"

[[deps.ImageShow]]
deps = ["Base64", "FileIO", "ImageBase", "ImageCore", "OffsetArrays", "StackViews"]
git-tree-sha1 = "b563cf9ae75a635592fc73d3eb78b86220e55bd8"
uuid = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
version = "0.3.6"

[[deps.ImageTransformations]]
deps = ["AxisAlgorithms", "ColorVectorSpace", "CoordinateTransformations", "ImageBase", "ImageCore", "Interpolations", "OffsetArrays", "Rotations", "StaticArrays"]
git-tree-sha1 = "8717482f4a2108c9358e5c3ca903d3a6113badc9"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.9.5"

[[deps.Images]]
deps = ["Base64", "FileIO", "Graphics", "ImageAxes", "ImageBase", "ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "ImageIO", "ImageMagick", "ImageMetadata", "ImageMorphology", "ImageQualityIndexes", "ImageSegmentation", "ImageShow", "ImageTransformations", "IndirectArrays", "IntegralArrays", "Random", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "TiledIteration"]
git-tree-sha1 = "03d1301b7ec885b266c0f816f338368c6c0b81bd"
uuid = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
version = "0.25.2"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[deps.IntegralArrays]]
deps = ["ColorTypes", "FixedPointNumbers", "IntervalSets"]
git-tree-sha1 = "be8e690c3973443bec584db3346ddc904d4884eb"
uuid = "1d092043-8f09-5a30-832f-7509e371ab51"
version = "0.1.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "64f138f9453a018c8f3562e7bae54edc059af249"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.4"

[[deps.IntervalSets]]
deps = ["Dates", "Random", "Statistics"]
git-tree-sha1 = "57af5939800bce15980bddd2426912c4f83012d8"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.1"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "Pkg", "Printf", "Reexport", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "81b9477b49402b47fbe7f7ae0b252077f53e4a08"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.22"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "a77b273f1ddec645d1b7c4fd5fb98c8f90ad10a5"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.1"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "361c2b088575b07946508f135ac556751240091c"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.17"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "e595b205efd49508358f7dc670a940c790204629"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.0.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.MetaGraphs]]
deps = ["Graphs", "JLD2", "Random"]
git-tree-sha1 = "2af69ff3c024d13bde52b34a2a7d6887d4e7b438"
uuid = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
version = "0.7.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "4e675d6e9ec02061800d6cfb695812becbd03cdf"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.4"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "0e353ed734b1747fc20cd4cba0edd9ac027eff6a"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.11"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "1ea784113a6aa054c5ebd95945fa5e52c2f378e7"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.7"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "e925a64b8585aa9f4e3047b8d2cdc3f0e79fd4e4"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.16"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "03a7a85b76381a3d04c7a1656039197e70eda03d"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.11"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "MutableArithmetics", "RecipesBase"]
git-tree-sha1 = "d317b9f0dcef76246166f24f19cec16cdad19bf6"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "3.1.7"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "d7a7aef8f8f2d537104f170139553b14dfe39fe9"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.2"

[[deps.PyCall]]
deps = ["Conda", "Dates", "Libdl", "LinearAlgebra", "MacroTools", "Serialization", "VersionParsing"]
git-tree-sha1 = "1fc929f47d7c151c839c5fc1375929766fb8edcc"
uuid = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
version = "1.93.1"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.Quaternions]]
deps = ["DualNumbers", "LinearAlgebra", "Random"]
git-tree-sha1 = "b327e4db3f2202a4efafe7569fcbe409106a1f75"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.5.6"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegionTrees]]
deps = ["IterTools", "LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "4618ed0da7a251c7f92e869ae1a19c74a7d2a7f9"
uuid = "dee08c22-ab7f-5625-9660-a9af2021b33f"
version = "0.3.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays", "Statistics"]
git-tree-sha1 = "3177100077c68060d63dd71aec209373c3ec339b"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays", "Test"]
git-tree-sha1 = "a6f404cc44d3d3b28c793ec0eb59af709d827e4e"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.2.1"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "8fb59825be681d451c246a795117f317ecbcaa28"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.2"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "23368a3313d12a2326ad0035f0db0c0966f438ef"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "66fe9eb253f910fe8cf161953880cfdaef01cdf0"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.0.1"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "fcf41697256f2b759de9380a7e8196d6516f0310"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.0"

[[deps.TiledIteration]]
deps = ["OffsetArrays"]
git-tree-sha1 = "5683455224ba92ef59db72d10690690f4a8dc297"
uuid = "06e1c1a7-607b-532d-9fad-de7d9aa2abac"
version = "0.3.1"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VersionParsing]]
git-tree-sha1 = "58d6e80b4ee071f5efd07fda82cb9fbe17200868"
uuid = "81def892-9a0e-5fdd-b105-ffc91e053289"
version = "1.3.0"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "78736dab31ae7a53540a6b752efc61f77b304c5b"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.8.6+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─87a51a42-1b80-11ed-2daf-ed0ffdbba2f1
# ╟─3ac2397f-5833-4a8b-a0c9-d7a1fb220dcd
# ╟─cc5d2b6a-df56-4323-b150-e38f4901ed61
# ╟─cb1acf84-f567-4ad3-b1e3-834270cba060
# ╟─8c852f74-80b5-4040-b253-7fa0a670e52a
# ╟─d86fadda-440b-4d21-a3b0-7e3843da0df5
# ╟─78dec682-8a8c-4d71-b5b5-c7cc3ed75844
# ╟─bf48bdc1-c394-4a80-9216-da12197a0fc3
# ╟─1baabb42-763c-47d5-b28f-ff1211c6b53f
# ╟─baca2f37-0302-46ee-867d-4142c0dc660f
# ╠═6ec4a969-a7ad-4374-b539-a46be3498492
# ╟─45dc971a-96c0-4666-9903-47ef3331c9a3
# ╟─63927b63-8449-4446-ba9d-9ca5677e603d
# ╟─6b4b0d20-01dc-4c65-8dfb-bb1a19f0f669
# ╟─1980995a-30e1-4361-989a-f492341b2170
# ╟─b20c49e5-6683-4c84-ba37-131dde8cae62
# ╟─b085d890-3ce8-43f6-9fa9-942fb043fb84
# ╟─aa4d3f8a-b3d7-4f53-844a-1a3e55081637
# ╟─ad200eed-620a-4f12-ac2b-bf4ff3b0df0d
# ╟─58593f12-386f-46a9-9b60-609ca14c1668
# ╟─60418d1a-2e7d-4b5b-b653-ecbf99a35b52
# ╟─f8ad71b9-2640-40ca-a336-0a8fbcd8d7e2
# ╟─b7cb9859-3077-4f0a-b7e4-b3508d80d1c7
# ╠═79120528-87aa-408d-aac4-a06afbf36956
# ╠═cc11833e-6dd2-4bb6-874d-18dc2a64df4b
# ╟─dcb7a836-8795-4d58-bb54-1b91102a0b6b
# ╟─3b06a94f-9fa6-4529-b947-5d60294ed888
# ╟─1698fb76-bd3c-42d6-a541-bb7f1a96811c
# ╟─535d10ff-921d-4fe5-a8cc-58ea42641248
# ╠═27a2c607-0938-43c0-98c0-02d6fb6fa996
# ╟─a31b097d-7763-400c-b7a1-2df9607f98d6
# ╠═1e43e851-a63c-4778-a180-9c463e044d50
# ╠═652ab662-ef89-422d-9cf2-28d71063d1b3
# ╟─021b7491-d01a-45fe-94ca-6cf55768d509
# ╟─7f231b63-22d2-46ce-ae36-5d3b75df3bdb
# ╟─4473310c-7b3e-47a3-8367-135f4ee6bc05
# ╠═4cb2e186-3e56-4014-a36b-d722753a6820
# ╟─63085d91-9407-442f-9106-58a5fc6a62b1
# ╠═8b723f2a-01c0-4d95-98d8-6587104399f9
# ╠═283ec60a-a925-431d-be49-f36a247612e9
# ╟─8f298bbd-b2f8-4d11-96fc-cb5d0c0793f0
# ╠═b2627290-f641-4bf1-81a4-fd60acd698f6
# ╟─3e92e715-b9c4-4420-817e-385a9f47b5ae
# ╟─af49fc76-13bb-486c-837d-2ce9ce753dcc
# ╟─86d61a95-c118-44e3-a35d-d1cab327bbd2
# ╟─ef6bcec6-3764-4103-976b-ed23870fa4cd
# ╠═d278c9c5-0e2c-4117-be32-4deaaf7f62dc
# ╠═14cf1de6-8225-47ee-a54f-fce2aa9b15fe
# ╟─cc7a5c65-497d-4d9c-b2a3-2d3317528b5c
# ╟─9423537a-31e1-4966-b11b-9ca8deef5c73
# ╟─700e2abe-3c77-4046-b14e-5149db3fcf80
# ╟─895f4aa3-c4d6-4e58-978a-261995983fc0
# ╟─5360c45f-88b9-4193-ade8-469a9d87cbb2
# ╟─0c6d5f87-773e-4d58-a972-1199981855a0
# ╠═61e8ed0c-ae56-448f-b8b7-559a96c6300f
# ╟─c33f4c84-d965-4beb-a30f-4831b1d4c18d
# ╟─18bf7a1c-8b8b-49ae-b2f8-88b5034c7e57
# ╠═1045e45f-1d38-40b6-b914-6eaff3d04d3e
# ╟─af942307-3cd0-4c22-8dd8-a8fd3ac739c0
# ╟─8a543f5c-610b-47e6-8cb7-511a2d593317
# ╠═ae324f81-719f-4fd3-b627-1341a550e6aa
# ╠═bcc6de80-a742-4d0e-936c-eba49a71a4fe
# ╠═94d24f8e-5b36-497a-8513-19af9c01e885
# ╟─97002a41-ce6b-4e93-a863-682173ee85ea
# ╠═51048d6b-7942-4d7e-b320-8cf181c749b8
# ╟─c6e925a3-6463-415b-8566-5d7354185b25
# ╟─4e36a48c-a80a-4380-86f8-3f0b24eb9698
# ╟─366d1de3-d83c-45fa-9546-978829c424c9
# ╠═2d57a0fc-7a18-474c-85ef-5dbf217ac62b
# ╟─0819a435-9f3c-40b2-af29-082f4aed35f6
# ╟─c45bd3e9-4166-451c-bd74-93676a32a07e
# ╟─82fb768d-8a8d-4f09-8f18-582ff474fb00
# ╟─c38c09d7-8fb8-4379-ab27-b025803f250b
# ╟─a33126cb-f331-492b-bb4a-a439e86e2968
# ╠═ae1d577c-920b-484c-9424-2eaa983e2749
# ╟─58110a88-0dc0-41e7-a6d5-9192588f0a54
# ╠═12deb10d-8f64-4372-9787-e7fd548704bf
# ╟─80a234ae-fcfc-42bd-b9fc-74931c127f0d
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
