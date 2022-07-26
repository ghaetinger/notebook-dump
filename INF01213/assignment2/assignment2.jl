### A Pluto.jl notebook ###
# v0.19.10

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ de381642-2434-4667-8268-660ea5769ec7
using DSP, Images, ImageFiltering, HypertextLiteral, MAT, PlutoUI, Statistics, Latexify

# ╔═╡ 1d63597d-d742-4b21-9e7e-73ec897a5257
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

# ╔═╡ c3796886-34a8-4f18-a56b-2efb7c5e7bbd
@htl("""
<div style="border: solid black; padding: 10px;">
<h1 style="text-align: center">Assignment 2: High Dynamic Range (HDR) Images</h1>
<h4 style="text-align: center">Guilherme Gomes Haetinger - 00274702</h4>
</div>
""")

# ╔═╡ ade34e30-d3d2-4270-a098-1254b68b2ec5
md"""
**Proposal**:
*The goal of this assignment is to familiarize the students with high dynamic range (HDR) images. For this, you will be exploring and creating HDR images from a sequence of
low dynamic range (LDR) images captured with multiple exposures. In order to display
them on LDR displays, you will be also implementing some simple tone mapping operator.
The assignment will also familiarize you with the concept of camera response curves
used for mapping exposure values to pixel values.*
"""

# ╔═╡ 5d9b90c1-6cb6-45fe-950b-cffa47605273
md"""
# Introduction

HDR images are used by most people today to take images without any over/underexposed areas. Most phones already have this functionality and allow us to create beautiful portrait or landscape photos.

I have decided to use Julia for this assignment. I used Matlab to use the **makehdr** command needed for Task 5.
"""

# ╔═╡ 49bb3830-54aa-4fed-a4ca-b1b75a14783f
md"# Task 1"

# ╔═╡ da376133-7b10-425b-838b-fda45e73f7c7
exposure_table = [1/30, 0.1, 0.33, 0.63, 1.3, 4]

# ╔═╡ 4549d5d7-5ab8-44f3-a6ee-3e85ed9a9f80
md"# Task 2"

# ╔═╡ ff337e76-7f06-4ebf-a072-254d63c3940e
md"""
Having the previous exposure time table set, I was able to insert them into the **HDR Shop** tool to calculate the **CRC** (Camera Response Curve). We can, thus, read the curve here in Julia.
"""

# ╔═╡ a30e0020-6c9f-4abb-85e2-435fb60a9948
inverted_parse(a, b) = parse(b, a);

# ╔═╡ 3e8771f6-a85b-4920-8231-3a50118fa4b0
function read_log_curve(filename)
	content = readlines("./res/curve.m")[2:end-2]
	arrays = split.(content, " ") .|> arr -> inverted_parse.(arr, Float64)
	return exp.(reshape(reduce(vcat, arrays), (3, :)))
end

# ╔═╡ ff1ed0d9-008c-4be5-8641-bf0e11afe1e2
curve = read_log_curve("./res/curve.m")

# ╔═╡ 64522ebb-9cd8-4160-bb13-1e13ca632a6c
md"# Task 3"

# ╔═╡ 8d34f96d-485d-4e09-822f-1c90764f5a21
md"""
Still using **HDR Shop**, we can retrieve the following HDR image:

$(load("./res/outhdrshop.jpg"))
"""

# ╔═╡ 8d1fe930-ff02-4026-ba2b-be166de9113c
md"# Task 4"

# ╔═╡ 713652dc-d3ed-4ac3-a573-4c9c9ef91b66
md"""
Now for the main part: retrieving the HDR image through the curve. First of all, we need to load and gamma-decode our images:
"""

# ╔═╡ 2f259531-b963-4aa5-abab-56c9b0948048
image_dir = "./res/images/office/";

# ╔═╡ b6ee6188-2b46-4056-bb0f-00cbbfbd3a06
function gamma_decode(image, γ=1/1.75)
	channels = channelview(image)
	R = channels[1, :, :] .^ (1/γ)
	G = channels[2, :, :] .^ (1/γ)
	B = channels[3, :, :] .^ (1/γ)

	return colorview(RGB, R, G, B)
end

# ╔═╡ c869ffa7-7405-47ee-b0f2-279d1b4ed791
images_no_decode = readdir(image_dir) .|> name -> joinpath(image_dir, name) .|> load;

# ╔═╡ 7ef394e8-692b-4753-9248-864a409bafe4
images = images_no_decode .|> gamma_decode;

