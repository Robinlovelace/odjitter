Jittering: A computationally efficient method for generating realistic
route networks from origin-destination data
================
Robin Lovelace, Rosa Félix, Dustin Carlino

<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![.github/workflows/render-rmarkdown.yaml](https://github.com/Robinlovelace/odjitter/actions/workflows/render-rmarkdown.yaml/badge.svg)](https://github.com/Robinlovelace/odjitter/actions/workflows/render-rmarkdown.yaml)
<!-- badges: end -->

# Abstract

Origin-destination (OD) datasets are often represented as ‘desire lines’
between zone centroids. This paper presents a ‘jittering’ approach to
pre-processing and conversion of OD data into geographic desire lines
that (1) samples unique origin and destination locations for each OD
pair, and (2) splits ‘large’ OD pairs into ‘sub-OD’ pairs. Reproducible
findings show that route networks generated from jittered desire lines
are more geographically diffuse than route networks generated from
‘unjittered’ (centroid based) desire lines. The approach, implemented in
the open source Rust crate odjitter, is a computationally efficient and
flexible way to simulate diffuse travel patterns from OD data. Further
work is needed to validate the approach and to find optimal settings for
sampling and disaggregation.

# Questions

Origin-destination (OD) datasets are widely used in transport planning
to efficiently represent aggregate travel behavior. Despite emerging
‘big data’ sources such as massive GPS datasets, OD data continues to
play an established — if not central — role in 21<sup>st</sup> century
transport planning and modelling. Recent applications range from
analysis of the evolution of urban activity and shared mobility services
over time (e.g. Shi et al. 2019; Li et al. 2019) to inference of
congestion and mode split (Bachir et al. 2019; Gao et al. 2021).

<!-- Perhaps in part because they are so well established, comparatively few recent research papers have explored new methods for processing OD datasets. -->

There has been much written on optimal zoning systems for and geographic
representations of OD data (e.g. Openshaw 1977; Boyce and Williams
2015). Recent papers have presented new methods for OD dataset
validation (Alexander et al. 2015), aggregation (He et al. 2018; Liu et
al. 2021), disaggregation (Katranji et al. 2016) and location of
‘connectors’ joining zone center points (centroids) with the surrounding
network (Jafari et al. 2015). Broadly, there are two approaches to
converting OD data into geographic representations for transport
modelling:

1.  Centroid to centroid representations, a common approach involving
    the simplifying assumption that all trip destinations and origins
    can be represented by (sometimes population weighted or aggregated)
    zone centroids (Guo and Zhu 2014; Martin et al. 2018).
2.  Subdividing zones (also referred to as transport analysis zones,
    TAZ) at which data is available to subzones centroids (Opie,
    Rowinski, and Spasovic 2009) or ‘centroid connectors’ or simply
    ‘connectors’ “between trip ends and zonal anchors” using stochastic
    or deterministic approaches (Leurent, Benezech, and Samadzad 2011;
    Friedrich and Galster 2009).

In this paper we present a new approach to pre-processing OD datasets
with a focus route network generation. Unlike established approaches
which convert centroid based desire lines to routes and then route
networks (Morgan and Lovelace 2020), the ‘jittering’ approach presented
in this paper allows the user to adjust start and end locations based on
variables such as transport network density, residential density or size
of commercial buildings acting as trip attractors.
<!-- The results, represented as 'jittered desire lines' are more spatially diffuse than desire lines that go from and to zone centroids. -->
The approach is flexible, enabling the user to adjust the level of
disaggregation, the location of start and end points from which
disaggregate OD pairs are sampled, and weights representing the
importance of different trip ‘originators’ and ‘attractors’.
<!-- appropriate start points and trip attractors, and weights highlighting the relative importance of different origin and destination points. -->

Unlike aforementioned papers, jittering can be understood as a simple,
transparent and flexible pre-processing stage that can add value to OD
datasets by representing the diffuse nature of travel networks. This is
particularly important when designing for active travel (Buehler and
Dill 2016), explaining the choice of input data to illustrate the
technique in this paper: it was developed to support active travel
planning in an applied setting funded by Edinburgh City Council. We
developed the approach to support strategic investment in walking and
cycling infrastructure networks based on our observation that route
networks resulting from OD pairs from and to single centroids per zone
were too sparse, and not adequate for active travel representation. The
approach can ‘slot into’ existing transport modelling workflows that use
desire lines as the basis of route network assignment, uptake modelling,
and route network generation workflows (Morgan and Lovelace 2020).
<!-- todo: add flow diagram --> We refer to the approach as jittering,
noting the use term to describe a similar process of adding “random
noise to the data” for data visualization (Wickham 2016).

<!-- In this paper we outline such methods and their uses, demonstrating how jittering can be used to create more diffuse and accurate estimates of movement at the level of segments ('flows') on transport network, with minimal computational overheads compared with the computationally intensive process of route calculation ('routing') or processing large GPS datasets. -->
<!-- Long version of paper: -->
<!-- We do this by defining OD datasets, their uses, and other terms in relation to jittering, in Section \@ref(od); describing a real world case study, input datasets, and methods, in Section \@ref(methods); presenting the results of different jittering techniques in Section \@ref(findings); and discussing the potential uses of and next steps for the development of methods to add value to OD datasets for sustainable transport planning in section \@ref(discussion). -->
<!-- Short version of paper: -->
<!-- We do this by defining OD datasets, their uses, and other terms in relation to jittering, in this introduction; outlining the research question with reference to a real world case study of modelling cycling networks in Edinburgh, in Section \@ref(q); describing the results in Section \@ref(methods); and presenting the results of different jittering techniques in Section \@ref(findings). -->
<!-- # Origin-destination data {#od} -->
<!-- First, a description of the utility of OD data in contemporary policy contexts, and definitions, are in order. -->
<!-- An example of the utility of OD data, and the utility of open access (anonymised and aggregtated) OD data in particular, is Propensity to Cycle Tool (PCT), first launched nationally across England in 2017 [@lovelace_propensity_2017]. -->
<!-- The PCT provides a strong and consistent evidence-base that local authorities across England and Wales are using to inform strategic Local Cycling and Walking Plans. -->
<!-- Based on OD data --- initially for commuting trips only but subsequently also based on travel to school data [@goodman_scenarios_2019] --- the tool visualises cycling potential at zone, desire line, route and route network levels, and is being used by government, consultancy and public/advocacy stakeholders nationwide [@lovelace_open_2020]. -->
<!-- The PCT makes open OD data 'come to life' by converting a 'haystack' of data into meaningful insights into currently cycling levels and future potential, highlighting the need to invest in cohesive networks of cycling interventions, as illustrated in Figure \@ref(fig:haystack). -->
<!-- The PCT is available for use by local authorities, consultancies, cycling advocacy groups, academic researchers and members of the public. -->
<!-- Subsequent work building on the tool has been used to prioritise investment in active transport in the wake of the coronavirus pandemic [@lovelace_methods_2020]. -->
<!-- Comparable tools have yet to be developed and deployed publicly in most other countries. -->
<!-- With the exception of regionally specific models using software such as sDNA [@cooper_using_2017] (the results of which are usually not in the public domain) and bespoke city-specific models [@larsen_build_2013; @zhang_prioritizing_2014], there are few large scale tools using OD data that are free for public use that we are aware of. -->
<!-- In this context, this paper outlines methods to add further value to OD data through processes of disaggregating OD data and 'jittering' to increase the density of route networks arising from the conversion of OD data into route network outputs of the kind illustrated in Figure \@ref(fig:haystack). -->

The jittering approach presented in this paper was motivated by the
following question:

> How can OD data representing trips between large geographic zones be
> used more effectively, to generate diffuse route networks of current
> or potential flow to inform local interventions?

<!-- Our hypothesis is that jittering leads to more effective use of OD data in transport planning. -->
<!-- Before describing the approach to answer this question, some definitions are in order: -->
<!-- , it is worth briefly defining OD data: datasets that consist of: -->
<!-- - **Origins**: locations of trip departure, typically stored as ID codes linking to zones -->
<!-- - **Destinations**: trip destinations, also stored as ID codes linking to zones -->
<!-- - **Attributes**: the number of trips made between each 'OD pair' and additional attributes such as route distance between each OD pair -->
<!-- - **Jittering**: The combined process of 'splitting' OD pairs representing many trips into multiple 'sub OD' pairs (disaggregation) and assigning origins and destinations to multiple unique points within each zone -->

# Methods

<!-- The methods described in this paper were developed to support a project to support Edinburgh City Council with their strategic cycle network planning activity. -->
<!-- To understand the method and results it makes sense to start by introducing the case study area. -->
<!-- ## A synthetic example: synthetic zones -->
<!-- ## Real world example: Edinburgh -->

The approach was developed to support public sector transport planning
in Edinburgh, UK. The original study area was Edinburgh City Council, a
major economic hub with ambitious
[plans](https://www.edinburgh.gov.uk/downloads/file/30073/active-travel-investment-programme-update-october-2021)
for investment in active travel, making evidence to support investment
where it will be most beneficial key. For the purposes of this study we
focus on a comparatively small area around central Edinburgh. We focus
in this paper on walking trips in this central area because much
research into route networks has focused on cycling and, because walking
trips tend to be short, they create a need to convert aggregated OD
datasets into diffuse route network representations of travel. Input
datasets developed for this paper can be downloaded using reproducible
code that accompanies the paper; see code at \[url to be included on
publication\] to fully reproduce the findings.

Beyond the zone data illustrated in Figure @ref(fig:od), the input
dataset consisted of open access OD data from the 2011 census. The OD
data can be represented as both tabular and, when start and end points
are assigned to centroids within each zone, as geographic entities, as
illustrated in a sample of three OD pairs presented in Figure
@ref(fig:od). To generate the route networks presented in Figure
@ref(fig:rneted) we used the OpenStreetMap Routing Machine (OSRM) with
the profile set to ‘foot’.
<!-- , which presents data at the zone and OD level for the top 3 OD pairs by number of interzonal travel between zones by all modes in Edinburgh in tabular and visual form. -->
<!-- The zone boundaries are based on open boundary data provided by data.gov.uk at the Middle Super Output Area (MSOA) level. -->
<!-- The population was 480,139 in the 2011 Census, 237,839 of whom were employed. -->
<!-- In the 2011 Census, 4.3% of residents of the area reported cycling to work, ranging from 1% in Intermediate Zone (IZ) Ferniehill, South Moredun and Craigour to 10% in the IZ Marchmont West. -->
<!-- There are 101 IZs (2001 definition) in the study region. -->

<img src="figures/od-top-3-zones-metafigure.png" title="Illustration of input data in tabular (bottom right, inset) and geographic form (in the map). Note how the ID codes in the first two columns of the table correspond with IDs in the zone data and how the cells in the 'foot' column are represented geographically on the map." alt="Illustration of input data in tabular (bottom right, inset) and geographic form (in the map). Note how the ID codes in the first two columns of the table correspond with IDs in the zone data and how the cells in the 'foot' column are represented geographically on the map." width="80%" style="display: block; margin: auto;" />

The techniques outlined in the following sub-sections are perhaps best
understood visually, as illustrated in each of the facetted maps in
Figure @ref(fig:jitters). The subfigures show the flexibility of
approach, with C) and D) demonstrating the use of vertices on the road
network as start and end points, building on the observation from
spatial network analysis that the density of the transport network is a
reasonable proxy for travel demand (Cooper 2018). Other refinements
including weighted subpoints could be used when data sources
(e.g. building footprint areas) are available.

