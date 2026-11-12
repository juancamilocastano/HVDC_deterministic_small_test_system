# Frequency metrics of the robust model, used by plotfunction_robust! and printparameters_robust!.
# Include this file before the two functions:  include("frequency_metrics_robust.jl")

function compute_frequency_metrics(m::Model)
    # For every area, event type, hour t, contingency k and wind scenario w, computes:
    #   RoCoF  = f * P_loss / (2 H)                                                  [Hz/s]
    #   Nadir  Δf = f / (4 H) * ( (P_loss - R_fast)^2 / sum(R_g / T_g) + sum(R_fast * T_fast) )   [Hz]
    # which is the nadir constraint of the model (rotated cone) solved for Δf at equality.
    # H is the inertia left after the event: the tripped generator's inertia is removed for a generator
    # loss; converter losses and HVDC reserve-provision imbalances keep the full inertia of the area.

    sets = m.ext[:sets]
    par  = m.ext[:parameters]
    baseMVA = par[:baseMVA]
    T = sets[:t]
    W = sets[:Wind_scenarios]

    G  = Dict(1 => sets[:G1],  2 => sets[:G2])
    S  = Dict(1 => sets[:S1],  2 => sets[:S2])
    E  = Dict(1 => sets[:E1],  2 => sets[:E2])
    CV = Dict(1 => sets[:CV1], 2 => sets[:CV2])
    fallos_g = Dict(1 => sets[:fallos_g1], 2 => sets[:fallos_g2])
    fallos_c = Dict(1 => sets[:fallos_c1], 2 => sets[:fallos_c2])
    other    = Dict(1 => 2, 2 => 1)

    f          = Dict(1 => par[:f1],      2 => par[:f2])
    rocof_lim  = Dict(1 => par[:rocof1],  2 => par[:rocof2])
    deltaf_lim = Dict(1 => par[:deltaf1], 2 => par[:deltaf2])

    ic              = par[:ic]
    pmax            = par[:pmax]
    G_dt            = par[:G_dt]
    Edeployment     = par[:Edeployment]
    Sdeployment     = par[:Sdeployment]
    HVDC_deployment = par[:convdc][:HVDC_deployment]

    zg  = JuMP.value.(m.ext[:variables][:zg_fs])
    val(name) = JuMP.value.(m.ext[:variables][name]) .* baseMVA      # MW

    # Inertia after the event [MW·s]
    H_full(a, t)    = sum(zg[g, t] * ic[g] * pmax[g] for g in G[a]) * baseMVA
    H_gen(a, t, k)  = H_full(a, t) - zg[k, t] * ic[k] * pmax[k] * baseMVA

    # Variables of each event type
    spec(a) = [
        (title = "Generator loss (own area)", K = fallos_g[a], lose_inertia = true,
         pl = Symbol("plg$(a)_ss"), rg = Symbol("rg_lg$(a)_ss"), re = Symbol("re_lg$(a)_ss"),
         rs = Symbol("rs_lg$(a)_ss"), rh = Symbol("rhvdc_lg$(a)_ss")),
        (title = "Converter loss (own area)", K = fallos_c[a], lose_inertia = false,
         pl = Symbol("plc$(a)_ss"), rg = Symbol("rg_lc$(a)_ss"), re = Symbol("re_lc$(a)_ss"),
         rs = Symbol("rs_lc$(a)_ss"), rh = Symbol("rhvdc_lc$(a)_ss")),
        (title = "HVDC reserve-provision imbalance (generator trips in the other area)", K = fallos_g[other[a]], lose_inertia = false,
         pl = Symbol("plreserve_$(a)_g_ss"), rg = Symbol("rg_l_reserve_$(a)_g_ss"), re = Symbol("re_l_reserve_$(a)_g_ss"),
         rs = Symbol("rs_l_reserve_$(a)_g_ss"), rh = nothing),
        (title = "HVDC reserve-provision imbalance (converter trips in the other area)", K = fallos_c[other[a]], lose_inertia = false,
         pl = Symbol("plreserve_$(a)_c_ss"), rg = Symbol("rg_l_reserve_$(a)_c_ss"), re = Symbol("re_l_reserve_$(a)_c_ss"),
         rs = Symbol("rs_l_reserve_$(a)_c_ss"), rh = nothing)
    ]

    results = Dict{Int,Vector{Any}}()
    for a in (1, 2)
        results[a] = Any[]
        for sp in spec(a)
            pl = val(sp.pl); rg = val(sp.rg); re = val(sp.re); rs = val(sp.rs)
            rh = sp.rh === nothing ? nothing : val(sp.rh)

            rocof   = Dict{Any,Float64}()
            deltaf  = Dict{Any,Float64}()
            ploss   = Dict{Any,Float64}()
            inertia = Dict{Any,Float64}()
            # reserve deployed to face contingency k, by resource [MW]
            r_gen   = Dict{Any,Float64}()
            r_batt  = Dict{Any,Float64}()
            r_elec  = Dict{Any,Float64}()
            r_hvdc  = Dict{Any,Float64}()

            for t in T, k in sp.K, w in W
                H = sp.lose_inertia ? H_gen(a, t, k) : H_full(a, t)
                P = pl[t, k, w]

                # fast reserves (electrolyzers, batteries, HVDC) and their deployment-time weighted sum
                R_fast  = sum((re[e, t, k, w] for e in E[a]); init = 0.0) + sum((rs[s, t, k, w] for s in S[a]); init = 0.0)
                RT_fast = sum((re[e, t, k, w] * Edeployment[e] for e in E[a]); init = 0.0) +
                          sum((rs[s, t, k, w] * Sdeployment[s] for s in S[a]); init = 0.0)
                if rh !== nothing
                    R_fast  += sum((rh[cv, t, k, w] for cv in CV[a]); init = 0.0)
                    RT_fast += sum((rh[cv, t, k, w] * HVDC_deployment[cv] for cv in CV[a]); init = 0.0)
                end
                # generator reserves divided by their delivery time
                z = sum((rg[g, t, k, w] / G_dt[g] for g in G[a]); init = 0.0)

                x = max(P - R_fast, 0.0)
                slow_term = x <= 1e-9 ? 0.0 : (z <= 1e-12 ? Inf : x^2 / z)

                ploss[(t, k, w)]   = P
                inertia[(t, k, w)] = H
                r_gen[(t, k, w)]   = sum((rg[g, t, k, w] for g in G[a]); init = 0.0)
                r_batt[(t, k, w)]  = sum((rs[s, t, k, w] for s in S[a]); init = 0.0)
                r_elec[(t, k, w)]  = sum((re[e, t, k, w] for e in E[a]); init = 0.0)
                r_hvdc[(t, k, w)]  = rh === nothing ? 0.0 : sum((rh[cv, t, k, w] for cv in CV[a]); init = 0.0)
                if H <= 1e-9
                    rocof[(t, k, w)]  = P <= 1e-9 ? 0.0 : Inf
                    deltaf[(t, k, w)] = P <= 1e-9 ? 0.0 : Inf
                else
                    rocof[(t, k, w)]  = f[a] * P / (2 * H)
                    deltaf[(t, k, w)] = f[a] / (4 * H) * (slow_term + RT_fast)
                end
            end
            push!(results[a], (title = sp.title, K = sp.K, rocof = rocof, deltaf = deltaf, ploss = ploss, inertia = inertia,
                               r_gen = r_gen, r_batt = r_batt, r_elec = r_elec, r_hvdc = r_hvdc))
        end
    end
    return (results = results, rocof_lim = rocof_lim, deltaf_lim = deltaf_lim)
