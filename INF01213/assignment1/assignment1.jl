### A Pluto.jl notebook ###
# v0.19.9

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

# ╔═╡ 4e03a70e-fbda-11ec-27e8-57c94e35d7f5
using Images, PyCall, HypertextLiteral, PlutoUI, LinearAlgebra, DSP, Latexify

# ╔═╡ 353d5894-7748-4dba-99b7-ac73d18cb02c
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
</style>
""")

# ╔═╡ 8db7742a-a33a-487e-a70a-494607f20ae7
@htl("""
<div style="border: solid black; padding: 10px;">
<h1 style="text-align: center">Assignment 1: Raw Image Decoder</h1>
<h4 style="text-align: center">Guilherme Gomes Haetinger - 00274702</h4>
</div>
""")

# ╔═╡ d8a61941-ea04-41fb-ae05-506ad0e1b3a4
md"""
**Proposal**:
*The goal of this assignment is to familiarize the students with how digital cameras acquire and process  images.  For  this,  you  will  be  implementing  a  raw  image  decoder.  A  CCD  is  a monochromatic sensor and in order to capture color images, digital cameras use color filters on top of the CCD. To reduce cost and simplify design and construction, most cameras use a single CCD  with  a  color  filter  array  (CFA),  such  as  the  Bayer  filter  (see  Figure  1).  Thus,  the  image processing module of a digital camera has to convert the captured raw image data into a full‐color image.*
"""

# ╔═╡ 26f137ef-0ced-4afa-9c54-dd28bb8bec8d
md"# Introduction"

# ╔═╡ 7d406314-7bfe-408e-9774-43a991d43642
md"""
Building the raw image decoder designated to us, students, takes essentially four steps:

- **Reading an image** avoiding all libraries that do all the work for you, *i. e.* finding a library that will give you a correct mosaic of values;

- **Demosaic the image** in a way that it respect the image mosaic pattern (which should be also fetched from the raw image metadata);

- **Apply whitebalancing** to the image in a way that we get a more real like color distribution (not too green, red or blue). This can be made through a couple of ways and we'll be exploring a single one: *Scaling Camera RGB*;

- **Apply γ-encoding** to produce a more real-like picture by enhancing the light effect in the dark areas.
"""

# ╔═╡ 397e9d24-301b-46c4-8161-1937b19daf95
md"""
I've setup three pictures to undergo this whole process. One of them was given with the assignment and the other two were taken with my cellphone, which has the ability of taking *.dng* raw photos.

The image given along the assignment was converted from *.CR2* to *.dng* by Adobe's Digital Negative converter sofware. We'll be using this as our main picture to go along the illustrative examples.
"""

# ╔═╡ 25af2871-6506-4556-97f5-aecf0746ee67
begin
	imgs = readdir("./res/jpgs/") .|>
		   file -> joinpath("./res/jpgs", file) |>
		   load |>
		   img -> PlutoUI.ExperimentalLayout.Div(img, class="jpgedimages")
	PlutoUI.ExperimentalLayout.hbox(imgs, style=Dict("align-items" => "center", "justify-content" => "center"))
end

# ╔═╡ 0fb190f1-4663-42d7-9298-1e3f09ca34e1
md"# Reading Raw Images"

# ╔═╡ ed9e1310-2f6e-43b7-9bc3-4bd76a6c0a74
md"""
I used **Julia** to program this whole assignment, but took advantage of Python's *rawpy* library to read raw image information. This way we can simply extract a variable `raw_pixels` from the read image.

"""

# ╔═╡ 5eb222ff-0413-450c-9fbf-58b89bc8b159
rawpy = PyCall.pyimport("rawpy");

# ╔═╡ 00687920-7625-45fe-9a6a-fad401a93e24
function read_image_and_normalize_content(filename)
	raw = rawpy.imread("./res/dngs/$filename");
	raw_pixels = raw.raw_image;
	norm = Int.(raw_pixels) / maximum(raw_pixels);
	Gray.(norm)
end;

# ╔═╡ 0272f0c8-f017-4d32-bd04-3e1f028c1c6c
PlutoUI.ExperimentalLayout.hbox(["BB8.dng", "Piano.dng"] .|> read_image_and_normalize_content .|> PlutoUI.ExperimentalLayout.Div)

# ╔═╡ 17749ad8-0259-48d0-94b3-3c1265510c99
md"## Filling in the Color Mosaic"

# ╔═╡ 78f3c2c8-c38d-4fb5-9c63-d5e82eb24ae0
md"""
To understand how exactly we should be filling the mosaic, *i. e.* assigning each pixel to a given color, we need to first pick a pattern out of two possible Bayer filter patterns. To do so, we use the `raw_pattern` value from *rawpy*.