# ╔═╡ a25748af-b2f1-42e2-98e5-ea31b1b2af34
md"""
Using the **FastStone** image viewer, I was able to retrieve the exposure times of the input images:

| Image  | Exposure Time |
|---     |---            |
|    $(PlutoUI.ExperimentalLayout.Div(images[1], class="img-show"))    |       $\frac{1}{30}$s        |
|    $(PlutoUI.ExperimentalLayout.Div(images[2], class="img-show"))    |       $0.1$s|
|    $(PlutoUI.ExperimentalLayout.Div(images[3], class="img-show"))    |       $0.33$s|
|    $(PlutoUI.ExperimentalLayout.Div(images[4], class="img-show"))    |       $0.63$s|
|    $(PlutoUI.ExperimentalLayout.Div(images[5], class="img-show"))    |       $1.3$s|
|    $(PlutoUI.ExperimentalLayout.Div(images[6], class="img-show"))    |       $4$s|

I was also able to notice how detailed the EXIF metadata for the `.CR2` images from the last assignment were. They contained `date`, `camera model`, `flash`, `focal length`, `exposure program (Aperture priority)`, `FNUM`, `Metering`, `Exposure time`, `ISO` and even more information.
"""

# ╔═╡ 2939e9ea-e111-48ca-a7cd-7b5953086e44
PlutoUI.ExperimentalLayout.vbox([
	PlutoUI.ExperimentalLayout.hbox(vcat([md"not decode", md":"], images_no_decode), class="img-show"),
	PlutoUI.ExperimentalLayout.hbox(vcat([md"γ-decoded", md":"], images), class="img-show")
])

# ╔═╡ 3afa5b5f-c461-42a4-b809-08f9522e7f97
md"## Clamping method"

# ╔═╡ 922c5d7a-82fd-48bb-bd81-6fd06005d525
md"""
Now that we need to apply the curve to the image channels and put them together with a mean, my first thought on how to get rid of extremes and fit to the curve was to clamp values from the channels to $[1, 255]$. Now, this means we consider every pixel in every image, not discarding the over/underexposed pixels.

Hence, we can achieve this by clamping every image before applying the curve. The following function does that and later on applies the curve and divides every value by the image exposure to retrieve the irradiance value of a pixel.
"""

# ╔═╡ 4700f4cc-f354-4c69-87e0-f3a9cb98aa6d
function get_image_irradiance(image, curve, exposure)
	channels = channelview(image)
	floor_int(x) = floor(Int64, x)
	clamp_255(x) = clamp(x, 1, 255)
	R = channels[1, :, :] .* 255 .+ 1 .|> floor_int .|> clamp_255
	G = channels[2, :, :] .* 255 .+ 1 .|> floor_int .|> clamp_255
	B = channels[3, :, :] .* 255 .+ 1 .|> floor_int .|> clamp_255

	R_crc = curve[1, :][R]
	G_crc = curve[2, :][G]
	B_crc = curve[3, :][B]

	R_n = R_crc ./ exposure
	G_n = G_crc ./ exposure
	B_n = B_crc ./ exposure

	colorview(RGB, R_n, G_n, B_n)
end

# ╔═╡ ff5d62a0-9335-46c1-bb75-42b6ff2bfccc
md"""
We can, then, compute this for every image and calculate the mean:
"""

# ╔═╡ 99fb664e-5e8c-4683-9066-6770caa9ec1b
function clamping_curve_map(curve, images, exposures)
	mean([get_image_irradiance(images[i], curve, exposures[i]) for i ∈ 1:length(images)])
end

# ╔═╡ 0d8c8896-b40f-4c73-a8c3-7927dc43a2f5
md"""
This results in the following HDR image (~70ms):
"""

# ╔═╡ 4ed3d93d-3205-43dd-975d-66c62aef55db
clamping_curve_map(curve, images, exposure_table)

# ╔═╡ 533f00c5-bbc8-4dfe-be26-b662dcbacb83
md"## Discarding method"

# ╔═╡ 28c428fa-535f-4d89-bbb8-9b86e433e45a
md"""
After using clamping, I decided to compare it with the "discard under/overexposed" pixels method using a for loop and recording which pixels should be accounted for:
"""