end

# Largest value over the contingencies K of one event type, and the contingency k that causes it
function worst_over_k(d, K, t, w)
    isempty(K) && return (0.0, "-")
    best_k = first(K)
    best   = d[(t, best_k, w)]
    for k in K
        if d[(t, k, w)] > best
            best, best_k = d[(t, k, w)], k
        end
    end
    return (best, best_k)
end

# Largest contingency of one event type (largest power loss over k) and the reserve deployed to face it.
# Returns (k, P_loss, R_generators, R_batteries, R_electrolyzers, R_hvdc, R_total), all in MW.
function largest_contingency(ev, t, w)
    isempty(ev.K) && return (k = "-", ploss = 0.0, r_gen = 0.0, r_batt = 0.0, r_elec = 0.0, r_hvdc = 0.0, r_total = 0.0)
    P, k = worst_over_k(ev.ploss, ev.K, t, w)
    rg, rs, re, rh = ev.r_gen[(t, k, w)], ev.r_batt[(t, k, w)], ev.r_elec[(t, k, w)], ev.r_hvdc[(t, k, w)]
    return (k = k, ploss = P, r_gen = rg, r_batt = rs, r_elec = re, r_hvdc = rh, r_total = rg + rs + re + rh)
end

# =====================================================================
# SYSTEM RESULTS (used by sections 9-16 of plotfunction_robust! and printparameters_robust!)
# =====================================================================
# Stage labels: "Day-ahead" = first stage; the wind scenario names (e.g. "High_wind", "Low_wind") = second stage.
# Power in MW, energy in MWh, hydrogen in kg (flows per hour), inertia in MW·s.