The possible patterns are the following:
"""

# ╔═╡ 56a5bc8f-44c4-469f-b96e-3a10312ade99
begin
pattern1 = [
	:R :G
	:G :B
]
	
pattern2 = [
	:G :R
	:B :G
]

latexify(("pattern_1", "pattern2"), (pattern1, pattern2), env=:align)
end

# ╔═╡ 077f11c0-12ff-4da8-9122-335ab051b701
md"""
The format defines in which diagonal the green value takes over. In our example images, we have $pattern_1$ in our assignment image and $pattern_2$ in the rest.

We can calculate the pattern for an image by computing the determinant of the `raw_pattern` matrix from *rawpy* and checking if it determinant is positive or negative.
"""

# ╔═╡ 88caa579-6376-4080-b1e6-0e7bdad1a667
function get_file_pattern(filename)
	raw = rawpy.imread("./res/dngs/$filename");
	pattern = raw.raw_pattern
	det(pattern) < 0 ? "pattern_1" : "pattern_2"
end;

# ╔═╡ 38230a36-50cb-49c5-b7d0-5dae8a97b0b5
md"""
Now that we know the pattern for the image, we can simply setup the indices that populate each channel. In **Julia**, we can do that by having an array of *CartesianIndex* for each color channel.

To populate them, we can move around the image indices by moving a $2x2$ matrix and filling in the correct indices.
"""

# ╔═╡ 262e6d13-6dd5-4b2c-8561-46948d28502a
function create_color_channel_idxs(image, pattern)
	(rows, cols) = size(image);
	red_idxs = []
	green_idxs = []
	blue_idxs = []
	for i ∈ (1:2:rows)
		for j ∈ (1:2:cols)
			if (pattern == "pattern_1")
				push!(red_idxs, (i, j))
				push!(green_idxs, (i, j + 1))
				push!(green_idxs, (i + 1, j))
				push!(blue_idxs, (i + 1, j + 1))
			else
				push!(green_idxs, (i, j))
				push!(red_idxs, (i, j + 1))
				push!(blue_idxs, (i + 1, j))
				push!(green_idxs, (i + 1, j + 1))
			end
		end
	end
	red_idxs = red_idxs .|> CartesianIndex
	green_idxs = green_idxs .|> CartesianIndex
	blue_idxs = blue_idxs .|> CartesianIndex
	return (red_idxs, green_idxs, blue_idxs)
end;

# ╔═╡ d6cf7a17-f149-4e92-9fd2-573e1017b5fb
md"""
Generating the color channel given the indices should be quite easy now. We can generate a blank version the same size of the image using `zeros`, fill it up given the `CartesianIndex` array and make sure it's properly shaped with the original dimensions.
"""

# ╔═╡ 9ec90d84-66be-463d-844e-43c24b3c6505
function setup_color_channel(idxs, values, rows, cols)
	img = zeros((rows, cols))
	img[idxs] = values[idxs]
	return reshape(img, (rows, cols))
end;

# ╔═╡ c8d3cc70-9f2a-4896-8fef-49933c825d6d
md"""
Doing this for every channel should be as straightforward as the following function:
"""

# ╔═╡ c7c55911-c056-4e8a-91db-363957c6c4b0
md"""
From now on, we'll be working on channels separately as they are completely independent from each other. Once we have a decent result, we can then put them together with the `colorview` function. Thus, we can retrieve the color channels from the pattern using the code below.
"""

# ╔═╡ c4fd6dc1-6a3b-44c6-a951-5aeaebe9a818
PlutoUI.ExperimentalLayout.hbox([
	PlutoUI.ExperimentalLayout.Div(load("./out/BB8_mosaic.png")),
	PlutoUI.ExperimentalLayout.Div(load("./out/Piano_mosaic.png")),
])

# ╔═╡ 261edcd3-bb30-4f11-b174-280e5c3889f1
md"# Demosaicking"

# ╔═╡ e185a6d2-073a-40ad-af8f-7d67d6c761fc
md"""
Now that we have the separate channels, we can move on to Demosaicking. This process is done by finding the values of the missing pixels in each channel. We'll be using Bilinear Interpolation to do so. This can be achieved by applying matrix convolution to each channel. The kernels used for this will be the same for the red and blue channel, but will be different for the green channel, which has more pixels in the image.

It's easier to think of them in the following way:

- The green channel's missing pixels will be either red or blue, both of which have green neighbors in all points but the diagonals. Hence, their kernel will be missing weights for the corners.

- The red and blue channels need to look for either pixels on the diagonal, where they need to weight 4 pixels, or look for pixels on the sides, where they'll only have 2 pixels weighted.

Thus, they are represented as follows:

"""

# ╔═╡ ac97e01e-ebd7-476e-8360-99fedbbdfc45
begin
	K_r = [ 1 2 1; 2 4 2; 1 2 1 ];
	K_b = K_r;
	K_g = [ 0 1 0; 1 4 1; 0 1 0 ];
end;

# ╔═╡ eff57c69-9140-407e-8c87-deffce586bfb
latexify((("K_r = K_b", "K_g"), (K_r, K_g)), env=:align)

# ╔═╡ d53e7af6-eb7e-45cc-b331-ebce1e276483
md"""
We can apply the convolution by using the `conv` function, dividing by the defined weight (in this case, 4), clipping out the resulted borders and clamping the results to keep all values in the range $[0, 1]$.
"""

# ╔═╡ b4c784ab-45d9-4a41-996a-5de879b32ea7
function conv_norm(K, M)
	convoluted = conv(K, M)[2:end-1, 2:end-1] / 4.0
	return clamp.(convoluted, 0, 1)
end

# ╔═╡ 0c88c830-ce93-4bfe-8246-31becc6ace30
"""
	conv_image(R, G, B)

Given the three color channels, apply the respective kernels.
"""
function conv_image(R, G, B)
	K_r = [ 1 2 1; 2 4 2; 1 2 1 ];
	K_b = K_r;
	K_g = [ 0 1 0; 1 4 1; 0 1 0 ];
	R_c = conv_norm(K_r, R)
	G_c = conv_norm(K_g, G)
	B_c = conv_norm(K_b, B)
	return (R_c, G_c, B_c)
end

# ╔═╡ 9e52c261-d31f-45f8-afe6-44c049323ee8
md"""
After applying the demosaicking process, we can see that the image is no longer as dark and green, getting more of other colors as well, *e. g.* the blue of the desktop background and the purple on BB8's core. However, it's pretty clear things are still a long way from perfect. Green is predominant and dark objects have almost no inner contrast.
"""

# ╔═╡ 8a3113ed-bbe6-463a-b8ab-f3bd2cbbd317
PlutoUI.ExperimentalLayout.hbox([
	PlutoUI.ExperimentalLayout.Div(load("./out/demosaicked_BB8.png")),
	PlutoUI.ExperimentalLayout.Div(load("./out/demosaicked_Piano.png")),
])

# ╔═╡ 487908e4-c1da-489d-97f0-7d7296171654
md"# White Balance"

# ╔═╡ 50794263-79ee-4de1-b9fa-a4d507d0f594
md"""
To achieve more real-like colors, we rely on a technique called **White Balance**. This technique is based on normalizing each pixel given the assumption that another pixel `P_w` of color `[R_w, B_w, G_w]` is actually white. Therefore, we can create a transformation that maps `[R_w, B_w, G_w]` to `[1, 1, 1]`. This is thus applied to every pixel.

There are some ways of getting the coordinates to `P_w`. Here, we'll just be using a Pluto widget that allows us to click where we want the white pixel to be set. This *Interactive Example* section will only be interactive if on a running Pluto session.
"""

# ╔═╡ 97ef41f3-f49e-42fc-a3b0-17211202852b
"""
	apply_white_balancing(image, P_w)

Apply white balancing to `image` when `P_w` is the considered true white color.
"""
function apply_white_balancing(image, P_w)
	channels = channelview(image)
	R_wb = channels[1, :, :] / P_w.r
	G_wb = channels[2, :, :] / P_w.g
	B_wb = channels[3, :, :] / P_w.b
	colorview(RGB, R_wb, G_wb, B_wb)
end

# ╔═╡ 4bd05bae-ec59-48b3-b590-7762326939e0
md"## Results"

# ╔═╡ 1a5bffa9-7a74-4314-a49e-b3a58d812625
md"""

|   |   |
|---|---|
| $(load("./out/scene_raw_wall.png")) Wall (3336x271) | $(load("./out/scene_raw_paper.png")) Paper (2329x2482) |
| $(load("./out/scene_raw_file.png")) File (1746x754) | $(load("./out/scene_raw_charger.png")) Charger (1298x1448) |

"""

# ╔═╡ fd13c40e-44b7-4a38-b966-a27b17003df0
md"""

It's clear that the picked pixel has a huge influence on how the image will turn out. Not only is the overall brightness of the image influenced, but also the color tone. The two best results, in my opinion, would be the *File* and the *Charger*. The *File* is a bit darker but holds contrast in the desktop with a somewhat warmer tone. The *Charger* holds a colder tone and has more contrast on the darker areas of the image.

"""

# ╔═╡ 1fb77f03-af1d-473a-ba6d-d731497ac8db
md"""

| BB8  | Piano  |
|---|---|
| $(load("./out/BB8_body.png")) BB8's core (2796x3034) | $(load("./out/Piano_bg_light.png")) Background Light (175x1780) |
| $(load("./out/BB8_eye.png")) The Pug's eyeball (3043x1094) | $(load("./out/Piano_light_key.png")) Lightest Key (3027x2571) |