<img src="README_files/figure-gfm/jitters-1.png" title="Illustration of jittering and disaggregation of origin-destination (OD) data with a minimal input dataset. Subfigure A) shows the conventional way of representing OD data as desire lines between zone centroids. Subfigures B) and C) show the same desire lines but with jittered origin and destination locations based on simple random sampling of points and sampling locations on the road network. Subfigure D) shows the combined impact of disaggregation and jittering. Zone limits are represented in grey, while road network is in green." alt="Illustration of jittering and disaggregation of origin-destination (OD) data with a minimal input dataset. Subfigure A) shows the conventional way of representing OD data as desire lines between zone centroids. Subfigures B) and C) show the same desire lines but with jittered origin and destination locations based on simple random sampling of points and sampling locations on the road network. Subfigure D) shows the combined impact of disaggregation and jittering. Zone limits are represented in grey, while road network is in green." width="80%" style="display: block; margin: auto;" />

## Sampling origin and destination points

<!-- ## Random sampling of origin and destination points -->

Key to jittering is ensuring that each trip starts and ends in a
different place. To do this, there must be ‘sub-points’ within each
zone, one for each trip originating and departing.

The simplest approach is simple random spatial sampling, as illustrated
in Figure @ref(fig:jitters) (B), which involves generating random
coordinate pairs.
<!-- testing to check if the point is contained withing the boundary of each zone from which points are required, and repeating the process until enough randomly located points have been created. -->
This approach has the advantages of simplicity, requiring no additional
datasets, but has the disadvantage that it may lead to unrealistic start
and end points, e.g. with trips being simulated to start in rivers and
in uninhabited wilderness areas.