function compute_system_results(m::Model)
    sets = m.ext[:sets]
    par  = m.ext[:parameters]
    vars = m.ext[:variables]
    baseMVA = par[:baseMVA]
    baseKG  = par[:baseKG]
    T = sets[:t]
    W = sets[:Wind_scenarios]
    DA = "Day-ahead"
    stages = vcat([DA], W)

    area_name = Dict(1 => "Nordic", 2 => "GB")
    G       = Dict(1 => sets[:G1],       2 => sets[:G2])
    S       = Dict(1 => sets[:S1],       2 => sets[:S2])
    E       = Dict(1 => sets[:E1],       2 => sets[:E2])
    CV      = Dict(1 => sets[:CV1],      2 => sets[:CV2])
    G_wind  = Dict(1 => sets[:G_wind_1], 2 => sets[:G_wind_2])
    G_solar = Dict(1 => sets[:G_solar_1], 2 => sets[:G_solar_2])
    G_pump  = Dict(1 => sets[:G_pump_1], 2 => sets[:G_pump_2])
    fallos_g = Dict(1 => sets[:fallos_g1], 2 => sets[:fallos_g2])
    fallos_c = Dict(1 => sets[:fallos_c1], 2 => sets[:fallos_c2])

    pmax            = par[:pmax]
    ic              = par[:ic]
    demand          = par[:demand]
    cf_solar        = par[:capacity_factor_solar]
    cf_wind         = par[:capacity_factor_wind]
    cf_wind_w       = par[:capacity_factor_wind_w]
    solar_roof_pmax = par[:solar_roof_pmax]

    MW(name) = JuMP.value.(vars[name]) .* baseMVA
    KG(name) = JuMP.value.(vars[name]) .* baseKG

    # Value of a variable at stage s: first stage is indexed [..., t], second stage [..., t, w]
    at(fs, ss, idx, t, s) = s == DA ? fs[idx..., t] : ss[idx..., t, s]
    total(itr) = sum(itr; init = 0.0)

    pg_fs,  pg_ss  = MW(:pg_fs),  MW(:pg_ss)
    zg_fs          = JuMP.value.(vars[:zg_fs])
    pe_fs,  pe_ss  = MW(:pe_fs),  MW(:pe_ss)
    pec_fs, pec_ss = MW(:pe_compressor_fs), MW(:pe_compressor_ss)
    psc_fs, psc_ss = MW(:psc_fs), MW(:psc_ss)
    psd_fs, psd_ss = MW(:psd_fs), MW(:psd_ss)
    es_fs,  es_ss  = MW(:es_fs),  MW(:es_ss)
    pcp_fs, pcp_ss = MW(:p_charge_pump_fs), MW(:p_charge_pump_ss)
    cv_fs,  cv_ss  = MW(:conv_p_ac_fs), MW(:conv_p_ac_ss)
    hfe_fs, hfe_ss = KG(:hfe_fs), KG(:hfe_ss)
    hbu_fs, hbu_ss = KG(:hfgconsum_fs), KG(:hfgconsum_ss)
    hse_fs, hse_ss = KG(:hfginyect_fs), KG(:hfginyect_ss)
    hss_fs, hss_ss = KG(:hss_fs), KG(:hss_ss)
    ls_fs = Dict(1 => MW(:load_shed_1_fs), 2 => MW(:load_shed_2_fs))
    ls_ss = Dict(1 => MW(:load_shed_1_ss), 2 => MW(:load_shed_2_ss))
    rh_lg = Dict(a => MW(Symbol("rhvdc_lg$(a)_ss")) for a in (1, 2))
    rh_lc = Dict(a => MW(Symbol("rhvdc_lc$(a)_ss")) for a in (1, 2))

    techs = ["nuclear", "gas", "biomass", "oil", "hydro reservoir", "pumped storage", "solar", "wind"]
    tech_sets = Dict("nuclear" => sets[:G_nuclear], "gas" => sets[:G_gas], "biomass" => sets[:G_biomass],
                     "oil" => sets[:G_oil], "hydro reservoir" => sets[:G_reservoir], "pumped storage" => sets[:G_pump],
                     "solar" => sets[:G_solar], "wind" => sets[:G_wind])

    keys_ts = [(t, s) for t in T, s in stages]

    # ---------------- per area ----------------
    areas = Dict{Int,Any}()
    for a in (1, 2)
        an = area_name[a]
        D  = Dict{Symbol,Any}()

        D[:load_shed] = Dict(k => at(ls_fs[a], ls_ss[a], (), k...) for k in keys_ts)

        wind_cf(t, s) = s == DA ? cf_wind[an][t] : cf_wind_w[an][t][s]
        D[:wind_avail]  = Dict((t, s) => total(wind_cf(t, s) * pmax[g] * baseMVA for g in G_wind[a]) for (t, s) in keys_ts)
        D[:wind_prod]   = Dict((t, s) => total(at(pg_fs, pg_ss, (g,), t, s) for g in G_wind[a]) for (t, s) in keys_ts)
        D[:wind_curt]   = Dict(k => max(0.0, D[:wind_avail][k] - D[:wind_prod][k]) for k in keys_ts)
        D[:solar_avail] = Dict((t, s) => total(cf_solar[an][t] * pmax[g] * baseMVA for g in G_solar[a]) for (t, s) in keys_ts)
        D[:solar_prod]  = Dict((t, s) => total(at(pg_fs, pg_ss, (g,), t, s) for g in G_solar[a]) for (t, s) in keys_ts)
        D[:solar_curt]  = Dict(k => max(0.0, D[:solar_avail][k] - D[:solar_prod][k]) for k in keys_ts)

        D[:gen_tech] = Dict(tech => Dict((t, s) => total(at(pg_fs, pg_ss, (g,), t, s) for g in G[a] if g in tech_sets[tech])
                                         for (t, s) in keys_ts) for tech in techs)

        D[:inertia] = Dict(t => total(zg_fs[g, t] * ic[g] * pmax[g] for g in G[a]) * baseMVA for t in T)

        D[:demand_base] = Dict(t => demand[string(a)][t] * baseMVA for t in T)
        D[:rooftop]     = Dict(t => solar_roof_pmax[string(a)] * cf_solar[an][t] * baseMVA for t in T)
        D[:elec_cons]   = Dict((t, s) => total(at(pe_fs, pe_ss, (e,), t, s) + at(pec_fs, pec_ss, (e,), t, s) for e in E[a])
                               for (t, s) in keys_ts)
        D[:batt_charge]    = Dict((t, s) => total(at(psc_fs, psc_ss, (b,), t, s) for b in S[a]) for (t, s) in keys_ts)
        D[:batt_discharge] = Dict((t, s) => total(at(psd_fs, psd_ss, (b,), t, s) for b in S[a]) for (t, s) in keys_ts)
        D[:pump_charge]    = Dict((t, s) => total(at(pcp_fs, pcp_ss, (g,), t, s) for g in G_pump[a]) for (t, s) in keys_ts)
        # Net demand = demand - rooftop solar + electrolyzer consumption (incl. compressors) + battery charging
        D[:net_demand] = Dict((t, s) => D[:demand_base][t] - D[:rooftop][t] + D[:elec_cons][(t, s)] + D[:batt_charge][(t, s)]
                              for (t, s) in keys_ts)
        areas[a] = D
    end

    # ---------------- per converter: flow and HVDC reserve delivered through it ----------------
    converters = Dict{Any,Any}()
    for a in (1, 2), cv in CV[a]
        worst_reserve(t, w) = max(isempty(fallos_g[a]) ? 0.0 : maximum(rh_lg[a][cv, t, k, w] for k in fallos_g[a]),
                                  isempty(fallos_c[a]) ? 0.0 : maximum(rh_lc[a][cv, t, k, w] for k in fallos_c[a]))
        converters[cv] = (area = a,
                          flow = Dict(k => at(cv_fs, cv_ss, (cv,), k...) for k in keys_ts),
                          reserve = Dict((t, w) => worst_reserve(t, w) for t in T, w in W))
    end

    # ---------------- per battery ----------------
    batteries = Dict{Any,Any}()
    for a in (1, 2), b in S[a]
        batteries[b] = (area = a,
                        charge    = Dict(k => at(psc_fs, psc_ss, (b,), k...) for k in keys_ts),
                        discharge = Dict(k => at(psd_fs, psd_ss, (b,), k...) for k in keys_ts),
                        energy    = Dict(k => at(es_fs,  es_ss,  (b,), k...) for k in keys_ts))
    end

    # ---------------- per electrolyzer ----------------
    electrolyzers = Dict{Any,Any}()
    for a in (1, 2), e in E[a]
        electrolyzers[e] = (area = a,
                            power      = Dict(k => at(pe_fs,  pe_ss,  (e,), k...) for k in keys_ts),
                            production = Dict(k => at(hfe_fs, hfe_ss, (e,), k...) for k in keys_ts),
                            purchase   = Dict(k => at(hbu_fs, hbu_ss, (e,), k...) for k in keys_ts),
                            sale       = Dict(k => at(hse_fs, hse_ss, (e,), k...) for k in keys_ts),
                            storage    = Dict(k => at(hss_fs, hss_ss, (e,), k...) for k in keys_ts))
    end

    return (stages = stages, DA = DA, techs = techs, areas = areas,
            converters = converters, batteries = batteries, electrolyzers = electrolyzers)