"""

# ╔═╡ 9a830790-d2bc-41be-9349-15e9e55d8c04
md"""
These two extra example images have faulty setups for this *pick your pixel* algorithm: both of them don't have a clear white element. Thus, the colors can assume tones that aren't real-like even with white-balancing. Although I was able to get a better result on *BB8*'s picture by selecting the *Pug's eyeball*, it got too dark (which will be fixed by gamma encoding) and too warm. The *Piano* picture was taken in a very dark room with warm lighting, so selecting the white-ish key means every other pixel will have to increase their blue value and so the scene will be a bit bluer.
"""

# ╔═╡ da19139d-ab23-4c04-8f36-bf4102d5cef0
md"# Gamma Encoding" 

# ╔═╡ 04b08803-37ea-433a-9e6d-3866b3831ca3
md"""
The human eye is more sensible to changes in dark areas of pictures. This variation isn't present in digital picture capture, which captures the signals linearly. Thus, we must find a way to compensate and enhance dark signals while compressing bright ones. This can be done by raising every value to a `γ`. This process is called *Gamma Encoding*. We'll be doing this just the same as the other functionalities, processing per channel.
"""

# ╔═╡ 5459ed87-9748-4b1f-8ed7-73e1451b7298
"""
	apply_gamma(image, γ)

Apply gamma correction given an `image` and a `γ`.
"""
function apply_gamma(image, γ)
	channels = channelview(image)
	R_gc = (channels[1, :, :]) .^ γ
	G_gc = (channels[2, :, :]) .^ γ
	B_gc = (channels[3, :, :]) .^ γ
	colorview(RGB, R_gc, G_gc, B_gc)
end

# ╔═╡ 59991d37-9e10-4462-a6fe-25b866e121a6
md"""
As a first impression, we can see how the picture isn't as dark and uniform anymore. We can see more of it and the colors are more natural. The result isn't perfect, but it's still much better than what we had as an input.
"""

# ╔═╡ 01cf5689-c8a0-47a4-82e9-c0d42a69757e
md"## Results"

# ╔═╡ 81b1bd62-da6c-4d86-9337-6ebd0c651eca
md"""
The results below show how much the `γ` variation can change the picture. 

The computer with a high `γ` of `2.0` shows the monitor in high contrast with colorful icons, but with a dark and almost uniform background. When applying a very small `γ`, however, we see that all the picture becomes unrealistically bright. We then settle for a small `γ` that helps us see the laptop monitor is displaying something while also keeping the overall contrast of the picture.

The same goes for *BB8*'s picture, there the high `γ` offuscates the toy and highlights the highly contrasted pug, whereas with `γ = 0.75` they both seem to have the same amount of contrast, arranging the picture in a much better way.

The Piano picture still shows to have a bad result. With the failed attempt of whitebalancing, the picture looks extremely bluish. The `γ = 1.0` seems to give out the best result in terms of visibilty, though. This is probably due to the fact that the image was captured in a very dark room. Even though this isn't the best taken photo out of the three, the piano's `γ = 2.0` result is a very artistic output in my opinion.
"""

# ╔═╡ 2d885f08-e7b3-4076-8b90-e2ec7c3c9d60
md"# Conclusion"

# ╔═╡ fe92f091-b309-4dba-9a91-9f4ad6fac275
md"""
This assignment was very interesting and insightful to take. Not only was I able to relearn the things we talked about in class, but I was able to put them to practice, understanding the influence of each variable in the process of creating a digital photography, from taking a picture to producing the proper color channels for it. I think the most fascinating was to finish it and think *"how did people take pictures that look better than the ones I produced on the early 20th century?"* Creative people like **Sergei Mikhailovich Prokudin-Gorskii** took pictures and elaborated concepts that would precede these optimizations and post-processing factors we have today.

$(PlutoUI.ExperimentalLayout.hbox([
	PlutoUI.ExperimentalLayout.Div(load("./res/examples/monastery.jpg"), class="monastery"),
 	PlutoUI.ExperimentalLayout.Div(load("./res/examples/monastery_final.jpg"))
], style=Dict("align-items" => "center", "justify-content" => "center", "gap" => "2em")))

> Set of images taken with separate filters `R, G, B` (left) reconstructed by me into a full colored picture (right) using alignment algorithms. Pictures were taken by **Sergei** with his three lensed camera.
"""

# ╔═╡ b458fb9f-cd7e-461c-9dfa-bc6217faa776
md"""
As a retrospect to what I was able to achieve with my examples, I'd say that both my pictures could look better if I had added a piece of white paper on the picture, just to make sure I had a proper white reference. Other than that, maybe I could have achieve better white balance results on the Piano image if I had approached it with the Gray world algorithm, which finds a proper pixel instead of having the user select it. Maybe in the future I can go back to this and apply more complex and automatic processes to image post-processing.