<!-- ## Sampling origin and destination points from the transport network -->

To overcome the limitations of the simple random sampling approach, the
universe of possible coordinates from which trips can originate and end
can be reduced by providing another geographic input dataset. This
dataset could contain known trip attractors such as city centers and
work places, as well as tightly defined residential ‘subzones’. For
highly disaggregated flows in cases where accurate building datasets are
available, building footprints could also be used. A useful, and widely
available (Barrington-Leigh and Millard-Ball 2017), input for
subsampling is a transport road network, as illustrated in Figure
@ref(fig:jitters) (C). Additional refinements to the stochastic
selection of origin and destination based on weights relating to other
datasets are possible, as discussed in the final section.

The key elements of the jittering approach outlined in this paper are
described below.

## Disaggregation

Both of the jittering techniques outlined above generate more diffuse
route networks. However, a problem with OD datasets is that they are
often highly variable: one OD pair could represent 1 trip, while another
could represent 1000 trips. To overcome this problem a process of
disaggregation can be used, resulting in additional OD pairs within each
pair of zones. The results of disaggregation are illustrated
geographically in Figure @ref(fig:jitters) (D) and in terms of changes
to attributes, in Tables @ref(tab:dis1) and @ref(tab:dis2). As shown in
those tables, updated attributes can be calculated by dividing previous
trip counts by the number of OD pairs in the disaggregated
representation of the data, 5 in this case. To determine how many
disaggregated OD pairs each original OD pair is split into, a maximum
threshold was set: an OD pairs with a total trip count exceeding this
threshold (set at 100 in this case) is split into the minimum number of
disaggregated OD pairs that reduce the total number of trips below the
threshold.

