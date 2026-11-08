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

    
        K = vcat([(:gen,g)  for g  in G],
         [(:conv, cv) for cv in CV])
         omega = [(k..., w) for k in K for w in  Wind_scenarios]


    ##### Create variables 
    # AC components
    # Bus variables

  


    pg_fs = m.ext[:variables][:pg_fs] = @variable(m, [g=G, t=T], lower_bound=0, upper_bound=pmax[g], base_name="pg_fs") # active power generation
    pg_ss = m.ext[:variables][:pg_ss] = @variable(m, [g=G, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=pmax[g], base_name="pg_ss") # active power generation
    pg_ss_up = m.ext[:variables][:pg_ss_up] = @variable(m, [g=G, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g], base_name="pg_ss_up") # upward adjustment of generation w.r.t. the first-stage schedule
    pg_ss_dn = m.ext[:variables][:pg_ss_dn] = @variable(m, [g=G, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=downramp[g], base_name="pg_ss_dn") # downward adjustment of generation w.r.t. the first-stage schedule

    # Generator variables
    rg_lg1_ss = m.ext[:variables][:rg_lg1_ss] = @variable(m, [g=G1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lg1_ss") # frequency reserve generators loss of generation area 1 second stage

    rg_lc1_ss = m.ext[:variables][:rg_lc1_ss] = @variable(m, [g=G1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lc1_ss") # frequency reserve generators loss of converter area 1 second stage

    rg_lg2_ss = m.ext[:variables][:rg_lg2_ss] = @variable(m, [g=G2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lg2_ss") # frequency reserve generators loss of generation area 2 second stage

    rg_lc2_ss = m.ext[:variables][:rg_lc2_ss] = @variable(m, [g=G2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_lc2_ss") # frequency reserve generators loss of converter area 2 second stage

    rg_l_reserve_1_ss = m.ext[:variables][:rg_l_reserve_1_ss] = @variable(m, [g=G1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_l_reserve_1_ss") # frequency reserve generators for FCR provision area 1 second stage

    rg_l_reserve_2_ss = m.ext[:variables][:rg_l_reserve_2_ss] = @variable(m, [g=G2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="rg_l_reserve_2_ss") # frequency reserve generators for FCR provision area 2 second stage

    r_proc_g_1 = m.ext[:variables][:r_proc_g_1] = @variable(m, [g=G1, t=T], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="r_proc_g_1") # procured reserve generators area 1
    r_proc_g_2 = m.ext[:variables][:r_proc_g_2] = @variable(m, [g=G2, t=T], lower_bound=0, upper_bound=upramp[g]*G_dt[g]/3600, base_name="r_proc_g_2") # procured reserve generators area 2

    # Status variables generators
    zg_fs = m.ext[:variables][:zg_fs] = @variable(m, [g=G, t=T], binary=true, base_name="zg_fs") # status variable generator
    betag_fs = m.ext[:variables][:betag_fs] = @variable(m, [g=G, t=T], binary=true, base_name="betag_fs") # start-up variable generator
    gammag_fs = m.ext[:variables][:gammag_fs] = @variable(m, [g=G, t=T], binary=true, base_name="gammag_fs") # shut-down variable generator

    # DC components
    # Branches
    brdc_p_fs = m.ext[:variables][:brdc_p_fs] = @variable(m, [(d,e,f)=BD_dc, t=T], lower_bound=-brdc_rate_a[d], upper_bound=brdc_rate_a[d], base_name="brdc_p_fs")
    brdc_p_ss = m.ext[:variables][:brdc_p_ss] = @variable(m, [(d,e,f)=BD_dc, t=T, k=fallos, w=Wind_scenarios], lower_bound=-brdc_rate_a[d], upper_bound=brdc_rate_a[d], base_name="brdc_p_ss")

    # Converters
    conv_p_ac_fs = m.ext[:variables][:conv_p_ac_fs] = @variable(m, [cv=CV, t=T], lower_bound=-conv_p_ac_max[cv], upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_fs") # converter active power
    conv_p_ac_ss = m.ext[:variables][:conv_p_ac_ss] = @variable(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios], lower_bound=-conv_p_ac_max[cv], upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_ss") # converter active power
    conv_p_ac_ss_up = m.ext[:variables][:conv_p_ac_ss_up] = @variable(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=2*conv_p_ac_max[cv], base_name="conv_p_ac_ss_up") # upward adjustment of converter AC power w.r.t. the first-stage schedule
    conv_p_ac_ss_dn = m.ext[:variables][:conv_p_ac_ss_dn] = @variable(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=2*conv_p_ac_max[cv], base_name="conv_p_ac_ss_dn") # downward adjustment of converter AC power w.r.t. the first-stage schedule

    conv_p_ac_abs_fs = m.ext[:variables][:conv_p_ac_abs_fs] = @variable(m, [cv=CV, t=T], lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_abs_fs") # absorbed power converter
    conv_p_ac_abs_ss = m.ext[:variables][:conv_p_ac_abs_ss] = @variable(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_abs_ss") # absorbed power converter

    conv_p_ac_inj_fs = m.ext[:variables][:conv_p_ac_inj_fs] = @variable(m, [cv=CV, t=T], lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_inj_fs") # injected power converter
    conv_p_ac_inj_ss = m.ext[:variables][:conv_p_ac_inj_ss] = @variable(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=conv_p_ac_max[cv], base_name="conv_p_ac_inj_ss") # injected power converter

    u_conv_p_ac_fs = m.ext[:variables][:u_conv_p_ac_fs] = @variable(m, [cv=CV, t=T], binary=true, base_name="u_conv_p_ac_fs") # binary variable for converter active power
    u_conv_p_ac_ss = m.ext[:variables][:u_conv_p_ac_ss] = @variable(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios], binary=true, base_name="u_conv_p_ac_ss") # binary variable for converter active power

    conv_p_dc_fs = m.ext[:variables][:conv_p_dc_fs] = @variable(m, [cv=CV, t=T], lower_bound=-conv_p_dc_max[cv], upper_bound=conv_p_dc_max[cv], base_name="conv_p_dc_fs") # converter active power
    conv_p_dc_ss = m.ext[:variables][:conv_p_dc_ss] = @variable(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios], lower_bound=-conv_p_dc_max[cv], upper_bound=conv_p_dc_max[cv], base_name="conv_p_dc_ss") # converter active power

    rhvdc_lg1_ss = m.ext[:variables][:rhvdc_lg1_ss] = @variable(m, [cv=CV1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lg1_ss") # frequency reserve HVDC loss of generation area 1
    rhvdc_lc1_ss = m.ext[:variables][:rhvdc_lc1_ss] = @variable(m, [cv=CV1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lc1_ss") # frequency reserve HVDC loss of converter area 1
    rhvdc_lg2_ss = m.ext[:variables][:rhvdc_lg2_ss] = @variable(m, [cv=CV2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lg2_ss") # frequency reserve HVDC loss of generation area 2
    rhvdc_lc2_ss = m.ext[:variables][:rhvdc_lc2_ss] = @variable(m, [cv=CV2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=2*(40/40)conv_p_dc_max[cv], base_name="rhvdc_lc2_ss") # frequency reserve HVDC loss of converter area 2

    # Reservoir storage variables
    e_reservoir_fs = m.ext[:variables][:e_reservoir_fs] = @variable(m, [g=G_reservoir, t=T], lower_bound=0, upper_bound=G_storage[g], base_name="e_reservoir_fs") # energy storage reservoir
    e_reservoir_ss = m.ext[:variables][:e_reservoir_ss] = @variable(m, [g=G_reservoir, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=G_storage[g], base_name="e_reservoir_ss") # energy storage reservoir

    # Pump generators variables
    p_charge_pump_fs = m.ext[:variables][:p_charge_pump_fs] = @variable(m, [g=G_pump, t=T], base_name="p_charge_pump_fs")
    p_charge_pump_ss = m.ext[:variables][:p_charge_pump_ss] = @variable(m, [g=G_pump, t=T, k=fallos, w=Wind_scenarios], base_name="p_charge_pump_ss")
    p_charge_pump_ss_up = m.ext[:variables][:p_charge_pump_ss_up] = @variable(m, [g=G_pump, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="p_charge_pump_ss_up") # upward adjustment of pumping power w.r.t. the first-stage schedule
    p_charge_pump_ss_dn = m.ext[:variables][:p_charge_pump_ss_dn] = @variable(m, [g=G_pump, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="p_charge_pump_ss_dn") # downward adjustment of pumping power w.r.t. the first-stage schedule

    e_pump_fs = m.ext[:variables][:e_pump_fs] = @variable(m, [g=G_pump, t=T], lower_bound=0, upper_bound=G_storage[g], base_name="e_pump_fs") # energy storage pump
    e_pump_ss = m.ext[:variables][:e_pump_ss] = @variable(m, [g=G_pump, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=G_storage[g], base_name="e_pump_ss") # energy storage pump

    # Electrolyzer continuous variables
    pe_fs = m.ext[:variables][:pe_fs] = @variable(m, [e=E, t=T], lower_bound=0, upper_bound=Epmax[e], base_name="pe_fs") # Electrolyzer power consumption
    pe_ss = m.ext[:variables][:pe_ss] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Epmax[e], base_name="pe_ss") # Electrolyzer power consumption
    pe_ss_up = m.ext[:variables][:pe_ss_up] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Epmax[e], base_name="pe_ss_up") # upward adjustment of electrolyzer consumption w.r.t. the first-stage schedule
    pe_ss_dn = m.ext[:variables][:pe_ss_dn] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Epmax[e], base_name="pe_ss_dn") # downward adjustment of electrolyzer consumption w.r.t. the first-stage schedule

    pe_compressor_fs = m.ext[:variables][:pe_compressor_fs] = @variable(m, [e=E, t=T], lower_bound=0, base_name="pe_compressor_fs") # Electrolyzer power consumption for compressor
    pe_compressor_ss = m.ext[:variables][:pe_compressor_ss] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="pe_compressor_ss") # Electrolyzer power consumption for compressor

    pes_fs = m.ext[:variables][:pes_fs] = @variable(m, [e=E, t=T], lower_bound=0, base_name="pes_fs") # Electrolyzer reserve power
    pes_ss = m.ext[:variables][:pes_ss] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="pes_ss") # Electrolyzer reserve power

    hfe_fs = m.ext[:variables][:hfe_fs] = @variable(m, [e=E, t=T], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfe_fs") # Electrolyzer hydrogen flow
    hfe_ss = m.ext[:variables][:hfe_ss] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfe_ss") # Electrolyzer hydrogen flow

    hfginyect_fs = m.ext[:variables][:hfginyect_fs] = @variable(m, [e=E, t=T], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_fs") # Electrolyzer hydrogen flow injected to the hydrogen grid
    hfginyect_ss = m.ext[:variables][:hfginyect_ss] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_ss") # Electrolyzer hydrogen flow injected to the hydrogen grid
    hfginyect_ss_up = m.ext[:variables][:hfginyect_ss_up] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_ss_up") # upward adjustment of hydrogen sold (injected) w.r.t. the first-stage schedule
    hfginyect_ss_dn = m.ext[:variables][:hfginyect_ss_dn] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfginyect_ss_dn") # downward adjustment of hydrogen sold (injected) w.r.t. the first-stage schedule

    hfgconsum_fs = m.ext[:variables][:hfgconsum_fs] = @variable(m, [e=E, t=T], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_fs") # Electrolyzer hydrogen flow consumed from the hydrogen grid
    hfgconsum_ss = m.ext[:variables][:hfgconsum_ss] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_ss") # Electrolyzer hydrogen flow consumed from the hydrogen grid
    hfgconsum_ss_up = m.ext[:variables][:hfgconsum_ss_up] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_ss_up") # upward adjustment of hydrogen purchased (consumed) w.r.t. the first-stage schedule
    hfgconsum_ss_dn = m.ext[:variables][:hfgconsum_ss_dn] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, upper_bound=Eflowmax[e], base_name="hfgconsum_ss_dn") # downward adjustment of hydrogen purchased (consumed) w.r.t. the first-stage schedule
    
    hss_fs = m.ext[:variables][:hss_fs] = @variable(m, [e=E, t=T], lower_bound=Estoragemin[e], upper_bound=Estoragemax[e], base_name="hss_fs") # Electrolyzer storage level
    hss_ss = m.ext[:variables][:hss_ss] = @variable(m, [e=E, t=T, k=fallos, w=Wind_scenarios], lower_bound=Estoragemin[e], upper_bound=Estoragemax[e], base_name="hss_ss") # Electrolyzer storage level

    # Electrolyzer binary variables (first stage only)
    ze_fs = m.ext[:variables][:ze_fs] = @variable(m, [e=E, t=T], binary=true, base_name="ze_fs") # Electrolyzer status
    zesu_fs = m.ext[:variables][:zesu_fs] = @variable(m, [e=E, t=T], binary=true, base_name="zesu_fs") # Electrolyzer start up
    zestb_fs = m.ext[:variables][:zestb_fs] = @variable(m, [e=E, t=T], binary=true, base_name="zestb_fs") # Electrolyzer standby indicator

    # Electrolyzer reserve variables
    re_lg1_ss = m.ext[:variables][:re_lg1_ss] = @variable(m, [e=E1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="re_lg1_ss") # frequency reserve electrolyzers loss of generation area 1

    re_lc1_ss = m.ext[:variables][:re_lc1_ss] = @variable(m, [e=E1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="re_lc1_ss") # frequency reserve electrolyzers loss of converter area 1

    re_lg2_ss = m.ext[:variables][:re_lg2_ss] = @variable(m, [e=E2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="re_lg2_ss") # frequency reserve electrolyzer loss of generation area 2

    re_lc2_ss = m.ext[:variables][:re_lc2_ss] = @variable(m, [e=E2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="re_lc2_ss") # frequency reserve electrolyzer loss of converter area 2

    re_l_reserve_1_ss = m.ext[:variables][:re_l_reserve_1_ss] = @variable(m, [e=E1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="re_l_reserve_1_ss") # frequency reserve for FCR provision

    re_l_reserve_2_ss = m.ext[:variables][:re_l_reserve_2_ss] = @variable(m, [e=E2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="re_l_reserve_2_ss") # frequency reserve for FCR provision

    r_proc_e_1 = m.ext[:variables][:r_proc_e_1] = @variable(m, [e=E1, t=T], lower_bound=0, base_name="r_proc_e_1") # procured reserve electrolyzers area 1
    r_proc_e_2 = m.ext[:variables][:r_proc_e_2] = @variable(m, [e=E2, t=T], lower_bound=0, base_name="r_proc_e_2") # procured reserve electrolyzers area 2

    # Storage variables
    psc_fs = m.ext[:variables][:psc_fs] = @variable(m, [s=S, t=T], lower_bound=0, base_name="psc_fs") # Charging power of the batteries
    psc_ss = m.ext[:variables][:psc_ss] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="psc_ss") # Charging power of the batteries
    psc_ss_up = m.ext[:variables][:psc_ss_up] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="psc_ss_up") # upward adjustment of battery charging power w.r.t. the first-stage schedule
    psc_ss_dn = m.ext[:variables][:psc_ss_dn] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="psc_ss_dn") # downward adjustment of battery charging power w.r.t. the first-stage schedule

    psd_fs = m.ext[:variables][:psd_fs] = @variable(m, [s=S, t=T], lower_bound=0, base_name="psd_fs") # Discharging power of the batteries
    psd_ss = m.ext[:variables][:psd_ss] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="psd_ss") # Discharging power of the batteries
    psd_ss_up = m.ext[:variables][:psd_ss_up] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="psd_ss_up") # upward adjustment of battery discharging power w.r.t. the first-stage schedule
    psd_ss_dn = m.ext[:variables][:psd_ss_dn] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="psd_ss_dn") # downward adjustment of battery discharging power w.r.t. the first-stage schedule

    es_fs = m.ext[:variables][:es_fs] = @variable(m, [s=S, t=T], lower_bound=Sstoragemax[s]*(1-Sdod[s]), upper_bound=Sstoragemax[s], base_name="es_fs") # Energy bounds of the batteries
    es_ss = m.ext[:variables][:es_ss] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], lower_bound=Sstoragemax[s]*(1-Sdod[s]), upper_bound=Sstoragemax[s], base_name="es_ss") # Energy bounds of the batteries

    zs_fs = m.ext[:variables][:zs_fs] = @variable(m, [s=S, t=T], binary=true, base_name="zs_fs") # standby indicator of the batteries
    zs_ss = m.ext[:variables][:zs_ss] = @variable(m, [s=S, t=T, k=fallos, w=Wind_scenarios], binary=true, base_name="zs_ss") # standby indicator of the batteries

    rs_lg1_ss = m.ext[:variables][:rs_lg1_ss] = @variable(m, [s=S1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="rs_lg1_ss") # frequency reserve batteries loss of generation area 1

    rs_lg2_ss = m.ext[:variables][:rs_lg2_ss] = @variable(m, [s=S2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="rs_lg2_ss") # frequency reserve batteries loss of generation area 2

    rs_lc1_ss = m.ext[:variables][:rs_lc1_ss] = @variable(m, [s=S1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="rs_lc1_ss") # frequency reserve batteries loss of converter area 1

    rs_lc2_ss = m.ext[:variables][:rs_lc2_ss] = @variable(m, [s=S2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="rs_lc2_ss") # frequency reserve batteries loss of converter area 2

    rs_l_reserve_1_ss = m.ext[:variables][:rs_l_reserve_1_ss] = @variable(m, [s=S1, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="rs_l_reserve_1_ss") # frequency reserve for FCR provision

    rs_l_reserve_2_ss = m.ext[:variables][:rs_l_reserve_2_ss] = @variable(m, [s=S2, t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="rs_l_reserve_2_ss") # frequency reserve for FCR provision

    r_proc_s_1 = m.ext[:variables][:r_proc_s_1] = @variable(m, [s=S1, t=T], lower_bound=0, base_name="r_proc_s_1") # procured reserve batteries area 1
    r_proc_s_2 = m.ext[:variables][:r_proc_s_2] = @variable(m, [s=S2, t=T], lower_bound=0, base_name="r_proc_s_2") # procured reserve batteries area 2

    # Frequency stability variables
    plg1_ss = m.ext[:variables][:plg1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="plg1_ss") # loss of power generators area 1
    plg2_ss = m.ext[:variables][:plg2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="plg2_ss") # loss of power generators area 2
    plc1_ss = m.ext[:variables][:plc1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="plc1_ss") # loss of power converters area 1
    plc2_ss = m.ext[:variables][:plc2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="plc2_ss") # loss of power converters area 2
    plreserve_1_ss = m.ext[:variables][:plreserve_1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="plreserve_1_ss") # loss of power due to the FCR provision
    plreserve_2_ss = m.ext[:variables][:plreserve_2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="plreserve_2_ss") # loss of power due to the FCR provision

    # Auxiliary variables for rotated second order cone constraints
    ypg1_ss = m.ext[:variables][:ypg1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="ypg1_ss") # Auxiliary variable rotated SOC generators fault area 1
    zpg1_ss = m.ext[:variables][:zpg1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="zpg1_ss") # Auxiliary variable rotated SOC generators fault area 1
    ypc1_ss = m.ext[:variables][:ypc1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="ypc1_ss") # Auxiliary variable rotated SOC converters fault area 1
    zpc1_ss = m.ext[:variables][:zpc1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="zpc1_ss") # Auxiliary variable rotated SOC converters fault area 1
    ypg2_ss = m.ext[:variables][:ypg2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="ypg2_ss") # Auxiliary variable rotated SOC generators fault area 2
    zpg2_ss = m.ext[:variables][:zpg2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="zpg2_ss") # Auxiliary variable rotated SOC generators fault area 2
    ypc2_ss = m.ext[:variables][:ypc2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="ypc2_ss") # Auxiliary variable rotated SOC converters fault area 2
    zpc2_ss = m.ext[:variables][:zpc2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="zpc2_ss") # Auxiliary variable rotated SOC converters fault area 2
    ypreserve1_ss = m.ext[:variables][:ypreserve1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="ypreserve1_ss") # Auxiliary variable rotated SOC reserve provision fault area 1
    zpreserve1_ss = m.ext[:variables][:zpreserve1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="zpreserve1_ss") # Auxiliary variable rotated SOC reserve provision fault area 1
    ypreserve2_ss = m.ext[:variables][:ypreserve2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="ypreserve2_ss") # Auxiliary variable rotated SOC reserve provision fault area 2
    zpreserve2_ss = m.ext[:variables][:zpreserve2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="zpreserve2_ss") # Auxiliary variable rotated SOC reserve provision fault area 2

    # Other variables
    load_shed_1_fs = m.ext[:variables][:load_shed_1_fs] = @variable(m, [t=T], lower_bound=0, base_name="load_shed_1_fs") # Load shedding area 1
    load_shed_1_ss = m.ext[:variables][:load_shed_1_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="load_shed_1_ss") # Load shedding area 1

    load_shed_2_fs = m.ext[:variables][:load_shed_2_fs] = @variable(m, [t=T], lower_bound=0, base_name="load_shed_2_fs") # Load shedding area 2
    load_shed_2_ss = m.ext[:variables][:load_shed_2_ss] = @variable(m, [t=T, k=fallos, w=Wind_scenarios], lower_bound=0, base_name="load_shed_2_ss") # Load shedding area 2
    sigma= m.ext[:variables][:sigma] = @variable(m, base_name="sigma") # sigma variable to minimize

    VOLL     = 10000
    α,   β   = 1.1, 0.9
    α_H, β_H = 1.1, 0.9

    m.ext[:objective] = @objective(m, Min,       sum(gen_cost[g][1] * pg_fs[g, t] + gen_cost[g][2] for g in G, t in T)
    + sum(Estartupcost[e] * zesu_fs[e, t] for e in E, t in T)
    + sum(start_up_cost[g] * betag_fs[g, t] for g in G, t in T)
    + sum(Hydrogencost[e] * baseKG * (-hfginyect_fs[e, t] + hfgconsum_fs[e, t]) for e in E, t in T)

    + sum(Ereservecost[e] * r_proc_e_1[e, t] for e in E1, t in T) * baseMVA
    + sum(Ereservecost[e] * r_proc_e_2[e, t] for e in E2, t in T) * baseMVA

    + sum(Sreservecost[s] * r_proc_s_1[s, t] for s in S1, t in T) * baseMVA
    + sum(Sreservecost[s] * r_proc_s_2[s, t] for s in S2, t in T) * baseMVA

    + sum(G_reservecost[g] * r_proc_g_1[g, t] for g in G1, t in T) * baseMVA
    + sum(G_reservecost[g] * r_proc_g_2[g, t] for g in G2, t in T) * baseMVA

    + sum(load_shed_1_fs[t] * VOLL for t in T) * baseMVA
    + sum(load_shed_2_fs[t] * VOLL for t in T) * baseMVA+sigma)




m.ext[:constraints][:cost_ss] = @constraint(m, [k = fallos, w = Wind_scenarios],
      sum( α * gen_cost[g][1] * pg_ss_up[g, t, k, w]
         - β * gen_cost[g][1] * pg_ss_dn[g, t, k, w]  for g in G, t in T)

    + sum( Hydrogencost[e] * baseKG * (
             α_H * hfgconsum_ss_up[e, t, k, w]
           - β_H * hfgconsum_ss_dn[e, t, k, w]
           - β_H * hfginyect_ss_up[e, t, k, w]
           + α_H * hfginyect_ss_dn[e, t, k, w] )
           for e in E, t in T)

    + sum( VOLL * (load_shed_1_ss[t, k, w] + load_shed_2_ss[t, k, w]) for t in T) * baseMVA
    <= sigma
)


    
    keys_contingency = collect(keys(all_contingencies))




    #Reserve constraints generators
# Reserve constraints generators, area 1
    m.ext[:constraints][:r_proc_g_1_bound_lg] = @constraint(m, [g=G1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_g_1[g,t] >= rg_lg1_ss[g,t,k,w])
    m.ext[:constraints][:r_proc_g_1_bound_lc] = @constraint(m, [g=G1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_g_1[g,t] >= rg_lc1_ss[g,t,k,w])
    m.ext[:constraints][:r_proc_g_1_bound_lreserve] = @constraint(m, [g=G1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_g_1[g,t] >= rg_l_reserve_1_ss[g,t,k,w])

    # Reserve constraints generators, area 2
    m.ext[:constraints][:r_proc_g_2_bound_lg] = @constraint(m, [g=G2, t=T, k=fallos, w=Wind_scenarios],
        r_proc_g_2[g,t] >= rg_lg2_ss[g,t,k,w])
    m.ext[:constraints][:r_proc_g_2_bound_lc] = @constraint(m, [g=G2, t=T, k=fallos, w=Wind_scenarios],
        r_proc_g_2[g,t] >= rg_lc2_ss[g,t,k,w])
    m.ext[:constraints][:r_proc_g_2_bound_lreserve] = @constraint(m, [g=G2, t=T, k=fallos, w=Wind_scenarios],
    r_proc_g_2[g,t] >= rg_l_reserve_2_ss[g,t,k,w])

    # Storage reserve constraints, area 1
    m.ext[:constraints][:r_proc_s_1_bound_lg] = @constraint(m, [s=S1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_s_1[s,t] >= rs_lg1_ss[s,t,k,w])
    m.ext[:constraints][:r_proc_s_1_bound_lc] = @constraint(m, [s=S1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_s_1[s,t] >= rs_lc1_ss[s,t,k,w])
    m.ext[:constraints][:r_proc_s_1_bound_lreserve] = @constraint(m, [s=S1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_s_1[s,t] >= rs_l_reserve_1_ss[s,t,k,w])

    # Storage reserve constraints, area 2
    m.ext[:constraints][:r_proc_s_2_bound_lg] = @constraint(m, [s=S2, t=T, k=fallos, w=Wind_scenarios],
        r_proc_s_2[s,t] >= rs_lg2_ss[s,t,k,w])
    m.ext[:constraints][:r_proc_s_2_bound_lc] = @constraint(m, [s=S2, t=T, k=fallos, w=Wind_scenarios],
        r_proc_s_2[s,t] >= rs_lc2_ss[s,t,k,w])
    m.ext[:constraints][:r_proc_s_2_bound_lreserve] = @constraint(m, [s=S2, t=T, k=fallos, w=Wind_scenarios],
        r_proc_s_2[s,t] >= rs_l_reserve_2_ss[s,t,k,w])

    # Electrolyzer reserve constraints, area 1
    m.ext[:constraints][:r_proc_e_1_bound_lg] = @constraint(m, [e=E1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_e_1[e,t] >= re_lg1_ss[e,t,k,w])
    m.ext[:constraints][:r_proc_e_1_bound_lc] = @constraint(m, [e=E1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_e_1[e,t] >= re_lc1_ss[e,t,k,w])
    m.ext[:constraints][:r_proc_e_1_bound_lreserve] = @constraint(m, [e=E1, t=T, k=fallos, w=Wind_scenarios],
        r_proc_e_1[e,t] >= re_l_reserve_1_ss[e,t,k,w])

    # Electrolyzer reserve constraints, area 2
    m.ext[:constraints][:r_proc_e_2_bound_lg] = @constraint(m, [e=E2, t=T, k=fallos, w=Wind_scenarios],
        r_proc_e_2[e,t] >= re_lg2_ss[e,t,k,w])
    m.ext[:constraints][:r_proc_e_2_bound_lc] = @constraint(m, [e=E2, t=T, k=fallos, w=Wind_scenarios],
        r_proc_e_2[e,t] >= re_lc2_ss[e,t,k,w])
    m.ext[:constraints][:r_proc_e_2_bound_lreserve] = @constraint(m, [e=E2, t=T, k=fallos, w=Wind_scenarios],
    r_proc_e_2[e,t] >= re_l_reserve_2_ss[e,t,k,w])

    # Procured reserve must be deliverable on the actual operating point, in every wind realization
    m.ext[:constraints][:headroom_rproc_g1_ss] = @constraint(m, [g=G1, t=T, k=fallos, w=Wind_scenarios],
        pg_fs[g,t] + pg_ss_up[g,t,k,w] - pg_ss_dn[g,t,k,w] + r_proc_g_1[g,t] <= pmax[g] * zg_fs[g,t])

    m.ext[:constraints][:headroom_rproc_g2_ss] = @constraint(m, [g=G2, t=T, k=fallos, w=Wind_scenarios],
        pg_fs[g,t] + pg_ss_up[g,t,k,w] - pg_ss_dn[g,t,k,w] + r_proc_g_2[g,t] <= pmax[g] * zg_fs[g,t])

    # Generation: first-stage schedule + second-stage adjustment
    m.ext[:constraints][:pg_fs_pg_ss_link] = @constraint(m, [g=G, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] == pg_fs[g,t] + pg_ss_up[g,t,k,w] - pg_ss_dn[g,t,k,w])






    # --- First stage: Power balance constraints (forecast wind) ---
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

    # --- Second stage: power balance in each wind realization ---
    m.ext[:constraints][:power_balance_1_ss] = @constraint(m, [t=T, k=fallos, w=Wind_scenarios],
        sum(pg_ss[g,t,k,w] for g in G1)
        - sum(p_charge_pump_ss[g,t,k,w] for g in G_pump_1)
        + sum(conv_p_ac_ss[cv,t,k,w] for cv in CV1)
        + sum(psd_ss[s,t,k,w] for s in S1) - sum(psc_ss[s,t,k,w] for s in S1)
        - sum(pe_ss[e,t,k,w] for e in E1) - sum(pe_compressor_ss[e,t,k,w] for e in E1)
        - demand["1"][t] + load_shed_1_ss[t,k,w]
        + solar_roof_pmax["1"] * capacity_factor_solar["Nordic"][t] == 0)

    m.ext[:constraints][:power_balance_2_ss] = @constraint(m, [t=T, k=fallos, w=Wind_scenarios],
        sum(pg_ss[g,t,k,w] for g in G2)
        - sum(p_charge_pump_ss[g,t,k,w] for g in G_pump_2)
        + sum(conv_p_ac_ss[cv,t,k,w] for cv in CV2)
        + sum(psd_ss[s,t,k,w] for s in S2) - sum(psc_ss[s,t,k,w] for s in S2)
        - sum(pe_ss[e,t,k,w] for e in E2) - sum(pe_compressor_ss[e,t,k,w] for e in E2)
        - demand["2"][t] + load_shed_2_ss[t,k,w]
        + solar_roof_pmax["2"] * capacity_factor_solar["GB"][t] == 0)

        

    # --- First stage ---
    m.ext[:constraints][:load_shed_1_limit_fs] = @constraint(m, [t=T],
        load_shed_1_fs[t] <= demand["1"][t])
    m.ext[:constraints][:load_shed_2_limit_fs] = @constraint(m, [t=T],
        load_shed_2_fs[t] <= demand["2"][t])

    # --- Second stage ---
    m.ext[:constraints][:load_shed_1_limit_ss] = @constraint(m, [t=T, k=fallos, w=Wind_scenarios],
        load_shed_1_ss[t,k,w] <= demand["1"][t])
    m.ext[:constraints][:load_shed_2_limit_ss] = @constraint(m, [t=T, k=fallos, w=Wind_scenarios],
        load_shed_2_ss[t,k,w] <= demand["2"][t])


        # Link first and second stage (HVDC flow adjustment)
    m.ext[:constraints][:conv_p_ac_link] = @constraint(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] == conv_p_ac_fs[cv,t] + conv_p_ac_ss_up[cv,t,k,w] - conv_p_ac_ss_dn[cv,t,k,w])

    # Reserve headroom (eq. 16), converters of area 1: loss of generation and loss of converter
    m.ext[:constraints][:hvdc_headroom_lg1] = @constraint(m, [cv=CV1, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] + rhvdc_lg1_ss[cv,t,k,w] <= conv_p_ac_max[cv])
    m.ext[:constraints][:hvdc_headroom_lc1] = @constraint(m, [cv=CV1, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] + rhvdc_lc1_ss[cv,t,k,w] <= conv_p_ac_max[cv])

    # Area 2
    m.ext[:constraints][:hvdc_headroom_lg2] = @constraint(m, [cv=CV2, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] + rhvdc_lg2_ss[cv,t,k,w] <= conv_p_ac_max[cv])
    m.ext[:constraints][:hvdc_headroom_lc2] = @constraint(m, [cv=CV2, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] + rhvdc_lc2_ss[cv,t,k,w] <= conv_p_ac_max[cv])


    # Nodal power balance DC  taken from https://github.com/Electa-Git/OPES/blob/main/opf_acdc/build_ac_opf_acdc_tap.jl line 431

    # ============================== FIRST STAGE ==============================
    m.ext[:constraints][:nodal_p_dc_balance_fs] = @constraint(m, [nd=ND, t=T],
        sum(conv_p_dc_fs[cv,t] for cv in CV if conv_busdc[cv] == nd)
        - sum(brdc_p_fs[(d,f,e),t] for (d,f,e) in ND_arcs[nd]) == 0)   # 3.14

    m.ext[:constraints][:conv_p_loss_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_fs[cv,t] + conv_p_dc_fs[cv,t] == 0)   # 3.17

    m.ext[:constraints][:conv_injec_ac_abs_inj_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_fs[cv,t] == conv_p_ac_inj_fs[cv,t] - conv_p_ac_abs_fs[cv,t])

    m.ext[:constraints][:direccional_flow_dc_fs] = @constraint(m, [(d,f,e)=BD_dc_fr, t=T],
        brdc_p_fs[(d,f,e),t] == -brdc_p_fs[(d,e,f),t])

    m.ext[:constraints][:conv_injec_ac_limit_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_inj_fs[cv,t] <= conv_p_ac_max[cv] * u_conv_p_ac_fs[cv,t])
    m.ext[:constraints][:conv_abs_limit_fs] = @constraint(m, [cv=CV, t=T],
        conv_p_ac_abs_fs[cv,t] <= conv_p_ac_max[cv] * (1 - u_conv_p_ac_fs[cv,t]))

    # ============================== SECOND STAGE =============================
    m.ext[:constraints][:nodal_p_dc_balance_ss] = @constraint(m, [nd=ND, t=T, k=fallos, w=Wind_scenarios],
        sum(conv_p_dc_ss[cv,t,k,w] for cv in CV if conv_busdc[cv] == nd)
        - sum(brdc_p_ss[(d,f,e),t,k,w] for (d,f,e) in ND_arcs[nd]) == 0)   # 3.14

    m.ext[:constraints][:conv_p_loss_ss] = @constraint(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] + conv_p_dc_ss[cv,t,k,w] == 0)   # 3.17

    m.ext[:constraints][:conv_injec_ac_abs_inj_ss] = @constraint(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] == conv_p_ac_inj_ss[cv,t,k,w] - conv_p_ac_abs_ss[cv,t,k,w])

    m.ext[:constraints][:direccional_flow_dc_ss] = @constraint(m, [(d,f,e)=BD_dc_fr, t=T, k=fallos, w=Wind_scenarios],
        brdc_p_ss[(d,f,e),t,k,w] == -brdc_p_ss[(d,e,f),t,k,w])

    m.ext[:constraints][:conv_injec_ac_limit_ss] = @constraint(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_inj_ss[cv,t,k,w] <= conv_p_ac_max[cv] * u_conv_p_ac_ss[cv,t,k,w])
    m.ext[:constraints][:conv_abs_limit_ss] = @constraint(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_abs_ss[cv,t,k,w] <= conv_p_ac_max[cv] * (1 - u_conv_p_ac_ss[cv,t,k,w]))

    # ============================ LINK BETWEEN STAGES ========================
    m.ext[:constraints][:conv_p_ac_link] = @constraint(m, [cv=CV, t=T, k=fallos, w=Wind_scenarios],
        conv_p_ac_ss[cv,t,k,w] == conv_p_ac_fs[cv,t] + conv_p_ac_ss_up[cv,t,k,w] - conv_p_ac_ss_dn[cv,t,k,w])

            # ======================= Solar generation limits =======================
    # Solar is deterministic: the same capacity factor applies in both stages

    # First stage: day-ahead schedule
    m.ext[:constraints][:solar_generation_1_fs] = @constraint(m, [g=G_solar_1, t=T],
        pg_fs[g,t] <= capacity_factor_solar["Nordic"][t] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:solar_generation_2_fs] = @constraint(m, [g=G_solar_2, t=T],
        pg_fs[g,t] <= capacity_factor_solar["GB"][t] * pmax[g])       # area 2 (GB)

    # Second stage: actual operation in each wind realization
    m.ext[:constraints][:solar_generation_1_ss] = @constraint(m, [g=G_solar_1, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] <= capacity_factor_solar["Nordic"][t] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:solar_generation_2_ss] = @constraint(m, [g=G_solar_2, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] <= capacity_factor_solar["GB"][t] * pmax[g])       # area 2 (GB)

    # ======================= Wind generation limits ========================

    # First stage: the day-ahead schedule cannot exceed the forecast wind availability
    m.ext[:constraints][:wind_generation_1_fs] = @constraint(m, [g=G_wind_1, t=T],
        pg_fs[g,t] <= capacity_factor_wind["Nordic"][t] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:wind_generation_2_fs] = @constraint(m, [g=G_wind_2, t=T],
        pg_fs[g,t] <= capacity_factor_wind["GB"][t] * pmax[g])       # area 2 (GB)

    # Second stage: the actual wind output cannot exceed the availability of each realization (high or low)
    m.ext[:constraints][:wind_generation_1_ss] = @constraint(m, [g=G_wind_1, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] <= capacity_factor_wind_w["Nordic"][t][w] * pmax[g])   # area 1 (Nordic)
    m.ext[:constraints][:wind_generation_2_ss] = @constraint(m, [g=G_wind_2, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] <= capacity_factor_wind_w["GB"][t][w] * pmax[g])       # area 2 (GB)

  


   

    # Renewable frequency reserve constraints: renewables do not provide FCR
    renewable_1 = vcat(G_solar_1, G_wind_1)
    renewable_2 = vcat(G_solar_2, G_wind_2)

    # Second stage: no reserve from renewables in any contingency or wind realization (area 1)
    m.ext[:constraints][:renewable_reserve_rg_lg1] = @constraint(m, [g=renewable_1, t=T, k=fallos, w=Wind_scenarios],
        rg_lg1_ss[g,t,k,w] == 0)
    m.ext[:constraints][:renewable_reserve_rg_lc1] = @constraint(m, [g=renewable_1, t=T, k=fallos, w=Wind_scenarios],
        rg_lc1_ss[g,t,k,w] == 0)
    m.ext[:constraints][:renewable_reserve_l_reserve_1] = @constraint(m, [g=renewable_1, t=T, k=fallos, w=Wind_scenarios],
        rg_l_reserve_1_ss[g,t,k,w] == 0)

    # Area 2
    m.ext[:constraints][:renewable_reserve_rg_lg2] = @constraint(m, [g=renewable_2, t=T, k=fallos, w=Wind_scenarios],
        rg_lg2_ss[g,t,k,w] == 0)
    m.ext[:constraints][:renewable_reserve_rg_lc2] = @constraint(m, [g=renewable_2, t=T, k=fallos, w=Wind_scenarios],
        rg_lc2_ss[g,t,k,w] == 0)
    m.ext[:constraints][:renewable_reserve_l_reserve_2] = @constraint(m, [g=renewable_2, t=T, k=fallos, w=Wind_scenarios],
        rg_l_reserve_2_ss[g,t,k,w] == 0)

    # First stage: no procured reserve from renewables
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

    # Second stage: actual output within the unit limits, in every wind realization
    m.ext[:constraints][:max_gen_power_ss] = @constraint(m, [g=G, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] <= pmax[g] * zg_fs[g,t])
    m.ext[:constraints][:min_gen_power_ss] = @constraint(m, [g=G, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] >= pmin[g] * zg_fs[g,t])

    # ===================== Reserve headroom =====================

    # Second stage: the procured reserve must be deliverable on the actual operating point
    m.ext[:constraints][:headroom_rproc_g1_ss] = @constraint(m, [g=G1, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] + r_proc_g_1[g,t] <= pmax[g] * zg_fs[g,t])   # area 1
    m.ext[:constraints][:headroom_rproc_g2_ss] = @constraint(m, [g=G2, t=T, k=fallos, w=Wind_scenarios],
        pg_ss[g,t,k,w] + r_proc_g_2[g,t] <= pmax[g] * zg_fs[g,t])   # area 2

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
    # Second stage: ramp limits on the actual output pg_ss in every contingency k
    #               and wind realization w. The commitment is NOT repeated: start-ups
    #               and shut-downs are first-stage decisions, the same in all scenarios.

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
    #          RAMP LIMITS: SECOND STAGE (actual output in each realization)
    # ---------------------------------------------------------------------
    # Once the wind realization (high or low) is revealed, each generator follows an
    # actual 24-hour trajectory pg_ss, which must also respect the ramp rates.
    # Indices: i = time index, k = contingency, w = wind realization.
    # Start-ups (betag_fs) and shut-downs (gammag_fs) come from the first stage.

    # Ramp-down limit on the actual output
    m.ext[:constraints][:ramp_down_ss] = @constraint(m, [g in TG, i in 2:NT, k in fallos, w in Wind_scenarios],
        pg_ss[g, Tlabels[i-1], k, w] - pg_ss[g, Tlabels[i], k, w] <= downramp[g] + pmin[g] * gammag_fs[g, Tlabels[i]])   # 3.20

    # Ramp-up limit on the actual output
    m.ext[:constraints][:ramp_up_ss] = @constraint(m, [g in TG, i in 2:NT, k in fallos, w in Wind_scenarios],
        pg_ss[g, Tlabels[i], k, w] - pg_ss[g, Tlabels[i-1], k, w] <= upramp[g] + (pmin[g] - upramp[g]) * betag_fs[g, Tlabels[i]])   # 3.19

    # Note: within each hour, the deviation of the actual output from the schedule is
    # limited by the bounds of the adjustment variables (in the variable definitions):
    #   0 <= pg_ss_up[g,t,k,w] <= upramp[g],   0 <= pg_ss_dn[g,t,k,w] <= downramp[g]
    # together with the link: pg_ss[g,t,k,w] == pg_fs[g,t] + pg_ss_up[g,t,k,w] - pg_ss_dn[g,t,k,w]

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
    # Second stage: actual battery operation in every contingency k and wind realization w
    #               (psc_ss, psd_ss, es_ss, zs_ss). The charging/discharging status zs can
    #               change between stages, so each stage has its own binary.

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
    # Same constraints on the actual battery operation, for every contingency k and
    # wind realization w. Each realization must also start and end with the required energy.

    m.ext[:constraints][:upper_bound_storage_charging_ss] = @constraint(m, [s=S, t=T, k=fallos, w=Wind_scenarios],
        psc_ss[s,t,k,w] <= Spmax[s] * (1 - zs_ss[s,t,k,w]))   # 3.25

    m.ext[:constraints][:upper_bound_storage_discharging_ss] = @constraint(m, [s=S, t=T, k=fallos, w=Wind_scenarios],
        psd_ss[s,t,k,w] <= Spmax[s] * zs_ss[s,t,k,w])   # 3.26

    m.ext[:constraints][:initial_energy_value_ss] = @constraint(m, [s in S, k in fallos, w in Wind_scenarios],
        es_ss[s, Tlabels[1], k, w] == Senergyinitial[s])   # 3.27

    m.ext[:constraints][:end_energy_value_ss] = @constraint(m, [s in S, k in fallos, w in Wind_scenarios],
        Senergyend[s] - es_ss[s, Tlabels[NT], k, w] ==
            Sefficiencycarga[s] * psc_ss[s, Tlabels[NT], k, w] - psd_ss[s, Tlabels[NT], k, w] / Sefficiencydischarge[s])   # 3.27

    # i = time index, k = contingency index
    m.ext[:constraints][:energy_balance_ss] = @constraint(m, [s in S, i in 1:NT-1, k in fallos, w in Wind_scenarios],
        es_ss[s, Tlabels[i+1], k, w] - es_ss[s, Tlabels[i], k, w] ==
            Sefficiencycarga[s] * psc_ss[s, Tlabels[i], k, w] - psd_ss[s, Tlabels[i], k, w] / Sefficiencydischarge[s])   # 3.27

    # ---------------------------------------------------------------------
    #                       LINK BETWEEN STAGES
    # ---------------------------------------------------------------------
    # The actual charging/discharging power equals the schedule plus the adjustment.
    # The energy and the status are not linked: they follow from the powers in each stage.

    m.ext[:constraints][:psc_link] = @constraint(m, [s=S, t=T, k=fallos, w=Wind_scenarios],
        psc_ss[s,t,k,w] == psc_fs[s,t] + psc_ss_up[s,t,k,w] - psc_ss_dn[s,t,k,w])

    m.ext[:constraints][:psd_link] = @constraint(m, [s=S, t=T, k=fallos, w=Wind_scenarios],
        psd_ss[s,t,k,w] == psd_fs[s,t] + psd_ss_up[s,t,k,w] - psd_ss_dn[s,t,k,w])



    # =====================================================================
    #                 RESERVOIR AND PUMPED-STORAGE CONSTRAINTS
    # =====================================================================
    # First stage : schedule of reservoirs and pumped-storage units (e_*_fs, pg_fs, p_charge_pump_fs).
    # Second stage: actual operation in every contingency k and wind realization w (e_*_ss, pg_ss, p_charge_pump_ss).
    # The operating mode (generating or pumping) is given by the first-stage commitment zg_fs.
    # Index i = time index (position in Tlabels); k = contingency index.

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

    m.ext[:constraints][:initial_energy_value_reservoir_ss] = @constraint(m, [g in G_reservoir, k in fallos, w in Wind_scenarios],
        e_reservoir_ss[g, Tlabels[1], k, w] == E_reservoirs_ini[g])

    m.ext[:constraints][:end_energy_value_reservoir_ss] = @constraint(m, [g in G_reservoir, k in fallos, w in Wind_scenarios],
        E_reservoirs_end[g] <= e_reservoir_ss[g, Tlabels[NT], k, w] - pg_ss[g, Tlabels[NT], k, w] / G_ngenerating[g])

    m.ext[:constraints][:transition_energy_value_reservoir_ss] = @constraint(m, [g in G_reservoir, i in 1:NT-1, k in fallos, w in Wind_scenarios],
        e_reservoir_ss[g, Tlabels[i+1], k, w] == e_reservoir_ss[g, Tlabels[i], k, w] - pg_ss[g, Tlabels[i], k, w] / G_ngenerating[g])

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

    m.ext[:constraints][:upper_bound_pump_charging_ss] = @constraint(m, [g=G_pump, t=T, k=fallos, w=Wind_scenarios],
        p_charge_pump_ss[g,t,k,w] <= (-P_pump[g]) * (1 - zg_fs[g,t]))

    m.ext[:constraints][:lower_bound_pump_charging_ss] = @constraint(m, [g=G_pump, t=T, k=fallos, w=Wind_scenarios],
        p_charge_pump_ss[g,t,k,w] >= 0.1 * (-P_pump[g]) * (1 - zg_fs[g,t]))

    m.ext[:constraints][:initial_energy_value_pump_ss] = @constraint(m, [g in G_pump, k in fallos, w in Wind_scenarios],
        e_pump_ss[g, Tlabels[1], k, w] == E_reservoirs_ini[g])

    m.ext[:constraints][:end_energy_value_pump_ss] = @constraint(m, [g in G_pump, k in fallos, w in Wind_scenarios],
        E_reservoirs_end[g] == e_pump_ss[g, Tlabels[NT], k, w]
            + p_charge_pump_ss[g, Tlabels[NT], k, w] * G_npumping[g] - pg_ss[g, Tlabels[NT], k, w] / G_ngenerating[g])

    m.ext[:constraints][:energy_balance_pump_ss] = @constraint(m, [g in G_pump, i in 1:NT-1, k in fallos, w in Wind_scenarios],
        e_pump_ss[g, Tlabels[i+1], k, w] == e_pump_ss[g, Tlabels[i], k, w]
            + p_charge_pump_ss[g, Tlabels[i], k, w] * G_npumping[g] - pg_ss[g, Tlabels[i], k, w] / G_ngenerating[g])

    # ---------------------------------------------------------------------
    #                       LINK BETWEEN STAGES
    # ---------------------------------------------------------------------
    # The actual pumping power equals the schedule plus the adjustment.
    # The generating side is already linked through pg_ss = pg_fs + pg_ss_up - pg_ss_dn.

    m.ext[:constraints][:p_charge_pump_link] = @constraint(m, [g=G_pump, t=T, k=fallos, w=Wind_scenarios],
        p_charge_pump_ss[g,t,k,w] == p_charge_pump_fs[g,t] + p_charge_pump_ss_up[g,t,k,w] - p_charge_pump_ss_dn[g,t,k,w])

    # =====================================================================
    #                       ELECTROLYZER CONSTRAINTS
    # =====================================================================
    # First stage : on/off, start-up and standby status (ze_fs, zesu_fs, zestb_fs), and the
    #               day-ahead schedule of power, hydrogen production, trade and storage.
    # Second stage: actual power, production, trade and storage in every contingency k and
    #               wind realization w. The status variables come from the first stage.
    # Index i = time index (position in Tlabels); k = contingency index.

    # ---------------------------------------------------------------------
    #                  STATUS LOGIC: FIRST STAGE ONLY
    # ---------------------------------------------------------------------

    # Start-up at the first hour: counted if the unit is on or in standby at hour 1
    m.ext[:constraints][:e_status_ini] = @constraint(m, [e in E],
        zesu_fs[e, Tlabels[1]] >= (ze_fs[e, Tlabels[1]] - 1) + (zestb_fs[e, Tlabels[1]] - 0))

    # Start-up in subsequent hours: counted when the unit switches on or into standby
    m.ext[:constraints][:e_status_subsequent] = @constraint(m, [e in E, i in 2:NT],
        zesu_fs[e, Tlabels[i]] >= (ze_fs[e, Tlabels[i]] - ze_fs[e, Tlabels[i-1]]) +
                                (zestb_fs[e, Tlabels[i]] - zestb_fs[e, Tlabels[i-1]]))

    # The electrolyzer cannot be on and in standby at the same time
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
    # Same constraints on the actual operation, with the first-stage status variables.

    m.ext[:constraints][:hydrogen_production_ss] = @constraint(m, [e in E, t in T, k in fallos, w in Wind_scenarios],
        hfe_ss[e,t,k,w] == pe_ss[e,t,k,w] / Eefficiency[e] - 0.05 * Epmax[e] * zestb_fs[e,t] / Eefficiency[e])

    m.ext[:constraints][:e_lower_bound_ss] = @constraint(m, [e=E, t=T, k=fallos, w=Wind_scenarios],
        pe_ss[e,t,k,w] >= Epmin[e] * ze_fs[e,t] + 0.05 * Epmax[e] * zestb_fs[e,t])
    m.ext[:constraints][:e_upper_bound_ss] = @constraint(m, [e=E, t=T, k=fallos, w=Wind_scenarios],
        pe_ss[e,t,k,w] <= Epmax[e] * ze_fs[e,t] + 0.05 * Epmax[e] * zestb_fs[e,t])

    m.ext[:constraints][:initial_hydrogen_value_ss] = @constraint(m, [e in E, k in fallos, w in Wind_scenarios],
        hss_ss[e, Tlabels[1], k, w] == Estorageinitial[e])

    m.ext[:constraints][:end_hydrogen_value_ss] = @constraint(m, [e in E, k in fallos, w in Wind_scenarios],
        Estorageend[e] == hss_ss[e, Tlabels[NT], k, w] + hfe_ss[e, Tlabels[NT], k, w]
            - hfginyect_ss[e, Tlabels[NT], k, w] / Eeficiencycarga[e]
            + hfgconsum_ss[e, Tlabels[NT], k, w] * Eeficiencydischarge[e]
            - Eloadfactor[e] * Epmax[e] / Eefficiency[e])

    m.ext[:constraints][:charging_discharging_hydrogen_ss] = @constraint(m, [e in E, i in 1:NT-1, k in fallos, w in Wind_scenarios],
        hss_ss[e, Tlabels[i+1], k, w] == hss_ss[e, Tlabels[i], k, w] + hfe_ss[e, Tlabels[i], k, w]
            - hfginyect_ss[e, Tlabels[i], k, w] / Eeficiencycarga[e]
            + hfgconsum_ss[e, Tlabels[i], k, w] * Eeficiencydischarge[e]
            - Eloadfactor[e] * Epmax[e] / Eefficiency[e])

    m.ext[:constraints][:compressor_power_ss] = @constraint(m, [e in E, t in T, k in fallos, w in Wind_scenarios],
        pe_compressor_ss[e,t,k,w] == Ecompressorpower[e] * (hfe_ss[e,t,k,w] + hfgconsum_ss[e,t,k,w] + hfginyect_ss[e,t,k,w]))

    # ---------------------------------------------------------------------
    #                       LINKS BETWEEN STAGES
    # ---------------------------------------------------------------------
    # Only the decisions taken directly by the operator are linked: electrolyzer power and
    # hydrogen trade. Production, storage and compressor power follow from them in each stage.

    # Electrolyzer power: schedule plus adjustment
    m.ext[:constraints][:pe_link] = @constraint(m, [e=E, t=T, k=fallos, w=Wind_scenarios],
        pe_ss[e,t,k,w] == pe_fs[e,t] + pe_ss_up[e,t,k,w] - pe_ss_dn[e,t,k,w])

    # Hydrogen purchased (consumed from the grid): schedule plus adjustment
    m.ext[:constraints][:hfgconsum_link] = @constraint(m, [e=E, t=T, k=fallos, w=Wind_scenarios],
        hfgconsum_ss[e,t,k,w] == hfgconsum_fs[e,t] + hfgconsum_ss_up[e,t,k,w] - hfgconsum_ss_dn[e,t,k,w])

    # Hydrogen sold (injected to the grid): schedule plus adjustment
    m.ext[:constraints][:hfginyect_link] = @constraint(m, [e=E, t=T, k=fallos, w=Wind_scenarios],
        hfginyect_ss[e,t,k,w] == hfginyect_fs[e,t] + hfginyect_ss_up[e,t,k,w] - hfginyect_ss_dn[e,t,k,w])



    
   


    #Events constraints (loss of generators)

    # m.ext[:constraints][:event_binary_constraint]= @constraint(m, [g=G,t=T],
    # zg[g,t]>=δg[g,t])

    m.ext[:constraints][:gen_constraint_1]= @constraint(m, [g=G1,t=T],
    pg[g,t]<=plg1[t]
    )

    m.ext[:constraints][:gen_constraint_2]= @constraint(m, [g=G2,t=T],
    pg[g,t]<=plg2[t] 
    )
    #Events constraints (loss of converters)
    m.ext[:constraints][:conv_constraint_1]= @constraint(m, [cv=CV1,t=T],
    conv_p_ac_inj[cv,t]<=plc1[t]
    )
    m.ext[:constraints][:conv_constraint_2]= @constraint(m, [cv=CV2,t=T],
    conv_p_ac_inj[cv,t]<=plc2[t]
    )

    #  m.ext[:constraints][:event_binary_constraint_c]= @constraint(m, [cv=CV,t=T],
    # u_conv_p_ac[cv,t]>=δhvdc[cv,t])

    #event constraint (frequency reserve provision)
    m.ext[:constraints][:loss_of_power_frequency_reserve_G_A_1]= @constraint(m, [t=T],
    sum(rhvdc_lg2[cv,t] for cv in CV2)==plreserve_1[t]
    )
    m.ext[:constraints][:loss_of_power_frequency_reserve_C_A_1]= @constraint(m, [t=T],
    sum(rhvdc_lc2[cv,t] for cv in CV2)<=plreserve_1[t]
    )
    
    m.ext[:constraints][:loss_of_power_frequency_reserve_G_A_2]= @constraint(m, [t=T],
    sum(rhvdc_lg1[cv,t] for cv in CV1)==plreserve_2[t]
    )
    m.ext[:constraints][:loss_of_power_frequency_reserve_C_A_2]= @constraint(m, [t=T],
    sum(rhvdc_lc1[cv,t] for cv in CV1)<=plreserve_2[t]
    )

    
    #Constraints that define that just one single events is considered per area

    m.ext[:constraints][:single_event_generator_1]= @constraint(m, [t=T],
    sum(δg[g,t] for g in G1) ==1
    )
 
    m.ext[:constraints][:single_event_generator_2]= @constraint(m, [t=T],
    sum(δg[g,t] for g in G2) ==1
    )

      m.ext[:constraints][:single_event_converter_1]= @constraint(m, [t=T],
    sum(δhvdc[cv,t] for cv in CV1) ==1
    )
    m.ext[:constraints][:single_event_converter_2]= @constraint(m, [t=T],
    sum(δhvdc[cv,t] for cv in CV2) ==1
    ) 
 



    bigMG=Dict()
    bigMC=Dict()
    for g in G
        bigMG[g]=pmax[g]
    end

    maxbigMG=maximum(values(bigMG))
    

    for cv in CV
        bigMC[cv]=conv_p_ac_max[cv]
    end

    maxbigMC=maximum(values(bigMC))
   
     m.ext[:constraints][:big_m1_gen_1]= @constraint(m, [g=G1,t=T],
    (δg[g,t]-1)*maxbigMC<= plg1[t]-pg[g,t]
    )
    m.ext[:constraints][:big_m2_gen_1]= @constraint(m, [g=G1,t=T],
    plg1[t]-pg[g,t] <= (1-δg[g,t])*maxbigMG
    )
    
    m.ext[:constraints][:big_m1_gen_2]= @constraint(m, [g=G2,t=T],
    (δg[g,t]-1)*maxbigMG<= plg2[t]-pg[g,t]
    )
    m.ext[:constraints][:big_m2_gen_2]= @constraint(m, [g=G2,t=T],
    plg2[t]-pg[g,t] <= (1-δg[g,t])*maxbigMG
    )

    m.ext[:constraints][:big_m1_conv_1]= @constraint(m, [cv=CV1,t=T],
    (δhvdc[cv,t]-1)*maxbigMC<= plc1[t]-conv_p_ac_inj[cv,t]
    )

    m.ext[:constraints][:big_m2_conv_1]= @constraint(m, [cv=CV1,t=T],
    plc1[t]-conv_p_ac_inj[cv,t] <= (1-δhvdc[cv,t])*maxbigMC
    )

    m.ext[:constraints][:big_m1_conv_2]= @constraint(m, [cv=CV2,t=T],
    (δhvdc[cv,t]-1)*maxbigMC<= plc2[t]-conv_p_ac_inj[cv,t]
    )

    m.ext[:constraints][:big_m2_conv_2]= @constraint(m, [cv=CV2,t=T],
    plc2[t]-conv_p_ac_inj[cv,t] <= (1-δhvdc[cv,t])*maxbigMC
    )

    # Inertia value per area after the event
    Inertia_nadir_frequency_1=Dict()
    Inertia_nadir_frequency_2=Dict()
    Inertia_nadir_frequency_converter_1=Dict()
    Inertia_nadir_frequency_converter_2=Dict()
    for t in T 
        Inertia_nadir_frequency_1[t]=sum((zg[g,t]-δg[g,t])*ic[g]*pmax[g] for g in G1)
        Inertia_nadir_frequency_2[t]=sum((zg[g,t]-δg[g,t])*ic[g]*pmax[g] for g in G2)
        Inertia_nadir_frequency_converter_1[t]=sum(zg[g,t]*ic[g]*pmax[g] for g in G1)
        Inertia_nadir_frequency_converter_2[t]=sum(zg[g,t]*ic[g]*pmax[g] for g in G2)
    end
    

  #bounding the FFR and FCR contributions of all generator andconverter assets
  m.ext[:constraints][:fcr_bound_gen_lg1]= @constraint(m, [g in G1, t in T],
     rg_lg1[g,t]<=(1-δg[g,t])*upramp[g]*G_dt[g]/3600
    )
    m.ext[:constraints][:fcr_bound_gen_lc1]= @constraint(m, [g in G1, t in T],
     rg_lc1[g,t]<=upramp[g]*G_dt[g]/3600
    )

    m.ext[:constraints][:fcr_bound_gen_lreserve_1]= @constraint(m, [g in G1, t in T],
     rg_l_reserve_1[g,t]<=upramp[g]*G_dt[g]/3600
    )
    
    m.ext[:constraints][:fcr_bound_gen_lg2]= @constraint(m, [g in G2, t in T],
     rg_lg2[g,t]<=(1-δg[g,t])*upramp[g]*G_dt[g]/3600
    )

    m.ext[:constraints][:fcr_bound_gen_lc2]= @constraint(m, [g in G2, t in T],
     rg_lc2[g,t]<=upramp[g]*G_dt[g]/3600
    )
    m.ext[:constraints][:fcr_bound_gen_lreserve_2]= @constraint(m, [g in G2, t in T],
     rg_l_reserve_2[g,t]<=upramp[g]*G_dt[g]/3600
    )


    m.ext[:constraints][:fcr_bound_conv_lg1]= @constraint(m, [cv in CV1, t in T],
         rhvdc_lg1[cv,t]<=2*conv_p_ac_max[cv]
     )
     m.ext[:constraints][:fcr_bound_conv_lc1]= @constraint(m, [cv in CV1, t in T],
         rhvdc_lc1[cv,t]<=(1-δhvdc[cv,t])*2*conv_p_ac_max[cv]
     )

    m.ext[:constraints][:fcr_bound_conv_lg2]= @constraint(m, [cv in CV2, t in T],
        rhvdc_lg2[cv,t]<=2*conv_p_ac_max[cv]
    )

    m.ext[:constraints][:fcr_bound_conv_lc2]= @constraint(m, [cv in CV2, t in T],
        rhvdc_lc2[cv,t]<=(1-δhvdc[cv,t])*2*conv_p_ac_max[cv]
    )







    #HVDC headroom reserve constraints
    m.ext[:constraints][:hvdc_headroom_reserve_upper_lg1]= @constraint(m, [cv in CV1, t in T],
        conv_p_ac[cv,t]+rhvdc_lg1[cv,t] <= conv_p_ac_max[cv]
    )

    m.ext[:constraints][:hvdc_headroom_reserve_lower_lg1]= @constraint(m, [cv in CV1, t in T],
        -conv_p_ac_max[cv]<=conv_p_ac[cv,t]+rhvdc_lg1[cv,t] 
    )

    m.ext[:constraints][:hvdc_headroom_reserve_upper_lc1]= @constraint(m, [cv in CV1, t in T],
        conv_p_ac[cv,t]+rhvdc_lc1[cv,t] <= conv_p_ac_max[cv]
    )

    m.ext[:constraints][:hvdc_headroom_reserve_lower_lc1]= @constraint(m, [cv in CV1, t in T],
        -conv_p_ac_max[cv]<=conv_p_ac[cv,t]+rhvdc_lc1[cv,t] 
    )

    m.ext[:constraints][:hvdc_headroom_reserve_upper_lg2]= @constraint(m, [cv in CV2, t in T],
        conv_p_ac[cv,t]+rhvdc_lg2[cv,t] <= conv_p_ac_max[cv]
    )
    m.ext[:constraints][:hvdc_headroom_reserve_lower_lg2]= @constraint(m, [cv in CV2, t in T],
        -conv_p_ac_max[cv]<=conv_p_ac[cv,t]+rhvdc_lg2[cv,t] 
    )

    m.ext[:constraints][:hvdc_headroom_reserve_upper_lc2]= @constraint(m, [cv in CV2, t in T],
        conv_p_ac[cv,t]+rhvdc_lc2[cv,t] <= conv_p_ac_max[cv]
    )

    m.ext[:constraints][:hvdc_headroom_reserve_lower_lc2]= @constraint(m, [cv in CV2, t in T],
        -conv_p_ac_max[cv]<=conv_p_ac[cv,t]+rhvdc_lc2[cv,t] 
    )

        #Reserve storage bound constraints per areas and type of contigency
        m.ext[:constraints][:reserve_storage_lg1]=@constraint(m, [s=S1, t=T],
            rs_lg1[s,t] <=  Spmax[s]+psc[s,t]-psd[s,t]
        )
        m.ext[:constraints][:reserve_storage_lc1]=@constraint(m, [s=S1, t=T],
            rs_lc1[s,t] <=  Spmax[s]+psc[s,t]-psd[s,t]
        )

        m.ext[:constraints][:reserve_storage_l_reserve_1]=@constraint(m, [s=S1, t=T],
        rs_l_reserve_1[s,t] <=  Spmax[s]+psc[s,t]-psd[s,t]
        )

        m.ext[:constraints][:reserve_storage_lg2]=@constraint(m, [s=S2, t=T],
            rs_lg2[s,t] <=  Spmax[s]+psc[s,t]-psd[s,t]
        )
        m.ext[:constraints][:reserve_storage_lc2]=@constraint(m, [s=S2, t=T],
            rs_lc2[s,t] <=  Spmax[s]+psc[s,t]-psd[s,t]
        )
        m.ext[:constraints][:reserve_storage_l_reserve_2]=@constraint(m, [s=S2, t=T],
        rs_l_reserve_2[s,t] <=  Spmax[s]+psc[s,t]-psd[s,t]
        )


        #Reserve electrolyzer bound constraint per areas and type of contigency
        m.ext[:constraints][:reserve_electrolyzer_lg1]=@constraint(m, [e=E1, t=T],
            re_lg1[e,t] <=  pe[e,t]-Epmin[e] * ze[e,t]-0.05*Epmax[e]*zestb[e,t] 
        )
        m.ext[:constraints][:reserve_electrolyzer_lc1]=@constraint(m, [e=E1, t=T],
            re_lc1[e,t] <=  pe[e,t]-Epmin[e] * ze[e,t]-0.05*Epmax[e]*zestb[e,t]
        )

        m.ext[:constraints][:reserve_electrolyzer_l_reserve_1]=@constraint(m, [e=E1, t=T],
        re_l_reserve_1[e,t] <=  pe[e,t]-Epmin[e] * ze[e,t]-0.05*Epmax[e]*zestb[e,t]
        )

        m.ext[:constraints][:reserve_electrolyzer_lg2]=@constraint(m, [e=E2, t=T],
            re_lg2[e,t] <=  pe[e,t]-Epmin[e] * ze[e,t]-0.05*Epmax[e]*zestb[e,t]
        )
        m.ext[:constraints][:reserve_electrolyzer_lc2]=@constraint(m, [e=E2, t=T],
            re_lc2[e,t] <=  pe[e,t]-Epmin[e] * ze[e,t]-0.05*Epmax[e]*zestb[e,t] 
        )
        m.ext[:constraints][:reserve_electrolyzer_l_reserve_2]=@constraint(m, [e=E2, t=T],
        re_l_reserve_2[e,t] <=  pe[e,t]-Epmin[e] * ze[e,t] -0.05*Epmax[e]*zestb[e,t]
        )

        
    #Reserve bound constraints
    m.ext[:constraints][:reserve_bound_rg_lg1] = @constraint(m, [g in G1, t in T],
    rg_lg1[g,t] <= MaxFreqDev[g]*zg[g,t]
    )

    m.ext[:constraints][:reserve_bound_rg_lc1] = @constraint(m, [g in G1, t in T],
    rg_lc1[g,t] <= MaxFreqDev[g]*zg[g,t]
    )

    m.ext[:constraints][:reserve_bound_rg_l_reserve_1] = @constraint(m, [g in G1, t in T],
    rg_l_reserve_1[g,t] <= MaxFreqDev[g]*zg[g,t]
    )

    m.ext[:constraints][:reserve_bound_rg_lg2] = @constraint(m, [g in G2, t in T],
    rg_lg2[g,t] <= MaxFreqDev[g]*zg[g,t]
    )

    m.ext[:constraints][:reserve_bound_rg_lc2] = @constraint(m, [g in G2, t in T],
    rg_lc2[g,t] <= MaxFreqDev[g]*zg[g,t]
    )

    m.ext[:constraints][:reserve_bound_rg_l_reserve_2] = @constraint(m, [g in G2, t in T],
    rg_l_reserve_2[g,t] <= MaxFreqDev[g]*zg[g,t]
    )
    

   



    #Rocof constraints generators and converters per areas
    m.ext[:constraints][:rocof_constraint_plg_1]= @constraint(m, [t in T],
        f1*plg1[t] <= rocof1*(2*Inertia_nadir_frequency_1[t] )
    )

    m.ext[:constraints][:rocof_constraint_plc_1]= @constraint(m, [t in T], 
        f1*plc1[t] <= rocof1*(2*Inertia_nadir_frequency_converter_1[t] )
    )
    
    m.ext[:constraints][:rocof_constraint_plg_2]= @constraint(m, [t in T],
        f2*plg2[t] <= rocof2*(2*Inertia_nadir_frequency_2[t] )
    )

    m.ext[:constraints][:rocof_constraint_plc_2]= @constraint(m, [t in T],
        f2*plc2[t] <= rocof2*(2*Inertia_nadir_frequency_converter_2[t] )
    )

    m.ext[:constraints][:rocof_constraint_plreserve_1]= @constraint(m, [t in T],
        f1*plreserve_1[t] <= rocof1*(2*Inertia_nadir_frequency_converter_1[t] )
    )

    m.ext[:constraints][:rocof_constraint_plreserve_2]= @constraint(m, [t in T],
        f2*plreserve_2[t] <= rocof2*(2*Inertia_nadir_frequency_converter_2[t] )
    )

    #Power balance constraint

        m.ext[:constraints][:power_balance_lg1]= @constraint(m, [t in T],
        sum(rs_lg1[s,t] for s in S1)+sum(re_lg1[e,t] for e in E1)+sum(rg_lg1[g,t] for g in G1)+sum(rhvdc_lg1[cv,t] for cv in CV1)>=plg1[t]
    )
    m.ext[:constraints][:power_balance_lc1]= @constraint(m, [t in T],
      sum(rs_lc1[s,t] for s in S1)+sum(re_lc1[e,t] for e in E1)+sum(rg_lc1[g,t] for g in G1)+sum(rhvdc_lc1[cv,t] for cv in CV1)>=plc1[t]
    )

     m.ext[:constraints][:power_balance_lg2]= @constraint(m, [t in T],
        sum(rs_lg2[s,t] for s in S2)+sum(re_lg2[e,t] for e in E2)+sum(rg_lg2[g,t] for g in G2)+sum(rhvdc_lg2[cv,t] for cv in CV2)>=plg2[t]
    )
     m.ext[:constraints][:power_balance_lc2]= @constraint(m, [t in T],
        sum(rs_lc2[s,t] for s in S2)+sum(re_lc2[e,t] for e in E2)+sum(rg_lc2[g,t] for g in G2)+sum(rhvdc_lc2[cv,t] for cv in CV2)>=plc2[t]
    )

    m.ext[:constraints][:power_balance_lreserve_1]= @constraint(m, [t in T],
        sum(rs_l_reserve_1[s,t] for s in S1)+sum(re_l_reserve_1[e,t] for e in E1)+sum(rg_l_reserve_1[g,t] for g in G1)>=plreserve_1[t]
    )
    m.ext[:constraints][:power_balance_lreserve_2]= @constraint(m, [t in T],
        sum(rs_l_reserve_2[s,t] for s in S2)+sum(re_l_reserve_2[e,t] for e in E2)+sum(rg_l_reserve_2[g,t] for g in G2)>=plreserve_2[t]
    )

   # Constraint frequency nadir generators and converters area 1

    m.ext[:constraints][:nadir_frequency_g_1_constraint_1]= @constraint(m, [t in T],
    ypg1[t]==2*deltaf1*(Inertia_nadir_frequency_1[t] )/f1-sum(re_lg1[e,t]*Edeployment[e] for e in E1)/2-sum(rs_lg1[s,t]*Sdeployment[s] for s in S1)/2-sum(rhvdc_lg1[cv,t]*HVDC_deployment[cv] for cv in CV1)/2   
    )

    m.ext[:constraints][:nadir_frequency_g_1_constraint_2]= @constraint(m, [t in T],
    zpg1[t]==sum(rg_lg1[g,t]/G_dt[g] for g in G1)   
    )


    m.ext[:constraints][:nadir_frequency_g_1_constraint_3] = @constraint(m,[t in T],
    [ypg1[t]; zpg1[t]; plg1[t]-sum(re_lg1[e,t] for e in E1)-sum(rs_lg1[s,t] for s in S1)-sum(rhvdc_lg1[cv,t] for cv in CV1)] in RotatedSecondOrderCone()
    )

    m.ext[:constraints][:nadir_frequency_c_1_constraint_1]= @constraint(m, [t in T],
    ypc1[t]==2*deltaf1*(Inertia_nadir_frequency_converter_1[t] )/f1-sum(re_lc1[e,t]*Edeployment[e] for e in E1)/2-sum(rs_lc1[s,t]*Sdeployment[s] for s in S1)/2-sum(rhvdc_lc1[cv,t]*HVDC_deployment[cv] for cv in CV1)/2 
    )

    m.ext[:constraints][:nadir_frequency_c_1_constraint_2]= @constraint(m, [t in T],
    zpc1[t]==sum(rg_lc1[g,t]/G_dt[g] for g in G1)
    )

    m.ext[:constraints][:nadir_frequency_c_1_constraint_3] = @constraint(m,[t in T],
    [ypc1[t]; zpc1[t]; plc1[t]-sum(re_lc1[e,t] for e in E1)-sum(rs_lc1[s,t] for s in S1)-sum(rhvdc_lc1[cv,t] for cv in CV1)] in RotatedSecondOrderCone()
    )

    m.ext[:constraints][:nadir_frequency_reserve_1_constraint_1]= @constraint(m, [t in T],
    ypreserve1[t]==2*deltaf1*(Inertia_nadir_frequency_converter_1[t] )/f1-sum(re_l_reserve_1[e,t]*Edeployment[e] for e in E1)/2-sum(rs_l_reserve_1[s,t]*Sdeployment[s] for s in S1)/2
    )

    m.ext[:constraints][:nadir_frequency_reserve_1_constraint_2]= @constraint(m, [t in T],
    zpreserve1[t]==sum(rg_l_reserve_1[g,t]/G_dt[g] for g in G1)
    )
    m.ext[:constraints][:nadir_frequency_reserve_1_constraint_3] = @constraint(m,[t in T],
    [ypreserve1[t]; zpreserve1[t]; plreserve_1[t]-sum(re_l_reserve_1[e,t] for e in E1)-sum(rs_l_reserve_1[s,t] for s in S1)] in RotatedSecondOrderCone()
    )

    # #Constraint frequency nadir generators and converters area 2

    m.ext[:constraints][:nadir_frequency_g_2_constraint_1]= @constraint(m, [t in T],
    ypg2[t]==2*deltaf2*(Inertia_nadir_frequency_2[t] )/f2-sum(re_lg2[e,t]*Edeployment[e] for e in E2)/2-sum(rs_lg2[s,t]*Sdeployment[s] for s in S2)/2-sum(rhvdc_lg2[cv,t]*HVDC_deployment[cv] for cv in CV2)/2   
    )

    m.ext[:constraints][:nadir_frequency_g_2_constraint_2]= @constraint(m, [t in T],
    zpg2[t]==sum(rg_lg2[g,t]/G_dt[g] for g in G2)   
    )

    m.ext[:constraints][:nadir_frequency_g_2_constraint_3] = @constraint(m,[t in T],
    [ypg2[t]; zpg2[t]; plg2[t]-sum(re_lg2[e,t] for e in E2)-sum(rs_lg2[s,t] for s in S2)-sum(rhvdc_lg2[cv,t] for cv in CV2) ] in RotatedSecondOrderCone()
    )

    m.ext[:constraints][:nadir_frequency_c_2_constraint_1]= @constraint(m, [t in T],
    ypc2[t]==2*deltaf2*(Inertia_nadir_frequency_converter_2[t] )/f2-sum(re_lc2[e,t]*Edeployment[e] for e in E2)/2-sum(rs_lc2[s,t]*Sdeployment[s] for s in S2)/2-sum(rhvdc_lc2[cv,t]*HVDC_deployment[cv] for cv in CV2)/2 
    )

    m.ext[:constraints][:nadir_frequency_c_2_constraint_2]= @constraint(m, [t in T],
    zpc2[t]==sum(rg_lc2[g,t]/G_dt[g] for g in G2)
    )

    m.ext[:constraints][:nadir_frequency_c_2_constraint_3] = @constraint(m,[t in T],
    [ypc2[t]; zpc2[t]; plc2[t]-sum(re_lc2[e,t] for e in E2)-sum(rs_lc2[s,t] for s in S2)-sum(rhvdc_lc2[cv,t] for cv in CV2) ] in RotatedSecondOrderCone()
    )

    m.ext[:constraints][:nadir_frequency_reserve_2_constraint_1]= @constraint(m, [t in T],
    ypreserve2[t]==2*deltaf2*(Inertia_nadir_frequency_converter_2[t] )/f2-sum(re_l_reserve_2[e,t]*Edeployment[e] for e in E2)/2-sum(rs_l_reserve_2[s,t]*Sdeployment[s] for s in S2)/2
    )

    m.ext[:constraints][:nadir_frequency_reserve_2_constraint_2]= @constraint(m, [t in T],
    zpreserve2[t]==sum(rg_l_reserve_2[g,t]/G_dt[g] for g in G2)
    )
    m.ext[:constraints][:nadir_frequency_reserve_2_constraint_3] = @constraint(m,[t in T],
    [ypreserve2[t]; zpreserve2[t]; plreserve_2[t]-sum(re_l_reserve_2[e,t] for e in E2)-sum(rs_l_reserve_2[s,t] for s in S2)] in RotatedSecondOrderCone()
    )
   

    # #Constraint time occurrence nadir
    m.ext[:constraints][:time_nadir_occurrence_g1_1]= @constraint(m, [t in T],
    plg1[t]<= 0.0000001+ sum(re_lg1[e,t] for e in E1)+sum(rs_lg1[s,t] for s in S1)+sum(rhvdc_lg1[cv,t] for cv in CV1)+sum(rg_lg1[g,t] for g in G1)
    )
    m.ext[:constraints][:time_nadir_occurrence_g1_2]= @constraint(m, [t in T],
    plg1[t]>=0.0000001+ sum(re_lg1[e,t] for e in E1)+sum(rs_lg1[s,t] for s in S1)+sum(rhvdc_lg1[cv,t] for cv in CV1)+sum(rg_lg1[g,t] for g in G1)*Edeployment["1"]/G_dt["1"]
    )

    m.ext[:constraints][:time_nadir_occurrence_c1_1]= @constraint(m, [t in T],
    plc1[t]<= 0.0000001+ sum(re_lc1[e,t] for e in E1)+sum(rs_lc1[s,t] for s in S1)+sum(rhvdc_lc1[cv,t] for cv in CV1)+sum(rg_lc1[g,t] for g in G1)
    )
    m.ext[:constraints][:time_nadir_occurrence_c1_2]= @constraint(m, [t in T],
    plc1[t]>=0.0000001+ sum(re_lc1[e,t] for e in E1)+sum(rs_lc1[s,t] for s in S1)+sum(rhvdc_lc1[cv,t] for cv in CV1)+sum(rg_lc1[g,t] for g in G1)*Edeployment["1"]/G_dt["1"]
    )

    m.ext[:constraints][:time_nadir_occurrence_g2_1]= @constraint(m, [t in T],
    plg2[t]<= 0.0000001 +sum(re_lg2[e,t] for e in E2)+sum(rs_lg2[s,t] for s in S2)+sum(rhvdc_lg2[cv,t] for cv in CV2)+sum(rg_lg2[g,t] for g in G2)
    )
    m.ext[:constraints][:time_nadir_occurrence_g2_2]= @constraint(m, [t in T],
    plg2[t]>=0.0000001 +sum(re_lg2[e,t] for e in E2)+sum(rs_lg2[s,t] for s in S2)+sum(rhvdc_lg2[cv,t] for cv in CV2)+sum(rg_lg2[g,t] for g in G2)*Edeployment["1"]/G_dt["1"]
    )

    m.ext[:constraints][:time_nadir_occurrence_c2_1]= @constraint(m, [t in T],
    plc2[t]<= 0.0000001 +sum(re_lc2[e,t] for e in E2)+sum(rs_lc2[s,t] for s in S2)+sum(rhvdc_lc2[cv,t] for cv in CV2)+sum(rg_lc2[g,t] for g in G2)
    )
    m.ext[:constraints][:time_nadir_occurrence_c2_2]= @constraint(m, [t in T],
    plc2[t]>=0.0000001 +sum(re_lc2[e,t] for e in E2)+sum(rs_lc2[s,t] for s in S2)+sum(rhvdc_lc2[cv,t] for cv in CV2)+sum(rg_lc2[g,t] for g in G2)*Edeployment["1"]/G_dt["1"]
    )

    m.ext[:constraints][:time_nadir_occurrence_reserve_1_1]= @constraint(m, [t in T],
    plreserve_1[t]<= 0.0000001 +sum(re_l_reserve_1[e,t] for e in E1)+sum(rs_l_reserve_1[s,t] for s in S1)+sum(rg_l_reserve_1[g,t] for g in G1)
    )
    m.ext[:constraints][:time_nadir_occurrence_reserve_1_2]= @constraint(m, [t in T],
    plreserve_1[t]>=0.0000001 +sum(re_l_reserve_1[e,t] for e in E1)+sum(rs_l_reserve_1[s,t] for s in S1)+sum(rg_l_reserve_1[g,t] for g in G1)*Edeployment["1"]/G_dt["1"]
    )

    m.ext[:constraints][:time_nadir_occurrence_reserve_2_1]= @constraint(m, [t in T],
    plreserve_2[t]<= 0.0000001 +sum(re_l_reserve_2[e,t] for e in E2)+sum(rs_l_reserve_2[s,t] for s in S2)+sum(rg_l_reserve_2[g,t] for g in G2)
    )
    m.ext[:constraints][:time_nadir_occurrence_reserve_2_2]= @constraint(m, [t in T],
    plreserve_2[t]>=0.0000001 +sum(re_l_reserve_2[e,t] for e in E2)+sum(rs_l_reserve_2[s,t] for s in S2)+sum(rg_l_reserve_2[g,t] for g in G2)*Edeployment["1"]/G_dt["1"]
    )

    #Absolute value constraints
  





      
    return m 
end