end

# =====================================================================
# RESERVE GAPS IN THE WIND-FARM CONTINGENCY (used by section 17 of the plot and print functions)
# =====================================================================
# For each area and each wind farm k that is a contingency (k in fallos_g ∩ G_wind), hour t and wind scenario w:
#   deployed : reserve each technology delivers when wind farm k trips                    (rg/rs/re/rhvdc_lg_ss)
#   unused   : procured reserve that is NOT used in that contingency          (margin A = procured - deployed)
#   extra    : reserve that could still be procured on top of the procured one (margin B = maximum - procured)
# Maximum reserve per technology at the operating point of scenario w:
#   gas/other generators: min(MaxFreqDev·zg, ramp during delivery upramp·G_dt/3600, pmax·zg - pg)
#   batteries: Spmax + psc - psd;   electrolyzers: pe - Epmin·ze - 0.05·Epmax·zestb
#   HVDC: converter headroom above the actual flow (no procured reserve: everything is "extra"). Note that the HVDC
#         reserve actually delivered can be limited by other constraints (e.g. the imbalance it creates in the other area).
# All values in MW.

function compute_reserve_gaps(m::Model)
    sets = m.ext[:sets]; par = m.ext[:parameters]; vars = m.ext[:variables]
    baseMVA = par[:baseMVA]
    T = sets[:t]; W = sets[:Wind_scenarios]
    area_name = Dict(1 => "Nordic", 2 => "GB")
    G  = Dict(1 => sets[:G1],  2 => sets[:G2]);  S  = Dict(1 => sets[:S1],  2 => sets[:S2])
    E  = Dict(1 => sets[:E1],  2 => sets[:E2]);  CV = Dict(1 => sets[:CV1], 2 => sets[:CV2])
    fallos_g = Dict(1 => sets[:fallos_g1], 2 => sets[:fallos_g2])
    G_wind   = sets[:G_wind]

    pmax = par[:pmax]; upramp = par[:upramp]; G_dt = par[:G_dt]; MaxFreqDev = par[:MaxFreqDev]
    Spmax = par[:Spmax]; Epmax = par[:Epmax]; Epmin = par[:Epmin]
    conv_p_ac_max = par[:convdc][:p_ac_max]; conv_p_dc_max = par[:convdc][:p_dc_max]
    cf_wind_w = par[:capacity_factor_wind_w]

    val(name) = JuMP.value.(vars[name])          # per unit
    total(itr) = sum(itr; init = 0.0)

    pg = val(:pg_ss); zg = val(:zg_fs); psc = val(:psc_ss); psd = val(:psd_ss)
    pe = val(:pe_ss); ze = val(:ze_fs); zestb = val(:zestb_fs); conv = val(:conv_p_ac_ss)

    techs = ["Generators", "Batteries", "Electrolyzers", "HVDC"]
    gaps = Dict{Int,Any}()
    for a in (1, 2)
        rpg = val(Symbol("r_proc_g_$a")); rps = val(Symbol("r_proc_s_$a")); rpe = val(Symbol("r_proc_e_$a"))
        rg  = val(Symbol("rg_lg$(a)_ss")); rs = val(Symbol("rs_lg$(a)_ss")); re = val(Symbol("re_lg$(a)_ss"))
        rh  = val(Symbol("rhvdc_lg$(a)_ss"))
        wind_k = [k for k in fallos_g[a] if k in G_wind]
        list = Any[]
        for k in wind_k
            data = Dict{Any,Any}()
            for t in T, w in W
                others = [g for g in G[a] if g != k]
                deployed = Dict("Generators"    => total(rg[g, t, k, w] for g in G[a]),
                                "Batteries"     => total(rs[s, t, k, w] for s in S[a]),
                                "Electrolyzers" => total(re[e, t, k, w] for e in E[a]),
                                "HVDC"          => total(rh[cv, t, k, w] for cv in CV[a]))
                procured = Dict("Generators"    => total(rpg[g, t] for g in others),
                                "Batteries"     => total(rps[s, t] for s in S[a]),
                                "Electrolyzers" => total(rpe[e, t] for e in E[a]),
                                "HVDC"          => 0.0)
                maximum_ = Dict("Generators"    => total(max(0.0, min(MaxFreqDev[g] * zg[g, t], upramp[g] * G_dt[g] / 3600,
                                                                     pmax[g] * zg[g, t] - pg[g, t, w])) for g in others),
                                "Batteries"     => total(max(0.0, Spmax[s] + psc[s, t, w] - psd[s, t, w]) for s in S[a]),
                                "Electrolyzers" => total(max(0.0, pe[e, t, w] - Epmin[e] * ze[e, t] - 0.05 * Epmax[e] * zestb[e, t]) for e in E[a]),
                                "HVDC"          => total(max(0.0, min(conv_p_ac_max[cv] - conv[cv, t, w], 2 * conv_p_dc_max[cv])) for cv in CV[a]))
                # procured can never exceed the maximum (tolerances); deployed never exceeds procured, except HVDC
                tech_vals = Dict(tech => (deployed = deployed[tech] * baseMVA,
                                          unused   = max(0.0, procured[tech] - deployed[tech]) * baseMVA,
                                          extra    = max(0.0, maximum_[tech] - max(procured[tech], deployed[tech])) * baseMVA)
                                 for tech in techs)
                data[(t, w)] = (wind_prod  = pg[k, t, w] * baseMVA,
                                wind_avail = cf_wind_w[area_name[a]][t][w] * pmax[k] * baseMVA,
                                tech = tech_vals)
            end
            push!(list, (k = k, data = data))
        end
        gaps[a] = list
    end
    return (techs = techs, gaps = gaps)