# ╔═╡ 05653128-1d54-46fb-b505-f341b892eb88
function discarding_curve_map(curve, images, exposures)
	sz = size(images[1])
	non_discarded = zeros(sz)
	accumulator = zeros((3, sz...))
	(rows, cols) = sz
	for (idx, image) ∈ enumerate(images)
		for row ∈ (1:rows)
			for col ∈ (1:cols)
				discard = 0
				final_color = [0., 0., 0.]
				for channel ∈ [(red, 1), (green, 2), (blue, 3)]
					color = first(channel)(image[row, col])
					color = round(Int64, color * 255 + 1)
					clamped_color = clamp(color, 1, 255)
					curved = curve[last(channel), clamped_color]
					final_color[last(channel)] += curved ./ exposures[idx]
					if (color < 1 || color > 255)
						discard += 1
					end
				end
				if (discard < 3) 
					accumulator[:, row, col] += final_color
					non_discarded[row, col] += 1
				end
			end
		end
	end

	return colorview(RGB, accumulator[1, :, :], accumulator[2, :, :], accumulator[3, :, :]) ./ non_discarded
end

# ╔═╡ cd3f6fdd-41e7-4be2-8a2a-a5ebb92b34d0
md"""
This method results in an almost exact result with a much higher computation time (~10s):
"""

# ╔═╡ cffff739-a1f8-4187-b468-2e3fe978e739
discarding_curve_map(curve, images, exposure_table)

# ╔═╡ 4ebf4bc0-3a53-49e7-8299-01838b5e5aa6
md"## Playing with exposure"

# ╔═╡ e31b2cd4-4a0d-43cd-92ad-ca689dfff096
md"""
Now that we've retrieved the HDR image from the image sequence, we can multiply it by whatever exposure we want. Increasing exposure gives us a sequence like the following:
"""

# ╔═╡ 1a393ecf-29ca-4fbe-86ba-80c4ad1ca80c
hdr = clamping_curve_map(curve, images, exposure_table)

# ╔═╡ 246ccae4-056a-4ab2-bee8-098140acb7ea
PlutoUI.ExperimentalLayout.vbox([
	PlutoUI.ExperimentalLayout.hbox(vcat([md"image sequence", md":"], images), class="img-show"),
	PlutoUI.ExperimentalLayout.hbox(vcat([md"exposure multiplied images", md":"], [hdr * ex for ex ∈ exposure_table]), class="img-show")
])

# ╔═╡ 24fd0b2d-df8d-4765-929e-364eaa0b3315
md"""
Although this isn't a perfect reproduction of the original images, we are getting all of this from the same image, which is very impressive.
"""

# ╔═╡ f9c72445-d068-4760-9180-17f3e3b95675
md"## Tonemap command"

# ╔═╡ 583bced0-6ae6-4151-88bd-34520c118c6c
md"""
Using Matlab's *tonemap* command, we get the following image: 
"""

# ╔═╡ 6a2b4f82-0fce-4438-93d2-0c6ff27c61d5
load("./out/tonemapped_out.png")

# ╔═╡ 70f93096-667a-4ae9-beb9-3647d50ad30a
md"# Task 5"

# ╔═╡ f70072e3-20e5-47d7-a827-9a6615e9a68d
md"""
Using Matlab's **makehdr** command with the image sequence, we get the following image:
"""

# ╔═╡ 97c17a3a-e4fe-46ce-a02c-e7614bd576bf
function save_to_matlab(image, filename)
	(rows, columns) = size(image)
	new_image = zeros((rows, columns, 3))

	channels = channelview(image)
	R = channels[1, :, :]
	G = channels[2, :, :]
	B = channels[3, :, :]

	new_image[:, :, 1] = R
	new_image[:, :, 2] = G
	new_image[:, :, 3] = B

	matwrite(filename, Dict("hdr" => new_image))
end;

# ╔═╡ dfc94077-132f-45e3-8289-f712a0b49578
save_to_matlab(hdr, "./out/office.mat")

# ╔═╡ 0e3d6df0-2d93-4ce1-b915-f395c9e02dc8
a =load("./out/makehdr_out.png")

# ╔═╡ 59f172d0-d1ac-4fa1-ad2b-036accca90d4
md"""

This image is much different from our HDR image. It seems to be extremely overexposed while ours seems more saturated and still shows every component of the picture (tree, computer, chair, ...). This might be because of the fact that I saved Matlab's image to PNG, removing some of the data particularities (probably clamping a lot of the data to $1.0$) and resulting on this predominantly white image.

Obviously, this image isn't supposed to be used as the final result. We're still missing the the tonemapping step. Applying **tonemap** to it, we get the following image:
"""

# ╔═╡ dc7952b8-85a8-49b7-ba4e-538d19980068
load("./out/tonemapped_new_hdrout.png")

# ╔═╡ b061af34-f256-437c-b1fb-88493a18e9cf
md"""
Even the tonemapping result seems different. While mine seems to have more contrast, Matlab's seems more uniform. This could be a product of my custom γ value on γ-decoding. 
"""