It's funny to see how complex digital image capturing actually is. I grew up taking pictures with my father's camera and then my phone, and then sharing it with whomever I wanted in any format I wanted to do so. This assignment shows the depth that digital image capturing has, as we've seemed to have just scratched the surface since I am not able to say confidently that my images are real-like. I'm excited to see what's next.
"""

# ╔═╡ f55831b2-c4ad-4a7c-9541-d12fb3eb8c9b
@htl("""
$([@htl("<br>") for i ∈ (1:40)])
""")

# ╔═╡ 4d591a49-6eee-4913-aa4b-c89729a59595
md"# Appendix: Use this on a running Pluto instance!"

# ╔═╡ eda6fe51-894d-491e-a7a5-b99f3057ba5a
md"## Interaction"

# ╔═╡ dcae0d33-669e-4f50-82f8-491f6695e926
md"### Select a photo"

# ╔═╡ a899b736-922c-4139-ac85-e2fc7fa52497
@bind filename Select(readdir("./res/dngs"), default="scene_raw.dng")

# ╔═╡ 5234ce64-51ec-4552-81a5-61905f5ce17b
grayscale = read_image_and_normalize_content(filename)

# ╔═╡ e67d0353-27d0-4944-a881-c638729fa573
PlutoUI.ExperimentalLayout.hbox([md"""
If we zoom in, we can actually see how mosaicked this image is even when monochromatic, since different colors have different influence values on the output image.
""", grayscale[200:220, 200:220]])

# ╔═╡ b66d8053-e997-4dc9-a4f6-c104d35296cb
function setup_color_channels(image, red_idxs, green_idxs, blue_idxs)
	(rows, cols) = size(image);
	R = setup_color_channel(red_idxs, grayscale, rows, cols)
	G = setup_color_channel(green_idxs, grayscale, rows, cols)
	B = setup_color_channel(blue_idxs, grayscale, rows, cols)
	return (R, G, B)
end;

# ╔═╡ a7051130-902c-4287-b481-d1f2349ca5ba
scene_pattern = get_file_pattern(filename)

# ╔═╡ 1f5a9ad8-20de-4ef3-ab1f-bac95d20ebbc
(red_idxs, green_idxs, blue_idxs) =
	create_color_channel_idxs(grayscale, scene_pattern);

# ╔═╡ ba9eb291-ce6a-4cad-b471-3daa6517aadc
(R, G, B) = setup_color_channels(grayscale, red_idxs, green_idxs, blue_idxs);

# ╔═╡ 49ae0a41-bf81-46d6-905b-47f898d0a1fe
md"""
We can see how the pattern is reflected by plotting the values of each channel!

| R | G | B | RGB |
|---|---|---|-----|
| $(Gray.(R[200:220, 200:220]))  | $(Gray.(G[200:220, 200:220]))  | $(Gray.(B[200:220, 200:220]))  | $(colorview(RGB, R, G, B)[200:220, 200:220]) |

"""

# ╔═╡ 5ee77197-6b2a-4b92-8eb1-0e95d9919fe9
colorview(RGB, R, G, B)

# ╔═╡ 0600353f-f353-4bd5-a4d5-0bcf26c3c412
(R_c, G_c, B_c) = conv_image(R, G, B);

# ╔═╡ a2e61c94-415d-4018-8437-098de32364d4
demosaicked = colorview(RGB, R_c, G_c, B_c)

# ╔═╡ bb118283-e82f-45f7-a9a3-fde1e5d1b95e
white_balanced = apply_white_balancing(demosaicked, demosaicked[754, 1746])

# ╔═╡ 9fbe174f-8bb8-44a6-9bae-3d0a5f8f8952
apply_gamma(white_balanced, 0.75)

# ╔═╡ 0b0de13c-c10c-48f7-9a2e-224ce2673849
@bind γ Slider(0:0.1:3; show_value=true, default=0.7)

# ╔═╡ c28b891a-8776-470a-ac79-1f5ffb6cd978
md"""

### Click on the image on the top
### Adjust `γ` with the slider
"""

# ╔═╡ 5830809d-00c1-48bb-b1a8-6dedb7c57c0b
md"## Setup"

# ╔═╡ b77e54c9-7283-4662-9be0-8f8da6412c61
"""
	ImageClicker(img_src, id; default=Dict("x" => 0.5, "y" => 0.5))