end

# =====================================================================
# DEPLOYED VS PROCURED RESERVE FOR THE THREE IMBALANCES OF ONE AREA AND ONE WIND SCENARIO (section 18)
# =====================================================================
# The three imbalances are: generator loss, converter loss and HVDC reserve-provision imbalance (the larger of the
# generator-triggered and converter-triggered versions). For each one, the largest contingency k (largest power loss)
# is taken, as in section 8. Procured reserve is the first-stage r_proc of the area. HVDC has no procured reserve:
# in its place, r_hvdc gives the MAXIMUM HVDC reserve the link could deliver into the area in scenario w, i.e. the
# headroom of the area's converters above their actual flow, min(p_ac_max - p_ac, 2·p_dc_max).
# fm = compute_frequency_metrics(m). All values in MW.

function deployed_vs_procured(m::Model, fm, a::Int, w)
    sets = m.ext[:sets]; vars = m.ext[:variables]
    baseMVA = m.ext[:parameters][:baseMVA]
    T = sets[:t]
    Ga = a == 1 ? sets[:G1] : sets[:G2]
    Sa = a == 1 ? sets[:S1] : sets[:S2]
    Ea = a == 1 ? sets[:E1] : sets[:E2]
    rpg = JuMP.value.(vars[Symbol("r_proc_g_$a")]) .* baseMVA
    rps = JuMP.value.(vars[Symbol("r_proc_s_$a")]) .* baseMVA
    rpe = JuMP.value.(vars[Symbol("r_proc_e_$a")]) .* baseMVA
    CVa = a == 1 ? sets[:CV1] : sets[:CV2]
    conv = JuMP.value.(vars[:conv_p_ac_ss])
    conv_p_ac_max = m.ext[:parameters][:convdc][:p_ac_max]
    conv_p_dc_max = m.ext[:parameters][:convdc][:p_dc_max]
    hvdc_max(t) = sum((max(0.0, min(conv_p_ac_max[cv] - conv[cv, t, w], 2 * conv_p_dc_max[cv])) for cv in CVa); init = 0.0) * baseMVA
    evs = fm.results[a]          # 1 generator loss, 2 converter loss, 3 reserve imbalance (g), 4 reserve imbalance (c)

    titles = ["Generator loss", "Converter loss", "HVDC reserve-provision imbalance"]
    rows = Dict{Any,Any}()
    for t in T
        c_g  = largest_contingency(evs[1], t, w)
        c_c  = largest_contingency(evs[2], t, w)
        c_rg = largest_contingency(evs[3], t, w)
        c_rc = largest_contingency(evs[4], t, w)
        # reserve-provision imbalance: keep the larger one and remember what triggered it
        c_r, trig = c_rg.ploss >= c_rc.ploss ? (c_rg, "generator $(c_rg.k) trips in the other area") :
                                               (c_rc, "converter $(c_rc.k) trips in the other area")
        events = [(title = titles[1], trigger = "generator $(c_g.k) trips", c = c_g),
                  (title = titles[2], trigger = "converter $(c_c.k) trips", c = c_c),
                  (title = titles[3], trigger = trig,                        c = c_r)]
        procured = (r_gen  = sum((rpg[g, t] for g in Ga); init = 0.0),
                    r_batt = sum((rps[s, t] for s in Sa); init = 0.0),
                    r_elec = sum((rpe[e, t] for e in Ea); init = 0.0),
                    r_hvdc = hvdc_max(t))          # maximum HVDC reserve (not procured: converter headroom)
        rows[t] = (events = events, procured = procured)
    end
    return (titles = titles, rows = rows)