# ╔═╡ c3669784-54c1-4faf-afd0-2d621a16bfa5
md"# Task 6"

# ╔═╡ 1d044142-29a4-45ac-a5ac-8ec861afb4a6
md"""
Using the algorithm learned in class, we aim to find the proper global luminance for each pixel and replace the currently present one with it. To do so, we start by retrieving the luminance of the linearized intensity with the following function:
"""

# ╔═╡ 004cf0a8-431e-4a12-a813-104e20f1dfa3
function luminance(image)
	channels = channelview(image)
	R = channels[1, :, :]
	G = channels[2, :, :]
	B = channels[3, :, :]

	return (0.299 .* R) .+ (0.587 .* G) .+ (0.114 .* B)
end

# ╔═╡ da4c6d98-770c-4cd2-9ba8-e8329834f3e9
L = luminance(hdr);

# ╔═╡ 2d35e1a0-3940-48f2-a635-30bf917d8bde
L .|> Gray

# ╔═╡ a55215fe-67fc-4a0a-9735-e478899af4b3
md"""
Once we have the $L(x, y)$ image, we can get the **Average Log Luminance** by computing

$\tilde{L} = e^{\frac{1}{N}\sum{\log(L(x, y) + δ)}}$
"""

# ╔═╡ 5f48ab6d-618f-4026-8c74-5d62752b0e30
δ = 1e-8

# ╔═╡ b66b052e-41de-42b5-b863-d4ab03e603d5
L̃ = exp(mean(log.(L .+ δ)))

# ╔═╡ 97914b5f-9750-44d5-ac58-2cd9a918ee4b
md"""
Moreover, we calculate the **Scaled Luminance** using the suggested $\alpha = 0.18$:

$L_s = \frac{\alpha * L}{\tilde{L}}$
"""

# ╔═╡ 3bd55dc0-07e3-4f58-97ab-800764eb1aa4
α = 0.18

# ╔═╡ 9a0addc0-9b9c-460a-95bf-ae4f7d8cc98e
Lₛ = (α * L)/L̃;

# ╔═╡ de691dc2-b1b9-4d7e-a61f-3758f50bd280
Lₛ .|> Gray 

# ╔═╡ dcfdcf4c-03f6-4db4-ac08-cbec22635c31
md"""
Finally, we move $L_s$ to a period $[0, 1)$ by computing the global operator:
"""

# ╔═╡ f3c0fbca-36c4-41dc-8e41-534bbd4314bd
LG = Lₛ ./ (Lₛ .+ 1);

# ╔═╡ 09333c37-c10e-4fbd-beaa-c6193cdbd31a
md"We define the saturation as $1$ as we replace the **linearized intensity** by the **Global operator**"

# ╔═╡ 8d822e59-78d6-448e-b932-8cbe836aa465
saturation = 1

# ╔═╡ 3a260b6e-155a-4edc-b819-3b6847b94b24
tonemapped = LG .* hdr ./ L .* saturation

# ╔═╡ 6f53ae2d-b9ee-4828-929e-26ba0b2bee10
md"""
Playing with saturation, we get the following sequence:
$(PlutoUI.ExperimentalLayout.hbox([ LG .* hdr ./ L .* satu for satu ∈ [0.1, 0.5, 0.8, 1, 1.5, 2, 4]], class="img-show"))
"""

# ╔═╡ 1d5682da-f429-4174-9562-f04485934e97
md"""
We notice the image is still a bit dark, but increasing saturation might make things look overexposed. This is because we are missing a step: γ-encoding. reintegrating γ is much like we did in the previous assignment:
"""

# ╔═╡ 0e948c1b-b698-4d91-ac41-4bd5a737a886
function gamma_encode(image, γ=1/1.75)
	channels = channelview(image)
	R = channels[1, :, :] .^ γ
	G = channels[2, :, :] .^ γ
	B = channels[3, :, :] .^ γ

	return colorview(RGB, R, G, B)
end

# ╔═╡ d886e195-17b5-4770-a7d4-25971f70aea8
gamma_encoded_tonemapped = gamma_encode(tonemapped) .|> RGB

# ╔═╡ 233f0460-2d64-4749-944a-760155d98ef8
md"""
Needless to say, my final result is much more colorful and beautiful than Matlab's. I also thing this is because of the fact I picked a good value for γ ($1.75$).
"""

# ╔═╡ 492f7b4e-8551-47c5-900a-1f5cf5433937
md"# Extra task: *Reinhard's local photographic operator*"

