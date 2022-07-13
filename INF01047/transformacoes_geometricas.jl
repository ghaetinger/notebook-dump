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

# ╔═╡ 210b43e4-dd08-11ec-124e-832694b3f20f
begin
	using Pkg
	Pkg.activate(".")
	using HypertextLiteral, PlutoUI, Portinari, Images, StaticArrays
end

# ╔═╡ 92565f5d-c70f-4737-8787-2e368c9a89cb
@htl("""
<style>

#title {
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	text-align: center;
	height: 15em;
    color: white;
	background: #373789;
	border: solid 0.1em black;
	border-radius: 37px;
}

#title-text {
	font-family: "JuliaMono";
	font-size: 1.5em;
    text-decoration: underline;
}

h3 {
    color: white !important;
	text-align: center;
    text-decoration: underline;
	background: #373789;
	border: solid 0.05em black;
	border-radius: 37px;
	font-family: "JuliaMono";
}

.plot {
	background: #498258;
	border: solid 0.1em black;
	border-radius: 5px;
	justify-content: center;
	align-items: center;
	position: absolute;
}

@media only screen and (max-width: 1000px) {
	.plot {
		position: unset;
	}
}



</style>
<div id="title">
<p id="title-text">Transformações Geométricas - INF01047</p>
<p id="contact">Prof. Eduardo S. L. Gastal - <i>eslgastal@inf.ufrgs.br</i></p>
<p id="contact">Guilherme G. Haetinger - <i>gghaetinger@inf.ufrgs.br</i></p>
</div>
""")

# ╔═╡ 0e4384cf-20c2-4676-bda2-79538f8ff4e6
TableOfContents(title="Transformações Geométricas 🔬", aside=true)

# ╔═╡ 032dfedc-41d5-4fbb-9f10-0d3eae33f0e5
md"# 2D"

# ╔═╡ 2c0384a9-f04e-4d32-9566-c038892c9df3
load("./res/conjunto_de_transformacoes.png")

# ╔═╡ 04e370e5-5e40-4711-b0dd-2531fddc79bd
md"## Base"

# ╔═╡ 2e85c857-ff6c-4619-ab12-2f4ba33c3f13
abstract type Forma end

# ╔═╡ 87de8f46-72ca-4fa2-b5c8-4343f6a47b1c
struct Triangulo <: Forma
	x :: SVector{3, Real}
	y :: SVector{3, Real}
end

# ╔═╡ ee657ead-fb7f-4866-b53f-803a644ec9d5
struct Quadrado <: Forma
	x :: SVector{4, Real}
	y :: SVector{4, Real}
end

# ╔═╡ df874665-dabd-4b79-91a7-e31eadfde59c
triangulo_base = Triangulo(SVector(0, 1, 2), SVector(0, 2, 0));

# ╔═╡ 7a84dab8-b520-44bb-a09c-92b89d041473
quadrado_base = Quadrado(SVector(0, 0, 1, 1), SVector(0, 1, 1, 0));

# ╔═╡ db3cdf8f-3f64-42f0-91f4-c1f9239c4b3f
function forma_para_matriz(forma :: F; vetor_homogeneo=false) where F <: Forma
	dim = length(forma.x);
	vetores = vetor_homogeneo ? [[forma.x[i], forma.y[i], 1] for i ∈ (1:dim)] : [[forma.x[i], forma.y[i]] for i ∈ (1:dim)]
	flat = reduce(vcat, vetores)
	return reshape(flat, (vetor_homogeneo ? 3 : 2, dim))
end

# ╔═╡ 1c10616b-cdaa-4720-b7f3-be41003f0c8e
function matriz_para_forma(M, F)
	x = M[1, :]
	y = M[2, :]
	F(x, y)
end

# ╔═╡ f59220ae-a219-4198-8047-3a8419e6a9f1
md"## Transformações Projetivas"

# ╔═╡ 0266faae-4ba9-4891-bc99-b03c91a3b747
md"### Perspectiva"

# ╔═╡ 1421a300-2bf3-4b9f-9178-95b66a6a9d3a
md"## Transformações Similares"

