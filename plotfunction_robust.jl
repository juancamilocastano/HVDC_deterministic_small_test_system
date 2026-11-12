function plotfunction_robust!(m::Model; save_figures::Bool = true, focus_area::Int = 2, focus_scenario = :all)
    # Plots for the robust model:
    #   1. Power of each generator: day-ahead schedule (first stage) and actual output in each wind scenario (second stage)
    #   2. Procured reserve of each generator (first stage)
    #   3. Total procured reserve per area by resource type (generators, batteries, electrolyzers)
    #   4. Power loss per event type and area: generator loss, converter loss and the imbalance created
    #      by HVDC reserve provision (worst contingency k, one bar per wind scenario)
    #   5. HVDC reserve delivered to each area (worst contingency k, summed over the converters of the area)
    #   6. HVDC power flow: DC branch flow and converter AC power, day-ahead schedule and actual operation
    #   7. RoCoF and frequency nadir deviation of the worst contingency k of each event type, with the limits
    #   8. Largest contingency of each event type: power lost and reserve deployed to face it, by resource
    #   9. Load shedding per area
    #  10. Renewable curtailment (wind and solar) per area
    #  11. Total generation by technology per area
    #  12. Total procured inertia per area
    #  13. HVDC flow with the HVDC reserve on top, per converter and wind scenario
    #  14. System demand: base demand, demand minus rooftop solar, and net demand
    #      (minus rooftop solar + electrolyzer consumption + battery charging)
    #  15. Battery power and stored energy
    #  16. Electrolyzer hydrogen flows (production, purchase, sale) and stored hydrogen
    #  17. Reserve gaps in the wind-farm contingency: reserve deployed, procured but unused, and still procurable,
    #      by technology, together with the wind production and the wind available (extra figures)
    #  18. Deployed vs procured reserve (+ maximum HVDC reserve) for the three imbalances (generator loss, converter
    #      loss, HVDC reserve-provision imbalance) of area focus_area, one figure per wind scenario
    #      (focus_scenario = :all for every scenario, or the name of one scenario)
    #  20. Electrolyzers: power consumed and procured reserve, in both areas
    # Requires frequency_metrics_robust.jl to be included.
    # Requires Makie (CairoMakie or GLMakie) to be loaded. Returns a Dict with all figures.

    # ============================================================
    # SETS AND PARAMETERS
    # ============================================================

    G1 = m.ext[:sets][:G1]
    G2 = m.ext[:sets][:G2]
    S1 = m.ext[:sets][:S1]
    S2 = m.ext[:sets][:S2]
    E1 = m.ext[:sets][:E1]
    E2 = m.ext[:sets][:E2]
    T  = m.ext[:sets][:t]
    W  = m.ext[:sets][:Wind_scenarios]

    G_solar = m.ext[:sets][:G_solar]
    G_wind  = m.ext[:sets][:G_wind]

    baseMVA = m.ext[:parameters][:baseMVA]
    pmax    = m.ext[:parameters][:pmax]

    x  = 1:length(T)      # hour position on the x axis (T is a vector of strings)
    NT = length(T)

    # Technology of each generator, used in the panel titles
    technology = Dict{Any,String}()
    for (set_name, label) in [(:G_nuclear, "nuclear"), (:G_gas, "gas"), (:G_biomass, "biomass"), (:G_oil, "oil"),
                              (:G_reservoir, "hydro reservoir"), (:G_pump, "pumped storage"),
                              (:G_solar, "solar"), (:G_wind, "wind")]
        for g in m.ext[:sets][set_name]
            technology[g] = label
        end
    end

    # Sort unit names numerically when possible ("1", "2", "10" instead of "1", "10", "2")
    sortkeys(v) = sort(collect(v), by = k -> (n = tryparse(Int, string(k)); n === nothing ? typemax(Int) : n))

    # ============================================================
    # RESULTS (converted to MW)
    # ============================================================

    pg_fs = JuMP.value.(m.ext[:variables][:pg_fs]) .* baseMVA      # [g, t]
    pg_ss = JuMP.value.(m.ext[:variables][:pg_ss]) .* baseMVA      # [g, t, w]
    zg_fs = JuMP.value.(m.ext[:variables][:zg_fs])                 # [g, t]

    r_proc_g = Dict(1 => JuMP.value.(m.ext[:variables][:r_proc_g_1]) .* baseMVA,
                    2 => JuMP.value.(m.ext[:variables][:r_proc_g_2]) .* baseMVA)
    r_proc_s = Dict(1 => JuMP.value.(m.ext[:variables][:r_proc_s_1]) .* baseMVA,
                    2 => JuMP.value.(m.ext[:variables][:r_proc_s_2]) .* baseMVA)
    r_proc_e = Dict(1 => JuMP.value.(m.ext[:variables][:r_proc_e_1]) .* baseMVA,
                    2 => JuMP.value.(m.ext[:variables][:r_proc_e_2]) .* baseMVA)

    areas = Dict(1 => (name = "Area 1 (Nordic)", G = G1, S = S1, E = E1),
                 2 => (name = "Area 2 (GB)",     G = G2, S = S2, E = E2))

    # Contingency sets and converters per area
    fallos_g = Dict(1 => m.ext[:sets][:fallos_g1], 2 => m.ext[:sets][:fallos_g2])
    fallos_c = Dict(1 => m.ext[:sets][:fallos_c1], 2 => m.ext[:sets][:fallos_c2])
    CVa      = Dict(1 => m.ext[:sets][:CV1],       2 => m.ext[:sets][:CV2])
    other    = Dict(1 => 2, 2 => 1)

    val(name) = JuMP.value.(m.ext[:variables][name]) .* baseMVA

    # Power losses [t, k, w] per area and event type
    events = Dict(a => [
        (title = "Generator loss (own area)",
         pl = val(Symbol("plg$(a)_ss")),          K = fallos_g[a]),
        (title = "Converter loss (own area)",
         pl = val(Symbol("plc$(a)_ss")),          K = fallos_c[a]),
        (title = "HVDC reserve-provision imbalance (generator trips in the other area)",
         pl = val(Symbol("plreserve_$(a)_g_ss")), K = fallos_g[other[a]]),
        (title = "HVDC reserve-provision imbalance (converter trips in the other area)",
         pl = val(Symbol("plreserve_$(a)_c_ss")), K = fallos_c[other[a]])
    ] for a in (1, 2))

    # HVDC reserve delivered to each area [cv, t, k, w]
    rhvdc = Dict(a => [
        (title = "After a generator trip in $(areas[a].name)", r = val(Symbol("rhvdc_lg$(a)_ss")), K = fallos_g[a]),
        (title = "After a converter trip in $(areas[a].name)", r = val(Symbol("rhvdc_lc$(a)_ss")), K = fallos_c[a])
    ] for a in (1, 2))

    # Worst case over the contingencies k of one type
    worst_loss(pl, K, t, w)       = isempty(K) ? 0.0 : maximum(pl[t, k, w] for k in K)
    worst_hvdc(r, CVs, K, t, w)   = isempty(K) ? 0.0 : maximum(sum((r[cv, t, k, w] for cv in CVs); init = 0.0) for k in K)

    colors  = [:dodgerblue, :darkorange, :seagreen, :purple, :firebrick]   # 1-2: wind scenarios, 3: generator reserve
    figures = Dict{String,Any}()

    # Grouped bars (side by side, so the wind scenarios do not overlap): series = one vector per wind scenario
    function grouped_bars!(ax, series)
        n   = length(series)
        grp = repeat(1:n, inner = NT)
        barplot!(ax, repeat(collect(x), n), reduce(vcat, series), dodge = grp, color = colors[grp])
    end
    wind_legend(pos) = Legend(pos, [PolyElement(color = colors[j]) for j in eachindex(W)], ["$w" for w in W],
                              orientation = :horizontal, framevisible = false, tellwidth = false)

    # Day-ahead schedule drawn so that it stays visible when it coincides with the actual output:
    #   schedule_band!    -> wide translucent grey band, drawn BEFORE the actual-output lines (stays underneath)
    #   schedule_markers! -> thin dashed black line with hollow squares, drawn AFTER them (stays on top)
    # Where the schedule and an actual output coincide, the coloured line runs inside the grey band and its
    # markers sit inside the hollow squares; where they differ, band and squares appear apart from it.
    schedule_band!(ax, vals)    = lines!(ax, x, vals, color = (:black, 0.18), linewidth = 12)
    schedule_markers!(ax, vals) = scatterlines!(ax, x, vals, color = :black, linestyle = :dash, linewidth = 1.2,
                                                marker = :rect, markersize = 17, markercolor = :transparent,
                                                strokecolor = :black, strokewidth = 1.5)

    # Actual value per wind scenario, drawn in layers so that coinciding scenarios remain visible:
    #   first scenario (High_wind): thick semi-transparent line + large hollow circles (underneath)
    #   other scenarios (Low_wind): thin line + small crosses (on top)
    # Where they coincide, the cross sits inside the circle and the thin line runs inside the thick one.
    # Together with the schedule squares this gives nested markers: cross ⊂ circle ⊂ square.
    actual_line_style(j) = j == 1 ?
        (line = (color = (colors[1], 0.55), linewidth = 5),
         marker = (marker = :circle, markersize = 12, color = :transparent, strokecolor = colors[1], strokewidth = 1.8)) :
        (line = (color = colors[j], linewidth = 1.5),
         marker = (marker = :xcross, markersize = 8, color = colors[j], strokecolor = colors[j], strokewidth = 0))

    function actual_lines!(ax, series)
        for (j, vals) in enumerate(series)
            st = actual_line_style(j)
            lines!(ax, x, vals; st.line...)
            scatter!(ax, x, vals; st.marker...)
        end
    end

    # Legend entries: day-ahead schedule + actual value per wind scenario
    function schedule_legend_entries(actual_label)
        elems  = Any[[LineElement(color = (:black, 0.18), linewidth = 12),
                      LineElement(color = :black, linestyle = :dash, linewidth = 1.2),
                      MarkerElement(marker = :rect, markersize = 17, color = :transparent,
                                    strokecolor = :black, strokewidth = 1.5)]]
        labels = ["Day-ahead schedule (first stage)"]
        for (j, w) in enumerate(W)
            st = actual_line_style(j)
            push!(elems, [LineElement(; st.line...), MarkerElement(; st.marker...)])
            push!(labels, "$actual_label, $w (second stage)")
        end
        return elems, labels
    end

    # ============================================================
    # 1. POWER OF EACH GENERATOR
    # ============================================================
    # One panel per generator: grey band + hollow squares = day-ahead schedule, coloured = actual output per
    # wind scenario, dotted grey = available capacity (pmax if the unit is committed, 0 otherwise).

    for a in (1, 2)
        gens = sortkeys(areas[a].G)
        isempty(gens) && continue
        nc = min(3, length(gens))
        nr = cld(length(gens), nc)

        fig = Figure(size = (420 * nc, 280 * nr + 120))
        Label(fig[0, 1:nc], "Generation by unit, $(areas[a].name)", fontsize = 18, font = :bold, tellwidth = false)

        for (i, g) in enumerate(gens)
            r, c = fldmod1(i, nc)
            ax = Axis(fig[r, c], title = "Generator $g ($(get(technology, g, "other")))",
                      xlabel = "Time (hours)", ylabel = "Power (MW)")
            schedule_vals = [pg_fs[g, t] for t in T]
            lines!(ax, x, [pmax[g] * baseMVA * zg_fs[g, t] for t in T], color = :gray, linestyle = :dot)
            schedule_band!(ax, schedule_vals)                                 # underneath
            actual_lines!(ax, [[pg_ss[g, t, w] for t in T] for w in W])        # High_wind thick, Low_wind thin on top
            schedule_markers!(ax, schedule_vals)                              # on top
            xlims!(ax, 0.5, NT + 0.5)
        end
        elems, labels = schedule_legend_entries("Actual output")
        Legend(fig[nr + 1, 1:nc], vcat(elems, [LineElement(color = :gray, linestyle = :dot)]),
               vcat(labels, ["Available capacity (pmax × commitment)"]),
               orientation = :horizontal, framevisible = false, tellwidth = false, nbanks = 2)

        figures["generation_area$a"] = fig
        save_figures && save("generation_by_unit_area$(a).png", fig)
    end

    # ============================================================
    # 2. PROCURED RESERVE OF EACH GENERATOR
    # ============================================================
    # Renewables are left out because their procured reserve is fixed to zero.

    for a in (1, 2)
        gens = [g for g in sortkeys(areas[a].G) if !(g in G_solar) && !(g in G_wind)]
        isempty(gens) && continue
        nc = min(3, length(gens))
        nr = cld(length(gens), nc)

        fig = Figure(size = (420 * nc, 280 * nr + 60))
        Label(fig[0, 1:nc], "Procured reserve by generator (first stage), $(areas[a].name)", fontsize = 18, font = :bold, tellwidth = false)

        for (i, g) in enumerate(gens)
            r, c = fldmod1(i, nc)
            ax = Axis(fig[r, c], title = "Generator $g ($(get(technology, g, "other")))",
                      xlabel = "Time (hours)", ylabel = "Procured reserve (MW)")
            barplot!(ax, x, [r_proc_g[a][g, t] for t in T], color = colors[3])
            xlims!(ax, 0.5, NT + 0.5)
            ylims!(ax, low = 0)
        end

        figures["procured_reserve_generators_area$a"] = fig
        save_figures && save("procured_reserve_by_generator_area$(a).png", fig)
    end

    # ============================================================
    # 3. TOTAL PROCURED RESERVE PER AREA BY RESOURCE TYPE
    # ============================================================
    # Stacked bars: generators + batteries + electrolyzers, one bar per hour.

    fig = Figure(size = (1000, 750))
    Label(fig[0, 1], "Total procured reserve by resource type (first stage)", fontsize = 18, font = :bold, tellwidth = false)
    resource_labels = ["Generators", "Batteries", "Electrolyzers"]
    resource_colors = [:seagreen, :dodgerblue, :darkorange]

    for a in (1, 2)
        gen_total  = [sum((r_proc_g[a][g, t] for g in areas[a].G); init = 0.0) for t in T]
        stor_total = [sum((r_proc_s[a][s, t] for s in areas[a].S); init = 0.0) for t in T]
        elec_total = [sum((r_proc_e[a][e, t] for e in areas[a].E); init = 0.0) for t in T]

        ax = Axis(fig[a, 1], title = areas[a].name, xlabel = "Time (hours)", ylabel = "Procured reserve (MW)")
        group = repeat(1:3, inner = NT)
        barplot!(ax, repeat(collect(x), 3), vcat(gen_total, stor_total, elec_total),
                 stack = group, color = resource_colors[group])
        xlims!(ax, 0.5, NT + 0.5)
        ylims!(ax, low = 0)
    end
    Legend(fig[3, 1], [PolyElement(color = c) for c in resource_colors], resource_labels,
           orientation = :horizontal, framevisible = false, tellwidth = false)

    figures["procured_reserve_by_resource"] = fig
    save_figures && save("procured_reserve_by_resource.png", fig)

    # ============================================================
    # 4. POWER LOSS PER EVENT TYPE
    # ============================================================
    # One figure per area, one panel per event type. Each bar is the largest loss over the
    # contingencies k of that type; bars of the two wind scenarios are placed side by side.

    for a in (1, 2)
        fig = Figure(size = (1150, 800))
        Label(fig[0, 1:2], "Power loss per event type (largest over contingencies k), $(areas[a].name)",
              fontsize = 18, font = :bold, tellwidth = false)
        for (i, ev) in enumerate(events[a])
            r, c = fldmod1(i, 2)
            ax = Axis(fig[r, c], title = replace(ev.title, " (" => "\n("),
                      xlabel = "Time (hours)", ylabel = "Power (MW)")
            grouped_bars!(ax, [[worst_loss(ev.pl, ev.K, t, w) for t in T] for w in W])
            xlims!(ax, 0.5, NT + 0.5)
            ylims!(ax, low = 0)
        end
        wind_legend(fig[3, 1:2])

        figures["power_loss_area$a"] = fig
        save_figures && save("power_loss_area$(a).png", fig)
    end

    # ============================================================
    # 5. HVDC RESERVE
    # ============================================================
    # Reserve delivered to each area through the HVDC link, summed over the converters of the area,
    # for the worst contingency k of each type. It equals the reserve-provision imbalance of the other area.

    fig = Figure(size = (1150, 800))
    Label(fig[0, 1:2], "HVDC reserve delivered to each area (largest over contingencies k)", fontsize = 18, font = :bold, tellwidth = false)
    for a in (1, 2), (j, rv) in enumerate(rhvdc[a])
        ax = Axis(fig[a, j], title = rv.title, xlabel = "Time (hours)", ylabel = "HVDC reserve (MW)")
        grouped_bars!(ax, [[worst_hvdc(rv.r, CVa[a], rv.K, t, w) for t in T] for w in W])
        xlims!(ax, 0.5, NT + 0.5)
        ylims!(ax, low = 0)
    end
    wind_legend(fig[3, 1:2])

    figures["hvdc_reserve"] = fig
    save_figures && save("hvdc_reserve.png", fig)

    # ============================================================
    # 6. HVDC POWER FLOW
    # ============================================================
    # Row 1: flow on each DC branch (from-to direction). Row 2: AC power of each converter
    # (positive = injection into its AC area, negative = absorption). Grey band + hollow squares =
    # day-ahead schedule, coloured = actual flow per wind scenario, dotted grey = rating (±).

    BD_dc_fr      = m.ext[:sets][:BD_dc_fr]
    brdc_rate_a   = m.ext[:parameters][:branchdc][:rate_a]
    conv_p_ac_max = m.ext[:parameters][:convdc][:p_ac_max]

    brdc_fs = val(:brdc_p_fs)       # [(d,e,f), t]
    brdc_ss = val(:brdc_p_ss)       # [(d,e,f), t, w]
    conv_fs = val(:conv_p_ac_fs)    # [cv, t]
    conv_ss = val(:conv_p_ac_ss)    # [cv, t, w]

    branches = collect(BD_dc_fr)
    convs    = vcat([(cv, 1) for cv in sortkeys(CVa[1])], [(cv, 2) for cv in sortkeys(CVa[2])])
    nc_flow  = max(length(branches), length(convs), 1)

    function flow_panel!(pos, title, ylabel, fs_vals, ss_vals, limit)
        ax = Axis(pos, title = title, xlabel = "Time (hours)", ylabel = ylabel)
        hlines!(ax, [limit, -limit], color = :gray, linestyle = :dot)
        hlines!(ax, [0.0], color = :black, linewidth = 0.5)
        schedule_band!(ax, fs_vals)                               # underneath
        actual_lines!(ax, ss_vals)                                # High_wind thick, Low_wind thin on top
        schedule_markers!(ax, fs_vals)                            # on top
        xlims!(ax, 0.5, NT + 0.5)
        return ax
    end

    fig = Figure(size = (560 * nc_flow, 850))
    Label(fig[0, 1:nc_flow], "HVDC power flow: day-ahead schedule and actual operation", fontsize = 18, font = :bold, tellwidth = false)

    legend_ax = nothing
    for (i, (d, e, f)) in enumerate(branches)
        ax = flow_panel!(fig[1, i], "DC branch $d (DC bus $e → DC bus $f)", "Power flow (MW)",
                         [brdc_fs[(d, e, f), t] for t in T],
                         [[brdc_ss[(d, e, f), t, w] for t in T] for w in W],
                         brdc_rate_a[d] * baseMVA)
        legend_ax === nothing && (legend_ax = ax)
    end
    for (i, (cv, a)) in enumerate(convs)
        ax = flow_panel!(fig[2, i], "Converter $cv, $(areas[a].name)", "AC power (MW), + = injection into the area",
                         [conv_fs[cv, t] for t in T],
                         [[conv_ss[cv, t, w] for t in T] for w in W],
                         conv_p_ac_max[cv] * baseMVA)
        legend_ax === nothing && (legend_ax = ax)
    end
    if legend_ax !== nothing
        elems, labels = schedule_legend_entries("Actual flow")
        Legend(fig[3, 1:nc_flow], vcat(elems, [LineElement(color = :gray, linestyle = :dot)]), vcat(labels, ["Rating (±)"]),
               orientation = :horizontal, framevisible = false, tellwidth = false, nbanks = 2)
    end

    figures["hvdc_flow"] = fig
    save_figures && save("hvdc_flow.png", fig)

    # ============================================================
    # 7. RoCoF AND FREQUENCY NADIR (worst contingency of each event type)
    # ============================================================
    # Rows = areas, columns = event types. Each bar is the largest value over the contingencies k of
    # that type (bars of the two wind scenarios side by side); red dashed line = limit of the model.

    fm = compute_frequency_metrics(m)
    for (metric, lim, ylabel, fname, ttl) in [
            (:rocof,  fm.rocof_lim,  "RoCoF (Hz/s)", "rocof_worst_contingency.png", "RoCoF of the worst contingency of each event type"),
            (:deltaf, fm.deltaf_lim, "Δf nadir (Hz)", "nadir_worst_contingency.png", "Frequency nadir deviation of the worst contingency of each event type")]
        nev = length(fm.results[1])
        fig = Figure(size = (420 * nev, 800))
        Label(fig[0, 1:nev], ttl, fontsize = 18, font = :bold, tellwidth = false)
        for a in (1, 2), (i, ev) in enumerate(fm.results[a])
            ax = Axis(fig[a, i], title = "$(areas[a].name)\n" * replace(ev.title, " (" => "\n("),
                      titlesize = 13, xlabel = "Time (hours)", ylabel = ylabel)
            finite_or_nan(v) = isfinite(v) ? v : NaN
            series = [[finite_or_nan(worst_over_k(getproperty(ev, metric), ev.K, t, w)[1]) for t in T] for w in W]
            grouped_bars!(ax, series)
            hlines!(ax, [lim[a]], color = :red, linestyle = :dash, linewidth = 2)
            xlims!(ax, 0.5, NT + 0.5)
            ylims!(ax, low = 0)
        end
        Legend(fig[3, 1:nev],
               vcat([PolyElement(color = colors[j]) for j in eachindex(W)], [LineElement(color = :red, linestyle = :dash)]),
               vcat(["$w" for w in W], ["Limit"]), orientation = :horizontal, framevisible = false, tellwidth = false)

        figures[string(metric)] = fig
        save_figures && save(fname, fig)
    end

    # ============================================================
    # 8. LARGEST CONTINGENCY OF EACH EVENT TYPE AND THE RESERVE THAT FACES IT
    # ============================================================
    # One figure per area: rows = event types, columns = wind scenarios.
    # Black line with diamonds = power lost in the largest contingency k of that type (largest loss over k);
    # stacked bars = reserve deployed for that same k, by resource (generators, batteries, electrolyzers, HVDC).

    res_labels = ["Generators", "Batteries", "Electrolyzers", "HVDC"]
    res_colors = [:seagreen, :dodgerblue, :darkorange, :purple]

    for a in (1, 2)
        evs = fm.results[a]
        nev = length(evs)
        fig = Figure(size = (650 * length(W), 270 * nev + 140))
        Label(fig[0, 1:length(W)], "Largest contingency per event type and reserve deployed to face it, $(areas[a].name)",
              fontsize = 18, font = :bold, tellwidth = false)

        for (i, ev) in enumerate(evs), (j, w) in enumerate(W)
            lc = [largest_contingency(ev, t, w) for t in T]
            ax = Axis(fig[i, j], title = replace(ev.title, " (" => "\n(") * ", $w", titlesize = 13,
                      xlabel = "Time (hours)", ylabel = "Power (MW)")
            grp = repeat(1:4, inner = NT)
            barplot!(ax, repeat(collect(x), 4),
                     vcat([c.r_gen for c in lc], [c.r_batt for c in lc], [c.r_elec for c in lc], [c.r_hvdc for c in lc]),
                     stack = grp, color = res_colors[grp])
            scatterlines!(ax, x, [c.ploss for c in lc], color = :black, marker = :diamond, markersize = 9, linewidth = 2)
            xlims!(ax, 0.5, NT + 0.5)
            ylims!(ax, low = 0)
        end
        Legend(fig[nev + 1, 1:length(W)],
               vcat([PolyElement(color = c) for c in res_colors],
                    [[LineElement(color = :black, linewidth = 2), MarkerElement(color = :black, marker = :diamond)]]),
               vcat(res_labels, ["Power lost (largest contingency)"]),
               orientation = :horizontal, framevisible = false, tellwidth = false)

        figures["largest_contingency_area$a"] = fig
        save_figures && save("largest_contingency_reserve_area$(a).png", fig)
    end

    # ============================================================
    # SECTIONS 9-16: SYSTEM RESULTS
    # ============================================================
    sr = compute_system_results(m)
    DA = sr.DA

    # Draws one quantity in the usual style: day-ahead schedule (grey band + hollow squares) and the actual
    # value per wind scenario. d is a Dict((t, stage) => value).
    function stage_panel!(ax, d)
        fs_vals = [d[(t, DA)] for t in T]
        schedule_band!(ax, fs_vals)
        actual_lines!(ax, [[d[(t, w)] for t in T] for w in W])
        schedule_markers!(ax, fs_vals)
        xlims!(ax, 0.5, NT + 0.5)
    end
    function stage_legend!(pos)
        elems, labels = schedule_legend_entries("Actual")
        Legend(pos, elems, labels, orientation = :horizontal, framevisible = false, tellwidth = false)
    end
    unit_area(a) = areas[a].name

    # ---------------- 9. LOAD SHEDDING ----------------
    fig = Figure(size = (1150, 450))
    Label(fig[0, 1:2], "Load shedding", fontsize = 18, font = :bold, tellwidth = false)
    for a in (1, 2)
        ax = Axis(fig[1, a], title = unit_area(a), xlabel = "Time (hours)", ylabel = "Load shed (MW)")
        stage_panel!(ax, sr.areas[a][:load_shed])
        ylims!(ax, low = 0)
    end
    stage_legend!(fig[2, 1:2])
    figures["load_shedding"] = fig
    save_figures && save("load_shedding.png", fig)

    # ---------------- 10. RENEWABLE CURTAILMENT ----------------
    # Curtailment = available renewable power - renewable power produced (day-ahead: forecast availability).
    fig = Figure(size = (1150, 800))
    Label(fig[0, 1:2], "Renewable curtailment (available minus produced)", fontsize = 18, font = :bold, tellwidth = false)
    for a in (1, 2), (j, (key, lbl)) in enumerate([(:wind_curt, "Wind"), (:solar_curt, "Solar (utility scale)")])
        ax = Axis(fig[a, j], title = "$lbl, $(unit_area(a))", xlabel = "Time (hours)", ylabel = "Curtailment (MW)")
        stage_panel!(ax, sr.areas[a][key])
        ylims!(ax, low = 0)
    end
    stage_legend!(fig[3, 1:2])
    figures["curtailment"] = fig
    save_figures && save("renewable_curtailment.png", fig)

    # ---------------- 11. GENERATION BY TECHNOLOGY ----------------
    tech_colors = Dict("nuclear" => :mediumpurple, "gas" => :gray55, "biomass" => :saddlebrown, "oil" => :black,
                       "hydro reservoir" => :navy, "pumped storage" => :teal, "solar" => :gold, "wind" => :skyblue)
    for a in (1, 2)
        gt = sr.areas[a][:gen_tech]
        used = [tech for tech in sr.techs if any(gt[tech][(t, s)] > 1e-6 for t in T, s in sr.stages)]
        isempty(used) && continue
        ns  = length(sr.stages)
        fig = Figure(size = (480 * ns, 480))
        Label(fig[0, 1:ns], "Generation by technology, $(unit_area(a))", fontsize = 18, font = :bold, tellwidth = false)
        ymax = maximum(sum(gt[tech][(t, s)] for tech in used) for t in T, s in sr.stages)
        for (j, s) in enumerate(sr.stages)
            ax = Axis(fig[1, j], title = s == DA ? "Day-ahead schedule (first stage)" : "Actual, $s (second stage)",
                      xlabel = "Time (hours)", ylabel = "Generation (MW)")
            grp = repeat(1:length(used), inner = NT)
            barplot!(ax, repeat(collect(x), length(used)), reduce(vcat, [[gt[tech][(t, s)] for t in T] for tech in used]),
                     stack = grp, color = [tech_colors[used[i]] for i in grp])
            xlims!(ax, 0.5, NT + 0.5)
            ylims!(ax, 0, 1.05 * ymax)
        end
        Legend(fig[2, 1:ns], [PolyElement(color = tech_colors[tech]) for tech in used], used,
               orientation = :horizontal, framevisible = false, tellwidth = false)
        figures["generation_by_technology_area$a"] = fig
        save_figures && save("generation_by_technology_area$(a).png", fig)
    end

    # ---------------- 12. TOTAL PROCURED INERTIA ----------------
    # Inertia of the committed synchronous units (first stage): sum(zg * H * pmax).
    fig = Figure(size = (1150, 420))
    Label(fig[0, 1:2], "Total procured inertia (first stage commitment)", fontsize = 18, font = :bold, tellwidth = false)
    for a in (1, 2)
        ax = Axis(fig[1, a], title = unit_area(a), xlabel = "Time (hours)", ylabel = "Inertia (MW·s)")
        barplot!(ax, collect(x), [sr.areas[a][:inertia][t] for t in T], color = :slateblue)
        xlims!(ax, 0.5, NT + 0.5)
        ylims!(ax, low = 0)
    end
    figures["inertia"] = fig
    save_figures && save("procured_inertia.png", fig)

    # ---------------- 13. HVDC FLOW + HVDC RESERVE ----------------
    # One panel per converter and wind scenario: line = actual AC power of the converter (+ = injection into
    # its area), shaded band = HVDC reserve that can be delivered through it on top of the flow (worst k),
    # dashed line = flow + reserve, dotted grey = rating (±).
    convs_sorted = vcat([cv for cv in sortkeys(CVa[1])], [cv for cv in sortkeys(CVa[2])])
    if !isempty(convs_sorted)
        fig = Figure(size = (560 * length(W), 330 * length(convs_sorted) + 120))
        Label(fig[0, 1:length(W)], "HVDC flow and HVDC reserve on top of it", fontsize = 18, font = :bold, tellwidth = false)
        for (i, cv) in enumerate(convs_sorted), (j, w) in enumerate(W)
            c    = sr.converters[cv]
            flow = [c.flow[(t, w)] for t in T]
            top  = flow .+ [c.reserve[(t, w)] for t in T]
            ax = Axis(fig[i, j], title = "Converter $cv, $(unit_area(c.area)), $w", xlabel = "Time (hours)",
                      ylabel = "AC power (MW), + = injection")
            lim = conv_p_ac_max[cv] * baseMVA
            hlines!(ax, [lim, -lim], color = :gray, linestyle = :dot)
            hlines!(ax, [0.0], color = :black, linewidth = 0.5)
            band!(ax, collect(x), flow, top, color = (:purple, 0.3))
            lines!(ax, x, top, color = :purple, linestyle = :dash, linewidth = 1.5)
            scatterlines!(ax, x, flow, color = colors[j], linewidth = 2, markersize = 7)
            xlims!(ax, 0.5, NT + 0.5)
        end
        Legend(fig[length(convs_sorted) + 1, 1:length(W)],
               [[LineElement(color = :black, linewidth = 2), MarkerElement(color = :black, marker = :circle, markersize = 7)],
                PolyElement(color = (:purple, 0.3)), LineElement(color = :purple, linestyle = :dash),
                LineElement(color = :gray, linestyle = :dot)],
               ["Actual flow (colour = wind scenario)", "HVDC reserve (worst contingency)", "Flow + reserve", "Rating (±)"],
               orientation = :horizontal, framevisible = false, tellwidth = false)
        figures["hvdc_flow_reserve"] = fig
        save_figures && save("hvdc_flow_and_reserve.png", fig)
    end

    # ---------------- 14. SYSTEM DEMAND ----------------
    # Base demand: input demand (without electrolyzers, batteries or rooftop solar).
    # Demand - rooftop: base demand reduced by rooftop solar injection.
    # Net demand: base demand - rooftop solar + electrolyzer consumption (incl. compressors) + battery charging.
    for a in (1, 2)
        ns  = length(sr.stages)
        fig = Figure(size = (480 * ns, 480))
        Label(fig[0, 1:ns], "System demand, $(unit_area(a))", fontsize = 18, font = :bold, tellwidth = false)
        D = sr.areas[a]
        for (j, s) in enumerate(sr.stages)
            ax = Axis(fig[1, j], title = s == DA ? "Day-ahead schedule (first stage)" : "Actual, $s (second stage)",
                      xlabel = "Time (hours)", ylabel = "Power (MW)")
            lines!(ax, x, [D[:demand_base][t] for t in T], color = :black, linewidth = 2)
            lines!(ax, x, [D[:demand_base][t] - D[:rooftop][t] for t in T], color = :goldenrod, linestyle = :dash, linewidth = 2)
            scatterlines!(ax, x, [D[:net_demand][(t, s)] for t in T], color = :firebrick, linewidth = 2, markersize = 6)
            xlims!(ax, 0.5, NT + 0.5)
            ylims!(ax, low = 0)
        end
        Legend(fig[2, 1:ns],
               [LineElement(color = :black, linewidth = 2), LineElement(color = :goldenrod, linestyle = :dash, linewidth = 2),
                [LineElement(color = :firebrick, linewidth = 2), MarkerElement(color = :firebrick, marker = :circle, markersize = 6)]],
               ["Demand (without electrolyzers, batteries and rooftop solar)", "Demand minus rooftop solar",
                "Net demand (− rooftop solar + electrolyzers + battery charging)"],
               orientation = :horizontal, framevisible = false, tellwidth = false, nbanks = 2)
        figures["demand_area$a"] = fig
        save_figures && save("system_demand_area$(a).png", fig)
    end

    # ---------------- 15. BATTERIES ----------------
    # Left: net power (+ = discharging, - = charging). Right: stored energy.
    bats = vcat([b for b in sortkeys(areas[1].S)], [b for b in sortkeys(areas[2].S)])
    if !isempty(bats)
        fig = Figure(size = (1150, 300 * length(bats) + 120))
        Label(fig[0, 1:2], "Batteries: power and stored energy", fontsize = 18, font = :bold, tellwidth = false)
        for (i, b) in enumerate(bats)
            bb = sr.batteries[b]
            net = Dict(k => bb.discharge[k] - bb.charge[k] for k in keys(bb.charge))
            ax1 = Axis(fig[i, 1], title = "Battery $b, $(unit_area(bb.area)): net power", xlabel = "Time (hours)",
                       ylabel = "Power (MW), + = discharging")
            hlines!(ax1, [0.0], color = :black, linewidth = 0.5)
            stage_panel!(ax1, net)
            ax2 = Axis(fig[i, 2], title = "Battery $b, $(unit_area(bb.area)): stored energy", xlabel = "Time (hours)",
                       ylabel = "Energy (MWh)")
            stage_panel!(ax2, bb.energy)
        end
        stage_legend!(fig[length(bats) + 1, 1:2])
        figures["batteries"] = fig
        save_figures && save("batteries.png", fig)
    end

    # ---------------- 16. ELECTROLYZERS: HYDROGEN ----------------
    elecs = vcat([e for e in sortkeys(areas[1].E)], [e for e in sortkeys(areas[2].E)])
    if !isempty(elecs)
        cols = [(:production, "Hydrogen produced (kg/h)"), (:purchase, "Hydrogen purchased (kg/h)"),
                (:sale, "Hydrogen sold (kg/h)"), (:storage, "Hydrogen stored (kg)")]
        fig = Figure(size = (430 * length(cols), 300 * length(elecs) + 120))
        Label(fig[0, 1:length(cols)], "Electrolyzers: hydrogen flows and storage", fontsize = 18, font = :bold, tellwidth = false)
        for (i, e) in enumerate(elecs), (j, (key, lbl)) in enumerate(cols)
            ee = sr.electrolyzers[e]
            ax = Axis(fig[i, j], title = "Electrolyzer $e, $(unit_area(ee.area))", xlabel = "Time (hours)", ylabel = lbl)
            stage_panel!(ax, getproperty(ee, key))
            ylims!(ax, low = 0)
        end
        stage_legend!(fig[length(elecs) + 1, 1:length(cols)])
        figures["hydrogen"] = fig
        save_figures && save("electrolyzers_hydrogen.png", fig)
    end

    # ---------------- 17. RESERVE GAPS IN THE WIND-FARM CONTINGENCY ----------------
    # One figure per area: rows = wind farms that are a contingency, columns = wind scenarios.
    # Stacked bars (bottom to top): reserve deployed when the wind farm trips (solid), procured reserve not used
    # in that contingency (medium shade, margin A), reserve that could still be procured (light shade, margin B).
    # Black line with diamonds = wind production (= power lost if it trips); grey dashed line = wind available.
    # If the solid bars reach the black line and the medium shade is ~0, the procured reserve is exhausted and the
    # wind farm is limited by reserve; the light shade then shows which technology could still provide more.
    rg_data = compute_reserve_gaps(m)
    gap_alpha = [1.0, 0.45, 0.15]
    gap_names = ["Deployed", "Procured but unused (margin A)", "Still procurable (margin B)"]
    for a in (1, 2)
        winds = rg_data.gaps[a]
        isempty(winds) && continue
        fig = Figure(size = (650 * length(W), 330 * length(winds) + 170))
        Label(fig[0, 1:length(W)], "Reserve gaps when the wind farm trips, $(areas[a].name)", fontsize = 18, font = :bold, tellwidth = false)
        for (i, wk) in enumerate(winds), (j, w) in enumerate(W)
            ax = Axis(fig[i, j], title = "Wind farm $(wk.k) trips, $w", titlesize = 13,
                      xlabel = "Time (hours)", ylabel = "Power (MW)")
            heights = Float64[]; cols = Any[]; xs = Int[]; stk = Int[]
            for (layer, field) in enumerate((:deployed, :unused, :extra)), (ti, tech) in enumerate(rg_data.techs)
                for (h, t) in enumerate(T)
                    push!(xs, h)
                    push!(heights, getproperty(wk.data[(t, w)].tech[tech], field))
                    push!(cols, (res_colors[ti], gap_alpha[layer]))
                    push!(stk, (layer - 1) * length(rg_data.techs) + ti)
                end
            end
            barplot!(ax, xs, heights, stack = stk, color = cols, strokewidth = 0)
            lines!(ax, x, [wk.data[(t, w)].wind_avail for t in T], color = :gray40, linestyle = :dash, linewidth = 2)
            scatterlines!(ax, x, [wk.data[(t, w)].wind_prod for t in T], color = :black, marker = :diamond,
                          markersize = 9, linewidth = 2)
            xlims!(ax, 0.5, NT + 0.5)
            ylims!(ax, low = 0)
        end
        Legend(fig[length(winds) + 1, 1:length(W)],
               vcat([PolyElement(color = c) for c in res_colors],
                    [PolyElement(color = (:gray30, al)) for al in gap_alpha],
                    [[LineElement(color = :black, linewidth = 2), MarkerElement(color = :black, marker = :diamond)],
                     LineElement(color = :gray40, linestyle = :dash, linewidth = 2)]),
               vcat(rg_data.techs, gap_names, ["Wind production (= loss if it trips)", "Wind available"]),
               orientation = :horizontal, framevisible = false, tellwidth = false, nbanks = 3)
        figures["reserve_gaps_area$a"] = fig
        save_figures && save("reserve_gaps_wind_contingency_area$(a).png", fig)
    end

    # ---------------- 18. DEPLOYED VS PROCURED RESERVE, ONE AREA, EACH WIND SCENARIO ----------------
    # One figure per wind scenario (all scenarios by default, or only focus_scenario), for area focus_area.
    # One panel per imbalance. For every hour: left bar = reserve deployed in the largest contingency of that
    # imbalance, stacked by technology; right bar (light, black outline) = procured reserve of the area, stacked by
    # technology, with the MAXIMUM reserve the HVDC link could deliver on top (converter headroom; HVDC reserve is
    # not procured); black diamond = power lost. The right bar is the same in the three panels.
    dvp_scenarios = focus_scenario === :all ? W : [focus_scenario]
    for fsc in dvp_scenarios
        (fsc in W && focus_area in (1, 2)) || continue
        dvp = deployed_vs_procured(m, fm, focus_area, fsc)
        fields = (:r_gen, :r_batt, :r_elec, :r_hvdc)
        off, bw = 0.21, 0.38
        ymax = maximum(max(sum(getproperty(dvp.rows[t].procured, f) for f in fields),
                           maximum(max(ev.c.ploss, sum(getproperty(ev.c, f) for f in fields)) for ev in dvp.rows[t].events))
                       for t in T)
        fig = Figure(size = (1500, 300 * 3 + 160))
        Label(fig[0, 1], "Reserve deployed for each imbalance and reserve procured, $(areas[focus_area].name), $fsc",
              fontsize = 18, font = :bold, tellwidth = false)
        for (i, ttl) in enumerate(dvp.titles)
            ax = Axis(fig[i, 1], title = ttl * " (largest contingency of each hour; number = tripped element)", titlesize = 13,
                      xlabel = "Time (hours)", ylabel = "Power (MW)")
            xs = Float64[]; hs = Float64[]; st = Int[]; cl = Any[]
            for (h, t) in enumerate(T), (fi, f) in enumerate(fields)
                ev = dvp.rows[t].events[i]
                push!(xs, h - off); push!(hs, getproperty(ev.c, f));                 push!(st, fi); push!(cl, res_colors[fi])
                push!(xs, h + off); push!(hs, getproperty(dvp.rows[t].procured, f)); push!(st, fi); push!(cl, (res_colors[fi], 0.35))
            end
            barplot!(ax, xs, hs, stack = st, color = cl, width = bw, strokewidth = 0)
            # black outline around the procured reserve (generators + batteries + electrolyzers) ...
            proc_top = [dvp.rows[t].procured.r_gen + dvp.rows[t].procured.r_batt + dvp.rows[t].procured.r_elec for t in T]
            barplot!(ax, collect(x) .+ off, proc_top, width = bw, color = :transparent, strokecolor = :black, strokewidth = 1)
            # ... and a dashed purple outline around the maximum HVDC reserve stacked on top of it
            hv_top = proc_top .+ [dvp.rows[t].procured.r_hvdc for t in T]
            for (h, t) in enumerate(T)
                dvp.rows[t].procured.r_hvdc > 1e-6 || continue
                lines!(ax, [h + off - bw/2, h + off - bw/2, h + off + bw/2, h + off + bw/2],
                       [proc_top[h], hv_top[h], hv_top[h], proc_top[h]], color = :purple, linestyle = :dash, linewidth = 1)
            end
            scatter!(ax, collect(x) .- off, [dvp.rows[t].events[i].c.ploss for t in T], color = :black, marker = :diamond, markersize = 10)
            text!(ax, collect(x) .- off, fill(1.03 * ymax, NT), text = [string(dvp.rows[t].events[i].c.k) for t in T],
                  align = (:center, :bottom), fontsize = 9)
            xlims!(ax, 0.4, NT + 0.6)
            ylims!(ax, 0, 1.12 * ymax)
        end
        Legend(fig[4, 1],
               vcat([PolyElement(color = c) for c in res_colors],
                    [PolyElement(color = :gray30), PolyElement(color = (:gray30, 0.35), strokecolor = :black, strokewidth = 1),
                     PolyElement(color = (:purple, 0.35), strokecolor = :purple, strokewidth = 1, linestyle = :dash),
                     MarkerElement(color = :black, marker = :diamond, markersize = 10)]),
               vcat(res_labels, ["Deployed (left bar)", "Procured (right bar)", "Maximum HVDC reserve (right bar, on top)", "Power lost"]),
               orientation = :horizontal, framevisible = false, tellwidth = false, nbanks = 2)
        figures["deployed_vs_procured_$fsc"] = fig
        save_figures && save("deployed_vs_procured_area$(focus_area)_$(fsc).png", fig)
    end

    # ---------------- 20. ELECTROLYZERS: POWER CONSUMED AND PROCURED RESERVE ----------------
    # One column per electrolyzer (both areas). Top: power consumed (day-ahead schedule = grey band + hollow
    # squares, actual consumption per wind scenario), with the minimum consumption (dotted) and the procured reserve
    # shaded below the actual consumption of each scenario (the electrolyzer provides FCR by reducing its consumption).
    # Bottom: procured reserve (bars, first stage) and maximum reserve it could provide in each scenario
    # (actual consumption - minimum consumption, lines).
    Epmin_ = m.ext[:parameters][:Epmin]; Epmax_ = m.ext[:parameters][:Epmax]
    ze_v = JuMP.value.(m.ext[:variables][:ze_fs]); zestb_v = JuMP.value.(m.ext[:variables][:zestb_fs])
    elec_list = vcat([(e, 1) for e in sortkeys(areas[1].E)], [(e, 2) for e in sortkeys(areas[2].E)])
    if !isempty(elec_list)
        ne  = length(elec_list)
        fig = Figure(size = (720 * ne, 820))
        Label(fig[0, 1:ne], "Electrolyzers: power consumed and procured reserve", fontsize = 18, font = :bold, tellwidth = false)
        for (j, (e, a)) in enumerate(elec_list)
            pw    = sr.electrolyzers[e].power
            pmin_ = [(Epmin_[e] * ze_v[e, t] + 0.05 * Epmax_[e] * zestb_v[e, t]) * baseMVA for t in T]
            rproc = [r_proc_e[a][e, t] for t in T]

            ax1 = Axis(fig[1, j], title = "Electrolyzer $e, $(areas[a].name): power consumed", xlabel = "Time (hours)",
                       ylabel = "Power (MW)")
            for (wi, w) in enumerate(W)       # procured reserve carved out of the actual consumption
                cons = [pw[(t, w)] for t in T]
                band!(ax1, collect(x), cons .- rproc, cons, color = (colors[wi], 0.18))
            end
            lines!(ax1, x, pmin_, color = :gray40, linestyle = :dot, linewidth = 2)
            stage_panel!(ax1, pw)
            ylims!(ax1, low = 0)

            ax2 = Axis(fig[2, j], title = "Electrolyzer $e, $(areas[a].name): reserve", xlabel = "Time (hours)",
                       ylabel = "Reserve (MW)")
            barplot!(ax2, collect(x), rproc, color = (:olivedrab, 0.75), width = 0.7)
            for (wi, w) in enumerate(W)
                st_ = actual_line_style(wi)
                lines!(ax2, x, [pw[(t, w)] for t in T] .- pmin_; st_.line...)
            end
            xlims!(ax2, 0.5, NT + 0.5)
            ylims!(ax2, low = 0)
        end
        elems, labels = schedule_legend_entries("Actual consumption")
        Legend(fig[3, 1:ne],
               vcat(elems, [LineElement(color = :gray40, linestyle = :dot, linewidth = 2),
                            PolyElement(color = (:gray40, 0.18)), PolyElement(color = (:olivedrab, 0.75))],
                    [LineElement(; actual_line_style(wi).line...) for wi in eachindex(W)]),
               vcat(labels, ["Minimum consumption", "Procured reserve below actual consumption (shade)",
                             "Procured reserve (bars, first stage)"],
                    ["Maximum reserve possible, $w (actual − minimum)" for w in W]),
               orientation = :horizontal, framevisible = false, tellwidth = false, nbanks = 3)
        figures["electrolyzer_power_reserve"] = fig
        save_figures && save("electrolyzers_power_and_reserve.png", fig)
    end

    save_figures && println("Figures saved: generation_by_unit_area*.png, procured_reserve_by_generator_area*.png, ",
                            "procured_reserve_by_resource.png, power_loss_area*.png, hvdc_reserve.png, hvdc_flow.png, ",
                            "rocof_worst_contingency.png, nadir_worst_contingency.png, largest_contingency_reserve_area*.png, ",
                            "load_shedding.png, renewable_curtailment.png, generation_by_technology_area*.png, ",
                            "procured_inertia.png, hvdc_flow_and_reserve.png, system_demand_area*.png, batteries.png, ",
                            "electrolyzers_hydrogen.png, reserve_gaps_wind_contingency_area*.png, deployed_vs_procured_area*.png, electrolyzers_power_and_reserve.png")
    return figures
end