# ╔═╡ 376c5a79-7233-42f7-a607-60d2a1ba7b23
md"""
Having all the steps for the global operator set, it's rather easy to setup the local operator. The first thing we need to do is define the key parameters for this:

* ϕ (sharpness parameter)
* σ_list, which is defined by
  * σ_step
  * max_σ
* ϵ (threshold for $W(x, y)$)

The following parameters were the ones that gave me the best result:
"""

# ╔═╡ 26e028e9-3c9d-4ccc-8ce7-c77e59765485
ϕ = 10

# ╔═╡ bf806dc6-27f8-443b-a895-96ef1406bde5
max_σ = 29

# ╔═╡ c83d9753-d453-426f-a95b-fbff97fe766a
σ_step = 2

# ╔═╡ 20f6a1ad-407f-4cd9-aad0-4715a34dfed0
σ_list = collect(0:σ_step:max_σ)

# ╔═╡ 9a53a711-b9cf-4222-9da7-8ffebac06c4f
ϵ = 0.0001

# ╔═╡ e1c50d81-cc24-4dc4-9a17-6840bd1bbd71
md"""
We can apply gaussian matrices and crop them accordingly to get a sequence of blurred **Scaled Luminance** values:
"""

# ╔═╡ 9708be17-2615-40e2-8bcd-d760ac08ffc8
σ_stack = vcat([Lₛ], [conv(collect(Kernel.gaussian([s, s], [31, 31])), Lₛ)[16:end-15, 16:end-15] for s ∈ σ_list[2:end]]);

# ╔═╡ 1b2b355b-c437-4e34-a34c-6e7a992dd807
PlutoUI.ExperimentalLayout.grid(reshape([l .|> Gray for l in σ_stack], (:, 5)), class="img-show")

# ╔═╡ 39ef672d-db51-43a9-8f3e-a7f28587730c
md"We define a function for $W(x, y)$"

# ╔═╡ d7ed5033-f37b-4bbb-adfd-0befc227f2a8
W(x, y, σ, σ_idx, σ_stack) = 
	(σ_stack[σ_idx][y, x] - σ_stack[σ_idx + 1][y, x])/(((2^ϕ) / (σ^2)) + σ_stack[σ_idx][y, x])

# ╔═╡ e6d06cd9-96d6-4233-ac3e-07a0ce4d4a20
md"""
Now we create a for loop function that goes through each σ value and each pixel, checking whether $|W(x, y)| < \epsilon$. If it is, it defines a maximum σ for it and doesn't visit that pixel again. Once we have every maximum value, we replace $L_s(x, y)$ by the value of the maximum given σ stack at the $(x, y)$ pixel. 
"""

# ╔═╡ 7634afac-40b5-4587-b5d8-9b44d95e0cd1
function local_tonemapping(Lₛ)
	(rows, cols) = size(Lₛ)
	σ_max = zeros(Int64, size(Lₛ))
	W_filled = zeros(Bool, size(Lₛ))
	for σ_idx ∈ (2:length(σ_list)-1)
		for row ∈ (1:rows)
			for col ∈ (1:cols)
				if (W_filled[row, col])
					continue
				end
				W_xy = W(col, row, σ_list[σ_idx], σ_idx, σ_stack)
				if (abs(W_xy) < ϵ)
					W_filled[row, col] = true
				end
				σ_max[row, col] = σ_idx
			end
		end
	end
	new_Lₛ = zeros(Float64, size(Lₛ))
	for row ∈ (1:rows)
			for col ∈ (1:cols)
				idx = σ_max[row, col]
				new_Lₛ[row, col] = σ_stack[idx][row, col]
			end
	end
	return new_Lₛ
end

# ╔═╡ b8334798-62e0-4ba8-b51d-5e22c6aa54da
md"We then do the same thing that we had done for the global operator:"

# ╔═╡ 9ac25a7e-6fa8-4afd-92a1-6d1f14c5fc3e
Ll = Lₛ ./ (local_tonemapping(Lₛ) .+ 1);

# ╔═╡ 6771397b-636d-4fee-b747-47a1eaec1330
local_tonemapped = Ll .* hdr ./ L * saturation;

# ╔═╡ f582fd28-3bb6-4880-90df-219883562e4b
local_gamma_tonemapped = gamma_encode(local_tonemapped)

# ╔═╡ 4aa8f09b-c9d6-4aa9-86a4-a83526e3a32d
md"""
## Result comparison

We can see the results below (top: global, bottom: local). The differences are easily perceivable: we have sharper details on the monitor and on the background trees.

There are some artifacts in the monitor, but mostly because I exagerated on some parameters in order for the differences to be **very perceivable**.
"""