<table>
<caption>
Attribute data associated with an OD pair before disaggregation.
</caption>
<thead>
<tr>
<th style="text-align:left;">
representation
</th>
<th style="text-align:left;">
geo_code1
</th>
<th style="text-align:left;">
geo_code2
</th>
<th style="text-align:right;">
all
</th>
<th style="text-align:right;">
foot
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
original
</td>
<td style="text-align:left;">
S02001647
</td>
<td style="text-align:left;">
S02001622
</td>
<td style="text-align:right;">
443
</td>
<td style="text-align:right;">
314
</td>
</tr>
</tbody>
</table>
<table>
<caption>
Attribute data associated with an OD pair after disaggregation.
</caption>
<thead>
<tr>
<th style="text-align:left;">
representation
</th>
<th style="text-align:left;">
geo_code1
</th>
<th style="text-align:left;">
geo_code2
</th>
<th style="text-align:right;">
all
</th>
<th style="text-align:right;">
foot
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
disaggregated
</td>
<td style="text-align:left;">
S02001647
</td>
<td style="text-align:left;">
S02001622
</td>
<td style="text-align:right;">
88.6
</td>
<td style="text-align:right;">
62.8
</td>
</tr>
<tr>
<td style="text-align:left;">
disaggregated
</td>
<td style="text-align:left;">
S02001647
</td>
<td style="text-align:left;">
S02001622
</td>
<td style="text-align:right;">
88.6
</td>
<td style="text-align:right;">
62.8
</td>
</tr>
<tr>
<td style="text-align:left;">
disaggregated
</td>
<td style="text-align:left;">
S02001647
</td>
<td style="text-align:left;">
S02001622
</td>
<td style="text-align:right;">
88.6
</td>
<td style="text-align:right;">
62.8
</td>
</tr>
<tr>
<td style="text-align:left;">
disaggregated
</td>
<td style="text-align:left;">
S02001647
</td>
<td style="text-align:left;">
S02001622
</td>
<td style="text-align:right;">
88.6
</td>
<td style="text-align:right;">
62.8
</td>
</tr>
<tr>
<td style="text-align:left;">
disaggregated
</td>
<td style="text-align:left;">
S02001647
</td>
<td style="text-align:left;">
S02001622
</td>
<td style="text-align:right;">
88.6
</td>
<td style="text-align:right;">
62.8
</td>
</tr>
</tbody>
</table>