Creates a widget that takes in the `cell_id` of a pluto displayed image and a unique `id` to enable other `ImageClicker`s. It can also have a default coordinate set.
"""
ImageClicker(cell_id, id; default=Dict("x" => 0.5, "y" => 0.5)) = @htl("""
<span id="$id">
	<script src="http://d3js.org/d3.v3.min.js" charset="utf-8"></script>
	<script>
		const span = currentScript.parentElement;
		span.value = {
				x: $(default["x"]),
				y: $(default["y"]),
			};
		span.dispatchEvent(new CustomEvent("input"));

		
		const myimage = d3.select("#" + $(cell_id)).select("img").node();
		const replicate_image = d3.select(span).select("#clickimage-" + $id)
		.attr("src", d3.select(myimage).attr("src")).node();
		
		replicate_image.onclick = function(e) {
			var ratioX = e.target.naturalWidth / e.target.offsetWidth;
			var ratioY = e.target.naturalHeight / e.target.offsetHeight;
			var imgX = Math.round(e.offsetX * ratioX);
			var imgY = Math.round(e.offsetY * ratioY);

			span.value = {
				x: imgX / e.target.naturalWidth,
				y: imgY / e.target.naturalHeight,
			};
			
			span.dispatchEvent(new CustomEvent("input"));
		};
	</script>
	<img id="clickimage-$(id)"/>
