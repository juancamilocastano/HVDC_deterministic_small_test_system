function build_ac_opf_acdc_frequency_robust!(m::Model)
    # This function builds the polar form of a nonlinear AC power flow formulation
    # Create m.ext entries "variables", "expressions" and "constraints"
    m.ext[:variables] = Dict()
    m.ext[:expressions] = Dict()
    m.ext[:constraints] = Dict()  
    Wind_scenarios = m.ext[:sets][:Wind_scenarios] 
    Solar_scenarios = m.ext[:sets][:Solar_scenarios]
   

    

    
    # Extract sets
    # AC network
    baseMVA = m.ext[:parameters][:baseMVA]
    N = m.ext[:sets][:N]
    N_sl = m.ext[:sets][:N_sl]
    N1=m.ext[:sets][:N1]
    N2=m.ext[:sets][:N2]
    B = m.ext[:sets][:B]
    B_ac_fr = m.ext[:sets][:B_ac_fr]
    B_ac_to = m.ext[:sets][:B_ac_to]
    G = m.ext[:sets][:G]
    G_ac = m.ext[:sets][:G_ac]
    L = m.ext[:sets][:L]
    L_ac = m.ext[:sets][:L_ac]
    # W_ac = m.ext[:sets][:W_ac]
    solar_roof = m.ext[:sets][:solar_roof]
    B_ac = m.ext[:sets][:B_ac]
    B_arcs = m.ext[:sets][:B_arcs]
    bus_ij = m.ext[:sets][:bus_ij]
    bus_ji = m.ext[:sets][:bus_ji]
    bus_ij_ji = m.ext[:sets][:bus_ij_ji]
    G_reservoir = m.ext[:sets][:G_reservoir]
    G_pump = m.ext[:sets][:G_pump]
    G_nuclear = m.ext[:sets][:G_nuclear]
    G_gas = m.ext[:sets][:G_gas]
    G_biomass = m.ext[:sets][:G_biomass]
    G_oil = m.ext[:sets][:G_oil]
    G_solar = m.ext[:sets][:G_solar]
    G_wind = m.ext[:sets][:G_wind]
    


    # DC network
    CV = m.ext[:sets][:CV]
    ND = m.ext[:sets][:ND]
    BD = m.ext[:sets][:BD]
    ND_arcs = m.ext[:sets][:ND_arcs]
    CV_arcs = m.ext[:sets][:CV_arcs]   
    BD_dc_fr = m.ext[:sets][:BD_dc_fr]
    BD_dc_to = m.ext[:sets][:BD_dc_to]
    BD_dc = m.ext[:sets][:BD_dc]

    busdc_ij = m.ext[:sets][:busdc_ij]
    busdc_ji = m.ext[:sets][:busdc_ji]
    T= m.ext[:sets][:t]

    S = m.ext[:sets][:S]
    S_ac = m.ext[:sets][:S_ac]
    E= m.ext[:sets][:E]
    E_ac= m.ext[:sets][:E_ac]

    # Extract parameters
    #Frequency stability parameters
    f1 = m.ext[:parameters][:f1]
    f2 = m.ext[:parameters][:f2]
    rocof1 = m.ext[:parameters][:rocof1]
    rocof2 = m.ext[:parameters][:rocof2]
    deltaf1 = m.ext[:parameters][:deltaf1]
    deltaf2 = m.ext[:parameters][:deltaf2]         

    # AC network
    gen_bus = m.ext[:parameters][:gen_bus]
    load_bus = m.ext[:parameters][:load_bus]
    
    #shunt_bus = m.ext[:parameters][:shunt_bus]
    vmmin = m.ext[:parameters][:vmmin]
    vmmax = m.ext[:parameters][:vmmax]
    vamin = m.ext[:parameters][:vamin]
    vamax = m.ext[:parameters][:vamax]
    rb =  m.ext[:parameters][:rb]
    xb =  m.ext[:parameters][:xb] 
    gb =  m.ext[:parameters][:gb]
    bb =  m.ext[:parameters][:bb] 
    #gs =  m.ext[:parameters][:gs]
    #bs =  m.ext[:parameters][:bs] 
    gfr = m.ext[:parameters][:gb_sh_fr]
    bfr = m.ext[:parameters][:bb_sh_fr]
    gto = m.ext[:parameters][:gb_sh_to]
    bto = m.ext[:parameters][:bb_sh_to]
    pmaxbranch = m.ext[:parameters][:pmaxbranch]
    angmin = m.ext[:parameters][:angmin]
    angmax = m.ext[:parameters][:angmax]
    b_shift = m.ext[:parameters][:b_shift]
    b_tap = m.ext[:parameters][:b_tap]
    pd = m.ext[:parameters][:pd]
    qd = m.ext[:parameters][:qd]
    pmax = m.ext[:parameters][:pmax]
    pmin = m.ext[:parameters][:pmin]
    #qmax = m.ext[:parameters][:qmax]
    #qmin = m.ext[:parameters][:qmin]
    gen_cost = m.ext[:parameters][:gen_cost]
    cg_up = m.ext[:parameters][:cg_up]
    cg_dn = m.ext[:parameters][:cg_dn]
    ij_ji_ang_max = m.ext[:parameters][:ij_ji_ang_max]
    ij_ji_ang_min = m.ext[:parameters][:ij_ji_ang_min]
    demand = m.ext[:parameters][:demand]
    upramp = m.ext[:parameters][:upramp]
    capacity_factor_solar= m.ext[:parameters][:capacity_factor_solar]
    capacity_factor_wind= m.ext[:parameters][:capacity_factor_wind]
    capacity_factor_wind_w=m.ext[:parameters][:capacity_factor_wind_w]
    downramp = m.ext[:parameters][:downramp]
    MUT = m.ext[:parameters][:MUT]
    MDT = m.ext[:parameters][:MDT]
    G_reservecost=m.ext[:parameters][:G_reservecost]
    G_dt=m.ext[:parameters][:G_dt]
    ic=m.ext[:parameters][:ic]
    start_up_cost=m.ext[:parameters][:startup_cost]
    G_storage=m.ext[:parameters][:G_storage]
    MaxFreqDev=m.ext[:parameters][:MaxFreqDev]
    P_pump=m.ext[:parameters][:P_pump]
    G_npumping=m.ext[:parameters][:G_npumping]
    G_ngenerating=m.ext[:parameters][:G_ngenerating] 
    E_reservoirs_min=m.ext[:parameters][:E_reservoirs_min]
    E_reservoirs_ini=m.ext[:parameters][:E_reservoirs_ini]
    E_reservoirs_end=m.ext[:parameters][:E_reservoirs_end]
    


    # DC network
    # DC bus
    busdc_vm_max = m.ext[:parameters][:busdc][:vm_max]
    busdc_vm_min = m.ext[:parameters][:busdc][:vm_min]
    busdc_vm_set = m.ext[:parameters][:busdc][:vm_set]
    busdc_c = m.ext[:parameters][:busdc][:c]
    busdc_p = m.ext[:parameters][:busdc][:p]

    # Converters
    conv_busdc = m.ext[:parameters][:convdc][:busdc]
    conv_bus = m.ext[:parameters][:convdc][:bus]
    conv_status = m.ext[:parameters][:convdc][:status]
    conv_loss_a = m.ext[:parameters][:convdc][:loss_a]
    conv_loss_b = m.ext[:parameters][:convdc][:loss_b]
    conv_loss_c_inv = m.ext[:parameters][:convdc][:loss_c_inv]
    conv_loss_c_rec = m.ext[:parameters][:convdc][:loss_c_rec]
    conv_p_ac_max = m.ext[:parameters][:convdc][:p_ac_max]
    conv_p_ac_min = m.ext[:parameters][:convdc][:p_ac_min]
    #conv_q_ac_max = m.ext[:parameters][:convdc][:q_ac_max]
    #conv_q_ac_min = m.ext[:parameters][:convdc][:q_ac_min]
    conv_p_dc_max = m.ext[:parameters][:convdc][:p_dc_max]
    conv_p_dc_min = m.ext[:parameters][:convdc][:p_dc_min]
    conv_droop = m.ext[:parameters][:convdc][:droop]
    conv_i_max = m.ext[:parameters][:convdc][:i_max]
    conv_vm_min = m.ext[:parameters][:convdc][:vm_min]
    conv_vm_max = m.ext[:parameters][:convdc][:vm_max]
    conv_vm_dc_set = m.ext[:parameters][:convdc][:vm_dc_set]
    conv_p_g = m.ext[:parameters][:convdc][:p_g]
    #conv_q_g = m.ext[:parameters][:convdc][:q_g]
    conv_b_f = m.ext[:parameters][:convdc][:b_f]
    conv_tf_r = m.ext[:parameters][:convdc][:r_tf]
    conv_tf_g = m.ext[:parameters][:convdc][:g_tf]
    conv_tf_x = m.ext[:parameters][:convdc][:x_tf]
    conv_tf_b = m.ext[:parameters][:convdc][:b_tf]
    conv_pr_r = m.ext[:parameters][:convdc][:r_pr]
    conv_pr_g = m.ext[:parameters][:convdc][:g_pr]
    conv_pr_x = m.ext[:parameters][:convdc][:x_pr]
    conv_pr_b = m.ext[:parameters][:convdc][:b_pr]
    conv_tf_tap = m.ext[:parameters][:convdc][:tap_tf]
    conv_is_tf = m.ext[:parameters][:convdc][:is_tf]
    conv_is_pr = m.ext[:parameters][:convdc][:is_pr]
    conv_is_filter = m.ext[:parameters][:convdc][:is_filter]
    HVDC_reservecost= m.ext[:parameters][:convdc][:HVDC_reservecost]
    HVDC_deployment=m.ext[:parameters][:convdc][:HVDC_deployment]

    # DC branches
    brdc_rate_a = m.ext[:parameters][:branchdc][:rate_a]
    brdc_rate_b = m.ext[:parameters][:branchdc][:rate_b]
    brdc_rate_c = m.ext[:parameters][:branchdc][:rate_c]
    brdc_status = m.ext[:parameters][:branchdc][:status]
    brdc_r = m.ext[:parameters][:branchdc][:r]
    brdc_g = m.ext[:parameters][:branchdc][:g]
    brdc_l = m.ext[:parameters][:branchdc][:l]
    brdc_dcpoles = m.ext[:parameters][:branchdc][:dcpoles]
    

    # Electrolyzer
    Epmax = m.ext[:parameters][:Epmax]
    Epmin = m.ext[:parameters][:Epmin]
    Eefficiency = m.ext[:parameters][:Eefficiency]
    Eloadfactor = m.ext[:parameters][:Eloadfactor] 
    Eflowmax = m.ext[:parameters][:Eflowmax]
    Estoragemax = m.ext[:parameters][:Estoragemax]
    Estoragemin = m.ext[:parameters][:Estoragemin]
    Estorageinitial = m.ext[:parameters][:Estorageinitial]
    Estorageend = m.ext[:parameters][:Estorageend]
    Edeployment = m.ext[:parameters][:Edeployment]
    Ereservecost = m.ext[:parameters][:Ereservecost]
    Hydrogencost = m.ext[:parameters][:Hydrogencost]
    Estartupcost=m.ext[:parameters][:Estartupcost]
    Eeficiencycarga = m.ext[:parameters][:Eeficiencycarga]
    Eeficiencydischarge = m.ext[:parameters][:Eeficiencydischarge]
    Estartupcost = m.ext[:parameters][:Estartupcost]
    Ecompressorpower = m.ext[:parameters][:Ecompressorpower]
    electrolyzer_bus = m.ext[:parameters][:electrolyzer_bus]
    baseKG = m.ext[:parameters][:baseKG]
  
    

    #storage
    Spmax = m.ext[:parameters][:Spmax]
    Sstoragemax = m.ext[:parameters][:Sstoragemax]
    Sdod = m.ext[:parameters][:Sdod]
    Sefficiencycarga = m.ext[:parameters][:Sefficiencycarga]
    Sefficiencydischarge = m.ext[:parameters][:Sefficiencydischarge]
    Senergyinitial = m.ext[:parameters][:Senergyinitial]
    Senergyend = m.ext[:parameters][:Senergyend]
    Sdeployment = m.ext[:parameters][:Sdeployment]
    Sreservecost = m.ext[:parameters][:Sreservecost]
    storage_bus = m.ext[:parameters][:storage_bus]
    solar_roof_pmax = m.ext[:parameters][:solar_roof_pmax]
    
    #Area elements
    S1= m.ext[:sets][:S1]
    S2= m.ext[:sets][:S2]
    E1= m.ext[:sets][:E1]
    E2= m.ext[:sets][:E2]
    G1 = m.ext[:sets][:G1]
    G2 = m.ext[:sets][:G2]
    CV1 = m.ext[:sets][:CV1]
    CV2 = m.ext[:sets][:CV2]
    G_wind=m.ext[:sets][:G_wind]
    G_wind_1=m.ext[:sets][:G_wind_1]
    G_wind_2=m.ext[:sets][:G_wind_2]
    G_solar=m.ext[:sets][:G_solar]
    G_solar_1=m.ext[:sets][:G_solar_1]
    G_solar_2=m.ext[:sets][:G_solar_2]
    G_reservoir_1=m.ext[:sets][:G_reservoir_1]
    G_reservoir_2=m.ext[:sets][:G_reservoir_2]
    G_pump_1=m.ext[:sets][:G_pump_1]
    G_pump_2=m.ext[:sets][:G_pump_2]
    G_nuclear_1=m.ext[:sets][:G_nuclear_1]
    G_nuclear_2=m.ext[:sets][:G_nuclear_2]
    G_gas_1=m.ext[:sets][:G_gas_1]
    G_gas_2=m.ext[:sets][:G_gas_2]
    G_biomass_1=m.ext[:sets][:G_biomass_1]
    G_biomass_2=m.ext[:sets][:G_biomass_2]
    G_oil_1=m.ext[:sets][:G_oil_1]
    G_oil_2=m.ext[:sets][:G_oil_2]
    all_contingencies = m.ext[:sets][:all_contingencies]
    TG=vcat(G_nuclear, G_gas, G_biomass, G_oil)
    TG1=vcat(G_nuclear_1, G_gas_1, G_biomass_1, G_oil_1) #Thermal 1
    TG2=vcat(G_nuclear_2, G_gas_2, G_biomass_2, G_oil_2) #Thermal 2
    Set_WWS=m.ext[:sets][:WWS] = setdiff(m.ext[:sets][:G], m.ext[:sets][:G_solar],m.ext[:sets][:G_wind])
    Set_WWS1=m.ext[:sets][:WWS1] = setdiff(m.ext[:sets][:G1], m.ext[:sets][:G_solar_1],m.ext[:sets][:G_wind_1])
    Set_WWS2=m.ext[:sets][:WWS2] = setdiff(m.ext[:sets][:G2], m.ext[:sets][:G_solar_2],m.ext[:sets][:G_wind_2])

    fallos = m.ext[:sets][:fallos] = vcat([(:gen, g) for g in G], [(:conv, cv) for cv in CV])
    fallos1 = m.ext[:sets][:fallos1] = vcat([(:gen, g) for g in G1], [(:conv, cv) for cv in CV1])
    fallos2 = m.ext[:sets][:fallos2] = vcat([(:gen, g) for g in G2], [(:conv, cv) for cv in CV2])