# Findings

We found that jittering generates desire lines that are more
geographically diffuse than desire lines resulting from the common
method of using zone centroids to represent start and end points. This
shown in Figure @ref(fig:jittered514), which demonstrates the use of
simple random sampling and sampling nodes on transport networks with
reference to a real world example. While the simple random sampling
method of jittering presented in Figure @ref(fig:jittered514) (B) may be
appropriate in some specific cases, we advocate using pre-defined
sub-points. Using sub-points representing vertices on the transport
network, as illustrated in Figures @ref(fig:jittered514) C and D, is
supported by ‘spatial network analysis’ (SNA) approaches to transport
modelling (e.g. Cooper 2018). Weighted points representing trip origins
and destinations such as houses and commercial buildings could also be
used.

<img src="README_files/figure-gfm/jittered514-1.png" title="Results showing the conversion of OD data to geographic desire lines using population weighted centroids for origins and destinations (A) and jittered results. The jittered results illustrate jittering with simple random sampling of origin and destination locations (B), sampling on the network (C), and sampling on the network plus disaggregation of OD pairs representing more than 100 trips (D)." alt="Results showing the conversion of OD data to geographic desire lines using population weighted centroids for origins and destinations (A) and jittered results. The jittered results illustrate jittering with simple random sampling of origin and destination locations (B), sampling on the network (C), and sampling on the network plus disaggregation of OD pairs representing more than 100 trips (D)." style="display: block; margin: auto;" />

The results of converting the desire lines to routes and then route
networks are illustrated in Figure @ref(fig:rneted). The figure shows
that the ‘jittered networks’ are more diffuse than the ‘unjittered
network’. Disaggregation leads to more diffuse networks as shown in
Figure @ref(fig:rneted) (D).

Advantages of this approach include simplicity, low computational cost
and flexibility: the level of disaggregation can be adjusted depending
on computational considerations. Full disaggregation (not demonstrated
in this paper) would lead to one route being calculated for every trip;
this would increase increase computational requirements but could
generate outputs that could feed into agent based models (ABM) such as
A/B Street and MATSim (Carlino et al. 2022; Horni, Nagel, and Axhausen
2016). The approach has fewer data input requirements than established
methods and could be used in setting where sub-zones are unavailable.

<!-- A summary of the results is presented in Table \@ref(tab:sumtable). -->