# ╔═╡ 6d17b764-ecab-44bf-acf3-4df081b68c55
md"### Escala uniforme"

# ╔═╡ 03d7f82f-bb17-4c36-b3ad-da2676a683a3
function escala_uniforme(s, forma :: F) where F <: Forma
	P = forma_para_matriz(forma);
	M = [
		s 0;
		0 s
	];
	return matriz_para_forma(M * P, F)
end

# ╔═╡ 47788a79-7256-49ba-b86c-a07ed54fcf9e
eu_ui = @bind eu Slider(0:0.1:2; default=0.5, show_value=true);

# ╔═╡ 74d37fcb-6d4a-48c0-98f4-147be773337c
tri_eu = escala_uniforme(eu, triangulo_base);

# ╔═╡ 2381e76a-23e7-43d1-abbd-283c909adaa0
qua_eu = escala_uniforme(eu, quadrado_base);

# ╔═╡ 4c6e064c-356f-4e1d-895a-f4e58a309795
eu_plot = Context(
	(; domain=[-3, 3], range=[0, 300]),
	(; domain=[2.5, -2.5], range=[0, 300]),
	[
		Portinari.Axis(Portinari.Bottom, D3Attr(;attr=(;transform="translate(0, 150)")), "eu-x-axis"),
		Portinari.Axis(Portinari.Left, D3Attr(;attr=(;transform="translate(150, 0)")), "eu-y-axis"),
		Line(tri_eu.x, tri_eu.y, "tri_eu"; attributes=D3Attr(
			attr=(;stroke="blue"), duration=0
		), curveType=Portinari.LinearClosed),
		Line(qua_eu.x, qua_eu.y, "qua_eu"; attributes=D3Attr(
			attr=(;stroke="purple"), duration=0
		), curveType=Portinari.LinearClosed)
	], D3Attr(attr=(;fill="none", color="black")), (0, 1), (0, 1), "EU", false
);

# ╔═╡ 44ec6444-fcc2-4f6f-ae9a-6b0fd5a00662
PlutoUI.ExperimentalLayout.vbox(
	[
		PlutoUI.ExperimentalLayout.hbox([md"s: ", eu_ui]),
		eu_plot
	],
	class="plot",
	style=Dict("top" => "-410px", "left" => "750px")
)

# ╔═╡ 9f1c917a-e5b7-48bc-af12-1a2dd27590a2
md"### Reflexão"

# ╔═╡ 38d3ae40-cc3d-45fb-a0f0-940ec2b05356
refl_ui = @bind refl Slider(-2:0.1:2; default=0.5, show_value=true);

# ╔═╡ 54478614-3599-4d6c-a5ed-64c4a8f40883
tri_refl = escala_uniforme(refl, triangulo_base);

# ╔═╡ 1ddd96a1-fa32-4c87-83cc-e121f46b6491
qua_refl = escala_uniforme(refl, quadrado_base);

