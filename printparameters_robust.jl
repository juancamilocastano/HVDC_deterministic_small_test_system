function printparameters_robust!(m::Model; output_file::String = "generation_and_reserve_results.txt",
                                 focus_area::Int = 2, focus_scenario = :all)
    # Writes to a text file the same results shown by plotfunction_robust!:
    #   1. Power of each generator: day-ahead schedule (first stage), actual output in each wind scenario
    #      (second stage), available capacity (pmax x commitment) and procured reserve (first stage)
    #   2. Total procured reserve per area by resource type (generators, batteries, electrolyzers)
    #   3. Summary per generator: energy over the day and maximum procured reserve
    #   4. Power loss per event type and area: generator loss, converter loss and the imbalance created by
    #      HVDC reserve provision, for every contingency k and wind scenario w (and the worst k per hour)
    #   5. HVDC reserve delivered to each area, summed over the converters of the area, for every k and w
    #   6. HVDC power flow: DC branch flow and converter AC power, day-ahead schedule and actual operation
    #   7. RoCoF and frequency nadir deviation of the worst contingency k of each event type
    #   8. Largest contingency of each event type: power lost and reserve deployed to face it, by resource
    #   9. Load shedding per area
    #  10. Renewable curtailment (wind and solar): available, produced and curtailed power
    #  11. Total generation by technology per area
    #  12. Total procured inertia per area
    #  13. HVDC flow and HVDC reserve per converter
    #  14. System demand: base demand, rooftop solar, electrolyzer consumption, battery charging, net demand
    #  15. Battery power and stored energy
    #  16. Electrolyzer hydrogen flows and stored hydrogen
    #  17. Reserve gaps in the wind-farm contingency: deployed, procured but unused, and still procurable reserve
    #  18. Deployed vs procured reserve (+ maximum HVDC reserve) for the three imbalances of area focus_area,
    #      for every wind scenario (focus_scenario = :all) or only one (its name)
    #  19. Cost of the objective for each wind realization: first-stage and second-stage cost, and the cost of
    #      generation, hydrogen, procured reserve and load shedding (also printed in the console)
    # Requires frequency_metrics_robust.jl to be included.
    # All values in MW (or MWh for daily energy).

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

    baseMVA = m.ext[:parameters][:baseMVA]
    pmax    = m.ext[:parameters][:pmax]

    # Technology of each generator
    technology = Dict{Any,String}()
    for (set_name, label) in [(:G_nuclear, "nuclear"), (:G_gas, "gas"), (:G_biomass, "biomass"), (:G_oil, "oil"),
                              (:G_reservoir, "hydro reservoir"), (:G_pump, "pumped storage"),
                              (:G_solar, "solar"), (:G_wind, "wind")]
        for g in m.ext[:sets][set_name]
            technology[g] = label
        end
    end

    # Sort unit names numerically when possible
    sortkeys(v) = sort(collect(v), by = k -> (n = tryparse(Int, string(k)); n === nothing ? typemax(Int) : n))

    # Number formatting: fixed width, 2 decimals, no "-0.0"
    clean(x) = abs(x) < 1e-6 ? 0.0 : x
    num(x; width = 18) = lpad(string(round(clean(x), digits = 2)), width)
    txt(s; width = 18) = lpad(string(s), width)

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
        (title = "HVDC reserve after a generator trip in $(areas[a].name)", r = val(Symbol("rhvdc_lg$(a)_ss")), K = fallos_g[a]),
        (title = "HVDC reserve after a converter trip in $(areas[a].name)", r = val(Symbol("rhvdc_lc$(a)_ss")), K = fallos_c[a])
    ] for a in (1, 2))

    # Writes one table: per hour, the worst value over k for each wind scenario (with the k that causes it),
    # followed by the value of every contingency k in every wind scenario. f(t, k, w) returns the value.
    function write_event_table(io, title, K, f)
        println(io)
        println(io, title)
        if isempty(K)
            println(io, "  (no contingencies of this type)")
            return
        end
        Ks = sortkeys(K)

        header = txt("Hour"; width = 6)
        for w in W
            header *= txt("Worst $w") * txt("k"; width = 6)
        end
        for k in Ks, w in W
            header *= txt("k=$k $w")
        end
        println(io, header)
        println(io, "-"^length(header))

        for t in T
            row = txt(t; width = 6)
            for w in W
                vals = [f(t, k, w) for k in Ks]
                i = argmax(vals)
                row *= num(vals[i]) * txt(Ks[i]; width = 6)
            end
            for k in Ks, w in W
                row *= num(f(t, k, w))
            end
            println(io, row)
        end
    end

    # ============================================================
    # WRITE FILE
    # ============================================================

    open(output_file, "w") do io

        # --------------------------------------------------------
        # 1. POWER AND PROCURED RESERVE OF EACH GENERATOR
        # --------------------------------------------------------
        for a in (1, 2)
            println(io, "="^100)
            println(io, "GENERATION AND PROCURED RESERVE BY UNIT, $(areas[a].name)   [MW]")
            println(io, "="^100)

            for g in sortkeys(areas[a].G)
                println(io)
                println(io, "Generator $g ($(get(technology, g, "other"))), pmax = $(round(pmax[g] * baseMVA, digits = 2)) MW")

                # Header
                header = txt("Hour"; width = 6) * txt("Schedule (fs)")
                for w in W
                    header *= txt("Actual $w")
                end
                header *= txt("Capacity") * txt("Proc. reserve")
                println(io, header)
                println(io, "-"^length(header))

                # One row per hour
                for t in T
                    row = txt(t; width = 6) * num(pg_fs[g, t])
                    for w in W
                        row *= num(pg_ss[g, t, w])
                    end
                    row *= num(pmax[g] * baseMVA * zg_fs[g, t]) * num(r_proc_g[a][g, t])
                    println(io, row)
                end
            end
            println(io)
        end

        # --------------------------------------------------------
        # 2. TOTAL PROCURED RESERVE PER AREA BY RESOURCE TYPE
        # --------------------------------------------------------
        for a in (1, 2)
            println(io, "="^100)
            println(io, "TOTAL PROCURED RESERVE BY RESOURCE TYPE (first stage), $(areas[a].name)   [MW]")
            println(io, "="^100)

            header = txt("Hour"; width = 6) * txt("Generators") * txt("Batteries") * txt("Electrolyzers") * txt("Total")
            println(io, header)
            println(io, "-"^length(header))

            for t in T
                gen_total  = sum((r_proc_g[a][g, t] for g in areas[a].G); init = 0.0)
                stor_total = sum((r_proc_s[a][s, t] for s in areas[a].S); init = 0.0)
                elec_total = sum((r_proc_e[a][e, t] for e in areas[a].E); init = 0.0)
                println(io, txt(t; width = 6) * num(gen_total) * num(stor_total) * num(elec_total) *
                            num(gen_total + stor_total + elec_total))
            end
            println(io)
        end

        # --------------------------------------------------------
        # 3. SUMMARY PER GENERATOR
        # --------------------------------------------------------
        for a in (1, 2)
            println(io, "="^100)
            println(io, "SUMMARY BY UNIT, $(areas[a].name)   (energy in MWh over the day, reserve in MW)")
            println(io, "="^100)

            header = txt("Unit"; width = 6) * txt("Technology"; width = 18) * txt("Energy (fs)")
            for w in W
                header *= txt("Energy $w")
            end
            header *= txt("Hours on") * txt("Max reserve")
            println(io, header)
            println(io, "-"^length(header))

            for g in sortkeys(areas[a].G)
                row = txt(g; width = 6) * txt(get(technology, g, "other"); width = 18) *
                      num(sum(pg_fs[g, t] for t in T))
                for w in W
                    row *= num(sum(pg_ss[g, t, w] for t in T))
                end
                row *= txt(count(t -> zg_fs[g, t] > 0.5, T)) * num(maximum(r_proc_g[a][g, t] for t in T))
                println(io, row)
            end
            println(io)
        end

        # --------------------------------------------------------
        # 4. POWER LOSS PER EVENT TYPE
        # --------------------------------------------------------
        for a in (1, 2)
            println(io, "="^100)
            println(io, "POWER LOSS PER EVENT TYPE, $(areas[a].name)   [MW]")
            println(io, "Worst = largest loss over the contingencies k of that type; the column k gives the element that causes it.")
            println(io, "="^100)
            for ev in events[a]
                write_event_table(io, ev.title, ev.K, (t, k, w) -> ev.pl[t, k, w])
            end
            println(io)
        end

        # --------------------------------------------------------
        # 5. HVDC RESERVE DELIVERED TO EACH AREA
        # --------------------------------------------------------
        for a in (1, 2)
            println(io, "="^100)
            println(io, "HVDC RESERVE DELIVERED TO $(uppercase(areas[a].name)) (summed over its converters)   [MW]")
            println(io, "It equals the reserve-provision imbalance of the other area for the same contingency k.")
            println(io, "="^100)
            for rv in rhvdc[a]
                write_event_table(io, rv.title, rv.K,
                                  (t, k, w) -> sum((rv.r[cv, t, k, w] for cv in CVa[a]); init = 0.0))
            end
            println(io)
        end

        # --------------------------------------------------------
        # 6. HVDC POWER FLOW
        # --------------------------------------------------------
        BD_dc_fr      = m.ext[:sets][:BD_dc_fr]
        brdc_rate_a   = m.ext[:parameters][:branchdc][:rate_a]
        conv_p_ac_max = m.ext[:parameters][:convdc][:p_ac_max]
        brdc_fs = val(:brdc_p_fs)       # [(d,e,f), t]
        brdc_ss = val(:brdc_p_ss)       # [(d,e,f), t, w]
        conv_fs = val(:conv_p_ac_fs)    # [cv, t]
        conv_ss = val(:conv_p_ac_ss)    # [cv, t, w]

        println(io, "="^100)
        println(io, "HVDC POWER FLOW   [MW]")
        println(io, "DC branch: flow in the from-to direction. Converter: AC power, + = injection into its area, - = absorption.")
        println(io, "="^100)

        for (d, e, f) in BD_dc_fr
            println(io)
            println(io, "DC branch $d (DC bus $e -> DC bus $f), rating = ±$(round(brdc_rate_a[d] * baseMVA, digits = 2)) MW")
            header = txt("Hour"; width = 6) * txt("Schedule (fs)")
            for w in W
                header *= txt("Actual $w")
            end
            println(io, header)
            println(io, "-"^length(header))
            for t in T
                row = txt(t; width = 6) * num(brdc_fs[(d, e, f), t])
                for w in W
                    row *= num(brdc_ss[(d, e, f), t, w])
                end
                println(io, row)
            end
        end

        for a in (1, 2), cv in sortkeys(CVa[a])
            println(io)
            println(io, "Converter $cv, $(areas[a].name), rating = ±$(round(conv_p_ac_max[cv] * baseMVA, digits = 2)) MW")
            header = txt("Hour"; width = 6) * txt("Schedule (fs)")
            for w in W
                header *= txt("Actual $w")
            end
            println(io, header)
            println(io, "-"^length(header))
            for t in T
                row = txt(t; width = 6) * num(conv_fs[cv, t])
                for w in W
                    row *= num(conv_ss[cv, t, w])
                end
                println(io, row)
            end
        end
        println(io)

        # --------------------------------------------------------
        # 7. RoCoF AND FREQUENCY NADIR OF THE WORST CONTINGENCY
        # --------------------------------------------------------
        fm = compute_frequency_metrics(m)
        num4(x; width = 18) = isfinite(x) ? lpad(string(round(clean(x), digits = 4)), width) : lpad("Inf", width)

        for a in (1, 2)
            println(io, "="^100)
            println(io, "RoCoF AND FREQUENCY NADIR, $(areas[a].name)")
            println(io, "Limits: RoCoF = $(fm.rocof_lim[a]) Hz/s, nadir deviation = $(fm.deltaf_lim[a]) Hz")
            println(io, "Worst = largest value over the contingencies k of that type; k = element that causes it;")
            println(io, "Ploss and H are the power lost [MW] and the inertia left [MW·s] for that same k.")
            println(io, "="^100)

            for ev in fm.results[a]
                println(io)
                println(io, ev.title)
                if isempty(ev.K)
                    println(io, "  (no contingencies of this type)")
                    continue
                end

                header = txt("Hour"; width = 6)
                for w in W
                    header *= txt("RoCoF $w") * txt("k"; width = 6) * txt("Ploss") * txt("H") *
                              txt("Δf $w")    * txt("k"; width = 6)
                end
                println(io, header)
                println(io, "-"^length(header))

                for t in T
                    row = txt(t; width = 6)
                    for w in W
                        r_val, r_k = worst_over_k(ev.rocof,  ev.K, t, w)
                        d_val, d_k = worst_over_k(ev.deltaf, ev.K, t, w)
                        row *= num4(r_val) * txt(r_k; width = 6) *
                               num(ev.ploss[(t, r_k, w)]) * num(ev.inertia[(t, r_k, w)]) *
                               num4(d_val) * txt(d_k; width = 6)
                    end
                    println(io, row)
                end
            end
            println(io)
        end

        # --------------------------------------------------------
        # 8. LARGEST CONTINGENCY AND THE RESERVE THAT FACES IT
        # --------------------------------------------------------
        for a in (1, 2)
            println(io, "="^100)
            println(io, "LARGEST CONTINGENCY PER EVENT TYPE AND RESERVE DEPLOYED TO FACE IT, $(areas[a].name)   [MW]")
            println(io, "k = element with the largest power loss of that type; reserves are those deployed for that same k.")
            println(io, "="^100)

            for ev in fm.results[a]
                println(io)
                println(io, ev.title)
                if isempty(ev.K)
                    println(io, "  (no contingencies of this type)")
                    continue
                end
                for w in W
                    println(io)
                    println(io, "  Wind scenario: $w")
                    header = txt("Hour"; width = 6) * txt("k"; width = 6) * txt("Power lost") * txt("Generators") *
                             txt("Batteries") * txt("Electrolyzers") * txt("HVDC") * txt("Total reserve")
                    println(io, header)
                    println(io, "-"^length(header))
                    for t in T
                        c = largest_contingency(ev, t, w)
                        println(io, txt(t; width = 6) * txt(c.k; width = 6) * num(c.ploss) * num(c.r_gen) *
                                    num(c.r_batt) * num(c.r_elec) * num(c.r_hvdc) * num(c.r_total))
                    end
                end
            end
            println(io)
        end


        # ========================================================
        # SECTIONS 9-16: SYSTEM RESULTS
        # ========================================================
        sr = compute_system_results(m)
        DA = sr.DA
        stage_name(st) = st == DA ? "Day-ahead" : "Actual $st"

        # Table with one column per stage (day-ahead + each wind scenario). d is a Dict((t, stage) => value).
        function write_stage_table(io, title, d)
            println(io)
            println(io, title)
            header = txt("Hour"; width = 6) * join(txt(stage_name(st)) for st in sr.stages)
            println(io, header)
            println(io, "-"^length(header))
            for t in T
                println(io, txt(t; width = 6) * join(num(d[(t, st)]) for st in sr.stages))
            end
        end
        section(title) = (println(io, "="^100); println(io, title); println(io, "="^100))

        # ---------------- 9. LOAD SHEDDING ----------------
        section("LOAD SHEDDING   [MW]")
        for a in (1, 2)
            write_stage_table(io, areas[a].name, sr.areas[a][:load_shed])
        end
        println(io)

        # ---------------- 10. RENEWABLE CURTAILMENT ----------------
        section("RENEWABLE CURTAILMENT   [MW]   (curtailment = available - produced; day-ahead uses the forecast)")
        for a in (1, 2), (tech, av, pr, cu) in [("Wind", :wind_avail, :wind_prod, :wind_curt),
                                                 ("Solar (utility scale)", :solar_avail, :solar_prod, :solar_curt)]
            D = sr.areas[a]
            println(io)
            println(io, "$tech, $(areas[a].name)")
            header = txt("Hour"; width = 6)
            for st in sr.stages
                header *= txt("Avail. $(st == DA ? "DA" : st)") * txt("Prod. $(st == DA ? "DA" : st)") * txt("Curt. $(st == DA ? "DA" : st)")
            end
            println(io, header)
            println(io, "-"^length(header))
            for t in T
                row = txt(t; width = 6)
                for st in sr.stages
                    row *= num(D[av][(t, st)]) * num(D[pr][(t, st)]) * num(D[cu][(t, st)])
                end
                println(io, row)
            end
        end
        println(io)

        # ---------------- 11. GENERATION BY TECHNOLOGY ----------------
        section("GENERATION BY TECHNOLOGY   [MW]")
        for a in (1, 2)
            gt   = sr.areas[a][:gen_tech]
            used = [tech for tech in sr.techs if any(gt[tech][(t, st)] > 1e-6 for t in T, st in sr.stages)]
            for st in sr.stages
                println(io)
                println(io, "$(areas[a].name), $(stage_name(st))")
                header = txt("Hour"; width = 6) * join(txt(tech) for tech in used) * txt("Total")
                println(io, header)
                println(io, "-"^length(header))
                for t in T
                    vals = [gt[tech][(t, st)] for tech in used]
                    println(io, txt(t; width = 6) * join(num(v) for v in vals) * num(sum(vals; init = 0.0)))
                end
            end
        end
        println(io)

        # ---------------- 12. TOTAL PROCURED INERTIA ----------------
        section("TOTAL PROCURED INERTIA   [MW·s]   (committed synchronous units, first stage)")
        header = txt("Hour"; width = 6) * txt(areas[1].name; width = 20) * txt(areas[2].name; width = 20)
        println(io, header)
        println(io, "-"^length(header))
        for t in T
            println(io, txt(t; width = 6) * num(sr.areas[1][:inertia][t]; width = 20) * num(sr.areas[2][:inertia][t]; width = 20))
        end
        println(io)

        # ---------------- 13. HVDC FLOW AND HVDC RESERVE ----------------
        section("HVDC FLOW AND HVDC RESERVE PER CONVERTER   [MW]   (flow: + = injection into the area; reserve: worst contingency)")
        for cv in vcat(sortkeys(CVa[1]), sortkeys(CVa[2]))
            c = sr.converters[cv]
            println(io)
            println(io, "Converter $cv, $(areas[c.area].name)")
            header = txt("Hour"; width = 6) * txt("Flow DA")
            for w in W
                header *= txt("Flow $w") * txt("Reserve $w") * txt("Fl+res $w")
            end
            println(io, header)
            println(io, "-"^length(header))
            for t in T
                row = txt(t; width = 6) * num(c.flow[(t, DA)])
                for w in W
                    row *= num(c.flow[(t, w)]) * num(c.reserve[(t, w)]) * num(c.flow[(t, w)] + c.reserve[(t, w)])
                end
                println(io, row)
            end
        end
        println(io)

        # ---------------- 14. SYSTEM DEMAND ----------------
        section("SYSTEM DEMAND   [MW]   (net demand = demand - rooftop solar + electrolyzers incl. compressors + battery charging)")
        for a in (1, 2)
            D = sr.areas[a]
            for st in sr.stages
                println(io)
                println(io, "$(areas[a].name), $(stage_name(st))")
                header = txt("Hour"; width = 6) * txt("Demand") * txt("Rooftop solar") * txt("Demand-rooftop") *
                         txt("Electrolyzers") * txt("Batt. charging") * txt("Net demand") * txt("Batt. disch.") * txt("Pump charging")
                println(io, header)
                println(io, "-"^length(header))
                for t in T
                    println(io, txt(t; width = 6) * num(D[:demand_base][t]) * num(D[:rooftop][t]) *
                                num(D[:demand_base][t] - D[:rooftop][t]) * num(D[:elec_cons][(t, st)]) *
                                num(D[:batt_charge][(t, st)]) * num(D[:net_demand][(t, st)]) *
                                num(D[:batt_discharge][(t, st)]) * num(D[:pump_charge][(t, st)]))
                end
            end
        end
        println(io)

        # ---------------- 15. BATTERIES ----------------
        section("BATTERIES   (power in MW, energy in MWh)")
        for b in vcat(sortkeys(areas[1].S), sortkeys(areas[2].S))
            bb = sr.batteries[b]
            write_stage_table(io, "Battery $b, $(areas[bb.area].name): charging power [MW]", bb.charge)
            write_stage_table(io, "Battery $b, $(areas[bb.area].name): discharging power [MW]", bb.discharge)
            write_stage_table(io, "Battery $b, $(areas[bb.area].name): stored energy [MWh]", bb.energy)
        end
        println(io)

        # ---------------- 16. ELECTROLYZERS: HYDROGEN ----------------
        section("ELECTROLYZERS   (hydrogen flows in kg/h, stored hydrogen in kg, power in MW)")
        for e in vcat(sortkeys(areas[1].E), sortkeys(areas[2].E))
            ee = sr.electrolyzers[e]
            nm = "Electrolyzer $e, $(areas[ee.area].name)"
            write_stage_table(io, "$nm: electrolyzer power [MW]", ee.power)
            write_stage_table(io, "$nm: hydrogen produced [kg/h]", ee.production)
            write_stage_table(io, "$nm: hydrogen purchased [kg/h]", ee.purchase)
            write_stage_table(io, "$nm: hydrogen sold [kg/h]", ee.sale)
            write_stage_table(io, "$nm: hydrogen stored [kg]", ee.storage)
        end
        println(io)

        # ---------------- 17. RESERVE GAPS IN THE WIND-FARM CONTINGENCY ----------------
        rgd = compute_reserve_gaps(m)
        section("RESERVE GAPS WHEN THE WIND FARM TRIPS   [MW]")
        println(io, "Deployed = reserve delivered when the wind farm trips; Unused = procured but not used in that contingency")
        println(io, "(margin A); Extra = reserve that could still be procured at that operating point (margin B).")
        println(io, "HVDC has no procured reserve: its Extra is the converter headroom (its delivery may be limited by other constraints).")
        short = Dict("Generators" => "Gen", "Batteries" => "Batt", "Electrolyzers" => "Elec", "HVDC" => "HVDC")
        for a in (1, 2), wk in rgd.gaps[a], w in W
            println(io)
            println(io, "$(areas[a].name), wind farm $(wk.k) trips, $w")
            header = txt("Hour"; width = 6) * txt("Wind avail."; width = 13) * txt("Wind prod."; width = 13) *
                     txt("Curtailed"; width = 13) * txt("Deployed"; width = 13) * txt("Unused"; width = 13) * txt("Extra"; width = 13)
            for tech in rgd.techs
                header *= txt("$(short[tech]) dep"; width = 11) * txt("$(short[tech]) unu"; width = 11) * txt("$(short[tech]) ext"; width = 11)
            end
            println(io, header)
            println(io, "-"^length(header))
            for t in T
                d = wk.data[(t, w)]
                dep = sum(d.tech[tech].deployed for tech in rgd.techs)
                unu = sum(d.tech[tech].unused   for tech in rgd.techs)
                ext = sum(d.tech[tech].extra    for tech in rgd.techs)
                row = txt(t; width = 6) * num(d.wind_avail; width = 13) * num(d.wind_prod; width = 13) *
                      num(max(0.0, d.wind_avail - d.wind_prod); width = 13) * num(dep; width = 13) * num(unu; width = 13) * num(ext; width = 13)
                for tech in rgd.techs
                    row *= num(d.tech[tech].deployed; width = 11) * num(d.tech[tech].unused; width = 11) * num(d.tech[tech].extra; width = 11)
                end
                println(io, row)
            end
        end
        println(io)

        # ---------------- 18. DEPLOYED VS PROCURED RESERVE, ONE AREA, EACH WIND SCENARIO ----------------
        for fsc in (focus_scenario === :all ? W : [focus_scenario])
            (fsc in W && focus_area in (1, 2)) || continue
            dvp = deployed_vs_procured(m, fm, focus_area, fsc)
            section("RESERVE DEPLOYED FOR EACH IMBALANCE AND RESERVE PROCURED, $(uppercase(areas[focus_area].name)), $fsc   [MW]")
            println(io, "For each imbalance, the largest contingency of each hour (k = tripped element). Procured = first-stage reserve")
            println(io, "of the area. HVDC reserve is not procured: 'HVDC max' is the maximum HVDC reserve the link could deliver into")
            println(io, "the area (converter headroom above the actual flow); the HVDC reserve actually delivered can be smaller.")
            fields = (:r_gen, :r_batt, :r_elec, :r_hvdc)
            for (i, ttl) in enumerate(dvp.titles)
                println(io)
                println(io, ttl)
                header = txt("Hour"; width = 6) * txt("Trigger"; width = 44) * txt("Power lost"; width = 12) *
                         join(txt(l; width = 14) for l in ("Gen", "Batteries", "Electrolyzers", "HVDC", "Deployed tot."))
                println(io, header)
                println(io, "-"^length(header))
                for t in T
                    ev = dvp.rows[t].events[i]
                    vals = [getproperty(ev.c, f) for f in fields]
                    println(io, txt(t; width = 6) * txt(ev.trigger; width = 44) * num(ev.c.ploss; width = 12) *
                                join(num(v; width = 14) for v in vals) * num(sum(vals); width = 14))
                end
            end
            println(io)
            println(io, "Procured reserve (first stage) and maximum HVDC reserve")
            header = txt("Hour"; width = 6) * join(txt(l; width = 14) for l in ("Gen", "Batteries", "Electrolyzers", "Procured tot.", "HVDC max", "Proc.+HVDC max"))
            println(io, header)
            println(io, "-"^length(header))
            for t in T
                pr = dvp.rows[t].procured
                proc = pr.r_gen + pr.r_batt + pr.r_elec
                println(io, txt(t; width = 6) * join(num(v; width = 14) for v in (pr.r_gen, pr.r_batt, pr.r_elec, proc, pr.r_hvdc, proc + pr.r_hvdc)))
            end
            println(io)
        end

        # ---------------- 19. COST BREAKDOWN FOR EACH WIND REALIZATION ----------------
        cb = compute_cost_breakdown(m)
        section("COST OF THE OBJECTIVE FOR EACH WIND REALIZATION   [same units as the objective]")
        println(io, "Total cost of realization w = first-stage cost C_I (same for every w) + second-stage cost C_II,w.")
        println(io, "Objective of the model = C_I + sigma = C_I + max_w C_II,w (worst realization).")
        cw = 54
        header = rpad("Component", cw) * join(txt(w; width = 18) for w in cb.W)
        println(io)
        println(io, header)
        println(io, "-"^length(header))
        println(io, rpad("FIRST STAGE", cw))
        for k in cb.first_order
            println(io, rpad("  " * k, cw) * join(num(cb.first[k]) for w in cb.W))
        end
        println(io, rpad("First-stage cost C_I", cw) * join(num(cb.C_I) for w in cb.W))
        println(io, rpad("SECOND STAGE", cw))
        for k in cb.second_order
            println(io, rpad("  " * k, cw) * join(num(cb.second[w][k]) for w in cb.W))
        end
        println(io, rpad("Second-stage cost C_II,w", cw) * join(num(cb.C_II[w]) for w in cb.W))
        println(io, "-"^length(header))
        println(io, rpad("TOTAL COST C_I + C_II,w", cw) * join(num(cb.total[w]) for w in cb.W))
        println(io)
        println(io, "Grouped by type (first + second stage)")
        println(io, header)
        println(io, "-"^length(header))
        for (lbl, f) in (("Generation (energy, no-load, start-ups, redispatch)", :generation),
                         ("Hydrogen (start-ups, trade, deviations)", :hydrogen),
                         ("Procured reserve", :reserve), ("Load shedding", :load_shed))
            println(io, rpad(lbl, cw) * join(num(getproperty(cb.groups[w], f)) for w in cb.W))
        end
        println(io, rpad("TOTAL", cw) * join(num(cb.total[w]) for w in cb.W))
        println(io)
        println(io, "Objective value = $(round(cb.objective, digits = 2)); C_I + max_w C_II,w = $(round(cb.C_I + cb.worst, digits = 2)); ",
                    "sigma = $(round(cb.sigma, digits = 2)).")
        abs(cb.residual) > 1e-3 * max(1.0, abs(cb.objective)) &&
            println(io, "Difference of $(round(cb.residual, digits = 2)): the objective contains terms not listed here (e.g. ε or ρ penalties).")
        println(io)
    end

    println("Generation and reserve results written to: ", abspath(output_file))
    cb = compute_cost_breakdown(m)
    println("\n===== COST OF THE OBJECTIVE FOR EACH WIND REALIZATION =====")
    for w in cb.W
        g = cb.groups[w]
        println(rpad(string(w), 12), " total = ", round(cb.total[w], digits = 2),
                "   (first stage = ", round(cb.C_I, digits = 2), ", second stage = ", round(cb.C_II[w], digits = 2), ")",
                "   generation = ", round(g.generation, digits = 2), ", hydrogen = ", round(g.hydrogen, digits = 2),
                ", reserve = ", round(g.reserve, digits = 2), ", load shedding = ", round(g.load_shed, digits = 2))
    end
    println("Objective value = ", round(cb.objective, digits = 2), "   (C_I + worst C_II = ", round(cb.C_I + cb.worst, digits = 2), ")")
    return nothing
end