<img src="README_files/figure-gfm/rneted-1.png" title="Route network results derived from non-jittered OD data (A) and OD data that has been jittered (B to D). The route network results correspond to the desire lines shown in Figure 4, with start and end points sampled from: random locations in geographic space (B); nodes on the transport network network (C); and nodes on the network plus disaggregation of OD pairs representing more than 100 trips (D)." alt="Route network results derived from non-jittered OD data (A) and OD data that has been jittered (B to D). The route network results correspond to the desire lines shown in Figure 4, with start and end points sampled from: random locations in geographic space (B); nodes on the transport network network (C); and nodes on the network plus disaggregation of OD pairs representing more than 100 trips (D)." width="100%" style="display: block; margin: auto;" />

Related methods of “centroid connector placement” have been developed
and tested (Jafari et al. 2015). This is however, to the best of our
knowledge, the first paper focussed on the two step process of jittering
described in this paper — sampling origin and destination points (with
simple random sampling or by sampling from the nodes on the network) and
disagreggation — supported with a reproducible implementation based on
open source software: the jittering methods presented in this paper are
implemented in the R package [`od`](https://itsleeds.github.io/od/). A
more feature complete and high performance implementation created in
parallel with this paper is the Rust crate
[`odjitter`](https://github.com/dabreegster/odjitter). Code accompanying
this paper which reproduces the results in each language.

The results raise questions and avenues for future research, including:

-   Are the jittered results measurably better when compared with
    counter datasets on the network?
-   What additional refinements to the jittering techniques outline in
    this paper could generate more realistic disaggregated OD pairs,
    e.g. as an input into ABMs?
-   Which jittering settings (including sampling strategies and levels
    of disaggregation) represent the best ‘boom for buck’ in terms of
    network accuracy relative to computational requirements?
-   And can further refinements, for example sampling with weights to
    increase the proportion of trips associated with large buildings and
    commercial centers, or modifying disaggregation threshold values
    depending on variables such as zone size, improve results?

Before further refinements are made, we advocate empirical research to
validate the jittering approach outlined in this paper as a foundation
for further work on OD data pre-processing and disaggregation. Such
research requires case studies that have both good open OD data and good
observed travel behavior data, for example from manual and automatic
counters at point locations on the network (Lindsey et al. 2013) and
other sources of data such as trajectory datasets from GPS devices
(Zheng et al. 2016).

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-alexander_validation_2015" class="csl-entry">

Alexander, Lauren, Shan Jiang, Mikel Murga, and Marta C Gonz. 2015.
“Validation of Origin-Destination Trips by Purpose and Time of Day
Inferred from Mobile Phone Data.” *Transportation Research Part B:
Methodological*, 1–20. <https://doi.org/10.1016/j.trc.2015.02.018>.

</div>

<div id="ref-bachir_inferring_2019" class="csl-entry">

Bachir, Danya, Ghazaleh Khodabandelou, Vincent Gauthier, Mounim El
Yacoubi, and Jakob Puchinger. 2019. “Inferring Dynamic
Origin-Destination Flows by Transport Mode Using Mobile Phone Data.”
*Transportation Research Part C: Emerging Technologies* 101: 254–75.

</div>

<div id="ref-barrington-leigh_world_2017" class="csl-entry">

Barrington-Leigh, Christopher, and Adam Millard-Ball. 2017. “The World’s
User-Generated Road Map Is More Than 80% Complete.” *PLOS ONE* 12 (8):
e0180698. <https://doi.org/10.1371/journal.pone.0180698>.

</div>

<div id="ref-boyce_forecasting_2015" class="csl-entry">

Boyce, David E., and Huw C. W. L. Williams. 2015. *Forecasting Urban
Travel: Past, Present and Future*. Edward Elgar Publishing.

</div>

<div id="ref-buehler_bikeway_2016" class="csl-entry">

Buehler, Ralph, and Jennifer Dill. 2016. “Bikeway Networks: A Review of
Effects on Cycling.” *Transport Reviews* 36 (1): 9–27.
<https://doi.org/10.1080/01441647.2015.1069908>.

</div>

<div id="ref-abstreet_2022" class="csl-entry">

Carlino, Dustin, Yuwen Li, Michael Kirk, Mateusz Konieczny, Gedalia
Kott, Bruce, Javed Nissar, et al. 2022. *A/B Street*. Zenodo.
<https://doi.org/10.5281/zenodo.6331922>.

</div>

<div id="ref-cooper_predictive_2018" class="csl-entry">

Cooper, Crispin H. V. 2018. “Predictive Spatial Network Analysis for
High-Resolution Transport Modeling, Applied to Cyclist Flows, Mode
Choice, and Targeting Investment.” *International Journal of Sustainable
Transportation* 0 (0): 1–11.
<https://doi.org/10.1080/15568318.2018.1432730>.

</div>

<div id="ref-friedrich_methods_2009" class="csl-entry">

Friedrich, Markus, and Manuel Galster. 2009. “Methods for Generating
Connectors in Transport Planning Models.” *Transportation Research
Record* 2132 (1): 133–42. <https://doi.org/10.3141/2132-15>.

</div>

<div id="ref-gao_method_2021" class="csl-entry">

Gao, Hong, Zhenjun Yan, Xu Hu, Zhaoyuan Yu, Wen Luo, Linwang Yuan, and
Jiyi Zhang. 2021. “A Method for Exploring and Analyzing Spatiotemporal
Patterns of Traffic Congestion in Expressway Networks Based on
Origin–Destination Data.” *ISPRS International Journal of
Geo-Information* 10 (5): 288.

</div>

<div id="ref-guo_origindestination_2014" class="csl-entry">

Guo, Diansheng, and Xi Zhu. 2014. “Origin-Destination Flow Data
Smoothing and Mapping.” *IEEE Transactions on Visualization and Computer
Graphics* 20 (12): 2043–52. <https://doi.org/10.1109/TVCG.2014.2346271>.

</div>

<div id="ref-he_simple_2018" class="csl-entry">

He, Biao, Yan Zhang, Yu Chen, and Zhihui Gu. 2018. “A Simple Line
Clustering Method for Spatial Analysis with Origin-Destination Data and
Its Application to Bike-Sharing Movement Data.” *ISPRS International
Journal of Geo-Information* 7 (6): 203.
<https://doi.org/10.3390/ijgi7060203>.

</div>

<div id="ref-horni_multiagent_2016" class="csl-entry">

Horni, Andreas, Kai Nagel, and Kay W. Axhausen. 2016. *The Multi-Agent
Transport Simulation MATSim*. Ubiquity Press.
<https://doi.org/10.5334/baw>.

</div>

<div id="ref-jafari_investigation_2015" class="csl-entry">

Jafari, Ehsan, Mason D. Gemar, Natalia Ruiz Juri, and Jennifer Duthie.
2015. “Investigation of Centroid Connector Placement for Advanced
Traffic Assignment Models with Added Network Detail.” *Transportation
Research Record: Journal of the Transportation Research Board* 2498
(June): 19–26. <https://doi.org/10.3141/2498-03>.

</div>

<div id="ref-katranji_mobility_2016" class="csl-entry">

Katranji, Mehdi, Etienne Thuillier, Sami Kraiem, Laurent Moalic, and
Fouad Hadj Selem. 2016. “Mobility Data Disaggregation: A Transfer
Learning Approach.” In *2016 IEEE 19th International Conference on
Intelligent Transportation Systems (ITSC)*, 1672–77.
<https://doi.org/10.1109/ITSC.2016.7795783>.

</div>

<div id="ref-leurent_stochastic_2011" class="csl-entry">

Leurent, Fabien, Vincent Benezech, and Mahdi Samadzad. 2011. “A
Stochastic Model of Trip End Disaggregation in Traffic Assignment to a
Transportation Network.” *Procedia - Social and Behavioral Sciences*,
The State of the Art in the European Quantitative Oriented
Transportation and Logistics Research – 14th Euro Working Group on
Transportation & 26th Mini Euro Conference & 1st European Scientific
Conference on Air Transport, 20 (January): 485–94.
<https://doi.org/10.1016/j.sbspro.2011.08.055>.

</div>

<div id="ref-li_effects_2019" class="csl-entry">

Li, Haojie, Yingheng Zhang, Hongliang Ding, and Gang Ren. 2019. “Effects
of Dockless Bike-Sharing Systems on the Usage of the London Cycle Hire.”
*Transportation Research Part A: Policy and Practice* 130 (December):
398–411. <https://doi.org/10.1016/j.tra.2019.09.050>.

</div>

<div id="ref-lindsey_minnesota_2013" class="csl-entry">

Lindsey, Greg, Steve Hankey, Xize Wang, and Junzhou Chen. 2013. “The
Minnesota Bicycle and Pedestrian Counting Initiative: Methodologies for
Non-Motorized Traffic Monitoring.” Minnesota Department of
Transportation. <https://www.lrrb.org/media/reports/201324.pdf>.

</div>

<div id="ref-liu_snn_2021" class="csl-entry">

Liu, Qiliang, Jie Yang, Min Deng, Ci Song, and Wenkai Liu. 2021.
“SNN\_flow: A Shared Nearest-Neighbor-Based Clustering Method for
Inhomogeneous Origin-Destination Flows.” *International Journal of
Geographical Information Science*, 1–27.

</div>

<div id="ref-martin_origindestination_2018" class="csl-entry">

Martin, David, Christopher Gale, Samantha Cockings, and Andrew Harfoot.
2018. “Origin-Destination Geodemographics for Analysis of Travel to Work
Flows.” *Computers, Environment and Urban Systems* 67 (January): 68–79.
<https://doi.org/10.1016/j.compenvurbsys.2017.09.002>.

</div>

<div id="ref-morgan_travel_2020" class="csl-entry">

Morgan, Malcolm, and Robin Lovelace. 2020. “Travel Flow Aggregation:
Nationally Scalable Methods for Interactive and Online Visualisation of
Transport Behaviour at the Road Network Level.” *Environment & Planning
B: Planning & Design*, July. <https://doi.org/10.1177/2399808320942779>.

</div>

<div id="ref-openshaw_optimal_1977" class="csl-entry">

Openshaw, S. 1977. “Optimal Zoning Systems for Spatial Interaction
Models.” *Environment and Planning A* 9 (2): 169–84.
<https://doi.org/10.1068/a090169>.

</div>

<div id="ref-opie_commodityspecific_2009" class="csl-entry">

Opie, Keir, Jakub Rowinski, and Lazar N. Spasovic. 2009.
“Commodity-Specific Disaggregation of 2002 Freight Analysis Framework
Data to County Level in New Jersey.” *Transportation Research Record*
2121 (1): 128–34. <https://doi.org/10.3141/2121-14>.

</div>

<div id="ref-shi_exploring_2019" class="csl-entry">

Shi, Xiaoying, Fanshun Lv, Dewen Seng, Baixi Xing, and Jing Chen. 2019.
“Exploring the Evolutionary Patterns of Urban Activity Areas Based on
Origin-Destination Data.” *IEEE Access* 7: 20416–31.

</div>

<div id="ref-wickham_ggplot2_2016" class="csl-entry">

Wickham, Hadley. 2016. *Ggplot2: Elegant Graphics for Data Analysis*.
2nd ed. 2016 edition. New York, NY: Springer.

</div>

<div id="ref-zheng_big_2016" class="csl-entry">

Zheng, Xinhu, Wei Chen, Pu Wang, Dayong Shen, Songhang Chen, Xiao Wang,
Qingpeng Zhang, and Liuqing Yang. 2016. “Big Data for Social
Transportation.” *IEEE Transactions on Intelligent Transportation
Systems* 17 (3): 620–30.
<http://ieeexplore.ieee.org/abstract/document/7359138/>.

</div>

</div>