# ╔═╡ 5d49cb3d-aa5f-490d-b727-2938fed7d7b9
refl_plot = Context(
	(; domain=[-3, 3], range=[0, 300]),
	(; domain=[2.5, -2.5], range=[0, 300]),
	[
		Portinari.Axis(Portinari.Bottom, D3Attr(;attr=(;transform="translate(0, 150
		)")), "refl-x-axis"),
		Portinari.Axis(Portinari.Left, D3Attr(;attr=(;transform="translate(150, 0)")), "refl-y-axis"),
		Line(tri_refl.x, tri_refl.y, "tri_refl"; attributes=D3Attr(
			attr=(;stroke="blue"), duration=0
		), curveType=Portinari.LinearClosed),
		Line(qua_refl.x, qua_refl.y, "qua_refl"; attributes=D3Attr(
			attr=(;stroke="purple"), duration=0
		), curveType=Portinari.LinearClosed)
	], D3Attr(attr=(;fill="none", color="black")), (0, 1), (0, 1), "REFL", false
);

# ╔═╡ 88aad719-64a0-4e1b-ad9b-d1fafc9a246a
PlutoUI.ExperimentalLayout.vbox(
	[		
		PlutoUI.ExperimentalLayout.hbox([md"s: ", refl_ui]),
		refl_plot
	],
	class="plot",
	style=Dict("top" => "-220px", "left" => "750px")
)

# ╔═╡ f24463ff-8350-4991-9c5f-b18ea9e57a65
md"## Transformações Lineares"

# ╔═╡ aa3a46c3-65d7-4823-b723-1ea7cfa740cc
md"### Escala não-uniforme"

# ╔═╡ f28bdb1c-8ae3-42d0-a26d-48f5bcf456da
function escala_nao_uniforme(sx, sy, forma :: F) where F <: Forma
	P = forma_para_matriz(forma);
	M = [
		sx 0;
		0 sy
	];
	return matriz_para_forma(M * P, F)
end

# ╔═╡ 6bc2fe4f-8b9c-4cd1-b61f-ebbed893ef6f
enu_x_ui = @bind enu_x Slider(-2:0.1:2; default=0.5, show_value=true);

# ╔═╡ a4aaac40-eb99-434d-8bb3-06fcf59ca98b
enu_y_ui = @bind enu_y Slider(-2:0.1:2; default=0.5, show_value=true);

# ╔═╡ 2b6e3392-c60b-4826-a845-d8ebfb9a32ef
tri_enu = escala_nao_uniforme(enu_x, enu_y, triangulo_base);

# ╔═╡ 534895b2-1431-42d2-883b-e3352f403372
qua_enu = escala_nao_uniforme(enu_x, enu_y, quadrado_base);

# ╔═╡ ea9bfcfe-31c9-4e75-a9fb-a5e38aad80ec
enu_plot = Context(
	(; domain=[-3, 3], range=[0, 300]),
	(; domain=[2.5, -2.5], range=[0, 300]),
	[
		Portinari.Axis(Portinari.Bottom, D3Attr(;attr=(;transform="translate(0, 150
		)")), "enu-x-axis"),
		Portinari.Axis(Portinari.Left, D3Attr(;attr=(;transform="translate(150, 0)")), "enu-y-axis"),
		Line(tri_enu.x, tri_enu.y, "tri_enu"; attributes=D3Attr(
			attr=(;stroke="blue"), duration=0
		), curveType=Portinari.LinearClosed),
		Line(qua_enu.x, qua_enu.y, "qua_enu"; attributes=D3Attr(
			attr=(;stroke="purple"), duration=0
		), curveType=Portinari.LinearClosed)
	], D3Attr(attr=(;fill="none", color="black")), (0, 1), (0, 1), "ENU", false
);

# ╔═╡ b5234c02-f7db-43ef-9d2d-10895f88af04
PlutoUI.ExperimentalLayout.vbox(
	[
		PlutoUI.ExperimentalLayout.hbox([md"x: ", enu_x_ui]),
		PlutoUI.ExperimentalLayout.hbox([md"y: ", enu_y_ui]),
		enu_plot
	],
	class="plot",
	style=Dict("top" => "-450px", "left" => "750px")
)

# ╔═╡ 29fe0461-12ff-46e2-9bf4-fe5b37036385
md"### Cisalhamento"

# ╔═╡ 08638632-2481-4042-9762-b7c9b2ae1e9b
function cisalhamento(γx, γy, forma :: F) where F <: Forma
	P = forma_para_matriz(forma);
	M = [
		1 γx;
		γy 1
	];
	return matriz_para_forma(M * P, F)
end

# ╔═╡ e1548ffa-39f0-46f2-b525-a93e4835d031
cis_x_ui = @bind cis_x Slider(-2:0.1:2; default=0, show_value=true);

# ╔═╡ aa082925-53c2-4738-be21-e16e039d4ca1
cis_y_ui = @bind cis_y Slider(-2:0.1:2; default=0, show_value=true);

# ╔═╡ cf131b5c-1c71-4c6b-941f-be84fc9ec27b
tri_cis = cisalhamento(cis_x, cis_y, triangulo_base);

# ╔═╡ 3b72fd1a-372c-4ad8-8017-eb0c85733163
qua_cis = cisalhamento(cis_x, cis_y, quadrado_base);

# ╔═╡ 64004ce4-be62-4c7c-9232-9c8313acde9d
cis_plot = Context(
	(; domain=[-3, 3], range=[0, 300]),
	(; domain=[2.5, -2.5], range=[0, 300]),
	[
		Portinari.Axis(Portinari.Bottom, D3Attr(;attr=(;transform="translate(0, 150
		)")), "CIS-x-axis"),
		Portinari.Axis(Portinari.Left, D3Attr(;attr=(;transform="translate(150, 0)")), "CIS-y-axis"),
		Line(tri_cis.x, tri_cis.y, "tri_cis"; attributes=D3Attr(
			attr=(;stroke="blue"), duration=0
		), curveType=Portinari.LinearClosed),
		Line(qua_cis.x, qua_cis.y, "qua_cis"; attributes=D3Attr(
			attr=(;stroke="purple"), duration=0
		), curveType=Portinari.LinearClosed)
	], D3Attr(attr=(;fill="none", color="black")), (0, 1), (0, 1), "CIS", false
);

# ╔═╡ b820b449-5624-4102-bf40-aef2ea635308
PlutoUI.ExperimentalLayout.vbox(
	[
		PlutoUI.ExperimentalLayout.hbox([md"Horizontal: ", cis_x_ui]),
		PlutoUI.ExperimentalLayout.hbox([md"Vertical: ", cis_y_ui]),
		cis_plot
	],
	class="plot",
	style=Dict("top" => "-450px", "left" => "750px")
)

# ╔═╡ 46acfedd-71fc-4423-b7db-dd6495c531f6
md"## Tranformações Rígidas"

# ╔═╡ e6786f7e-1e57-4463-8d97-8a96e618cb0c
md"### Identidade"

# ╔═╡ 28476867-729c-4cde-881d-e7e2281f8fc3
md"### Rotação"

# ╔═╡ fe1f49d2-2ad2-4f35-9a35-f78e23c5762e
function rotacao(α, forma :: F) where F <: Forma
	P = forma_para_matriz(forma);
	M = [
		cos(α) -sin(α);
		sin(α) cos(α)
	];
	return matriz_para_forma(M * P, F)
end

# ╔═╡ 595e5f80-b09c-405e-9255-1d8cab552257
M = [1 2; 3 4]

# ╔═╡ 494fe357-c55b-4c16-a9e2-ea45dc4c1024
rot_ui = @bind rot Slider(0:0.1:2 * 3.14; default=0, show_value=true);

# ╔═╡ 94d4960b-7770-4af1-84c9-d0eef7fb7ffe
tri_rot = rotacao(rot, triangulo_base);

# ╔═╡ 2fb79a4c-a789-49ee-a417-0e8242353d5f
qua_rot = rotacao(rot, quadrado_base);

# ╔═╡ f0abcbdb-2e51-421a-b11d-b0e9d672cb6e
rot_plot = Context(
	(; domain=[-3, 3], range=[0, 300]),
	(; domain=[2.5, -2.5], range=[0, 300]),
	[
		Portinari.Axis(Portinari.Bottom, D3Attr(;attr=(;transform="translate(0, 150
		)")), "rot-x-axis"),
		Portinari.Axis(Portinari.Left, D3Attr(;attr=(;transform="translate(150, 0)")), "rot-y-axis"),
		Line(tri_rot.x, tri_rot.y, "tri_rot"; attributes=D3Attr(
			attr=(;stroke="blue"), duration=0
		), curveType=Portinari.LinearClosed),
		Line(qua_rot.x, qua_rot.y, "qua_rot"; attributes=D3Attr(
			attr=(;stroke="purple"), duration=0
		), curveType=Portinari.LinearClosed)
	], D3Attr(attr=(;fill="none", color="black")), (0, 1), (0, 1), "ROT", false
);

# ╔═╡ af2526b1-48d4-4d72-8072-8505a753955d
PlutoUI.ExperimentalLayout.vbox(
	[
		PlutoUI.ExperimentalLayout.hbox([md"α: ", rot_ui]),
		rot_plot
	],
	class="plot",
	style=Dict("top" => "-400px", "left" => "750px")
)

# ╔═╡ 9050de7c-295c-4027-beff-2de0d75298c4
md"### Translação"

# ╔═╡ 754897a1-a4ce-42ef-9192-cb5c80aaf843
function translacao(Δx, Δy, forma :: F) where F <: Forma
	P = forma_para_matriz(forma; vetor_homogeneo=true);
	M = [
		1 0 Δx;
		0 1 Δy;
		0 0 1
	];
	return matriz_para_forma(M * P, F)
end

# ╔═╡ ded4b9d8-2589-45b7-bcf7-5a266e45796b
tra_x_ui = @bind tra_x Slider(-2:0.1:2; default=0.5, show_value=true);

# ╔═╡ 021a4429-3819-440f-b5da-5b10627f4fec
tra_y_ui = @bind tra_y Slider(-2:0.1:2; default=0.5, show_value=true);

# ╔═╡ 0bb1082e-2fa4-4d80-b1dd-e9844e18a7f0
tri_tra = translacao(tra_x, tra_y, triangulo_base);

# ╔═╡ 36e8a759-0302-4a80-9eea-102100954c5c
qua_tra = translacao(tra_x, tra_y, quadrado_base);

# ╔═╡ 77dc741a-551a-4177-b1c9-1d8433d37b35
tra_plot = Context(
	(; domain=[-3, 3], range=[0, 300]),
	(; domain=[2.5, -2.5], range=[0, 300]),
	[
		Portinari.Axis(Portinari.Bottom, D3Attr(;attr=(;transform="translate(0, 150
		)")), "tra-x-axis"),
		Portinari.Axis(Portinari.Left, D3Attr(;attr=(;transform="translate(150, 0)")), "tra-y-axis"),
		Line(tri_tra.x, tri_tra.y, "tri_tra"; attributes=D3Attr(
			attr=(;stroke="blue"), duration=0
		), curveType=Portinari.LinearClosed),
		Line(qua_tra.x, qua_tra.y, "qua_tra"; attributes=D3Attr(
			attr=(;stroke="purple"), duration=0
		), curveType=Portinari.LinearClosed)
	], D3Attr(attr=(;fill="none", color="black")), (0, 1), (0, 1), "TRA", false
);

# ╔═╡ 9ee3be0a-b722-45ee-9fad-e569a90d0de4
PlutoUI.ExperimentalLayout.vbox(
	[
		PlutoUI.ExperimentalLayout.hbox([md"x: ", tra_x_ui]),
		PlutoUI.ExperimentalLayout.hbox([md"y: ", tra_y_ui]),
		tra_plot
	],
	class="plot",
	style=Dict("top" => "-450px", "left" => "750px")
)

# ╔═╡ ace0790e-3c9e-42db-a612-44e4aefcca55
md"# Composição de Transformações"

# ╔═╡ Cell order:
# ╠═92565f5d-c70f-4737-8787-2e368c9a89cb
# ╟─210b43e4-dd08-11ec-124e-832694b3f20f
# ╟─0e4384cf-20c2-4676-bda2-79538f8ff4e6
# ╟─032dfedc-41d5-4fbb-9f10-0d3eae33f0e5
# ╟─2c0384a9-f04e-4d32-9566-c038892c9df3
# ╟─04e370e5-5e40-4711-b0dd-2531fddc79bd
# ╠═2e85c857-ff6c-4619-ab12-2f4ba33c3f13
# ╠═87de8f46-72ca-4fa2-b5c8-4343f6a47b1c
# ╠═ee657ead-fb7f-4866-b53f-803a644ec9d5
# ╠═df874665-dabd-4b79-91a7-e31eadfde59c
# ╠═7a84dab8-b520-44bb-a09c-92b89d041473
# ╟─db3cdf8f-3f64-42f0-91f4-c1f9239c4b3f
# ╟─1c10616b-cdaa-4720-b7f3-be41003f0c8e
# ╟─f59220ae-a219-4198-8047-3a8419e6a9f1
# ╟─0266faae-4ba9-4891-bc99-b03c91a3b747
# ╟─1421a300-2bf3-4b9f-9178-95b66a6a9d3a
# ╟─6d17b764-ecab-44bf-acf3-4df081b68c55
# ╠═03d7f82f-bb17-4c36-b3ad-da2676a683a3
# ╠═74d37fcb-6d4a-48c0-98f4-147be773337c
# ╠═2381e76a-23e7-43d1-abbd-283c909adaa0
# ╟─47788a79-7256-49ba-b86c-a07ed54fcf9e
# ╟─4c6e064c-356f-4e1d-895a-f4e58a309795
# ╟─44ec6444-fcc2-4f6f-ae9a-6b0fd5a00662
# ╟─9f1c917a-e5b7-48bc-af12-1a2dd27590a2
# ╠═54478614-3599-4d6c-a5ed-64c4a8f40883
# ╠═1ddd96a1-fa32-4c87-83cc-e121f46b6491
# ╟─38d3ae40-cc3d-45fb-a0f0-940ec2b05356
# ╟─5d49cb3d-aa5f-490d-b727-2938fed7d7b9
# ╟─88aad719-64a0-4e1b-ad9b-d1fafc9a246a
# ╟─f24463ff-8350-4991-9c5f-b18ea9e57a65
# ╟─aa3a46c3-65d7-4823-b723-1ea7cfa740cc
# ╠═f28bdb1c-8ae3-42d0-a26d-48f5bcf456da
# ╠═2b6e3392-c60b-4826-a845-d8ebfb9a32ef
# ╠═534895b2-1431-42d2-883b-e3352f403372
# ╟─6bc2fe4f-8b9c-4cd1-b61f-ebbed893ef6f
# ╟─a4aaac40-eb99-434d-8bb3-06fcf59ca98b
# ╟─ea9bfcfe-31c9-4e75-a9fb-a5e38aad80ec
# ╟─b5234c02-f7db-43ef-9d2d-10895f88af04
# ╟─29fe0461-12ff-46e2-9bf4-fe5b37036385
# ╠═08638632-2481-4042-9762-b7c9b2ae1e9b
# ╠═cf131b5c-1c71-4c6b-941f-be84fc9ec27b
# ╠═3b72fd1a-372c-4ad8-8017-eb0c85733163
# ╠═e1548ffa-39f0-46f2-b525-a93e4835d031
# ╠═aa082925-53c2-4738-be21-e16e039d4ca1
# ╟─64004ce4-be62-4c7c-9232-9c8313acde9d
# ╟─b820b449-5624-4102-bf40-aef2ea635308
# ╟─46acfedd-71fc-4423-b7db-dd6495c531f6
# ╟─e6786f7e-1e57-4463-8d97-8a96e618cb0c
# ╟─28476867-729c-4cde-881d-e7e2281f8fc3
# ╠═fe1f49d2-2ad2-4f35-9a35-f78e23c5762e
# ╠═94d4960b-7770-4af1-84c9-d0eef7fb7ffe
# ╠═2fb79a4c-a789-49ee-a417-0e8242353d5f
# ╠═595e5f80-b09c-405e-9255-1d8cab552257
# ╟─494fe357-c55b-4c16-a9e2-ea45dc4c1024
# ╟─f0abcbdb-2e51-421a-b11d-b0e9d672cb6e
# ╟─af2526b1-48d4-4d72-8072-8505a753955d
# ╟─9050de7c-295c-4027-beff-2de0d75298c4
# ╠═754897a1-a4ce-42ef-9192-cb5c80aaf843
# ╠═0bb1082e-2fa4-4d80-b1dd-e9844e18a7f0
# ╠═36e8a759-0302-4a80-9eea-102100954c5c
# ╟─ded4b9d8-2589-45b7-bcf7-5a266e45796b
# ╟─021a4429-3819-440f-b5da-5b10627f4fec
# ╟─77dc741a-551a-4177-b1c9-1d8433d37b35
# ╟─9ee3be0a-b722-45ee-9fad-e569a90d0de4
# ╟─ace0790e-3c9e-42db-a612-44e4aefcca55