# ╔═╡ 193dca93-9d2d-4fdf-a48b-b409eb7791ec
PlutoUI.ExperimentalLayout.vbox([gamma_encoded_tonemapped, local_gamma_tonemapped])

# ╔═╡ 29445d6e-52ef-40bc-bf9f-5384b63311a5
md"Here we can see a bit more how much sharper the local operator makes the image."

# ╔═╡ 4f923665-1872-4530-925b-f5eda787bdf5
PlutoUI.ExperimentalLayout.vbox([gamma_encoded_tonemapped[1:400, 500:end], local_gamma_tonemapped[1:400, 500:end]])

# ╔═╡ 5fc81c9f-8645-4ed9-9224-b4d11dff3d41
md"""
# Conclusion

It's truly amazing to see how this algorithm pans out in the end. HDR is a very simple idea that, when you dive deep enough, becomes a bit complicated but, nonetheless, elegant. Implementing this was a real treat and I think my results were great, specially the **Local operator** one. I wish I could've understood a bit more about how the local operator parameters affect the final result (ϕ didn't seem to have much effect).

I love taking landscape pictures with HDR on! Implementing it gave me a better insight to how it works and when to use it. Here's a picture I took with HDR on my trip to Punta del Este.
"""

# ╔═╡ da3721b2-6ab9-46fe-832e-b2fb14a2a8b5
load("./res/punta.jpg")

# ╔═╡ 2644c43f-408b-4e6c-84b2-95572ff97733
md"# Interactive playground"

# ╔═╡ e9693d09-4c54-434a-9879-7e7103fce8ac
md"## Exposure * HDR"

# ╔═╡ ecdf7ba0-c998-432a-82b7-695836257241
@bind exposure_time Slider(0.03333:0.01:2; show_value=true)

# ╔═╡ 105d0109-c353-466b-aeec-3a63bba39746
hdr * exposure_time

# ╔═╡ cf10e84a-1045-44e6-8361-ff11e6aa56bc
md"## Saturation"

# ╔═╡ cc143b7f-27a6-4bcb-ba3b-faa54e96642a
@bind sat Slider(0:0.01:2; default=0.8)

# ╔═╡ de394768-9206-4d1e-88ad-2c216f0467ec
LG .* hdr ./ L * sat

# ╔═╡ f4582281-6258-4f1a-be7d-ee9273796965
Ll .* hdr ./ L * sat

# ╔═╡ f8051606-4066-4f20-b1d8-cf579f0f220b
md"# Setup"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DSP = "717857b8-e6f2-59f4-9121-6e50c889abd2"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
ImageFiltering = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
Latexify = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
MAT = "23992714-dd62-5051-b70f-ba57cb901cac"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
DSP = "~0.7.6"
HypertextLiteral = "~0.9.4"
ImageFiltering = "~0.7.1"
Images = "~0.25.2"
Latexify = "~0.15.16"
MAT = "~0.10.3"
PlutoUI = "~0.7.39"
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
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

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

[[deps.BufferedStreams]]
git-tree-sha1 = "bb065b14d7f941b8617bc323063dbe79f55d16ea"
uuid = "e1450e63-4bb3-523b-b2a4-4ffa8c0fd77d"
version = "1.1.0"

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
git-tree-sha1 = "ff38036fb7edc903de4e79f32067d8497508616b"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.2"

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

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

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
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

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
git-tree-sha1 = "9267e5f50b0e12fdfd5a2455534345c4cf2c7f7a"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.14.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

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

[[deps.HDF5]]
deps = ["Compat", "HDF5_jll", "Libdl", "Mmap", "Random", "Requires"]
git-tree-sha1 = "9ffc57b9bb643bf3fce34f3daf9ff506ed2d8b7a"
uuid = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f"
version = "0.16.10"