</span>
""")

# ╔═╡ 25d6d8f1-3d31-49bf-a549-c9f8d7f334bc
clicker = @bind coord ImageClicker("a2e61c94-415d-4018-8437-098de32364d4", "whitebalance_img")

# ╔═╡ db4a481f-d170-41b6-88ed-b6c1dfb903e6
true_white = let
	(rows, cols) = size(grayscale)
	x = ismissing(coord) ? 0.5 : coord["x"] * cols |> floor |> Int64
	y = ismissing(coord) ? 0.5 : coord["y"] * rows |> floor |> Int64
	demosaicked[y, x]
end

# ╔═╡ 65382d23-88e1-494c-892e-1db25bb00ab4
white_applied = apply_white_balancing(demosaicked, true_white);

# ╔═╡ e60fbfb8-ca57-452b-a019-fab982f0a929
gamma_applied = apply_gamma(white_applied, γ);

# ╔═╡ 9033caf6-9911-425f-bf31-b59432ab2a6b
PlutoUI.ExperimentalLayout.vbox([PlutoUI.ExperimentalLayout.Div(clicker), 
	PlutoUI.ExperimentalLayout.hbox([PlutoUI.ExperimentalLayout.Div(white_applied), PlutoUI.ExperimentalLayout.Div(gamma_applied)])])

# ╔═╡ ff82d428-2e3c-4ed7-9fe1-1d0032d55703
md"# Environment Setup"

# ╔═╡ 022456b3-27f1-45da-9836-438af789a1fd
md"### Libraries"

# ╔═╡ 228d9438-685b-4278-8ea7-dd836363bddf
md"### Python environment fix"

# ╔═╡ 0b24ae86-e251-4d78-9275-42c49fa74176
link_dir = read(`which python`, String)[1:end-1]

# ╔═╡ 2a193177-f290-408a-8ad3-7f3b1c93cf6f
python_environment = read(`readlink -f $link_dir`, String)[1:end-length("/bin/python/" )]

# ╔═╡ 9c1b248f-9915-4b41-9120-1e5fe9ae1a49
pushfirst!(
	pyimport("sys")."path",
	joinpath(python_environment, "lib/python3.9/site-packages")
);

# ╔═╡ 72833147-bc90-4d16-83f4-26bb2a129a5f
γ_vals = [0.25, 0.75, 1.0, 2.0];

# ╔═╡ e5c7b497-c610-4adb-a91d-2a4ba8ed503e
PlutoUI.ExperimentalLayout.hbox([PlutoUI.ExperimentalLayout.vbox([md"γ = $(γ_vals[i])", img]) for (i, img) ∈ enumerate([load("./out/scene_raw_gamma_0.25.png"), load("./out/scene_raw_gamma_0.5.png"), load("./out/scene_raw_gamma_1.0.png"), load("./out/scene_raw_gamma_2.0.png")])])

# ╔═╡ 17c49036-9cb5-4dda-9f1d-a9b839f374d1
PlutoUI.ExperimentalLayout.hbox([PlutoUI.ExperimentalLayout.vbox([md"γ = $(γ_vals[i])", img]) for (i, img) ∈ enumerate([load("./out/BB8_gamma_0.25.png"), load("./out/BB8_gamma_0.5.png"), load("./out/BB8_gamma_1.0.png"), load("./out/BB8_gamma_2.0.png")])])

# ╔═╡ 61bc8caa-7ef9-4a08-b3d3-e5e7520f6b7f
PlutoUI.ExperimentalLayout.hbox([PlutoUI.ExperimentalLayout.vbox([md"γ = $(γ_vals[i])", img]) for (i, img) ∈ enumerate([load("./out/Piano_gamma_0.25.png"), load("./out/Piano_gamma_0.5.png"), load("./out/Piano_gamma_1.0.png"), load("./out/Piano_gamma_2.0.png")])])

# ╔═╡ a0d071a8-46ba-4f12-b733-32b318471558
#PlutoUI.ExperimentalLayout.vbox([clicker, white_balanced])

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DSP = "717857b8-e6f2-59f4-9121-6e50c889abd2"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
Latexify = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"

[compat]
DSP = "~0.7.6"
HypertextLiteral = "~0.9.4"
Images = "~0.25.2"
Latexify = "~0.15.15"
PlutoUI = "~0.7.39"
PyCall = "~1.93.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
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
git-tree-sha1 = "2dd813e5f2f7eec2d1268c57cf2373d3ee91fcea"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.1"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "1e315e3f4b0b7ce40feded39c73049692126cf53"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.3"

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
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
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

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

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
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils"]
git-tree-sha1 = "ca8d917903e7a1126b6583a097c5cb7a0bedeac1"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.2.2"

[[deps.ImageMagick_jll]]
deps = ["JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "1c0a2295cca535fabaf2029062912591e9b61987"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.10-12+3"

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
git-tree-sha1 = "40c9e991dbe0782a1422e6dca6c487158f3ca848"
uuid = "2996bd0c-7a13-11e9-2da2-2f5ce47296a9"
version = "0.3.2"

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
git-tree-sha1 = "42fe8de1fe1f80dab37a39d391b6301f7aeaa7b8"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.9.4"

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
git-tree-sha1 = "b7bc05649af456efc75d178846f47006c2c4c3c7"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.6"

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
git-tree-sha1 = "46a39b9c58749eefb5f2dc1178cb8fab5332b1ab"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.15"

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
git-tree-sha1 = "737a5957f387b17e74d4ad2f440eb330b39a62c5"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.0"

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
git-tree-sha1 = "5d389e6481b9d6c81d73ee9a74d1fd74f8b25abe"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "3.1.4"

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
git-tree-sha1 = "9f8a5dc5944dc7fbbe6eb4180660935653b0a9d9"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.0"

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
git-tree-sha1 = "48598584bacbebf7d30e20880438ed1d24b7c7d6"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.18"

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
# ╟─353d5894-7748-4dba-99b7-ac73d18cb02c
# ╟─8db7742a-a33a-487e-a70a-494607f20ae7
# ╟─d8a61941-ea04-41fb-ae05-506ad0e1b3a4
# ╟─26f137ef-0ced-4afa-9c54-dd28bb8bec8d
# ╟─7d406314-7bfe-408e-9774-43a991d43642
# ╟─397e9d24-301b-46c4-8161-1937b19daf95
# ╟─25af2871-6506-4556-97f5-aecf0746ee67
# ╟─0fb190f1-4663-42d7-9298-1e3f09ca34e1
# ╟─ed9e1310-2f6e-43b7-9bc3-4bd76a6c0a74
# ╠═5eb222ff-0413-450c-9fbf-58b89bc8b159
# ╠═00687920-7625-45fe-9a6a-fad401a93e24
# ╠═5234ce64-51ec-4552-81a5-61905f5ce17b
# ╟─0272f0c8-f017-4d32-bd04-3e1f028c1c6c
# ╟─e67d0353-27d0-4944-a881-c638729fa573
# ╟─17749ad8-0259-48d0-94b3-3c1265510c99
# ╟─78f3c2c8-c38d-4fb5-9c63-d5e82eb24ae0
# ╟─56a5bc8f-44c4-469f-b96e-3a10312ade99
# ╟─077f11c0-12ff-4da8-9122-335ab051b701
# ╠═88caa579-6376-4080-b1e6-0e7bdad1a667
# ╟─a7051130-902c-4287-b481-d1f2349ca5ba
# ╟─38230a36-50cb-49c5-b7d0-5dae8a97b0b5
# ╠═262e6d13-6dd5-4b2c-8561-46948d28502a
# ╟─d6cf7a17-f149-4e92-9fd2-573e1017b5fb
# ╠═9ec90d84-66be-463d-844e-43c24b3c6505
# ╟─c8d3cc70-9f2a-4896-8fef-49933c825d6d
# ╠═b66d8053-e997-4dc9-a4f6-c104d35296cb
# ╟─c7c55911-c056-4e8a-91db-363957c6c4b0
# ╠═1f5a9ad8-20de-4ef3-ab1f-bac95d20ebbc
# ╠═ba9eb291-ce6a-4cad-b471-3daa6517aadc
# ╟─49ae0a41-bf81-46d6-905b-47f898d0a1fe
# ╠═5ee77197-6b2a-4b92-8eb1-0e95d9919fe9
# ╟─c4fd6dc1-6a3b-44c6-a951-5aeaebe9a818
# ╟─261edcd3-bb30-4f11-b174-280e5c3889f1
# ╟─e185a6d2-073a-40ad-af8f-7d67d6c761fc
# ╟─eff57c69-9140-407e-8c87-deffce586bfb
# ╟─ac97e01e-ebd7-476e-8360-99fedbbdfc45
# ╟─d53e7af6-eb7e-45cc-b331-ebce1e276483
# ╠═b4c784ab-45d9-4a41-996a-5de879b32ea7
# ╠═0c88c830-ce93-4bfe-8246-31becc6ace30
# ╠═0600353f-f353-4bd5-a4d5-0bcf26c3c412
# ╟─9e52c261-d31f-45f8-afe6-44c049323ee8
# ╠═a2e61c94-415d-4018-8437-098de32364d4
# ╟─8a3113ed-bbe6-463a-b8ab-f3bd2cbbd317
# ╟─487908e4-c1da-489d-97f0-7d7296171654
# ╟─50794263-79ee-4de1-b9fa-a4d507d0f594
# ╠═97ef41f3-f49e-42fc-a3b0-17211202852b
# ╠═bb118283-e82f-45f7-a9a3-fde1e5d1b95e
# ╟─4bd05bae-ec59-48b3-b590-7762326939e0
# ╟─1a5bffa9-7a74-4314-a49e-b3a58d812625
# ╟─fd13c40e-44b7-4a38-b966-a27b17003df0
# ╟─1fb77f03-af1d-473a-ba6d-d731497ac8db
# ╟─9a830790-d2bc-41be-9349-15e9e55d8c04
# ╟─da19139d-ab23-4c04-8f36-bf4102d5cef0
# ╟─04b08803-37ea-433a-9e6d-3866b3831ca3
# ╠═5459ed87-9748-4b1f-8ed7-73e1451b7298
# ╠═9fbe174f-8bb8-44a6-9bae-3d0a5f8f8952
# ╟─59991d37-9e10-4462-a6fe-25b866e121a6
# ╟─01cf5689-c8a0-47a4-82e9-c0d42a69757e
# ╟─81b1bd62-da6c-4d86-9337-6ebd0c651eca
# ╟─e5c7b497-c610-4adb-a91d-2a4ba8ed503e
# ╟─17c49036-9cb5-4dda-9f1d-a9b839f374d1
# ╟─61bc8caa-7ef9-4a08-b3d3-e5e7520f6b7f
# ╟─2d885f08-e7b3-4076-8b90-e2ec7c3c9d60
# ╟─fe92f091-b309-4dba-9a91-9f4ad6fac275
# ╟─b458fb9f-cd7e-461c-9dfa-bc6217faa776
# ╟─f55831b2-c4ad-4a7c-9541-d12fb3eb8c9b
# ╟─4d591a49-6eee-4913-aa4b-c89729a59595
# ╟─eda6fe51-894d-491e-a7a5-b99f3057ba5a
# ╟─dcae0d33-669e-4f50-82f8-491f6695e926
# ╟─a899b736-922c-4139-ac85-e2fc7fa52497
# ╟─db4a481f-d170-41b6-88ed-b6c1dfb903e6
# ╠═0b0de13c-c10c-48f7-9a2e-224ce2673849
# ╟─c28b891a-8776-470a-ac79-1f5ffb6cd978
# ╟─9033caf6-9911-425f-bf31-b59432ab2a6b
# ╟─5830809d-00c1-48bb-b1a8-6dedb7c57c0b
# ╟─b77e54c9-7283-4662-9be0-8f8da6412c61
# ╠═25d6d8f1-3d31-49bf-a549-c9f8d7f334bc
# ╠═65382d23-88e1-494c-892e-1db25bb00ab4
# ╠═e60fbfb8-ca57-452b-a019-fab982f0a929
# ╟─ff82d428-2e3c-4ed7-9fe1-1d0032d55703
# ╟─022456b3-27f1-45da-9836-438af789a1fd
# ╠═4e03a70e-fbda-11ec-27e8-57c94e35d7f5
# ╟─228d9438-685b-4278-8ea7-dd836363bddf
# ╟─0b24ae86-e251-4d78-9275-42c49fa74176
# ╟─2a193177-f290-408a-8ad3-7f3b1c93cf6f
# ╠═9c1b248f-9915-4b41-9120-1e5fe9ae1a49
# ╟─72833147-bc90-4d16-83f4-26bb2a129a5f
# ╟─a0d071a8-46ba-4f12-b733-32b318471558
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