fallos_g1 = m.ext[:sets][:fallos_g1] = G1
fallos_c1 = m.ext[:sets][:fallos_c1] = CV1
fallos_g2 = m.ext[:sets][:fallos_g2] = G2
fallos_c2 = m.ext[:sets][:fallos_c2] = CV2

    
        K = vcat([(:gen,g)  for g  in G],
         [(:conv, cv) for cv in CV])
         omega = [(k..., w) for k in K for w in  Wind_scenarios]


    ##### Create variables 
    # AC components
    # Bus variables

  


    pg_fs    = m.ext[:variables][:pg_fs]    = @variable(m, [g=G, t=T],                   lower_bound=0, upper_bound=pmax[g],     base_name="pg_fs")    # day-ahead generation schedule (first stage)
    pg_ss    = m.ext[:variables][:pg_ss]    = @variable(m, [g=G, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=pmax[g],     base_name="pg_ss")    # actual generation in each wind realization (second stage)
    pg_ss_up = m.ext[:variables][:pg_ss_up] = @variable(m, [g=G, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g],   base_name="pg_ss_up") # upward adjustment of generation w.r.t. the first-stage schedule
    pg_ss_dn = m.ext[:variables][:pg_ss_dn] = @variable(m, [g=G, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=downramp[g], base_name="pg_ss_dn") # downward adjustment of generation w.r.t. the first-stage schedule


        # Reserve of generators for the loss of a generator / converter in their own area
    rg_lg1_ss = m.ext[:variables][:rg_lg1_ss] = @variable(m, [g=G1, t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lg1_ss") # frequency reserve of generators in area 1 for the loss of generator k in area 1
    rg_lc1_ss = m.ext[:variables][:rg_lc1_ss] = @variable(m, [g=G1, t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lc1_ss") # frequency reserve of generators in area 1 for the loss of converter k in area 1
    rg_lg2_ss = m.ext[:variables][:rg_lg2_ss] = @variable(m, [g=G2, t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lg2_ss") # frequency reserve of generators in area 2 for the loss of generator k in area 2
    rg_lc2_ss = m.ext[:variables][:rg_lc2_ss] = @variable(m, [g=G2, t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lc2_ss") # frequency reserve of generators in area 2 for the loss of converter k in area 2

    # Reserve of generators to cover the imbalance created when the HVDC link delivers reserve to the other area
    rg_l_reserve_1_g_ss = m.ext[:variables][:rg_l_reserve_1_g_ss] = @variable(m, [g=G1, t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_l_reserve_1_g_ss") # area 1 reserve when HVDC supports area 2 after the loss of generator k in area 2
    rg_l_reserve_1_c_ss = m.ext[:variables][:rg_l_reserve_1_c_ss] = @variable(m, [g=G1, t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_l_reserve_1_c_ss") # area 1 reserve when HVDC supports area 2 after the loss of converter k in area 2
    rg_l_reserve_2_g_ss = m.ext[:variables][:rg_l_reserve_2_g_ss] = @variable(m, [g=G2, t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_l_reserve_2_g_ss") # area 2 reserve when HVDC supports area 1 after the loss of generator k in area 1
    rg_l_reserve_2_c_ss = m.ext[:variables][:rg_l_reserve_2_c_ss] = @variable(m, [g=G2, t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_l_reserve_2_c_ss") # area 2 reserve when HVDC supports area 1 after the loss of converter k in area 1


    r_proc_g_1 = m.ext[:variables][:r_proc_g_1] = @variable(m, [g=G1, t=T], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="r_proc_g_1") # procured reserve of generators in area 1 (first stage)
    r_proc_g_2 = m.ext[:variables][:r_proc_g_2] = @variable(m, [g=G2, t=T], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="r_proc_g_2") # procured reserve of generators in area 2 (first stage)
    
    
    # Status variables generators (first stage)
    zg_fs     = m.ext[:variables][:zg_fs]     = @variable(m, [g=G, t=T], binary=true, base_name="zg_fs")     # on/off status of generator g (first stage)
    betag_fs  = m.ext[:variables][:betag_fs]  = @variable(m, [g=G, t=T], binary=true, base_name="betag_fs")  # start-up of generator g (first stage)
    gammag_fs = m.ext[:variables][:gammag_fs] = @variable(m, [g=G, t=T], binary=true, base_name="gammag_fs") # shut-down of generator g (first stage)
    
    # DC components
    # Branches
    brdc_p_fs = m.ext[:variables][:brdc_p_fs] = @variable(m, [(d,e,f)=BD_dc, t=T],                   lower_bound=-brdc_rate_a[d], upper_bound=brdc_rate_a[d], base_name="brdc_p_fs") # DC line flow in the day-ahead schedule (first stage)
    brdc_p_ss = m.ext[:variables][:brdc_p_ss] = @variable(m, [(d,e,f)=BD_dc, t=T, w=Wind_scenarios], lower_bound=-brdc_rate_a[d], upper_bound=brdc_rate_a[d], base_name="brdc_p_ss") # actual DC line flow in each wind realization (second stage)
    
    
    # Converters
    conv_p_ac_fs    = m.ext[:variables][:conv_p_ac_fs]    = @variable(m, [cv=CV, t=T],                   lower_bound=-conv_p_ac_max[cv], upper_bound=conv_p_ac_max[cv],   base_name="conv_p_ac_fs")    # converter AC power in the day-ahead schedule (first stage)
    conv_p_ac_ss    = m.ext[:variables][:conv_p_ac_ss]    = @variable(m, [cv=CV, t=T, w=Wind_scenarios], lower_bound=-conv_p_ac_max[cv], upper_bound=conv_p_ac_max[cv],   base_name="conv_p_ac_ss")    # actual converter AC power in each wind realization (second stage)
    conv_p_ac_ss_up = m.ext[:variables][:conv_p_ac_ss_up] = @variable(m, [cv=CV, t=T, w=Wind_scenarios], lower_bound=0,                  upper_bound=2*conv_p_ac_max[cv], base_name="conv_p_ac_ss_up") # upward adjustment of converter AC power w.r.t. the first-stage schedule
    conv_p_ac_ss_dn = m.ext[:variables][:conv_p_ac_ss_dn] = @variable(m, [cv=CV, t=T, w=Wind_scenarios], lower_bound=0,                  upper_bound=2*conv_p_ac_max[cv], base_name="conv_p_ac_ss_dn") # downward adjustment of converter AC power w.r.t. the first-stage schedule

    
    conv_p_ac_abs_fs = m.ext[:variables][:conv_p_ac_abs_fs] = @variable(m, [cv=CV, t=T],                   lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_abs_fs") # power absorbed by the converter from the AC side (first stage)
    conv_p_ac_abs_ss = m.ext[:variables][:conv_p_ac_abs_ss] = @variable(m, [cv=CV, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_abs_ss") # power absorbed by the converter from the AC side (second stage)

    conv_p_ac_inj_fs = m.ext[:variables][:conv_p_ac_inj_fs] = @variable(m, [cv=CV, t=T],                   lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_inj_fs") # power injected by the converter into the AC side (first stage)
    conv_p_ac_inj_ss = m.ext[:variables][:conv_p_ac_inj_ss] = @variable(m, [cv=CV, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_inj_ss") # power injected by the converter into the AC side (second stage)

    u_conv_p_ac_fs = m.ext[:variables][:u_conv_p_ac_fs] = @variable(m, [cv=CV, t=T],                   binary=true, base_name="u_conv_p_ac_fs") # converter direction: 1 if injecting, 0 if absorbing (first stage)
    u_conv_p_ac_ss = m.ext[:variables][:u_conv_p_ac_ss] = @variable(m, [cv=CV, t=T, w=Wind_scenarios], binary=true, base_name="u_conv_p_ac_ss") # converter direction: 1 if injecting, 0 if absorbing (second stage)

    conv_p_dc_fs = m.ext[:variables][:conv_p_dc_fs] = @variable(m, [cv=CV, t=T],                   lower_bound=-conv_p_dc_max[cv], upper_bound=conv_p_dc_max[cv], base_name="conv_p_dc_fs") # converter DC power (first stage)
    conv_p_dc_ss = m.ext[:variables][:conv_p_dc_ss] = @variable(m, [cv=CV, t=T, w=Wind_scenarios], lower_bound=-conv_p_dc_max[cv], upper_bound=conv_p_dc_max[cv], base_name="conv_p_dc_ss") # converter DC power (second stage)

    
    rhvdc_lg1_ss = m.ext[:variables][:rhvdc_lg1_ss] = @variable(m, [cv=CV1, t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lg1_ss") # HVDC reserve delivered to area 1 for the loss of generator k in area 1
    rhvdc_lc1_ss = m.ext[:variables][:rhvdc_lc1_ss] = @variable(m, [cv=CV1, t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lc1_ss") # HVDC reserve delivered to area 1 for the loss of converter k in area 1
    rhvdc_lg2_ss = m.ext[:variables][:rhvdc_lg2_ss] = @variable(m, [cv=CV2, t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lg2_ss") # HVDC reserve delivered to area 2 for the loss of generator k in area 2
    rhvdc_lc2_ss = m.ext[:variables][:rhvdc_lc2_ss] = @variable(m, [cv=CV2, t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lc2_ss") # HVDC reserve delivered to area 2 for the loss of converter k in area 2
    
        
    # Reservoir storage variables
    e_reservoir_fs = m.ext[:variables][:e_reservoir_fs] = @variable(m, [g=G_reservoir, t=T],                   lower_bound=0, upper_bound=G_storage[g], base_name="e_reservoir_fs") # energy stored in the reservoir (first stage)
    e_reservoir_ss = m.ext[:variables][:e_reservoir_ss] = @variable(m, [g=G_reservoir, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=G_storage[g], base_name="e_reservoir_ss") # energy stored in the reservoir (second stage)


    # Pump generators variables
    p_charge_pump_fs    = m.ext[:variables][:p_charge_pump_fs]    = @variable(m, [g=G_pump, t=T],                   lower_bound=0, base_name="p_charge_pump_fs")    # pumping power (first stage)
    p_charge_pump_ss    = m.ext[:variables][:p_charge_pump_ss]    = @variable(m, [g=G_pump, t=T, w=Wind_scenarios], lower_bound=0, base_name="p_charge_pump_ss")    # pumping power (second stage)
    p_charge_pump_ss_up = m.ext[:variables][:p_charge_pump_ss_up] = @variable(m, [g=G_pump, t=T, w=Wind_scenarios], lower_bound=0, base_name="p_charge_pump_ss_up") # upward adjustment of pumping power w.r.t. the first-stage schedule
    p_charge_pump_ss_dn = m.ext[:variables][:p_charge_pump_ss_dn] = @variable(m, [g=G_pump, t=T, w=Wind_scenarios], lower_bound=0, base_name="p_charge_pump_ss_dn") # downward adjustment of pumping power w.r.t. the first-stage schedule

    e_pump_fs = m.ext[:variables][:e_pump_fs] = @variable(m, [g=G_pump, t=T],                   lower_bound=0, upper_bound=G_storage[g], base_name="e_pump_fs") # energy stored in the pumped-storage reservoir (first stage)
    e_pump_ss = m.ext[:variables][:e_pump_ss] = @variable(m, [g=G_pump, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=G_storage[g], base_name="e_pump_ss") # energy stored in the pumped-storage reservoir (second stage)


    # Electrolyzer continuous variables
    pe_fs    = m.ext[:variables][:pe_fs]    = @variable(m, [e=E, t=T],                   lower_bound=0, upper_bound=Epmax[e], base_name="pe_fs")    # electrolyzer power consumption (first stage)
    pe_ss    = m.ext[:variables][:pe_ss]    = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Epmax[e], base_name="pe_ss")    # electrolyzer power consumption (second stage)
    pe_ss_up = m.ext[:variables][:pe_ss_up] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Epmax[e], base_name="pe_ss_up") # upward adjustment of electrolyzer consumption w.r.t. the first-stage schedule
    pe_ss_dn = m.ext[:variables][:pe_ss_dn] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Epmax[e], base_name="pe_ss_dn") # downward adjustment of electrolyzer consumption w.r.t. the first-stage schedule

    pe_compressor_fs = m.ext[:variables][:pe_compressor_fs] = @variable(m, [e=E, t=T],                   lower_bound=0, base_name="pe_compressor_fs") # compressor power consumption (first stage)
    pe_compressor_ss = m.ext[:variables][:pe_compressor_ss] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, base_name="pe_compressor_ss") # compressor power consumption (second stage)

    hfe_fs = m.ext[:variables][:hfe_fs] = @variable(m, [e=E, t=T],                   lower_bound=0, upper_bound=Eflowmax[e], base_name="hfe_fs") # hydrogen produced by the electrolyzer (first stage)
    hfe_ss = m.ext[:variables][:hfe_ss] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfe_ss") # hydrogen produced by the electrolyzer (second stage)

    hfginyect_fs    = m.ext[:variables][:hfginyect_fs]    = @variable(m, [e=E, t=T],                   lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_fs")    # hydrogen sold (injected to the hydrogen grid), first stage
    hfginyect_ss    = m.ext[:variables][:hfginyect_ss]    = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_ss")    # hydrogen sold (injected to the hydrogen grid), second stage
    hfginyect_ss_up = m.ext[:variables][:hfginyect_ss_up] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_ss_up") # upward adjustment of hydrogen sold w.r.t. the first-stage schedule
    hfginyect_ss_dn = m.ext[:variables][:hfginyect_ss_dn] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_ss_dn") # downward adjustment of hydrogen sold w.r.t. the first-stage schedule

    hfgconsum_fs    = m.ext[:variables][:hfgconsum_fs]    = @variable(m, [e=E, t=T],                   lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_fs")    # hydrogen purchased (consumed from the hydrogen grid), first stage
    hfgconsum_ss    = m.ext[:variables][:hfgconsum_ss]    = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_ss")    # hydrogen purchased (consumed from the hydrogen grid), second stage
    hfgconsum_ss_up = m.ext[:variables][:hfgconsum_ss_up] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_ss_up") # upward adjustment of hydrogen purchased w.r.t. the first-stage schedule
    hfgconsum_ss_dn = m.ext[:variables][:hfgconsum_ss_dn] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_ss_dn") # downward adjustment of hydrogen purchased w.r.t. the first-stage schedule

    hss_fs = m.ext[:variables][:hss_fs] = @variable(m, [e=E, t=T],                   lower_bound=Estoragemin[e], upper_bound=Estoragemax[e], base_name="hss_fs") # hydrogen storage level (first stage)
    hss_ss = m.ext[:variables][:hss_ss] = @variable(m, [e=E, t=T, w=Wind_scenarios], lower_bound=Estoragemin[e], upper_bound=Estoragemax[e], base_name="hss_ss") # hydrogen storage level (second stage)
    
    
    
    # Electrolyzer binary variables (first stage only)
    ze_fs = m.ext[:variables][:ze_fs] = @variable(m, [e=E, t=T], binary=true, base_name="ze_fs") # Electrolyzer status
    zesu_fs = m.ext[:variables][:zesu_fs] = @variable(m, [e=E, t=T], binary=true, base_name="zesu_fs") # Electrolyzer start up
    zestb_fs = m.ext[:variables][:zestb_fs] = @variable(m, [e=E, t=T], binary=true, base_name="zestb_fs") # Electrolyzer standby indicator

    # Electrolyzer reserve variables

    # Reserve of electrolyzers for the loss of a generator / converter in their own area
    re_lg1_ss = m.ext[:variables][:re_lg1_ss] = @variable(m, [e=E1, t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="re_lg1_ss") # frequency reserve of electrolyzers in area 1 for the loss of generator k in area 1
    re_lc1_ss = m.ext[:variables][:re_lc1_ss] = @variable(m, [e=E1, t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="re_lc1_ss") # frequency reserve of electrolyzers in area 1 for the loss of converter k in area 1
    re_lg2_ss = m.ext[:variables][:re_lg2_ss] = @variable(m, [e=E2, t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="re_lg2_ss") # frequency reserve of electrolyzers in area 2 for the loss of generator k in area 2
    re_lc2_ss = m.ext[:variables][:re_lc2_ss] = @variable(m, [e=E2, t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="re_lc2_ss") # frequency reserve of electrolyzers in area 2 for the loss of converter k in area 2

    # Reserve of electrolyzers to cover the imbalance created when the HVDC link delivers reserve to the other area
    re_l_reserve_1_g_ss = m.ext[:variables][:re_l_reserve_1_g_ss] = @variable(m, [e=E1, t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="re_l_reserve_1_g_ss") # area 1 reserve when HVDC supports area 2 after the loss of generator k in area 2
    re_l_reserve_1_c_ss = m.ext[:variables][:re_l_reserve_1_c_ss] = @variable(m, [e=E1, t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="re_l_reserve_1_c_ss") # area 1 reserve when HVDC supports area 2 after the loss of converter k in area 2
    re_l_reserve_2_g_ss = m.ext[:variables][:re_l_reserve_2_g_ss] = @variable(m, [e=E2, t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="re_l_reserve_2_g_ss") # area 2 reserve when HVDC supports area 1 after the loss of generator k in area 1
    re_l_reserve_2_c_ss = m.ext[:variables][:re_l_reserve_2_c_ss] = @variable(m, [e=E2, t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="re_l_reserve_2_c_ss") # area 2 reserve when HVDC supports area 1 after the loss of converter k in area 1
    
    r_proc_e_1 = m.ext[:variables][:r_proc_e_1] = @variable(m, [e=E1, t=T], lower_bound=0, base_name="r_proc_e_1") # procured reserve electrolyzers area 1
    r_proc_e_2 = m.ext[:variables][:r_proc_e_2] = @variable(m, [e=E2, t=T], lower_bound=0, base_name="r_proc_e_2") # procured reserve electrolyzers area 2

    # Storage variables
    psc_fs    = m.ext[:variables][:psc_fs]    = @variable(m, [s=S, t=T],                   lower_bound=0, base_name="psc_fs")    # battery charging power (first stage)
    psc_ss    = m.ext[:variables][:psc_ss]    = @variable(m, [s=S, t=T, w=Wind_scenarios], lower_bound=0, base_name="psc_ss")    # battery charging power (second stage)
    psc_ss_up = m.ext[:variables][:psc_ss_up] = @variable(m, [s=S, t=T, w=Wind_scenarios], lower_bound=0, base_name="psc_ss_up") # upward adjustment of battery charging power w.r.t. the first-stage schedule
    psc_ss_dn = m.ext[:variables][:psc_ss_dn] = @variable(m, [s=S, t=T, w=Wind_scenarios], lower_bound=0, base_name="psc_ss_dn") # downward adjustment of battery charging power w.r.t. the first-stage schedule

    psd_fs    = m.ext[:variables][:psd_fs]    = @variable(m, [s=S, t=T],                   lower_bound=0, base_name="psd_fs")    # battery discharging power (first stage)
    psd_ss    = m.ext[:variables][:psd_ss]    = @variable(m, [s=S, t=T, w=Wind_scenarios], lower_bound=0, base_name="psd_ss")    # battery discharging power (second stage)
    psd_ss_up = m.ext[:variables][:psd_ss_up] = @variable(m, [s=S, t=T, w=Wind_scenarios], lower_bound=0, base_name="psd_ss_up") # upward adjustment of battery discharging power w.r.t. the first-stage schedule
    psd_ss_dn = m.ext[:variables][:psd_ss_dn] = @variable(m, [s=S, t=T, w=Wind_scenarios], lower_bound=0, base_name="psd_ss_dn") # downward adjustment of battery discharging power w.r.t. the first-stage schedule

    es_fs = m.ext[:variables][:es_fs] = @variable(m, [s=S, t=T],                   lower_bound=Sstoragemax[s]*(1-Sdod[s]), upper_bound=Sstoragemax[s], base_name="es_fs") # energy stored in the battery (first stage)
    es_ss = m.ext[:variables][:es_ss] = @variable(m, [s=S, t=T, w=Wind_scenarios], lower_bound=Sstoragemax[s]*(1-Sdod[s]), upper_bound=Sstoragemax[s], base_name="es_ss") # energy stored in the battery (second stage)

    zs_fs = m.ext[:variables][:zs_fs] = @variable(m, [s=S, t=T],                   binary=true, base_name="zs_fs") # battery status: 1 if discharging, 0 if charging (first stage)
    zs_ss = m.ext[:variables][:zs_ss] = @variable(m, [s=S, t=T, w=Wind_scenarios], binary=true, base_name="zs_ss") # battery status: 1 if discharging, 0 if charging (second stage)

    # Reserve of batteries for the loss of a generator / converter in their own area
    rs_lg1_ss = m.ext[:variables][:rs_lg1_ss] = @variable(m, [s=S1, t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="rs_lg1_ss") # frequency reserve of batteries in area 1 for the loss of generator k in area 1
    rs_lg2_ss = m.ext[:variables][:rs_lg2_ss] = @variable(m, [s=S2, t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="rs_lg2_ss") # frequency reserve of batteries in area 2 for the loss of generator k in area 2
    rs_lc1_ss = m.ext[:variables][:rs_lc1_ss] = @variable(m, [s=S1, t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="rs_lc1_ss") # frequency reserve of batteries in area 1 for the loss of converter k in area 1
    rs_lc2_ss = m.ext[:variables][:rs_lc2_ss] = @variable(m, [s=S2, t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="rs_lc2_ss") # frequency reserve of batteries in area 2 for the loss of converter k in area 2

    # Reserve of batteries to cover the imbalance created when the HVDC link delivers reserve to the other area
    rs_l_reserve_1_g_ss = m.ext[:variables][:rs_l_reserve_1_g_ss] = @variable(m, [s=S1, t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="rs_l_reserve_1_g_ss") # area 1 reserve when HVDC supports area 2 after the loss of generator k in area 2
    rs_l_reserve_1_c_ss = m.ext[:variables][:rs_l_reserve_1_c_ss] = @variable(m, [s=S1, t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="rs_l_reserve_1_c_ss") # area 1 reserve when HVDC supports area 2 after the loss of converter k in area 2
    rs_l_reserve_2_g_ss = m.ext[:variables][:rs_l_reserve_2_g_ss] = @variable(m, [s=S2, t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="rs_l_reserve_2_g_ss") # area 2 reserve when HVDC supports area 1 after the loss of generator k in area 1
    rs_l_reserve_2_c_ss = m.ext[:variables][:rs_l_reserve_2_c_ss] = @variable(m, [s=S2, t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="rs_l_reserve_2_c_ss") # area 2 reserve when HVDC supports area 1 after the loss of converter k in area 1= m.ext[:variables][:rs_l_reserve_2_ss] = @variable(m, [s=S2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="rs_l_reserve_2_ss") # frequency reserve for FCR provision

    r_proc_s_1 = m.ext[:variables][:r_proc_s_1] = @variable(m, [s=S1, t=T], lower_bound=0, base_name="r_proc_s_1") # procured reserve batteries area 1
    r_proc_s_2 = m.ext[:variables][:r_proc_s_2] = @variable(m, [s=S2, t=T], lower_bound=0, base_name="r_proc_s_2") # procured reserve batteries area 2

    # Frequency stability variables (second stage: one value per contingency k and wind scenario w)
    plg1_ss = m.ext[:variables][:plg1_ss] = @variable(m, [t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="plg1_ss") # power lost in area 1 when generator k of area 1 trips
    plg2_ss = m.ext[:variables][:plg2_ss] = @variable(m, [t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="plg2_ss") # power lost in area 2 when generator k of area 2 trips
    plc1_ss = m.ext[:variables][:plc1_ss] = @variable(m, [t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="plc1_ss") # power lost in area 1 when converter k of area 1 trips
    plc2_ss = m.ext[:variables][:plc2_ss] = @variable(m, [t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="plc2_ss") # power lost in area 2 when converter k of area 2 trips

    # Power lost in one area because it sends FCR through the HVDC to the other area (triggered by a contingency in the other area)
    plreserve_1_g_ss = m.ext[:variables][:plreserve_1_g_ss] = @variable(m, [t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="plreserve_1_g_ss") # area 1 imbalance when generator k of area 2 trips
    plreserve_1_c_ss = m.ext[:variables][:plreserve_1_c_ss] = @variable(m, [t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="plreserve_1_c_ss") # area 1 imbalance when converter k of area 2 trips
    plreserve_2_g_ss = m.ext[:variables][:plreserve_2_g_ss] = @variable(m, [t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="plreserve_2_g_ss") # area 2 imbalance when generator k of area 1 trips
    plreserve_2_c_ss = m.ext[:variables][:plreserve_2_c_ss] = @variable(m, [t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="plreserve_2_c_ss") # area 2 imbalance when converter k of area 1 trips

    # Auxiliary variables for the rotated second-order cone (nadir) constraints, one pair per contingency k and wind scenario w
    ypg1_ss = m.ext[:variables][:ypg1_ss] = @variable(m, [t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="ypg1_ss") # rotated SOC auxiliary, generator k of area 1 trips
    zpg1_ss = m.ext[:variables][:zpg1_ss] = @variable(m, [t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="zpg1_ss") # rotated SOC auxiliary, generator k of area 1 trips
    ypc1_ss = m.ext[:variables][:ypc1_ss] = @variable(m, [t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="ypc1_ss") # rotated SOC auxiliary, converter k of area 1 trips
    zpc1_ss = m.ext[:variables][:zpc1_ss] = @variable(m, [t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="zpc1_ss") # rotated SOC auxiliary, converter k of area 1 trips
    ypg2_ss = m.ext[:variables][:ypg2_ss] = @variable(m, [t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="ypg2_ss") # rotated SOC auxiliary, generator k of area 2 trips
    zpg2_ss = m.ext[:variables][:zpg2_ss] = @variable(m, [t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="zpg2_ss") # rotated SOC auxiliary, generator k of area 2 trips
    ypc2_ss = m.ext[:variables][:ypc2_ss] = @variable(m, [t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="ypc2_ss") # rotated SOC auxiliary, converter k of area 2 trips
    zpc2_ss = m.ext[:variables][:zpc2_ss] = @variable(m, [t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="zpc2_ss") # rotated SOC auxiliary, converter k of area 2 trips

    # Reserve-provision imbalance: area 1 cones are triggered by contingencies in area 2, and vice versa
    ypreserve1_g_ss = m.ext[:variables][:ypreserve1_g_ss] = @variable(m, [t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="ypreserve1_g_ss") # rotated SOC auxiliary, area 1 supports area 2 after generator k trips
    zpreserve1_g_ss = m.ext[:variables][:zpreserve1_g_ss] = @variable(m, [t=T, k=fallos_g2, w=Wind_scenarios], lower_bound=0, base_name="zpreserve1_g_ss") # rotated SOC auxiliary, area 1 supports area 2 after generator k trips
    ypreserve1_c_ss = m.ext[:variables][:ypreserve1_c_ss] = @variable(m, [t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="ypreserve1_c_ss") # rotated SOC auxiliary, area 1 supports area 2 after converter k trips
    zpreserve1_c_ss = m.ext[:variables][:zpreserve1_c_ss] = @variable(m, [t=T, k=fallos_c2, w=Wind_scenarios], lower_bound=0, base_name="zpreserve1_c_ss") # rotated SOC auxiliary, area 1 supports area 2 after converter k trips
    ypreserve2_g_ss = m.ext[:variables][:ypreserve2_g_ss] = @variable(m, [t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="ypreserve2_g_ss") # rotated SOC auxiliary, area 2 supports area 1 after generator k trips
    zpreserve2_g_ss = m.ext[:variables][:zpreserve2_g_ss] = @variable(m, [t=T, k=fallos_g1, w=Wind_scenarios], lower_bound=0, base_name="zpreserve2_g_ss") # rotated SOC auxiliary, area 2 supports area 1 after generator k trips
    ypreserve2_c_ss = m.ext[:variables][:ypreserve2_c_ss] = @variable(m, [t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="ypreserve2_c_ss") # rotated SOC auxiliary, area 2 supports area 1 after converter k trips
    zpreserve2_c_ss = m.ext[:variables][:zpreserve2_c_ss] = @variable(m, [t=T, k=fallos_c1, w=Wind_scenarios], lower_bound=0, base_name="zpreserve2_c_ss") # rotated SOC auxiliary, area 2 supports area 1 after converter k trips
    
    # Other variables
    load_shed_1_fs = m.ext[:variables][:load_shed_1_fs] = @variable(m, [t=T], lower_bound=0, base_name="load_shed_1_fs") # load shedding in area 1, day-ahead schedule (first stage)
    load_shed_1_ss = m.ext[:variables][:load_shed_1_ss] = @variable(m, [t=T, w=Wind_scenarios], lower_bound=0, base_name="load_shed_1_ss") # load shedding in area 1, actual operation in wind scenario w (second stage)

    load_shed_2_fs = m.ext[:variables][:load_shed_2_fs] = @variable(m, [t=T], lower_bound=0, base_name="load_shed_2_fs") # load shedding in area 2, day-ahead schedule (first stage)
    load_shed_2_ss = m.ext[:variables][:load_shed_2_ss] = @variable(m, [t=T, w=Wind_scenarios], lower_bound=0, base_name="load_shed_2_ss") # load shedding in area 2, actual operation in wind scenario w (second stage)

    sigma = m.ext[:variables][:sigma] = @variable(m, base_name="sigma") # worst-case second-stage cost (free variable, no bounds)


#     # Tie-breaking penalty on deviations of zero-cost resources from their day-ahead schedule.
#     # It only selects, among solutions with the same real cost, the one whose schedule is closest to
#     # the actual operation. It must be much smaller than any real cost: here 0.1 % of the cheapest generator.
    ε = 1e-4 * minimum(gen_cost[g][1] for g in G if gen_cost[g][1] > 0)
    G_renewable = vcat(G_wind, G_solar)

       VOLL     = 10000
    α,   β   = 1.1, 0.9     # generator redispatch multipliers
    α_H, β_H = 1.1, 0.9     # hydrogen redispatch multipliers



#     # Objective: first-stage cost (day-ahead schedule, commitment and procured reserve) + worst-case second-stage cost
#     m.ext[:objective] = @objective(m, Min,
#         # energy and no-load cost of the day-ahead schedule
#           sum(gen_cost[g][1] * pg_fs[g, t] + gen_cost[g][2] * zg_fs[g, t] for g in G, t in T)
#         # start-up costs
#         + sum(Estartupcost[e] * zesu_fs[e, t] for e in E, t in T)
#         + sum(start_up_cost[g] * betag_fs[g, t] for g in G, t in T)
#         # day-ahead hydrogen purchases minus sales
#         + sum(Hydrogencost[e] * baseKG * (hfgconsum_fs[e, t] - hfginyect_fs[e, t]) for e in E, t in T)
#         # procured FCR
#         + sum(Ereservecost[e] * r_proc_e_1[e, t] for e in E1, t in T) * baseMVA
#         + sum(Ereservecost[e] * r_proc_e_2[e, t] for e in E2, t in T) * baseMVA
#         + sum(Sreservecost[s] * r_proc_s_1[s, t] for s in S1, t in T) * baseMVA
#         + sum(Sreservecost[s] * r_proc_s_2[s, t] for s in S2, t in T) * baseMVA
#         + sum(G_reservecost[g] * r_proc_g_1[g, t] for g in G1, t in T) * baseMVA
#         + sum(G_reservecost[g] * r_proc_g_2[g, t] for g in G2, t in T) * baseMVA
#         # day-ahead load shedding
#         + sum((load_shed_1_fs[t] + load_shed_2_fs[t]) * VOLL for t in T) * baseMVA
#         # worst-case second-stage cost
#         + sigma)

#   # Second-stage cost of each wind scenario w: only deviations from the day-ahead schedule are paid
#     m.ext[:constraints][:cost_ss] = @constraint(m, [w = Wind_scenarios],
#         # generator redispatch
#           sum( α * gen_cost[g][1] * pg_ss_up[g, t, w]
#              - β * gen_cost[g][1] * pg_ss_dn[g, t, w] for g in G, t in T)
#         # hydrogen market deviations
#         + sum( Hydrogencost[e] * baseKG * (
#                  α_H * hfgconsum_ss_up[e, t, w]
#                - β_H * hfgconsum_ss_dn[e, t, w]
#                - β_H * hfginyect_ss_up[e, t, w]
#                + α_H * hfginyect_ss_dn[e, t, w] ) for e in E, t in T)
#         # real-time load shedding
#         + sum( VOLL * (load_shed_1_ss[t, w] + load_shed_2_ss[t, w]) for t in T) * baseMVA
#         # tie-breaking penalty: deviations of wind and solar from their day-ahead schedule
#         + sum( 1 * (pg_ss_up[g, t, w] + pg_ss_dn[g, t, w]) for g in G_renewable, t in T)
#         # tie-breaking penalty: deviations of the HVDC flow from its day-ahead schedule
#         + sum( 1 * (conv_p_ac_ss_up[cv, t, w] + conv_p_ac_ss_dn[cv, t, w]) for cv in CV, t in T)
#         <= sigma
#     )




    ρ = 1e-5    # weight of the expected second-stage cost: tie-breaker so that non-worst scenarios are also optimized

    # Second-stage cost of each wind scenario w (only deviations from the day-ahead schedule are paid).
    # Defined as an expression because it is used both in the sigma constraint and in the objective.
    cost_ss_expr = m.ext[:expressions][:cost_ss_expr] = @expression(m, [w = Wind_scenarios],
        # generator redispatch
          sum( α * gen_cost[g][1] * pg_ss_up[g, t, w]
             - β * gen_cost[g][1] * pg_ss_dn[g, t, w] for g in G, t in T)
        # hydrogen market deviations
        + sum( Hydrogencost[e] * baseKG * (
                 α_H * hfgconsum_ss_up[e, t, w]
               - β_H * hfgconsum_ss_dn[e, t, w]
               - β_H * hfginyect_ss_up[e, t, w]
               + α_H * hfginyect_ss_dn[e, t, w] ) for e in E, t in T)
        # real-time load shedding
        + sum( VOLL * (load_shed_1_ss[t, w] + load_shed_2_ss[t, w]) for t in T) * baseMVA
        # tie-breaking penalty: deviations of wind and solar from their day-ahead schedule
        + sum( 1 * (pg_ss_up[g, t, w] + pg_ss_dn[g, t, w]) for g in G_renewable, t in T)
        # tie-breaking penalty: deviations of the HVDC flow from its day-ahead schedule
        + sum( 1 * (conv_p_ac_ss_up[cv, t, w] + conv_p_ac_ss_dn[cv, t, w]) for cv in CV, t in T))

    # sigma = worst-case second-stage cost
    m.ext[:constraints][:cost_ss] = @constraint(m, [w = Wind_scenarios],
        cost_ss_expr[w] <= sigma)

    m.ext[:objective] = @objective(m, Min,
        # energy and no-load cost of the day-ahead schedule
          sum(gen_cost[g][1] * pg_fs[g, t] + gen_cost[g][2] * zg_fs[g, t] for g in G, t in T)
        # start-up costs
        + sum(Estartupcost[e] * zesu_fs[e, t] for e in E, t in T)
        + sum(start_up_cost[g] * betag_fs[g, t] for g in G, t in T)
        # day-ahead hydrogen purchases minus sales
        + sum(Hydrogencost[e] * baseKG * (hfgconsum_fs[e, t] - hfginyect_fs[e, t]) for e in E, t in T)
        # procured FCR
        + sum(Ereservecost[e] * r_proc_e_1[e, t] for e in E1, t in T) * baseMVA
        + sum(Ereservecost[e] * r_proc_e_2[e, t] for e in E2, t in T) * baseMVA
        + sum(Sreservecost[s] * r_proc_s_1[s, t] for s in S1, t in T) * baseMVA
        + sum(Sreservecost[s] * r_proc_s_2[s, t] for s in S2, t in T) * baseMVA
        + sum(G_reservecost[g] * r_proc_g_1[g, t] for g in G1, t in T) * baseMVA
        + sum(G_reservecost[g] * r_proc_g_2[g, t] for g in G2, t in T) * baseMVA
        # day-ahead load shedding
        + sum((load_shed_1_fs[t] + load_shed_2_fs[t]) * VOLL for t in T) * baseMVA
        # worst-case second-stage cost
        + sigma
        # small weight on the second-stage cost of every scenario (tie-breaker for the non-worst scenarios)
        + ρ * sum(cost_ss_expr[w] for w in Wind_scenarios))

    
    keys_contingency = collect(keys(all_contingencies))




    # Reserve constraints generators: procured reserve (first stage) must cover the reserve deployed in every contingency k and wind scenario w

        # Area 1
        m.ext[:constraints][:r_proc_g_1_bound_lg] = @constraint(m, [g=G1, t=T, k=fallos_g1, w=Wind_scenarios],
            r_proc_g_1[g,t] >= rg_lg1_ss[g,t,k,w])            # generator k of area 1 trips
        m.ext[:constraints][:r_proc_g_1_bound_lc] = @constraint(m, [g=G1, t=T, k=fallos_c1, w=Wind_scenarios],
            r_proc_g_1[g,t] >= rg_lc1_ss[g,t,k,w])            # converter k of area 1 trips
        m.ext[:constraints][:r_proc_g_1_bound_lreserve_g] = @constraint(m, [g=G1, t=T, k=fallos_g2, w=Wind_scenarios],
            r_proc_g_1[g,t] >= rg_l_reserve_1_g_ss[g,t,k,w])  # area 1 supports area 2 after generator k of area 2 trips
        m.ext[:constraints][:r_proc_g_1_bound_lreserve_c] = @constraint(m, [g=G1, t=T, k=fallos_c2, w=Wind_scenarios],
            r_proc_g_1[g,t] >= rg_l_reserve_1_c_ss[g,t,k,w])  # area 1 supports area 2 after converter k of area 2 trips

        # Area 2
        m.ext[:constraints][:r_proc_g_2_bound_lg] = @constraint(m, [g=G2, t=T, k=fallos_g2, w=Wind_scenarios],
            r_proc_g_2[g,t] >= rg_lg2_ss[g,t,k,w])            # generator k of area 2 trips
        m.ext[:constraints][:r_proc_g_2_bound_lc] = @constraint(m, [g=G2, t=T, k=fallos_c2, w=Wind_scenarios],
            r_proc_g_2[g,t] >= rg_lc2_ss[g,t,k,w])            # converter k of area 2 trips
        m.ext[:constraints][:r_proc_g_2_bound_lreserve_g] = @constraint(m, [g=G2, t=T, k=fallos_g1, w=Wind_scenarios],
            r_proc_g_2[g,t] >= rg_l_reserve_2_g_ss[g,t,k,w])  # area 2 supports area 1 after generator k of area 1 trips
        m.ext[:constraints][:r_proc_g_2_bound_lreserve_c] = @constraint(m, [g=G2, t=T, k=fallos_c1, w=Wind_scenarios],
            r_proc_g_2[g,t] >= rg_l_reserve_2_c_ss[g,t,k,w])  # area 2 supports area 1 after converter k of area 1 trips

    # Storage reserve constraints: procured reserve (first stage) must cover the reserve deployed in every contingency k and wind scenario w

    # Area 1
    m.ext[:constraints][:r_proc_s_1_bound_lg] = @constraint(m, [s=S1, t=T, k=fallos_g1, w=Wind_scenarios],
        r_proc_s_1[s,t] >= rs_lg1_ss[s,t,k,w])            # generator k of area 1 trips
    m.ext[:constraints][:r_proc_s_1_bound_lc] = @constraint(m, [s=S1, t=T, k=fallos_c1, w=Wind_scenarios],
        r_proc_s_1[s,t] >= rs_lc1_ss[s,t,k,w])            # converter k of area 1 trips
    m.ext[:constraints][:r_proc_s_1_bound_lreserve_g] = @constraint(m, [s=S1, t=T, k=fallos_g2, w=Wind_scenarios],
        r_proc_s_1[s,t] >= rs_l_reserve_1_g_ss[s,t,k,w])  # area 1 supports area 2 after generator k of area 2 trips
    m.ext[:constraints][:r_proc_s_1_bound_lreserve_c] = @constraint(m, [s=S1, t=T, k=fallos_c2, w=Wind_scenarios],
        r_proc_s_1[s,t] >= rs_l_reserve_1_c_ss[s,t,k,w])  # area 1 supports area 2 after converter k of area 2 trips

    # Area 2
    m.ext[:constraints][:r_proc_s_2_bound_lg] = @constraint(m, [s=S2, t=T, k=fallos_g2, w=Wind_scenarios],
        r_proc_s_2[s,t] >= rs_lg2_ss[s,t,k,w])            # generator k of area 2 trips
    m.ext[:constraints][:r_proc_s_2_bound_lc] = @constraint(m, [s=S2, t=T, k=fallos_c2, w=Wind_scenarios],
        r_proc_s_2[s,t] >= rs_lc2_ss[s,t,k,w])            # converter k of area 2 trips
    m.ext[:constraints][:r_proc_s_2_bound_lreserve_g] = @constraint(m, [s=S2, t=T, k=fallos_g1, w=Wind_scenarios],
        r_proc_s_2[s,t] >= rs_l_reserve_2_g_ss[s,t,k,w])  # area 2 supports area 1 after generator k of area 1 trips
    m.ext[:constraints][:r_proc_s_2_bound_lreserve_c] = @constraint(m, [s=S2, t=T, k=fallos_c1, w=Wind_scenarios],
        r_proc_s_2[s,t] >= rs_l_reserve_2_c_ss[s,t,k,w])  # area 2 supports area 1 after converter k of area 1 trips

    # Electrolyzer reserve constraints: procured reserve (first stage) must cover the reserve deployed in every contingency k and wind scenario w

    # Area 1
    m.ext[:constraints][:r_proc_e_1_bound_lg] = @constraint(m, [e=E1, t=T, k=fallos_g1, w=Wind_scenarios],
        r_proc_e_1[e,t] >= re_lg1_ss[e,t,k,w])            # generator k of area 1 trips
    m.ext[:constraints][:r_proc_e_1_bound_lc] = @constraint(m, [e=E1, t=T, k=fallos_c1, w=Wind_scenarios],
        r_proc_e_1[e,t] >= re_lc1_ss[e,t,k,w])            # converter k of area 1 trips
    m.ext[:constraints][:r_proc_e_1_bound_lreserve_g] = @constraint(m, [e=E1, t=T, k=fallos_g2, w=Wind_scenarios],
        r_proc_e_1[e,t] >= re_l_reserve_1_g_ss[e,t,k,w])  # area 1 supports area 2 after generator k of area 2 trips
    m.ext[:constraints][:r_proc_e_1_bound_lreserve_c] = @constraint(m, [e=E1, t=T, k=fallos_c2, w=Wind_scenarios],
        r_proc_e_1[e,t] >= re_l_reserve_1_c_ss[e,t,k,w])  # area 1 supports area 2 after converter k of area 2 trips

    # Area 2
    m.ext[:constraints][:r_proc_e_2_bound_lg] = @constraint(m, [e=E2, t=T, k=fallos_g2, w=Wind_scenarios],
        r_proc_e_2[e,t] >= re_lg2_ss[e,t,k,w])            # generator k of area 2 trips
    m.ext[:constraints][:r_proc_e_2_bound_lc] = @constraint(m, [e=E2, t=T, k=fallos_c2, w=Wind_scenarios],
        r_proc_e_2[e,t] >= re_lc2_ss[e,t,k,w])            # converter k of area 2 trips
    m.ext[:constraints][:r_proc_e_2_bound_lreserve_g] = @constraint(m, [e=E2, t=T, k=fallos_g1, w=Wind_scenarios],
        r_proc_e_2[e,t] >= re_l_reserve_2_g_ss[e,t,k,w])  # area 2 supports area 1 after generator k of area 1 trips
    m.ext[:constraints][:r_proc_e_2_bound_lreserve_c] = @constraint(m, [e=E2, t=T, k=fallos_c1, w=Wind_scenarios],
        r_proc_e_2[e,t] >= re_l_reserve_2_c_ss[e,t,k,w])  # area 2 supports area 1 after converter k of area 1 trips




        # Generation: first-stage schedule + second-stage adjustment (one actual dispatch per wind scenario w)
        m.ext[:constraints][:pg_fs_pg_ss_link] = @constraint(m, [g=G, t=T, w=Wind_scenarios],
            pg_ss[g,t,w] == pg_fs[g,t] + pg_ss_up[g,t,w] - pg_ss_dn[g,t,w])

        # Procured reserve must be deliverable on the actual operating point, in every wind realization
        m.ext[:constraints][:headroom_rproc_g1_ss] = @constraint(m, [g=G1, t=T, w=Wind_scenarios],
            pg_ss[g,t,w] + r_proc_g_1[g,t] <= pmax[g] * zg_fs[g,t])

        m.ext[:constraints][:headroom_rproc_g2_ss] = @constraint(m, [g=G2, t=T, w=Wind_scenarios],
            pg_ss[g,t,w] + r_proc_g_2[g,t] <= pmax[g] * zg_fs[g,t])






    # --- First stage: power balance of the day-ahead schedule (forecast wind) ---
    m.ext[:constraints][:power_balance_1_fs] = @constraint(m, [t=T],
        sum(pg_fs[g,t] for g in G1)
        - sum(p_charge_pump_fs[g,t] for g in G_pump_1)
        + sum(conv_p_ac_fs[cv,t] for cv in CV1)
        + sum(psd_fs[s,t] for s in S1) - sum(psc_fs[s,t] for s in S1)
        - sum(pe_fs[e,t] for e in E1) - sum(pe_compressor_fs[e,t] for e in E1)
        - demand["1"][t] + load_shed_1_fs[t]
        + solar_roof_pmax["1"] * capacity_factor_solar["Nordic"][t] == 0)

    m.ext[:constraints][:power_balance_2_fs] = @constraint(m, [t=T],
        sum(pg_fs[g,t] for g in G2)
        - sum(p_charge_pump_fs[g,t] for g in G_pump_2)
        + sum(conv_p_ac_fs[cv,t] for cv in CV2)
        + sum(psd_fs[s,t] for s in S2) - sum(psc_fs[s,t] for s in S2)
        - sum(pe_fs[e,t] for e in E2) - sum(pe_compressor_fs[e,t] for e in E2)
        - demand["2"][t] + load_shed_2_fs[t]
        + solar_roof_pmax["2"] * capacity_factor_solar["GB"][t] == 0)

    # --- Second stage: power balance of the actual operation in each wind scenario w (pre-contingency, same dispatch for all k) ---
    m.ext[:constraints][:power_balance_1_ss] = @constraint(m, [t=T, w=Wind_scenarios],
        sum(pg_ss[g,t,w] for g in G1)
        - sum(p_charge_pump_ss[g,t,w] for g in G_pump_1)
        + sum(conv_p_ac_ss[cv,t,w] for cv in CV1)
        + sum(psd_ss[s,t,w] for s in S1) - sum(psc_ss[s,t,w] for s in S1)
        - sum(pe_ss[e,t,w] for e in E1) - sum(pe_compressor_ss[e,t,w] for e in E1)
        - demand["1"][t] + load_shed_1_ss[t,w]
        + solar_roof_pmax["1"] * capacity_factor_solar["Nordic"][t] == 0)

    m.ext[:constraints][:power_balance_2_ss] = @constraint(m, [t=T, w=Wind_scenarios],
        sum(pg_ss[g,t,w] for g in G2)
        - sum(p_charge_pump_ss[g,t,w] for g in G_pump_2)
        + sum(conv_p_ac_ss[cv,t,w] for cv in CV2)
        + sum(psd_ss[s,t,w] for s in S2) - sum(psc_ss[s,t,w] for s in S2)
        - sum(pe_ss[e,t,w] for e in E2) - sum(pe_compressor_ss[e,t,w] for e in E2)
        - demand["2"][t] + load_shed_2_ss[t,w]
        + solar_roof_pmax["2"] * capacity_factor_solar["GB"][t] == 0)

        

    # --- First stage: load shedding cannot exceed demand in the day-ahead schedule ---
    m.ext[:constraints][:load_shed_1_limit_fs] = @constraint(m, [t=T],
        load_shed_1_fs[t] <= demand["1"][t])
    m.ext[:constraints][:load_shed_2_limit_fs] = @constraint(m, [t=T],
        load_shed_2_fs[t] <= demand["2"][t])

    # --- Second stage: load shedding cannot exceed demand in the actual operation of each wind scenario w ---
    m.ext[:constraints][:load_shed_1_limit_ss] = @constraint(m, [t=T, w=Wind_scenarios],
        load_shed_1_ss[t,w] <= demand["1"][t])
    m.ext[:constraints][:load_shed_2_limit_ss] = @constraint(m, [t=T, w=Wind_scenarios],
        load_shed_2_ss[t,w] <= demand["2"][t])



    # Reserve headroom (eq. 16): actual HVDC flow + HVDC reserve deployed after contingency k must stay within converter rating

    # Area 1
    m.ext[:constraints][:hvdc_headroom_lg1] = @constraint(m, [cv=CV1, t=T, k=fallos_g1, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,w] + rhvdc_lg1_ss[cv,t,k,w] <= conv_p_ac_max[cv])   # generator k of area 1 trips
    m.ext[:constraints][:hvdc_headroom_lc1] = @constraint(m, [cv=CV1, t=T, k=fallos_c1, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,w] + rhvdc_lc1_ss[cv,t,k,w] <= conv_p_ac_max[cv])   # converter k of area 1 trips

    # Area 2
    m.ext[:constraints][:hvdc_headroom_lg2] = @constraint(m, [cv=CV2, t=T, k=fallos_g2, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,w] + rhvdc_lg2_ss[cv,t,k,w] <= conv_p_ac_max[cv])   # generator k of area 2 trips
    m.ext[:constraints][:hvdc_headroom_lc2] = @constraint(m, [cv=CV2, t=T, k=fallos_c2, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,w] + rhvdc_lc2_ss[cv,t,k,w] <= conv_p_ac_max[cv])   # converter k of area 2 trips


       # ============================== FIRST STAGE (day-ahead schedule) ==============================
    m.ext[:constraints][:nodal_p_dc_balance_fs] = @constraint(m, [nd=ND, t=T],
        sum(conv_p_dc_fs[cv,t] for cv in CV if conv_busdc[cv] == nd)
        - sum(brdc_p_fs[(d,f,e),t] for (d,f,e) in ND_arcs[nd]) == 0)   # 3.14 DC nodal balance

    m.ext[:constraints][:conv_p_loss_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_fs[cv,t] + conv_p_dc_fs[cv,t] == 0)   # 3.17 lossless converter: AC side = - DC side

    m.ext[:constraints][:conv_injec_ac_abs_inj_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_fs[cv,t] == conv_p_ac_inj_fs[cv,t] - conv_p_ac_abs_fs[cv,t])   # injection (+) minus absorption (-)

    m.ext[:constraints][:direccional_flow_dc_fs] = @constraint(m, [(d,f,e)=BD_dc_fr, t=T],
        brdc_p_fs[(d,f,e),t] == -brdc_p_fs[(d,e,f),t])   # DC branch flow: from-to = - to-from

    m.ext[:constraints][:conv_injec_ac_limit_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_inj_fs[cv,t] <= conv_p_ac_max[cv] * u_conv_p_ac_fs[cv,t])        # injection only if u = 1
    m.ext[:constraints][:conv_abs_limit_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_abs_fs[cv,t] <= conv_p_ac_max[cv] * (1 - u_conv_p_ac_fs[cv,t]))  # absorption only if u = 0

    # ============================== SECOND STAGE (actual operation in each wind scenario w) =============================
    m.ext[:constraints][:nodal_p_dc_balance_ss] = @constraint(m, [nd=ND, t=T, w=Wind_scenarios],
        sum(conv_p_dc_ss[cv,t,w] for cv in CV if conv_busdc[cv] == nd)
        - sum(brdc_p_ss[(d,f,e),t,w] for (d,f,e) in ND_arcs[nd]) == 0)   # 3.14 DC nodal balance

    m.ext[:constraints][:conv_p_loss_ss] = @constraint(m, [cv=CV, t=T, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,w] + conv_p_dc_ss[cv,t,w] == 0)   # 3.17 lossless converter

    m.ext[:constraints][:conv_injec_ac_abs_inj_ss] = @constraint(m, [cv=CV, t=T, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,w] == conv_p_ac_inj_ss[cv,t,w] - conv_p_ac_abs_ss[cv,t,w])   # injection (+) minus absorption (-)

    m.ext[:constraints][:direccional_flow_dc_ss] = @constraint(m, [(d,f,e)=BD_dc_fr, t=T, w=Wind_scenarios],
        brdc_p_ss[(d,f,e),t,w] == -brdc_p_ss[(d,e,f),t,w])   # DC branch flow: from-to = - to-from

    m.ext[:constraints][:conv_injec_ac_limit_ss] = @constraint(m, [cv=CV, t=T, w=Wind_scenarios],
        conv_p_ac_inj_ss[cv,t,w] <= conv_p_ac_max[cv] * u_conv_p_ac_ss[cv,t,w])        # injection only if u = 1
    m.ext[:constraints][:conv_abs_limit_ss] = @constraint(m, [cv=CV, t=T, w=Wind_scenarios],
        conv_p_ac_abs_ss[cv,t,w] <= conv_p_ac_max[cv] * (1 - u_conv_p_ac_ss[cv,t,w]))  # absorption only if u = 0

    # ============================ LINK BETWEEN STAGES ========================
    m.ext[:constraints][:conv_p_ac_link] = @constraint(m, [cv=CV, t=T, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,w] == conv_p_ac_fs[cv,t] + conv_p_ac_ss_up[cv,t,w] - conv_p_ac_ss_dn[cv,t,w])   # actual flow = schedule + up - down

            # ======================= Solar generation limits =======================
    # Solar is deterministic: the same capacity factor applies in both stages

    # First stage: day-ahead schedule
    m.ext[:constraints][:solar_generation_1_fs] = @constraint(m, [g=G_solar_1, t=T],
        pg_fs[g,t] <= capacity_factor_solar["Nordic"][t] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:solar_generation_2_fs] = @constraint(m, [g=G_solar_2, t=T],
        pg_fs[g,t] <= capacity_factor_solar["GB"][t] * pmax[g])       # area 2 (GB)

    # Second stage: actual operation in each wind scenario w
    m.ext[:constraints][:solar_generation_1_ss] = @constraint(m, [g=G_solar_1, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] <= capacity_factor_solar["Nordic"][t] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:solar_generation_2_ss] = @constraint(m, [g=G_solar_2, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] <= capacity_factor_solar["GB"][t] * pmax[g])       # area 2 (GB)

    # ======================= Wind generation limits ========================

    # First stage: the day-ahead schedule cannot exceed the forecast wind availability
    m.ext[:constraints][:wind_generation_1_fs] = @constraint(m, [g=G_wind_1, t=T],
        pg_fs[g,t] <= capacity_factor_wind["Nordic"][t] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:wind_generation_2_fs] = @constraint(m, [g=G_wind_2, t=T],
        pg_fs[g,t] <= capacity_factor_wind["GB"][t] * pmax[g])       # area 2 (GB)

    # Second stage: the actual wind output cannot exceed the availability of each scenario w (high or low)
    m.ext[:constraints][:wind_generation_1_ss] = @constraint(m, [g=G_wind_1, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] <= capacity_factor_wind_w["Nordic"][t][w] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:wind_generation_2_ss] = @constraint(m, [g=G_wind_2, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] <= capacity_factor_wind_w["GB"][t][w] * pmax[g])       # area 2 (GB)

  


   
    # Renewable frequency reserve constraints: renewables do not provide FCR
    renewable_1 = vcat(G_solar_1, G_wind_1)
    renewable_2 = vcat(G_solar_2, G_wind_2)

    # No procured reserve from renewables (first stage).
    # Since r_proc_g >= rg_*_ss >= 0 for every k and w, this also forces all their deployed reserves (second stage) to zero.
    m.ext[:constraints][:renewable_r_proc_1] = @constraint(m, [g=renewable_1, t=T],
        r_proc_g_1[g,t] == 0)
    m.ext[:constraints][:renewable_r_proc_2] = @constraint(m, [g=renewable_2, t=T],
        r_proc_g_2[g,t] == 0)


        

    #On status of nuclear generators constraint
    m.ext[:constraints][:nuclear_status] = @constraint(m, [g=G_nuclear,t=T],
    zg_fs[g,t] == 1
    )

    
    # ===================== Unit commitment: generation limits (3.11) =====================

    # First stage: day-ahead schedule within the unit limits
    m.ext[:constraints][:max_gen_power_fs] = @constraint(m, [g=G, t=T],
        pg_fs[g,t] <= pmax[g] * zg_fs[g,t])
    m.ext[:constraints][:min_gen_power_fs] = @constraint(m, [g=G, t=T],
        pg_fs[g,t] >= pmin[g] * zg_fs[g,t])

    # Second stage: actual output within the unit limits in every wind scenario w (commitment fixed day-ahead)
    m.ext[:constraints][:max_gen_power_ss] = @constraint(m, [g=G, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] <= pmax[g] * zg_fs[g,t])
    m.ext[:constraints][:min_gen_power_ss] = @constraint(m, [g=G, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] >= pmin[g] * zg_fs[g,t])

    # ===================== Reserve headroom =====================

    # Second stage: the procured reserve must be deliverable on the actual operating point of each wind scenario w
    m.ext[:constraints][:headroom_rproc_g1_ss] = @constraint(m, [g=G1, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] + r_proc_g_1[g,t] <= pmax[g] * zg_fs[g,t])   # area 1
    m.ext[:constraints][:headroom_rproc_g2_ss] = @constraint(m, [g=G2, t=T, w=Wind_scenarios],
        pg_ss[g,t,w] + r_proc_g_2[g,t] <= pmax[g] * zg_fs[g,t])   # area 2

    # First stage (optional): the day-ahead schedule also leaves room for the procured reserve
    m.ext[:constraints][:headroom_rproc_g1_fs] = @constraint(m, [g=G1, t=T],
        pg_fs[g,t] + r_proc_g_1[g,t] <= pmax[g] * zg_fs[g,t])
    m.ext[:constraints][:headroom_rproc_g2_fs] = @constraint(m, [g=G2, t=T],
        pg_fs[g,t] + r_proc_g_2[g,t] <= pmax[g] * zg_fs[g,t])

    # =====================================================================
    #                     UNIT COMMITMENT CONSTRAINTS
    # =====================================================================
    # First stage : commitment logic (status, start-ups, shut-downs, minimum
    #               up/down times) and ramp limits on the day-ahead schedule pg_fs.
    # Second stage: ramp limits on the actual output pg_ss in every wind scenario w.
    #               The commitment is NOT repeated: start-ups and shut-downs are
    #               first-stage decisions, the same in all scenarios. The actual output
    #               does not depend on the contingency k (preventive N-1 dispatch).

    Tlabels = collect(T)         # ensure indexable by position
    NT = length(Tlabels)

    # ---------------------------------------------------------------------
    #                 RAMP LIMITS: FIRST STAGE (day-ahead schedule)
    # ---------------------------------------------------------------------
    # The day-ahead schedule must be physically feasible: between two consecutive
    # hours, the scheduled output cannot change more than the ramp rates.
    # Index: i = time index (position in Tlabels).

    # Ramp-down limit: the scheduled output cannot decrease by more than downramp.
    # If the unit shuts down at hour i, it may drop by an additional pmin to reach zero.
    m.ext[:constraints][:ramp_down_fs] = @constraint(m, [g in TG, i in 2:NT],
        pg_fs[g, Tlabels[i-1]] - pg_fs[g, Tlabels[i]] <= downramp[g] + pmin[g] * gammag_fs[g, Tlabels[i]])   # 3.20

    # Ramp-up limit: the scheduled output cannot increase by more than upramp.
    # If the unit starts up at hour i, the limit becomes pmin, so the unit starts at its minimum output.
    m.ext[:constraints][:ramp_up_fs] = @constraint(m, [g in TG, i in 2:NT],
        pg_fs[g, Tlabels[i]] - pg_fs[g, Tlabels[i-1]] <= upramp[g] + (pmin[g] - upramp[g]) * betag_fs[g, Tlabels[i]])   # 3.19

    # ---------------------------------------------------------------------
    #          RAMP LIMITS: SECOND STAGE (actual output in each wind scenario)
    # ---------------------------------------------------------------------
    # Once the wind scenario (high or low) is revealed, each generator follows an
    # actual 24-hour trajectory pg_ss, which must also respect the ramp rates.
    # Indices: i = time index, w = wind scenario.
    # Start-ups (betag_fs) and shut-downs (gammag_fs) come from the first stage.

    # Ramp-down limit on the actual output
    m.ext[:constraints][:ramp_down_ss] = @constraint(m, [g in TG, i in 2:NT, w in Wind_scenarios],
        pg_ss[g, Tlabels[i-1], w] - pg_ss[g, Tlabels[i], w] <= downramp[g] + pmin[g] * gammag_fs[g, Tlabels[i]])   # 3.20

    # Ramp-up limit on the actual output
    m.ext[:constraints][:ramp_up_ss] = @constraint(m, [g in TG, i in 2:NT, w in Wind_scenarios],
        pg_ss[g, Tlabels[i], w] - pg_ss[g, Tlabels[i-1], w] <= upramp[g] + (pmin[g] - upramp[g]) * betag_fs[g, Tlabels[i]])   # 3.19

    # Note: within each hour, the deviation of the actual output from the schedule is
    # limited by the bounds of the adjustment variables (in the variable definitions):
    #   0 <= pg_ss_up[g,t,w] <= upramp[g],   0 <= pg_ss_dn[g,t,w] <= downramp[g]
    # together with the link: pg_ss[g,t,w] == pg_fs[g,t] + pg_ss_up[g,t,w] - pg_ss_dn[g,t,w]

    # ---------------------------------------------------------------------
    #                 COMMITMENT LOGIC: FIRST STAGE ONLY
    # ---------------------------------------------------------------------
    # Which units are on, and when they start up or shut down, is decided the day
    # before and applies to every scenario. No second-stage version is needed.

    # Initial status: all units are assumed to be on before the first hour,
    # so any change at the first hour is recorded as a start-up or a shut-down.
    m.ext[:constraints][:up_and_down_3] = @constraint(m, [g in TG],
        1 - zg_fs[g, Tlabels[1]] + betag_fs[g, Tlabels[1]] - gammag_fs[g, Tlabels[1]] == 0)

    # Status transition: a change in status between two hours must be recorded
    # as a start-up (betag) or a shut-down (gammag).
    m.ext[:constraints][:up_and_down_4] = @constraint(m, [g in TG, i in 2:NT],
        zg_fs[g, Tlabels[i-1]] - zg_fs[g, Tlabels[i]] + betag_fs[g, Tlabels[i]] - gammag_fs[g, Tlabels[i]] == 0)   # 3.23

    # Start-up and shut-down exclusivity: a unit cannot start up and shut down in the same hour.
    m.ext[:constraints][:up_and_down_4_1] = @constraint(m, [g in TG, t in T],
        betag_fs[g,t] + gammag_fs[g,t] <= 1)

    # Minimum up time: once started, a unit must stay on for at least MUT hours.
    m.ext[:constraints][:up_and_down_6] = Dict()
    for g in TG
        if MUT[g] > 0  # only for units with a positive minimum up time
            for i in MUT[g]:NT
                m.ext[:constraints][:up_and_down_6][g, Tlabels[i]] = @constraint(m,
                    zg_fs[g, Tlabels[i]] >= sum(betag_fs[g, Tlabels[i-τ]] for τ in 0:MUT[g]-1))   # 3.22
            end
        end
    end

    # Minimum down time: once shut down, a unit must stay off for at least MDT hours.
    m.ext[:constraints][:up_and_down_7] = Dict()
    for g in TG
        if MDT[g] > 0  # only for units with a positive minimum down time
            for i in MDT[g]:NT
                m.ext[:constraints][:up_and_down_7][g, Tlabels[i]] = @constraint(m,
                    1 - zg_fs[g, Tlabels[i]] >= sum(gammag_fs[g, Tlabels[i-τ]] for τ in 0:MDT[g]-1))   # 3.21
            end
        end
    end

      # =====================================================================
    #                         STORAGE CONSTRAINTS
    # =====================================================================
    # First stage : battery schedule in the day-ahead plan (psc_fs, psd_fs, es_fs, zs_fs).
    # Second stage: actual battery operation in every wind scenario w
    #               (psc_ss, psd_ss, es_ss, zs_ss). The charging/discharging status zs can
    #               change between stages, so each stage has its own binary.
    #               The operation does not depend on the contingency k (preventive N-1 dispatch).

    # ---------------------------------------------------------------------
    #                            FIRST STAGE
    # ---------------------------------------------------------------------

    # Charging limit: the battery can only charge when it is not discharging (zs = 0)
    m.ext[:constraints][:upper_bound_storage_charging_fs] = @constraint(m, [s=S, t=T],
        psc_fs[s,t] <= Spmax[s] * (1 - zs_fs[s,t]))   # 3.25

    # Discharging limit: the battery can only discharge when zs = 1
    m.ext[:constraints][:upper_bound_storage_discharging_fs] = @constraint(m, [s=S, t=T],
        psd_fs[s,t] <= Spmax[s] * zs_fs[s,t])   # 3.26

    # Initial energy of the battery
    m.ext[:constraints][:initial_energy_value_fs] = @constraint(m, [s in S],
        es_fs[s, Tlabels[1]] == Senergyinitial[s])   # 3.27

    # Final energy of the battery: the last hour's charge/discharge must reach the required end energy
    m.ext[:constraints][:end_energy_value_fs] = @constraint(m, [s in S],
        Senergyend[s] - es_fs[s, Tlabels[NT]] ==
            Sefficiencycarga[s] * psc_fs[s, Tlabels[NT]] - psd_fs[s, Tlabels[NT]] / Sefficiencydischarge[s])   # 3.27

    # Energy balance between consecutive hours (i = time index)
    m.ext[:constraints][:energy_balance_fs] = @constraint(m, [s in S, i in 1:NT-1],
        es_fs[s, Tlabels[i+1]] - es_fs[s, Tlabels[i]] ==
            Sefficiencycarga[s] * psc_fs[s, Tlabels[i]] - psd_fs[s, Tlabels[i]] / Sefficiencydischarge[s])   # 3.27

    # ---------------------------------------------------------------------
    #                            SECOND STAGE
    # ---------------------------------------------------------------------
    # Same constraints on the actual battery operation, for every wind scenario w.
    # Each scenario must also start and end with the required energy.

    m.ext[:constraints][:upper_bound_storage_charging_ss] = @constraint(m, [s=S, t=T, w=Wind_scenarios],
        psc_ss[s,t,w] <= Spmax[s] * (1 - zs_ss[s,t,w]))   # 3.25

    m.ext[:constraints][:upper_bound_storage_discharging_ss] = @constraint(m, [s=S, t=T, w=Wind_scenarios],
        psd_ss[s,t,w] <= Spmax[s] * zs_ss[s,t,w])   # 3.26

    m.ext[:constraints][:initial_energy_value_ss] = @constraint(m, [s in S, w in Wind_scenarios],
        es_ss[s, Tlabels[1], w] == Senergyinitial[s])   # 3.27

    m.ext[:constraints][:end_energy_value_ss] = @constraint(m, [s in S, w in Wind_scenarios],
        Senergyend[s] - es_ss[s, Tlabels[NT], w] ==
            Sefficiencycarga[s] * psc_ss[s, Tlabels[NT], w] - psd_ss[s, Tlabels[NT], w] / Sefficiencydischarge[s])   # 3.27

    # i = time index, w = wind scenario
    m.ext[:constraints][:energy_balance_ss] = @constraint(m, [s in S, i in 1:NT-1, w in Wind_scenarios],
        es_ss[s, Tlabels[i+1], w] - es_ss[s, Tlabels[i], w] ==
            Sefficiencycarga[s] * psc_ss[s, Tlabels[i], w] - psd_ss[s, Tlabels[i], w] / Sefficiencydischarge[s])   # 3.27

    # ---------------------------------------------------------------------
    #                       LINK BETWEEN STAGES
    # ---------------------------------------------------------------------
    # The actual charging/discharging power equals the schedule plus the adjustment.
    # The energy and the status are not linked: they follow from the powers in each stage.

    m.ext[:constraints][:psc_link] = @constraint(m, [s=S, t=T, w=Wind_scenarios],
        psc_ss[s,t,w] == psc_fs[s,t] + psc_ss_up[s,t,w] - psc_ss_dn[s,t,w])

    m.ext[:constraints][:psd_link] = @constraint(m, [s=S, t=T, w=Wind_scenarios],
        psd_ss[s,t,w] == psd_fs[s,t] + psd_ss_up[s,t,w] - psd_ss_dn[s,t,w])



    # =====================================================================
    #                 RESERVOIR AND PUMPED-STORAGE CONSTRAINTS
    # =====================================================================
    # First stage : schedule of reservoirs and pumped-storage units (e_*_fs, pg_fs, p_charge_pump_fs).
    # Second stage: actual operation in every wind scenario w (e_*_ss, pg_ss, p_charge_pump_ss).
    #               The operation does not depend on the contingency k (preventive N-1 dispatch).
    # The operating mode (generating or pumping) is given by the first-stage commitment zg_fs.
    # Index i = time index (position in Tlabels); w = wind scenario.

    # ---------------------------------------------------------------------
    #                       RESERVOIRS: FIRST STAGE
    # ---------------------------------------------------------------------

    # Initial energy stored in the reservoir
    m.ext[:constraints][:initial_energy_value_reservoir_fs] = @constraint(m, [g in G_reservoir],
        e_reservoir_fs[g, Tlabels[1]] == E_reservoirs_ini[g])

    # Final energy: after the last hour's generation, the reservoir must keep at least the required end energy
    m.ext[:constraints][:end_energy_value_reservoir_fs] = @constraint(m, [g in G_reservoir],
        E_reservoirs_end[g] <= e_reservoir_fs[g, Tlabels[NT]] - pg_fs[g, Tlabels[NT]] / G_ngenerating[g])

    # Energy balance: the stored energy decreases with the water used for generation
    m.ext[:constraints][:transition_energy_value_reservoir_fs] = @constraint(m, [g in G_reservoir, i in 1:NT-1],
        e_reservoir_fs[g, Tlabels[i+1]] == e_reservoir_fs[g, Tlabels[i]] - pg_fs[g, Tlabels[i]] / G_ngenerating[g])

    # ---------------------------------------------------------------------
    #                       RESERVOIRS: SECOND STAGE
    # ---------------------------------------------------------------------
    # Same constraints on the actual reservoir operation, one trajectory per wind scenario w.

    m.ext[:constraints][:initial_energy_value_reservoir_ss] = @constraint(m, [g in G_reservoir, w in Wind_scenarios],
        e_reservoir_ss[g, Tlabels[1], w] == E_reservoirs_ini[g])

    m.ext[:constraints][:end_energy_value_reservoir_ss] = @constraint(m, [g in G_reservoir, w in Wind_scenarios],
        E_reservoirs_end[g] <= e_reservoir_ss[g, Tlabels[NT], w] - pg_ss[g, Tlabels[NT], w] / G_ngenerating[g])

    m.ext[:constraints][:transition_energy_value_reservoir_ss] = @constraint(m, [g in G_reservoir, i in 1:NT-1, w in Wind_scenarios],
        e_reservoir_ss[g, Tlabels[i+1], w] == e_reservoir_ss[g, Tlabels[i], w] - pg_ss[g, Tlabels[i], w] / G_ngenerating[g])

       # ---------------------------------------------------------------------
    #                    PUMPED STORAGE: FIRST STAGE
    # ---------------------------------------------------------------------
    # -P_pump is used because the pumping power is given as a negative value in the input data.

    # Maximum pumping power: the unit can only pump when it is not generating (zg = 0)
    m.ext[:constraints][:upper_bound_pump_charging_fs] = @constraint(m, [g=G_pump, t=T],
        p_charge_pump_fs[g,t] <= (-P_pump[g]) * (1 - zg_fs[g,t]))

    # Minimum pumping power: assumed as 10% of the maximum pumping power when pumping
    m.ext[:constraints][:lower_bound_pump_charging_fs] = @constraint(m, [g=G_pump, t=T],
        p_charge_pump_fs[g,t] >= 0.1 * (-P_pump[g]) * (1 - zg_fs[g,t]))

    # Initial energy stored in the upper reservoir
    m.ext[:constraints][:initial_energy_value_pump_fs] = @constraint(m, [g in G_pump],
        e_pump_fs[g, Tlabels[1]] == E_reservoirs_ini[g])

    # Final energy: the last hour's pumping and generation must reach the required end energy
    m.ext[:constraints][:end_energy_value_pump_fs] = @constraint(m, [g in G_pump],
        E_reservoirs_end[g] == e_pump_fs[g, Tlabels[NT]]
            + p_charge_pump_fs[g, Tlabels[NT]] * G_npumping[g] - pg_fs[g, Tlabels[NT]] / G_ngenerating[g])

    # Energy balance: pumping fills the reservoir, generation empties it
    m.ext[:constraints][:energy_balance_pump_fs] = @constraint(m, [g in G_pump, i in 1:NT-1],
        e_pump_fs[g, Tlabels[i+1]] == e_pump_fs[g, Tlabels[i]]
            + p_charge_pump_fs[g, Tlabels[i]] * G_npumping[g] - pg_fs[g, Tlabels[i]] / G_ngenerating[g])

    # ---------------------------------------------------------------------
    #                    PUMPED STORAGE: SECOND STAGE
    # ---------------------------------------------------------------------
    # Same constraints on the actual operation, one trajectory per wind scenario w.
    # The mode (pumping or generating) is fixed by the first-stage commitment zg_fs.

    m.ext[:constraints][:upper_bound_pump_charging_ss] = @constraint(m, [g=G_pump, t=T, w=Wind_scenarios],
        p_charge_pump_ss[g,t,w] <= (-P_pump[g]) * (1 - zg_fs[g,t]))

    m.ext[:constraints][:lower_bound_pump_charging_ss] = @constraint(m, [g=G_pump, t=T, w=Wind_scenarios],
        p_charge_pump_ss[g,t,w] >= 0.1 * (-P_pump[g]) * (1 - zg_fs[g,t]))

    m.ext[:constraints][:initial_energy_value_pump_ss] = @constraint(m, [g in G_pump, w in Wind_scenarios],
        e_pump_ss[g, Tlabels[1], w] == E_reservoirs_ini[g])

    m.ext[:constraints][:end_energy_value_pump_ss] = @constraint(m, [g in G_pump, w in Wind_scenarios],
        E_reservoirs_end[g] == e_pump_ss[g, Tlabels[NT], w]
            + p_charge_pump_ss[g, Tlabels[NT], w] * G_npumping[g] - pg_ss[g, Tlabels[NT], w] / G_ngenerating[g])

    m.ext[:constraints][:energy_balance_pump_ss] = @constraint(m, [g in G_pump, i in 1:NT-1, w in Wind_scenarios],
        e_pump_ss[g, Tlabels[i+1], w] == e_pump_ss[g, Tlabels[i], w]
            + p_charge_pump_ss[g, Tlabels[i], w] * G_npumping[g] - pg_ss[g, Tlabels[i], w] / G_ngenerating[g])

    # ---------------------------------------------------------------------
    #                       LINK BETWEEN STAGES
    # ---------------------------------------------------------------------
    # The actual pumping power equals the schedule plus the adjustment.
    # The generating side is already linked through pg_ss = pg_fs + pg_ss_up - pg_ss_dn.

    m.ext[:constraints][:p_charge_pump_link] = @constraint(m, [g=G_pump, t=T, w=Wind_scenarios],
        p_charge_pump_ss[g,t,w] == p_charge_pump_fs[g,t] + p_charge_pump_ss_up[g,t,w] - p_charge_pump_ss_dn[g,t,w])

        


          # =====================================================================
    #                       ELECTROLYZER CONSTRAINTS
    # =====================================================================
    # First stage : on/off, start-up and standby status (ze_fs, zesu_fs, zestb_fs), and the
    #               day-ahead schedule of power, hydrogen production, trade and storage.
    # Second stage: actual power, production, trade and storage in every wind scenario w.
    #               The status variables come from the first stage.

    # ---------------------------------------------------------------------
    #                  STATUS LOGIC ELECTROLYZER: FIRST STAGE ONLY
    # ---------------------------------------------------------------------

    # Start-up at the first hour (initial state assumed: on = 1, standby = 0)
    m.ext[:constraints][:e_status_ini] = @constraint(m, [e in E],
        zesu_fs[e, Tlabels[1]] >= (ze_fs[e, Tlabels[1]] - 1) + (zestb_fs[e, Tlabels[1]] - 0))

    # Start-up in subsequent hours: counted when the unit switches on or into standby (eq. 38)
    m.ext[:constraints][:e_status_subsequent] = @constraint(m, [e in E, i in 2:NT],
        zesu_fs[e, Tlabels[i]] >= (ze_fs[e, Tlabels[i]] - ze_fs[e, Tlabels[i-1]]) +
                                (zestb_fs[e, Tlabels[i]] - zestb_fs[e, Tlabels[i-1]]))

    # The electrolyzer cannot be on and in standby at the same time (eq. 37)
    m.ext[:constraints][:e_standby] = @constraint(m, [e=E, t=T],
        zestb_fs[e,t] + ze_fs[e,t] <= 1)
    # ---------------------------------------------------------------------
    #                            FIRST STAGE
    # ---------------------------------------------------------------------

    # Hydrogen production: power above the standby consumption, divided by the efficiency
    m.ext[:constraints][:hydrogen_production_fs] = @constraint(m, [e in E, t in T],
        hfe_fs[e,t] == pe_fs[e,t] / Eefficiency[e] - 0.05 * Epmax[e] * zestb_fs[e,t] / Eefficiency[e])

    # Power bounds considering standby (standby consumption = 5% of the maximum power)
    m.ext[:constraints][:e_lower_bound_fs] = @constraint(m, [e=E, t=T],
        pe_fs[e,t] >= Epmin[e] * ze_fs[e,t] + 0.05 * Epmax[e] * zestb_fs[e,t])
    m.ext[:constraints][:e_upper_bound_fs] = @constraint(m, [e=E, t=T],
        pe_fs[e,t] <= Epmax[e] * ze_fs[e,t] + 0.05 * Epmax[e] * zestb_fs[e,t])

    # Initial hydrogen storage
    m.ext[:constraints][:initial_hydrogen_value_fs] = @constraint(m, [e in E],
        hss_fs[e, Tlabels[1]] == Estorageinitial[e])

    # Final hydrogen storage: the last hour's production, trade and demand must reach the end value
    m.ext[:constraints][:end_hydrogen_value_fs] = @constraint(m, [e in E],
        Estorageend[e] == hss_fs[e, Tlabels[NT]] + hfe_fs[e, Tlabels[NT]]
            - hfginyect_fs[e, Tlabels[NT]] / Eeficiencycarga[e]
            + hfgconsum_fs[e, Tlabels[NT]] * Eeficiencydischarge[e]
            - Eloadfactor[e] * Epmax[e] / Eefficiency[e])

    # Hydrogen storage balance between consecutive hours
    m.ext[:constraints][:charging_discharging_hydrogen_fs] = @constraint(m, [e in E, i in 1:NT-1],
        hss_fs[e, Tlabels[i+1]] == hss_fs[e, Tlabels[i]] + hfe_fs[e, Tlabels[i]]
            - hfginyect_fs[e, Tlabels[i]] / Eeficiencycarga[e]
            + hfgconsum_fs[e, Tlabels[i]] * Eeficiencydischarge[e]
            - Eloadfactor[e] * Epmax[e] / Eefficiency[e])

    # Compressor power: proportional to the hydrogen produced, purchased and sold
    m.ext[:constraints][:compressor_power_fs] = @constraint(m, [e in E, t in T],
        pe_compressor_fs[e,t] == Ecompressorpower[e] * (hfe_fs[e,t] + hfgconsum_fs[e,t] + hfginyect_fs[e,t]))

    # ---------------------------------------------------------------------
    #                            SECOND STAGE
    # ---------------------------------------------------------------------
    # Same constraints on the actual operation, one trajectory per wind scenario w,
    # with the first-stage status variables.

    m.ext[:constraints][:hydrogen_production_ss] = @constraint(m, [e in E, t in T, w in Wind_scenarios],
        hfe_ss[e,t,w] == pe_ss[e,t,w] / Eefficiency[e] - 0.05 * Epmax[e] * zestb_fs[e,t] / Eefficiency[e])

    m.ext[:constraints][:e_lower_bound_ss] = @constraint(m, [e=E, t=T, w=Wind_scenarios],
        pe_ss[e,t,w] >= Epmin[e] * ze_fs[e,t] + 0.05 * Epmax[e] * zestb_fs[e,t])
    m.ext[:constraints][:e_upper_bound_ss] = @constraint(m, [e=E, t=T, w=Wind_scenarios],
        pe_ss[e,t,w] <= Epmax[e] * ze_fs[e,t] + 0.05 * Epmax[e] * zestb_fs[e,t])

    m.ext[:constraints][:initial_hydrogen_value_ss] = @constraint(m, [e in E, w in Wind_scenarios],
        hss_ss[e, Tlabels[1], w] == Estorageinitial[e])

    m.ext[:constraints][:end_hydrogen_value_ss] = @constraint(m, [e in E, w in Wind_scenarios],
        Estorageend[e] == hss_ss[e, Tlabels[NT], w] + hfe_ss[e, Tlabels[NT], w]
            - hfginyect_ss[e, Tlabels[NT], w] / Eeficiencycarga[e]
            + hfgconsum_ss[e, Tlabels[NT], w] * Eeficiencydischarge[e]
            - Eloadfactor[e] * Epmax[e] / Eefficiency[e])

    m.ext[:constraints][:charging_discharging_hydrogen_ss] = @constraint(m, [e in E, i in 1:NT-1, w in Wind_scenarios],
        hss_ss[e, Tlabels[i+1], w] == hss_ss[e, Tlabels[i], w] + hfe_ss[e, Tlabels[i], w]
            - hfginyect_ss[e, Tlabels[i], w] / Eeficiencycarga[e]
            + hfgconsum_ss[e, Tlabels[i], w] * Eeficiencydischarge[e]
            - Eloadfactor[e] * Epmax[e] / Eefficiency[e])

    m.ext[:constraints][:compressor_power_ss] = @constraint(m, [e in E, t in T, w in Wind_scenarios],
        pe_compressor_ss[e,t,w] == Ecompressorpower[e] * (hfe_ss[e,t,w] + hfgconsum_ss[e,t,w] + hfginyect_ss[e,t,w]))

    # ---------------------------------------------------------------------
    #                       LINKS BETWEEN STAGES
    # ---------------------------------------------------------------------
    # Only the decisions taken directly by the operator are linked: electrolyzer power and
    # hydrogen trade. Production, storage and compressor power follow from them in each stage.

    # Electrolyzer power: schedule plus adjustment
    m.ext[:constraints][:pe_link] = @constraint(m, [e=E, t=T, w=Wind_scenarios],
        pe_ss[e,t,w] == pe_fs[e,t] + pe_ss_up[e,t,w] - pe_ss_dn[e,t,w])

    # Hydrogen purchased (consumed from the grid): schedule plus adjustment
    m.ext[:constraints][:hfgconsum_link] = @constraint(m, [e=E, t=T, w=Wind_scenarios],
        hfgconsum_ss[e,t,w] == hfgconsum_fs[e,t] + hfgconsum_ss_up[e,t,w] - hfgconsum_ss_dn[e,t,w])

    # Hydrogen sold (injected to the grid): schedule plus adjustment
    m.ext[:constraints][:hfginyect_link] = @constraint(m, [e=E, t=T, w=Wind_scenarios],
        hfginyect_ss[e,t,w] == hfginyect_fs[e,t] + hfginyect_ss_up[e,t,w] - hfginyect_ss_dn[e,t,w])
   


    # Power lost when generator k trips = its actual output in wind scenario w (one leaf per k and w)
    m.ext[:constraints][:gen_constraint_1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        plg1_ss[t,k,w] == pg_ss[k,t,w])   # area 1
    m.ext[:constraints][:gen_constraint_2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        plg2_ss[t,k,w] == pg_ss[k,t,w])   # area 2

    # Events constraints (loss of converters): power lost when converter k trips = its actual AC injection in wind scenario w
    m.ext[:constraints][:conv_constraint_1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        plc1_ss[t,k,w] == conv_p_ac_inj_ss[k,t,w])   # area 1
    m.ext[:constraints][:conv_constraint_2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        plc2_ss[t,k,w] == conv_p_ac_inj_ss[k,t,w])   # area 2



    # Event constraint (frequency reserve provision): when an element of the other area trips, the HVDC reserve
    # sent to that area is power withdrawn from this area, which creates an imbalance here.

    # Area 1 imbalance: area 1 supports area 2 through the converters of area 2
    m.ext[:constraints][:loss_of_power_frequency_reserve_G_A_1] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        plreserve_1_g_ss[t,k,w] == sum(rhvdc_lg2_ss[cv,t,k,w] for cv in CV2))   # generator k of area 2 trips
    m.ext[:constraints][:loss_of_power_frequency_reserve_C_A_1] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        plreserve_1_c_ss[t,k,w] == sum(rhvdc_lc2_ss[cv,t,k,w] for cv in CV2))   # converter k of area 2 trips

    # Area 2 imbalance: area 2 supports area 1 through the converters of area 1
    m.ext[:constraints][:loss_of_power_frequency_reserve_G_A_2] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        plreserve_2_g_ss[t,k,w] == sum(rhvdc_lg1_ss[cv,t,k,w] for cv in CV1))   # generator k of area 1 trips
    m.ext[:constraints][:loss_of_power_frequency_reserve_C_A_2] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        plreserve_2_c_ss[t,k,w] == sum(rhvdc_lc1_ss[cv,t,k,w] for cv in CV1))   # converter k of area 1 trips
    




    # Inertia available in each area after the event (depends only on first-stage commitment, not on wind scenario w)

    # Generator loss: the tripped generator k also loses its inertia
    Inertia_nadir_frequency_1 = m.ext[:expressions][:Inertia_nadir_frequency_1] = @expression(m, [t=T, k=fallos_g1],
        sum(zg_fs[g,t] * ic[g] * pmax[g] for g in G1) - zg_fs[k,t] * ic[k] * pmax[k])
    Inertia_nadir_frequency_2 = m.ext[:expressions][:Inertia_nadir_frequency_2] = @expression(m, [t=T, k=fallos_g2],
        sum(zg_fs[g,t] * ic[g] * pmax[g] for g in G2) - zg_fs[k,t] * ic[k] * pmax[k])

    # Converter loss (and HVDC reserve provision): no synchronous machine is lost, full inertia of the area
    Inertia_nadir_frequency_converter_1 = m.ext[:expressions][:Inertia_nadir_frequency_converter_1] = @expression(m, [t=T],
        sum(zg_fs[g,t] * ic[g] * pmax[g] for g in G1))
    Inertia_nadir_frequency_converter_2 = m.ext[:expressions][:Inertia_nadir_frequency_converter_2] = @expression(m, [t=T],
        sum(zg_fs[g,t] * ic[g] * pmax[g] for g in G2))
    

    # The tripped generator cannot provide FCR in its own contingency (replaces the (1 - δg) factor)
    m.ext[:constraints][:fcr_bound_gen_lg1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        rg_lg1_ss[k,t,k,w] == 0)   # area 1
    m.ext[:constraints][:fcr_bound_gen_lg2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        rg_lg2_ss[k,t,k,w] == 0)   # area 2



    # The tripped converter cannot provide HVDC reserve in its own contingency (replaces the (1 - δhvdc) factor).
    # rhvdc_lc1_ss[cv,t,k,w]: 1st index cv = converter providing reserve, 3rd index k = converter that trips.
    # Writing k in both positions selects only the diagonal (cv == k): the tripped converter's own reserve is zero,
    # while the reserves of all other converters in that contingency remain free.
    m.ext[:constraints][:fcr_bound_conv_lc1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        rhvdc_lc1_ss[k,t,k,w] == 0)   # area 1
    m.ext[:constraints][:fcr_bound_conv_lc2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        rhvdc_lc2_ss[k,t,k,w] == 0)   # area 2

        
    # Storage reserve headroom: the procured reserve (first stage) must be fully deliverable on the actual
    # operating point of every wind scenario w (high and low). The battery can stop charging and discharge up to Spmax.
    # Since rs_*_ss <= r_proc_s for every contingency k, this also bounds all deployed reserves.
    m.ext[:constraints][:headroom_rproc_s1_ss] = @constraint(m, [s=S1, t=T, w=Wind_scenarios],
        r_proc_s_1[s,t] <= Spmax[s] + psc_ss[s,t,w] - psd_ss[s,t,w])   # area 1
    m.ext[:constraints][:headroom_rproc_s2_ss] = @constraint(m, [s=S2, t=T, w=Wind_scenarios],
        r_proc_s_2[s,t] <= Spmax[s] + psc_ss[s,t,w] - psd_ss[s,t,w])   # area 2


    # Electrolyzer reserve headroom: the procured reserve (first stage) must be fully deliverable on the actual
    # operating point of every wind scenario w (high and low). The electrolyzer provides FCR by reducing its
    # consumption, down to its minimum (Epmin if on, 5% of Epmax if in standby).
    # Since re_*_ss <= r_proc_e for every contingency k, this also bounds all deployed reserves.
    m.ext[:constraints][:headroom_rproc_e1_ss] = @constraint(m, [e=E1, t=T, w=Wind_scenarios],
        r_proc_e_1[e,t] <= pe_ss[e,t,w] - Epmin[e] * ze_fs[e,t] - 0.05 * Epmax[e] * zestb_fs[e,t])   # area 1
    m.ext[:constraints][:headroom_rproc_e2_ss] = @constraint(m, [e=E2, t=T, w=Wind_scenarios],
        r_proc_e_2[e,t] <= pe_ss[e,t,w] - Epmin[e] * ze_fs[e,t] - 0.05 * Epmax[e] * zestb_fs[e,t])   # area 2

        
    # Reserve bound: the FCR capability of each generator (MaxFreqDev) limits its procured reserve,
    # and only committed units can provide it. Applied to the procured reserve (first stage);
    # since rg_*_ss <= r_proc_g for every contingency k and wind scenario w, it also bounds all deployed reserves.
    m.ext[:constraints][:reserve_bound_r_proc_g1] = @constraint(m, [g=G1, t=T],
        r_proc_g_1[g,t] <= MaxFreqDev[g] * zg_fs[g,t])   # area 1
    m.ext[:constraints][:reserve_bound_r_proc_g2] = @constraint(m, [g=G2, t=T],
        r_proc_g_2[g,t] <= MaxFreqDev[g] * zg_fs[g,t])   # area 2
    

   



    # RoCoF constraints per area and type of contingency, in every contingency k and wind scenario w:
    # the initial rate of change of frequency after losing power pl must stay below the limit rocof.
    # The loss depends on the actual operation (k, w); the inertia only on the first-stage commitment.

    # Area 1
    m.ext[:constraints][:rocof_constraint_plg_1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        f1 * plg1_ss[t,k,w] <= rocof1 * (2 * Inertia_nadir_frequency_1[t,k]))                     # generator k of area 1 trips (its inertia is lost too)
    m.ext[:constraints][:rocof_constraint_plc_1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        f1 * plc1_ss[t,k,w] <= rocof1 * (2 * Inertia_nadir_frequency_converter_1[t]))             # converter k of area 1 trips (full inertia)
    m.ext[:constraints][:rocof_constraint_plreserve_1_g] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        f1 * plreserve_1_g_ss[t,k,w] <= rocof1 * (2 * Inertia_nadir_frequency_converter_1[t]))    # area 1 supports area 2 after generator k of area 2 trips
    m.ext[:constraints][:rocof_constraint_plreserve_1_c] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        f1 * plreserve_1_c_ss[t,k,w] <= rocof1 * (2 * Inertia_nadir_frequency_converter_1[t]))    # area 1 supports area 2 after converter k of area 2 trips

    # Area 2
    m.ext[:constraints][:rocof_constraint_plg_2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        f2 * plg2_ss[t,k,w] <= rocof2 * (2 * Inertia_nadir_frequency_2[t,k]))                     # generator k of area 2 trips (its inertia is lost too)
    m.ext[:constraints][:rocof_constraint_plc_2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        f2 * plc2_ss[t,k,w] <= rocof2 * (2 * Inertia_nadir_frequency_converter_2[t]))             # converter k of area 2 trips (full inertia)
    m.ext[:constraints][:rocof_constraint_plreserve_2_g] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        f2 * plreserve_2_g_ss[t,k,w] <= rocof2 * (2 * Inertia_nadir_frequency_converter_2[t]))    # area 2 supports area 1 after generator k of area 1 trips
    m.ext[:constraints][:rocof_constraint_plreserve_2_c] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        f2 * plreserve_2_c_ss[t,k,w] <= rocof2 * (2 * Inertia_nadir_frequency_converter_2[t]))    # area 2 supports area 1 after converter k of area 1 trips

    # Quasi-steady-state power balance after each contingency k in every wind scenario w:
    # the FCR deployed in the area (storage + electrolyzers + generators + HVDC support) must cover the power lost.
    # Only assets that remain connected contribute, which is enforced by other constraints:
    #   - the tripped generator cannot provide reserve to itself: rg_lg1_ss[k,t,k,w] == 0 (same for area 2)
    #   - the tripped converter cannot provide HVDC reserve:      rhvdc_lc1_ss[k,t,k,w] == 0 (same for area 2)
    # Area 1
    m.ext[:constraints][:power_balance_lg1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        sum(rs_lg1_ss[s,t,k,w] for s in S1) + sum(re_lg1_ss[e,t,k,w] for e in E1)
        + sum(rg_lg1_ss[g,t,k,w] for g in G1) + sum(rhvdc_lg1_ss[cv,t,k,w] for cv in CV1)
        >= plg1_ss[t,k,w])                                                    # generator k of area 1 trips
    m.ext[:constraints][:power_balance_lc1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        sum(rs_lc1_ss[s,t,k,w] for s in S1) + sum(re_lc1_ss[e,t,k,w] for e in E1)
        + sum(rg_lc1_ss[g,t,k,w] for g in G1) + sum(rhvdc_lc1_ss[cv,t,k,w] for cv in CV1)
        >= plc1_ss[t,k,w])                                                    # converter k of area 1 trips
    m.ext[:constraints][:power_balance_lreserve_1_g] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        sum(rs_l_reserve_1_g_ss[s,t,k,w] for s in S1) + sum(re_l_reserve_1_g_ss[e,t,k,w] for e in E1)
        + sum(rg_l_reserve_1_g_ss[g,t,k,w] for g in G1)
        >= plreserve_1_g_ss[t,k,w])                                           # area 1 supports area 2 after generator k of area 2 trips
    m.ext[:constraints][:power_balance_lreserve_1_c] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        sum(rs_l_reserve_1_c_ss[s,t,k,w] for s in S1) + sum(re_l_reserve_1_c_ss[e,t,k,w] for e in E1)
        + sum(rg_l_reserve_1_c_ss[g,t,k,w] for g in G1)
        >= plreserve_1_c_ss[t,k,w])                                           # area 1 supports area 2 after converter k of area 2 trips

    # Area 2
    m.ext[:constraints][:power_balance_lg2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        sum(rs_lg2_ss[s,t,k,w] for s in S2) + sum(re_lg2_ss[e,t,k,w] for e in E2)
        + sum(rg_lg2_ss[g,t,k,w] for g in G2) + sum(rhvdc_lg2_ss[cv,t,k,w] for cv in CV2)
        >= plg2_ss[t,k,w])                                                    # generator k of area 2 trips
    m.ext[:constraints][:power_balance_lc2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        sum(rs_lc2_ss[s,t,k,w] for s in S2) + sum(re_lc2_ss[e,t,k,w] for e in E2)
        + sum(rg_lc2_ss[g,t,k,w] for g in G2) + sum(rhvdc_lc2_ss[cv,t,k,w] for cv in CV2)
        >= plc2_ss[t,k,w])                                                    # converter k of area 2 trips
    m.ext[:constraints][:power_balance_lreserve_2_g] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        sum(rs_l_reserve_2_g_ss[s,t,k,w] for s in S2) + sum(re_l_reserve_2_g_ss[e,t,k,w] for e in E2)
        + sum(rg_l_reserve_2_g_ss[g,t,k,w] for g in G2)
        >= plreserve_2_g_ss[t,k,w])                                           # area 2 supports area 1 after generator k of area 1 trips
    m.ext[:constraints][:power_balance_lreserve_2_c] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        sum(rs_l_reserve_2_c_ss[s,t,k,w] for s in S2) + sum(re_l_reserve_2_c_ss[e,t,k,w] for e in E2)
        + sum(rg_l_reserve_2_c_ss[g,t,k,w] for g in G2)
        >= plreserve_2_c_ss[t,k,w])                                           # area 2 supports area 1 after converter k of area 1 trips



    # =====================================================================
    #                    FREQUENCY NADIR CONSTRAINTS
    # =====================================================================
    # One rotated second-order cone per contingency k and wind scenario w (Badesa nadir formulation):
    #   y = 2*Δf*H/f - (fast reserves weighted by deployment time)/2
    #   z = sum of generator reserves / delivery time
    #   [y; z; P_loss - fast reserves] in RotatedSecondOrderCone()   ->   2*y*z >= (P_loss - fast reserves)^2
    # Inertia depends only on the first-stage commitment: [t,k] for generator loss, [t] otherwise.

    # ----------------------------- AREA 1 --------------------------------

    # Generator k of area 1 trips
    m.ext[:constraints][:nadir_frequency_g_1_constraint_1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        ypg1_ss[t,k,w] == 2*deltaf1*Inertia_nadir_frequency_1[t,k]/f1
            - sum(re_lg1_ss[e,t,k,w]*Edeployment[e] for e in E1)/2
            - sum(rs_lg1_ss[s,t,k,w]*Sdeployment[s] for s in S1)/2
            - sum(rhvdc_lg1_ss[cv,t,k,w]*HVDC_deployment[cv] for cv in CV1)/2)
    m.ext[:constraints][:nadir_frequency_g_1_constraint_2] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        zpg1_ss[t,k,w] == sum(rg_lg1_ss[g,t,k,w]/G_dt[g] for g in G1))
    m.ext[:constraints][:nadir_frequency_g_1_constraint_3] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        [ypg1_ss[t,k,w]; zpg1_ss[t,k,w];
         plg1_ss[t,k,w] - sum(re_lg1_ss[e,t,k,w] for e in E1) - sum(rs_lg1_ss[s,t,k,w] for s in S1)
                        - sum(rhvdc_lg1_ss[cv,t,k,w] for cv in CV1)] in RotatedSecondOrderCone())

    # Converter k of area 1 trips
    m.ext[:constraints][:nadir_frequency_c_1_constraint_1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        ypc1_ss[t,k,w] == 2*deltaf1*Inertia_nadir_frequency_converter_1[t]/f1
            - sum(re_lc1_ss[e,t,k,w]*Edeployment[e] for e in E1)/2
            - sum(rs_lc1_ss[s,t,k,w]*Sdeployment[s] for s in S1)/2
            - sum(rhvdc_lc1_ss[cv,t,k,w]*HVDC_deployment[cv] for cv in CV1)/2)
    m.ext[:constraints][:nadir_frequency_c_1_constraint_2] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        zpc1_ss[t,k,w] == sum(rg_lc1_ss[g,t,k,w]/G_dt[g] for g in G1))
    m.ext[:constraints][:nadir_frequency_c_1_constraint_3] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        [ypc1_ss[t,k,w]; zpc1_ss[t,k,w];
         plc1_ss[t,k,w] - sum(re_lc1_ss[e,t,k,w] for e in E1) - sum(rs_lc1_ss[s,t,k,w] for s in S1)
                        - sum(rhvdc_lc1_ss[cv,t,k,w] for cv in CV1)] in RotatedSecondOrderCone())

    # Area 1 supports area 2 after generator k of area 2 trips (no HVDC reserve: area 1 is the one sending it)
    m.ext[:constraints][:nadir_frequency_reserve_1_g_constraint_1] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        ypreserve1_g_ss[t,k,w] == 2*deltaf1*Inertia_nadir_frequency_converter_1[t]/f1
            - sum(re_l_reserve_1_g_ss[e,t,k,w]*Edeployment[e] for e in E1)/2
            - sum(rs_l_reserve_1_g_ss[s,t,k,w]*Sdeployment[s] for s in S1)/2)
    m.ext[:constraints][:nadir_frequency_reserve_1_g_constraint_2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        zpreserve1_g_ss[t,k,w] == sum(rg_l_reserve_1_g_ss[g,t,k,w]/G_dt[g] for g in G1))
    m.ext[:constraints][:nadir_frequency_reserve_1_g_constraint_3] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        [ypreserve1_g_ss[t,k,w]; zpreserve1_g_ss[t,k,w];
         plreserve_1_g_ss[t,k,w] - sum(re_l_reserve_1_g_ss[e,t,k,w] for e in E1)
                                 - sum(rs_l_reserve_1_g_ss[s,t,k,w] for s in S1)] in RotatedSecondOrderCone())

    # Area 1 supports area 2 after converter k of area 2 trips
    m.ext[:constraints][:nadir_frequency_reserve_1_c_constraint_1] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        ypreserve1_c_ss[t,k,w] == 2*deltaf1*Inertia_nadir_frequency_converter_1[t]/f1
            - sum(re_l_reserve_1_c_ss[e,t,k,w]*Edeployment[e] for e in E1)/2
            - sum(rs_l_reserve_1_c_ss[s,t,k,w]*Sdeployment[s] for s in S1)/2)
    m.ext[:constraints][:nadir_frequency_reserve_1_c_constraint_2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        zpreserve1_c_ss[t,k,w] == sum(rg_l_reserve_1_c_ss[g,t,k,w]/G_dt[g] for g in G1))
    m.ext[:constraints][:nadir_frequency_reserve_1_c_constraint_3] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        [ypreserve1_c_ss[t,k,w]; zpreserve1_c_ss[t,k,w];
         plreserve_1_c_ss[t,k,w] - sum(re_l_reserve_1_c_ss[e,t,k,w] for e in E1)
                                 - sum(rs_l_reserve_1_c_ss[s,t,k,w] for s in S1)] in RotatedSecondOrderCone())

    # ----------------------------- AREA 2 --------------------------------

    # Generator k of area 2 trips
    m.ext[:constraints][:nadir_frequency_g_2_constraint_1] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        ypg2_ss[t,k,w] == 2*deltaf2*Inertia_nadir_frequency_2[t,k]/f2
            - sum(re_lg2_ss[e,t,k,w]*Edeployment[e] for e in E2)/2
            - sum(rs_lg2_ss[s,t,k,w]*Sdeployment[s] for s in S2)/2
            - sum(rhvdc_lg2_ss[cv,t,k,w]*HVDC_deployment[cv] for cv in CV2)/2)
    m.ext[:constraints][:nadir_frequency_g_2_constraint_2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        zpg2_ss[t,k,w] == sum(rg_lg2_ss[g,t,k,w]/G_dt[g] for g in G2))
    m.ext[:constraints][:nadir_frequency_g_2_constraint_3] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        [ypg2_ss[t,k,w]; zpg2_ss[t,k,w];
         plg2_ss[t,k,w] - sum(re_lg2_ss[e,t,k,w] for e in E2) - sum(rs_lg2_ss[s,t,k,w] for s in S2)
                        - sum(rhvdc_lg2_ss[cv,t,k,w] for cv in CV2)] in RotatedSecondOrderCone())

    # Converter k of area 2 trips
    m.ext[:constraints][:nadir_frequency_c_2_constraint_1] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        ypc2_ss[t,k,w] == 2*deltaf2*Inertia_nadir_frequency_converter_2[t]/f2
            - sum(re_lc2_ss[e,t,k,w]*Edeployment[e] for e in E2)/2
            - sum(rs_lc2_ss[s,t,k,w]*Sdeployment[s] for s in S2)/2
            - sum(rhvdc_lc2_ss[cv,t,k,w]*HVDC_deployment[cv] for cv in CV2)/2)
    m.ext[:constraints][:nadir_frequency_c_2_constraint_2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        zpc2_ss[t,k,w] == sum(rg_lc2_ss[g,t,k,w]/G_dt[g] for g in G2))
    m.ext[:constraints][:nadir_frequency_c_2_constraint_3] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        [ypc2_ss[t,k,w]; zpc2_ss[t,k,w];
         plc2_ss[t,k,w] - sum(re_lc2_ss[e,t,k,w] for e in E2) - sum(rs_lc2_ss[s,t,k,w] for s in S2)
                        - sum(rhvdc_lc2_ss[cv,t,k,w] for cv in CV2)] in RotatedSecondOrderCone())

    # Area 2 supports area 1 after generator k of area 1 trips (no HVDC reserve: area 2 is the one sending it)
    m.ext[:constraints][:nadir_frequency_reserve_2_g_constraint_1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        ypreserve2_g_ss[t,k,w] == 2*deltaf2*Inertia_nadir_frequency_converter_2[t]/f2
            - sum(re_l_reserve_2_g_ss[e,t,k,w]*Edeployment[e] for e in E2)/2
            - sum(rs_l_reserve_2_g_ss[s,t,k,w]*Sdeployment[s] for s in S2)/2)
    m.ext[:constraints][:nadir_frequency_reserve_2_g_constraint_2] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        zpreserve2_g_ss[t,k,w] == sum(rg_l_reserve_2_g_ss[g,t,k,w]/G_dt[g] for g in G2))
    m.ext[:constraints][:nadir_frequency_reserve_2_g_constraint_3] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        [ypreserve2_g_ss[t,k,w]; zpreserve2_g_ss[t,k,w];
         plreserve_2_g_ss[t,k,w] - sum(re_l_reserve_2_g_ss[e,t,k,w] for e in E2)
                                 - sum(rs_l_reserve_2_g_ss[s,t,k,w] for s in S2)] in RotatedSecondOrderCone())

    # Area 2 supports area 1 after converter k of area 1 trips
    m.ext[:constraints][:nadir_frequency_reserve_2_c_constraint_1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        ypreserve2_c_ss[t,k,w] == 2*deltaf2*Inertia_nadir_frequency_converter_2[t]/f2
            - sum(re_l_reserve_2_c_ss[e,t,k,w]*Edeployment[e] for e in E2)/2
            - sum(rs_l_reserve_2_c_ss[s,t,k,w]*Sdeployment[s] for s in S2)/2)
    m.ext[:constraints][:nadir_frequency_reserve_2_c_constraint_2] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        zpreserve2_c_ss[t,k,w] == sum(rg_l_reserve_2_c_ss[g,t,k,w]/G_dt[g] for g in G2))
    m.ext[:constraints][:nadir_frequency_reserve_2_c_constraint_3] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        [ypreserve2_c_ss[t,k,w]; zpreserve2_c_ss[t,k,w];
         plreserve_2_c_ss[t,k,w] - sum(re_l_reserve_2_c_ss[e,t,k,w] for e in E2)
                                 - sum(rs_l_reserve_2_c_ss[s,t,k,w] for s in S2)] in RotatedSecondOrderCone())
       # =====================================================================
    #                 TIME OF OCCURRENCE OF THE NADIR
    # =====================================================================
    # For every contingency k and wind scenario w, the nadir must occur after the fast reserves are
    # fully deployed and before the generator reserves are fully delivered:
    #   _1: P_loss <= eps + all reserves
    #   _2: P_loss >= eps + fast reserves + generator reserves * (Edeployment / G_dt)
    eps_nadir = 0.0000001

    # ----------------------------- AREA 1 --------------------------------

    # Generator k of area 1 trips
    m.ext[:constraints][:time_nadir_occurrence_g1_1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        plg1_ss[t,k,w] <= eps_nadir + sum(re_lg1_ss[e,t,k,w] for e in E1) + sum(rs_lg1_ss[s,t,k,w] for s in S1)
            + sum(rhvdc_lg1_ss[cv,t,k,w] for cv in CV1) + sum(rg_lg1_ss[g,t,k,w] for g in G1))
    m.ext[:constraints][:time_nadir_occurrence_g1_2] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        plg1_ss[t,k,w] >= eps_nadir + sum(re_lg1_ss[e,t,k,w] for e in E1) + sum(rs_lg1_ss[s,t,k,w] for s in S1)
            + sum(rhvdc_lg1_ss[cv,t,k,w] for cv in CV1) + sum(rg_lg1_ss[g,t,k,w] for g in G1)*Edeployment["1"]/G_dt["1"])

    # Converter k of area 1 trips
    m.ext[:constraints][:time_nadir_occurrence_c1_1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        plc1_ss[t,k,w] <= eps_nadir + sum(re_lc1_ss[e,t,k,w] for e in E1) + sum(rs_lc1_ss[s,t,k,w] for s in S1)
            + sum(rhvdc_lc1_ss[cv,t,k,w] for cv in CV1) + sum(rg_lc1_ss[g,t,k,w] for g in G1))
    m.ext[:constraints][:time_nadir_occurrence_c1_2] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        plc1_ss[t,k,w] >= eps_nadir + sum(re_lc1_ss[e,t,k,w] for e in E1) + sum(rs_lc1_ss[s,t,k,w] for s in S1)
            + sum(rhvdc_lc1_ss[cv,t,k,w] for cv in CV1) + sum(rg_lc1_ss[g,t,k,w] for g in G1)*Edeployment["1"]/G_dt["1"])

    # Area 1 supports area 2 after generator k of area 2 trips (no HVDC reserve)
    m.ext[:constraints][:time_nadir_occurrence_reserve_1_g_1] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        plreserve_1_g_ss[t,k,w] <= eps_nadir + sum(re_l_reserve_1_g_ss[e,t,k,w] for e in E1)
            + sum(rs_l_reserve_1_g_ss[s,t,k,w] for s in S1) + sum(rg_l_reserve_1_g_ss[g,t,k,w] for g in G1))
    m.ext[:constraints][:time_nadir_occurrence_reserve_1_g_2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        plreserve_1_g_ss[t,k,w] >= eps_nadir + sum(re_l_reserve_1_g_ss[e,t,k,w] for e in E1)
            + sum(rs_l_reserve_1_g_ss[s,t,k,w] for s in S1) + sum(rg_l_reserve_1_g_ss[g,t,k,w] for g in G1)*Edeployment["1"]/G_dt["1"])

    # Area 1 supports area 2 after converter k of area 2 trips (no HVDC reserve)
    m.ext[:constraints][:time_nadir_occurrence_reserve_1_c_1] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        plreserve_1_c_ss[t,k,w] <= eps_nadir + sum(re_l_reserve_1_c_ss[e,t,k,w] for e in E1)
            + sum(rs_l_reserve_1_c_ss[s,t,k,w] for s in S1) + sum(rg_l_reserve_1_c_ss[g,t,k,w] for g in G1))
    m.ext[:constraints][:time_nadir_occurrence_reserve_1_c_2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        plreserve_1_c_ss[t,k,w] >= eps_nadir + sum(re_l_reserve_1_c_ss[e,t,k,w] for e in E1)
            + sum(rs_l_reserve_1_c_ss[s,t,k,w] for s in S1) + sum(rg_l_reserve_1_c_ss[g,t,k,w] for g in G1)*Edeployment["1"]/G_dt["1"])

    # ----------------------------- AREA 2 --------------------------------

    # Generator k of area 2 trips
    m.ext[:constraints][:time_nadir_occurrence_g2_1] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        plg2_ss[t,k,w] <= eps_nadir + sum(re_lg2_ss[e,t,k,w] for e in E2) + sum(rs_lg2_ss[s,t,k,w] for s in S2)
            + sum(rhvdc_lg2_ss[cv,t,k,w] for cv in CV2) + sum(rg_lg2_ss[g,t,k,w] for g in G2))
    m.ext[:constraints][:time_nadir_occurrence_g2_2] = @constraint(m, [t=T, k=fallos_g2, w=Wind_scenarios],
        plg2_ss[t,k,w] >= eps_nadir + sum(re_lg2_ss[e,t,k,w] for e in E2) + sum(rs_lg2_ss[s,t,k,w] for s in S2)
            + sum(rhvdc_lg2_ss[cv,t,k,w] for cv in CV2) + sum(rg_lg2_ss[g,t,k,w] for g in G2)*Edeployment["1"]/G_dt["1"])

    # Converter k of area 2 trips
    m.ext[:constraints][:time_nadir_occurrence_c2_1] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        plc2_ss[t,k,w] <= eps_nadir + sum(re_lc2_ss[e,t,k,w] for e in E2) + sum(rs_lc2_ss[s,t,k,w] for s in S2)
            + sum(rhvdc_lc2_ss[cv,t,k,w] for cv in CV2) + sum(rg_lc2_ss[g,t,k,w] for g in G2))
    m.ext[:constraints][:time_nadir_occurrence_c2_2] = @constraint(m, [t=T, k=fallos_c2, w=Wind_scenarios],
        plc2_ss[t,k,w] >= eps_nadir + sum(re_lc2_ss[e,t,k,w] for e in E2) + sum(rs_lc2_ss[s,t,k,w] for s in S2)
            + sum(rhvdc_lc2_ss[cv,t,k,w] for cv in CV2) + sum(rg_lc2_ss[g,t,k,w] for g in G2)*Edeployment["1"]/G_dt["1"])

    # Area 2 supports area 1 after generator k of area 1 trips (no HVDC reserve)
    m.ext[:constraints][:time_nadir_occurrence_reserve_2_g_1] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        plreserve_2_g_ss[t,k,w] <= eps_nadir + sum(re_l_reserve_2_g_ss[e,t,k,w] for e in E2)
            + sum(rs_l_reserve_2_g_ss[s,t,k,w] for s in S2) + sum(rg_l_reserve_2_g_ss[g,t,k,w] for g in G2))
    m.ext[:constraints][:time_nadir_occurrence_reserve_2_g_2] = @constraint(m, [t=T, k=fallos_g1, w=Wind_scenarios],
        plreserve_2_g_ss[t,k,w] >= eps_nadir + sum(re_l_reserve_2_g_ss[e,t,k,w] for e in E2)
            + sum(rs_l_reserve_2_g_ss[s,t,k,w] for s in S2) + sum(rg_l_reserve_2_g_ss[g,t,k,w] for g in G2)*Edeployment["1"]/G_dt["1"])

    # Area 2 supports area 1 after converter k of area 1 trips (no HVDC reserve)
    m.ext[:constraints][:time_nadir_occurrence_reserve_2_c_1] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        plreserve_2_c_ss[t,k,w] <= eps_nadir + sum(re_l_reserve_2_c_ss[e,t,k,w] for e in E2)
            + sum(rs_l_reserve_2_c_ss[s,t,k,w] for s in S2) + sum(rg_l_reserve_2_c_ss[g,t,k,w] for g in G2))
    m.ext[:constraints][:time_nadir_occurrence_reserve_2_c_2] = @constraint(m, [t=T, k=fallos_c1, w=Wind_scenarios],
        plreserve_2_c_ss[t,k,w] >= eps_nadir + sum(re_l_reserve_2_c_ss[e,t,k,w] for e in E2)
            + sum(rs_l_reserve_2_c_ss[s,t,k,w] for s in S2) + sum(rg_l_reserve_2_c_ss[g,t,k,w] for g in G2)*Edeployment["1"]/G_dt["1"])
      
    return m 
end