[[deps.HDF5_jll]]
deps = ["Artifacts", "JLLWrappers", "LibCURL_jll", "Libdl", "OpenSSL_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "bab67c0d1c4662d2c4be8c6007751b0b6111de5c"
uuid = "0234f1f7-429e-5d53-9886-15a909be8d59"
version = "1.12.1+0"

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
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "00a19d6ab0cbdea2978fc23c5a6482e02c192501"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.0"

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

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "1a43be956d433b5d0321197150c2f94e16c0aaa0"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.16"

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
git-tree-sha1 = "09e4b894ce6a976c354a69041a04748180d43637"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.15"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MAT]]
deps = ["BufferedStreams", "CodecZlib", "HDF5", "SparseArrays"]
git-tree-sha1 = "971be550166fe3f604d28715302b58a3f7293160"
uuid = "23992714-dd62-5051-b70f-ba57cb901cac"
version = "0.10.3"

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

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e60321e3f2616584ff98f0a4f18d98ae6f89bbb3"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.17+0"

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
git-tree-sha1 = "d6de04fd2559ecab7e9a683c59dcbc7dbd20581a"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "3.1.5"

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
git-tree-sha1 = "e972716025466461a3dc1588d9168334b71aafff"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.1"

[[deps.StaticArraysCore]]
git-tree-sha1 = "66fe9eb253f910fe8cf161953880cfdaef01cdf0"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.0.1"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "2c11d7290036fe7aac9038ff312d3b3a2a5bf89e"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.4.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "472d044a1c8df2b062b23f222573ad6837a615ba"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.19"

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
# ╟─1d63597d-d742-4b21-9e7e-73ec897a5257
# ╟─c3796886-34a8-4f18-a56b-2efb7c5e7bbd
# ╟─ade34e30-d3d2-4270-a098-1254b68b2ec5
# ╟─5d9b90c1-6cb6-45fe-950b-cffa47605273
# ╟─49bb3830-54aa-4fed-a4ca-b1b75a14783f
# ╟─a25748af-b2f1-42e2-98e5-ea31b1b2af34
# ╟─da376133-7b10-425b-838b-fda45e73f7c7
# ╟─4549d5d7-5ab8-44f3-a6ee-3e85ed9a9f80
# ╟─ff337e76-7f06-4ebf-a072-254d63c3940e
# ╟─a30e0020-6c9f-4abb-85e2-435fb60a9948
# ╠═3e8771f6-a85b-4920-8231-3a50118fa4b0
# ╠═ff1ed0d9-008c-4be5-8641-bf0e11afe1e2
# ╟─64522ebb-9cd8-4160-bb13-1e13ca632a6c
# ╟─8d34f96d-485d-4e09-822f-1c90764f5a21
# ╟─8d1fe930-ff02-4026-ba2b-be166de9113c
# ╟─713652dc-d3ed-4ac3-a573-4c9c9ef91b66
# ╟─2f259531-b963-4aa5-abab-56c9b0948048
# ╠═b6ee6188-2b46-4056-bb0f-00cbbfbd3a06
# ╠═c869ffa7-7405-47ee-b0f2-279d1b4ed791
# ╠═7ef394e8-692b-4753-9248-864a409bafe4
# ╟─2939e9ea-e111-48ca-a7cd-7b5953086e44
# ╟─3afa5b5f-c461-42a4-b809-08f9522e7f97
# ╟─922c5d7a-82fd-48bb-bd81-6fd06005d525
# ╠═4700f4cc-f354-4c69-87e0-f3a9cb98aa6d
# ╠═ff5d62a0-9335-46c1-bb75-42b6ff2bfccc
# ╠═99fb664e-5e8c-4683-9066-6770caa9ec1b
# ╟─0d8c8896-b40f-4c73-a8c3-7927dc43a2f5
# ╠═4ed3d93d-3205-43dd-975d-66c62aef55db
# ╟─533f00c5-bbc8-4dfe-be26-b662dcbacb83
# ╟─28c428fa-535f-4d89-bbb8-9b86e433e45a
# ╠═05653128-1d54-46fb-b505-f341b892eb88
# ╟─cd3f6fdd-41e7-4be2-8a2a-a5ebb92b34d0
# ╠═cffff739-a1f8-4187-b468-2e3fe978e739
# ╟─4ebf4bc0-3a53-49e7-8299-01838b5e5aa6
# ╟─e31b2cd4-4a0d-43cd-92ad-ca689dfff096
# ╠═1a393ecf-29ca-4fbe-86ba-80c4ad1ca80c
# ╟─246ccae4-056a-4ab2-bee8-098140acb7ea
# ╟─24fd0b2d-df8d-4765-929e-364eaa0b3315
# ╟─f9c72445-d068-4760-9180-17f3e3b95675
# ╟─583bced0-6ae6-4151-88bd-34520c118c6c
# ╟─6a2b4f82-0fce-4438-93d2-0c6ff27c61d5
# ╟─70f93096-667a-4ae9-beb9-3647d50ad30a
# ╟─f70072e3-20e5-47d7-a827-9a6615e9a68d
# ╟─97c17a3a-e4fe-46ce-a02c-e7614bd576bf
# ╠═dfc94077-132f-45e3-8289-f712a0b49578
# ╟─0e3d6df0-2d93-4ce1-b915-f395c9e02dc8
# ╟─59f172d0-d1ac-4fa1-ad2b-036accca90d4
# ╟─dc7952b8-85a8-49b7-ba4e-538d19980068
# ╟─b061af34-f256-437c-b1fb-88493a18e9cf
# ╟─c3669784-54c1-4faf-afd0-2d621a16bfa5
# ╟─1d044142-29a4-45ac-a5ac-8ec861afb4a6
# ╠═004cf0a8-431e-4a12-a813-104e20f1dfa3
# ╠═da4c6d98-770c-4cd2-9ba8-e8329834f3e9
# ╟─2d35e1a0-3940-48f2-a635-30bf917d8bde
# ╟─a55215fe-67fc-4a0a-9735-e478899af4b3
# ╟─5f48ab6d-618f-4026-8c74-5d62752b0e30
# ╠═b66b052e-41de-42b5-b863-d4ab03e603d5
# ╟─97914b5f-9750-44d5-ac58-2cd9a918ee4b
# ╟─3bd55dc0-07e3-4f58-97ab-800764eb1aa4
# ╠═9a0addc0-9b9c-460a-95bf-ae4f7d8cc98e
# ╟─de691dc2-b1b9-4d7e-a61f-3758f50bd280
# ╟─dcfdcf4c-03f6-4db4-ac08-cbec22635c31
# ╠═f3c0fbca-36c4-41dc-8e41-534bbd4314bd
# ╟─09333c37-c10e-4fbd-beaa-c6193cdbd31a
# ╟─8d822e59-78d6-448e-b932-8cbe836aa465
# ╠═3a260b6e-155a-4edc-b819-3b6847b94b24
# ╟─6f53ae2d-b9ee-4828-929e-26ba0b2bee10
# ╟─1d5682da-f429-4174-9562-f04485934e97
# ╠═0e948c1b-b698-4d91-ac41-4bd5a737a886
# ╠═d886e195-17b5-4770-a7d4-25971f70aea8
# ╟─233f0460-2d64-4749-944a-760155d98ef8
# ╟─492f7b4e-8551-47c5-900a-1f5cf5433937
# ╟─376c5a79-7233-42f7-a607-60d2a1ba7b23
# ╟─26e028e9-3c9d-4ccc-8ce7-c77e59765485
# ╠═bf806dc6-27f8-443b-a895-96ef1406bde5
# ╠═c83d9753-d453-426f-a95b-fbff97fe766a
# ╠═20f6a1ad-407f-4cd9-aad0-4715a34dfed0
# ╠═9a53a711-b9cf-4222-9da7-8ffebac06c4f
# ╠═e1c50d81-cc24-4dc4-9a17-6840bd1bbd71
# ╠═9708be17-2615-40e2-8bcd-d760ac08ffc8
# ╟─1b2b355b-c437-4e34-a34c-6e7a992dd807
# ╟─39ef672d-db51-43a9-8f3e-a7f28587730c
# ╠═d7ed5033-f37b-4bbb-adfd-0befc227f2a8
# ╟─e6d06cd9-96d6-4233-ac3e-07a0ce4d4a20
# ╠═7634afac-40b5-4587-b5d8-9b44d95e0cd1
# ╟─b8334798-62e0-4ba8-b51d-5e22c6aa54da
# ╠═9ac25a7e-6fa8-4afd-92a1-6d1f14c5fc3e
# ╠═6771397b-636d-4fee-b747-47a1eaec1330
# ╠═f582fd28-3bb6-4880-90df-219883562e4b
# ╟─4aa8f09b-c9d6-4aa9-86a4-a83526e3a32d
# ╟─193dca93-9d2d-4fdf-a48b-b409eb7791ec
# ╟─29445d6e-52ef-40bc-bf9f-5384b63311a5
# ╟─4f923665-1872-4530-925b-f5eda787bdf5
# ╟─5fc81c9f-8645-4ed9-9224-b4d11dff3d41
# ╟─da3721b2-6ab9-46fe-832e-b2fb14a2a8b5
# ╟─2644c43f-408b-4e6c-84b2-95572ff97733
# ╟─e9693d09-4c54-434a-9879-7e7103fce8ac
# ╟─ecdf7ba0-c998-432a-82b7-695836257241
# ╠═105d0109-c353-466b-aeec-3a63bba39746
# ╟─cf10e84a-1045-44e6-8361-ff11e6aa56bc
# ╠═cc143b7f-27a6-4bcb-ba3b-faa54e96642a
# ╠═de394768-9206-4d1e-88ad-2c216f0467ec
# ╠═f4582281-6258-4f1a-be7d-ee9273796965
# ╟─f8051606-4066-4f20-b1d8-cf579f0f220b
# ╠═de381642-2434-4667-8268-660ea5769ec7
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