end

# =====================================================================
# COST BREAKDOWN OF THE OBJECTIVE FOR EACH WIND REALIZATION (section 19 of printparameters_robust!)
# =====================================================================
# Total cost of realization w = first-stage cost C_I (the same for every w) + second-stage cost C_II,w.
# The objective of the model is C_I + sigma = C_I + max_w C_II,w (plus any tie-breaking terms you may have added).
# The multipliers and VOLL must be the same as in the model (defaults = values of build_ac_opf_acdc_frequency_robust).

function compute_cost_breakdown(m::Model; α = 1.1, β = 0.9, α_H = 1.1, β_H = 0.9, VOLL = 10000)
    sets = m.ext[:sets]; par = m.ext[:parameters]; vars = m.ext[:variables]
    G = sets[:G]; E = sets[:E]; T = sets[:t]; W = sets[:Wind_scenarios]
    G1, G2, S1, S2, E1, E2 = sets[:G1], sets[:G2], sets[:S1], sets[:S2], sets[:E1], sets[:E2]
    baseMVA = par[:baseMVA]; baseKG = par[:baseKG]
    gen_cost = par[:gen_cost]; start_up_cost = par[:startup_cost]; Estartupcost = par[:Estartupcost]
    Hcost = par[:Hydrogencost]
    Gres, Sres, Eres = par[:G_reservecost], par[:Sreservecost], par[:Ereservecost]
    v(name) = JuMP.value.(vars[name])
    total(itr) = sum(itr; init = 0.0)

    pg_fs = v(:pg_fs); zg = v(:zg_fs); betag = v(:betag_fs); zesu = v(:zesu_fs)
    hbu_fs = v(:hfgconsum_fs); hse_fs = v(:hfginyect_fs)
    up = v(:pg_ss_up); dn = v(:pg_ss_dn)
    hbu_up, hbu_dn = v(:hfgconsum_ss_up), v(:hfgconsum_ss_dn)
    hse_up, hse_dn = v(:hfginyect_ss_up), v(:hfginyect_ss_dn)
    ls1_fs, ls2_fs = v(:load_shed_1_fs), v(:load_shed_2_fs)
    ls1_ss, ls2_ss = v(:load_shed_1_ss), v(:load_shed_2_ss)
    rpg1, rpg2 = v(:r_proc_g_1), v(:r_proc_g_2)
    rps1, rps2 = v(:r_proc_s_1), v(:r_proc_s_2)
    rpe1, rpe2 = v(:r_proc_e_1), v(:r_proc_e_2)

    # ---------------- first stage (same for every realization) ----------------
    first = Dict(
        "Generation energy (day-ahead schedule)" => total(gen_cost[g][1] * pg_fs[g, t] for g in G, t in T),
        "Generation no-load cost"                => total(gen_cost[g][2] * zg[g, t] for g in G, t in T),
        "Generator start-ups"                    => total(start_up_cost[g] * betag[g, t] for g in G, t in T),
        "Electrolyzer start-ups"                 => total(Estartupcost[e] * zesu[e, t] for e in E, t in T),
        "Hydrogen purchased (day-ahead)"         => total(Hcost[e] * baseKG * hbu_fs[e, t] for e in E, t in T),
        "Hydrogen sold (day-ahead, income)"      => -total(Hcost[e] * baseKG * hse_fs[e, t] for e in E, t in T),
        "Procured reserve: generators"           => baseMVA * (total(Gres[g] * rpg1[g, t] for g in G1, t in T) + total(Gres[g] * rpg2[g, t] for g in G2, t in T)),
        "Procured reserve: batteries"            => baseMVA * (total(Sres[s] * rps1[s, t] for s in S1, t in T) + total(Sres[s] * rps2[s, t] for s in S2, t in T)),
        "Procured reserve: electrolyzers"        => baseMVA * (total(Eres[e] * rpe1[e, t] for e in E1, t in T) + total(Eres[e] * rpe2[e, t] for e in E2, t in T)),
        "Load shedding (day-ahead)"              => baseMVA * VOLL * total(ls1_fs[t] + ls2_fs[t] for t in T))
    first_order = ["Generation energy (day-ahead schedule)", "Generation no-load cost", "Generator start-ups",
                   "Electrolyzer start-ups", "Hydrogen purchased (day-ahead)", "Hydrogen sold (day-ahead, income)",
                   "Procured reserve: generators", "Procured reserve: batteries", "Procured reserve: electrolyzers",
                   "Load shedding (day-ahead)"]
    C_I = sum(values(first))

    # ---------------- second stage (one value per realization) ----------------
    second_order = ["Generation redispatch up (α·c)", "Generation redispatch down (−β·c, refund)",
                    "Hydrogen deviations (α_H/β_H)", "Load shedding (real time)"]
    second = Dict{Any,Dict{String,Float64}}()
    for w in W
        second[w] = Dict(
            "Generation redispatch up (α·c)"            => total(α * gen_cost[g][1] * up[g, t, w] for g in G, t in T),
            "Generation redispatch down (−β·c, refund)" => -total(β * gen_cost[g][1] * dn[g, t, w] for g in G, t in T),
            "Hydrogen deviations (α_H/β_H)"             => total(Hcost[e] * baseKG * (α_H * hbu_up[e, t, w] - β_H * hbu_dn[e, t, w]
                                                                 - β_H * hse_up[e, t, w] + α_H * hse_dn[e, t, w]) for e in E, t in T),
            "Load shedding (real time)"                 => baseMVA * VOLL * total(ls1_ss[t, w] + ls2_ss[t, w] for t in T))
    end
    C_II = Dict(w => sum(values(second[w])) for w in W)

    # ---------------- grouped view: generation, hydrogen, reserve, load shedding ----------------
    groups(w) = (generation = first["Generation energy (day-ahead schedule)"] + first["Generation no-load cost"] +
                              first["Generator start-ups"] + second[w]["Generation redispatch up (α·c)"] +
                              second[w]["Generation redispatch down (−β·c, refund)"],
                 hydrogen   = first["Electrolyzer start-ups"] + first["Hydrogen purchased (day-ahead)"] +
                              first["Hydrogen sold (day-ahead, income)"] + second[w]["Hydrogen deviations (α_H/β_H)"],
                 reserve    = first["Procured reserve: generators"] + first["Procured reserve: batteries"] +
                              first["Procured reserve: electrolyzers"],
                 load_shed  = first["Load shedding (day-ahead)"] + second[w]["Load shedding (real time)"])

    obj = objective_value(m)
    worst = maximum(C_II[w] for w in W)
    return (W = W, first = first, first_order = first_order, C_I = C_I, second = second, second_order = second_order,
            C_II = C_II, total = Dict(w => C_I + C_II[w] for w in W), groups = Dict(w => groups(w) for w in W),
            objective = obj, sigma = JuMP.value(vars[:sigma]), worst = worst,
            residual = obj - (C_I + worst))     # ≠ 0 only if the objective has extra terms (e.g. ε or ρ penalties)
end
