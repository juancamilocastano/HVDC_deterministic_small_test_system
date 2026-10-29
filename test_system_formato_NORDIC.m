%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                                                                  			 	  %%%%%
%%%%    IEEE PES Power Grid Library - Optimal Power Flow with HVDC Lines - v23.09     %%%%%
%%%%          (https://github.com/power-grid-lib/pglib-opf-hvdc)      				  %%%%%
%%%%               Benchmark Group - Typical Operations               				  %%%%%
%%%%                         23 - August - 2023                       				  %%%%%
%%%%                                                                  				  %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   AC/DC grid OPF test case based on:
%   Sass, F., Sennewald, T., Marten, A.-K. and Westermann, D. (2017),
%   Mixed AC high-voltage direct current benchmark test system for security constrained optimal power flow calculation.
%   IET Gener. Transm. Distrib., 11: 447-455. https://doi.org/10.1049/iet-gtd.2016.0993
%
%   Copyright (c) 2023 by Hakan Ergun, Vaishally Bhardwaj ({hakan.ergun, vaishally.bhardwaj}@kuleuven.be)
%   Licensed under the Creative Commons Attribution 4.0
%   International license, http://creativecommons.org/licenses/by/4.0/
%
%   CONVERSION NOTE
%   This file is test_system.m rewritten in the format of test_system_NORDIC_GB_HVDC.m:
%   - mpc.gencost uses the linear model (n=2: c1, c0) instead of n=3 (c2, c1, c0).
%   - mpc.genextra has the 18-column layout with technology type (col 12).
%   - G1-G6 are thermal units (type 4 = gas). MaxFRdeliverable = 10% of Pmax.
%   - The two rows of the former mpc.wind are now generators G7-G8 (type 8 = wind)
%     in mpc.gen, mpc.gencost and mpc.genextra. mpc.wind has been removed.
%   - mpc.solar_roof added with 0 MW in both areas.
%   - Generator status set to 1 (it was 0 for all units in the original file).
%

function mpc = case67
mpc.version = '2';
mpc.baseMVA = 100.0;
mpc.baseKG=31034.48;
mpc.frequency1=50;
mpc.frequency2=50;
mpc.rocof1=0.6;
mpc.rocof2=0.4;
mpc.deltaf1=0.8;
mpc.deltaf2=0.8;

%After Vm, they are generic values

%% bus data
%	bus_i	type		Pd		Qd		  Gs	 Bs	   area		Vm	   Va		   baseKV	zone	  Vmax			 Vmin
mpc.bus = [
	1	 	1	 		0.0	 	0.0	 	  0.0	 0.0	 1	    1.0	    0	 		380.0	  1	      1.10000	    0.90000;
	2	 	2	 		0.0	    0.0	      0.0	 0.0	 1	    1.0	    0	 		380.0	  1	      1.10000	    0.90000;
	];



%% generator data
%	bus	   Pg	  Qg		Qmax		 Qmin	  Vg	   mBase	status		Pmax	  Pmin	 Pc1	 Pc2   Qc1min	Qc1max    Qc2min	Qc2max	ramp_agc	    ramp_10	      ramp_30	  ramp_q	   apf         alpha
% Rows 1-6: thermal units G1-G6.
% Rows 7-8: wind units G7-G8 (former mpc.wind), Pmin = 0, as in the NORDIC_GB wind fleet.
mpc.gen = [
	1	0	0	0	0	0	100	1	120.0	12.0	0	0	0	0	0	0	0	0	0	0	0	0;   % G1 thermal
	1	0	0	0	0	0	100	1	 50.0	 5.0	0	0	0	0	0	0	0	0	0	0	0	0;   % G2 thermal
	1	0	0	0	0	0	100	1	 50.0	 5.0	0	0	0	0	0	0	0	0	0	0	0	0;   % G3 thermal
	2	0	0	0	0	0	100	1	120.0	12.0	0	0	0	0	0	0	0	0	0	0	0	0;   % G4 thermal
	2	0	0	0	0	0	100	1	 50.0	 5.0	0	0	0	0	0	0	0	0	0	0	0	0;   % G5 thermal
	2	0	0	0	0	0	100	1	 50.0	 5.0	0	0	0	0	0	0	0	0	0	0	0	0;   % G6 thermal
	1	0	0	0	0	0	100	1	100.0	 0	0	0	0	0	0	0	0	0	0	0	0	0;   % G7 wind (area 1)
	2	0	0	0	0	0	100	1	 33.3	 0	0	0	0	0	0	0	0	0	0	0	0	0;   % G8 wind (area 2)
];


%% bus mapping: n1=1, n2=2, n3=3, n4=4, n5=5, n6=6

%% branch data r, x, b assigned randomly using random data for matpower case 14
%  1-fbus  2-tbus   3-r       4-x       5-b       6-rateA  7-rateB  8-rateC  9-ratio  10-angle  11-status  12-angmin  13-angmax
mpc.branch = [
     1       2     0.0235    0.0712    0.0356     100      100      100       0         0         1         -60         60;  % n1–n2
 
];

%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%  busdc_i    grid    Pdc     Vdc   basekVdc    Vdcmax   Vdcmin   Cdc  area
mpc.busdc = [
    			1       1       0       1       500       1.1     0.9     0	  1;
    			2       1       0       1       500       1.1     0.9     0	  1;
];

%% converters
%column_names%  busdc_i  busac_i  area  type_dc  type_ac   P_g       Q_g   islcc  Vtar   rtf   xtf   transformer  tm   bf    filter   rc     xc     reactor  basekVac  Vmmax  Vmmin  Imax  status  LossA  LossB  LossCrec  LossCinv  droop    Pdcset     Vdcset   dVdcset  Pacmax  Pacmin  Qacmax  Qacmin   DT   reservecost
mpc.convdc = [
                1        1        1     2        1        -577.5     0     0      1     0.01  0.01      1        1   0.01     0     0.01   0.01     0       500      1.1    0.9    1.1    1     1.103  0.887  2.885   2.885    0.0050   -465.9871  0.9999    20.001   20.001   20.001   20.001   -20.001   0.2    0.01;
                2        2        2     3        1         1000      0     0      1     0.01  0.01      1        1   0.01     0     0.01   0.01     0       500      1.1    0.9    1.1    1     1.103  0.887  2.885   2.885    0.0050    500.0000  0.9947    20.001   20.001   20.001   20.001   -20.001   0.2    0.01;
];


%% branches
%column_names%  fbusdc  tbusdc  r        l   c   rateA   rateB   rateC   status
mpc.branchdc = [
      1        2       0.0012   0    0      20.001       20.001       20.001        1;
      ];

%% generator cost data
% 1-model  2-startup  3-shutdown  4-n   5-c1($/MWh)  6-c0
% Linear cost model: Cost = c1*P + c0. All rows use n=2, so only 2 coefficients (c1, c0) are given.
% Rows 7-8: wind units (zero generation cost, no startup cost).
mpc.gencost = [
    2        5            0         2     20       0;   % G1 thermal
    2        5            0         2     35       0;   % G2 thermal
    2        5            0         2     45       0;   % G3 thermal
    2        5            0         2      1       0;   % G4 thermal
    2        5            0         2      1       0;   % G5 thermal
    2        5            0         2      1       0;   % G6 thermal
    2        0            0         2      0       0;   % G7 wind
    2        0            0         2      0       0;   % G8 wind
];

%% Unified extra operational data with technology type
% Columns:
% Bus  DT[s]  IC[s]  upramp_MWph  downramp_MWph  MUT[h]  MDT[h]  reservecost_g  MaxFRdeliverable[MW]  Ppump  Storage  type  n_pumping  n_generating  E_Pump_min  E_Pump_ini  E_pump_end  area
%
% type:
% 1 = mpc.genextra_reservoir
% 2 = mpc.gen_extra_pump
% 3 = mpc.gen_extra_nuclear
% 4 = mpc.gen_extra_gas
% 5 = mpc.gen_extra_biomass
% 6 = mpc.gen_extra_oil
% 7 = mpc.gen_extra_solar
% 8 = mpc.gen_extra_wind
%
% Rows 1-6: thermal units (type 4), MaxFRdeliverable = 10% of Pmax.
% Rows 7-8: wind units (type 8), same non-dispatchable characteristics as the NORDIC_GB wind fleet
% (DT=0.03 s, no ramp limits, no MUT/MDT, no reserve).
mpc.genextra = [
%   bus  DT     IC     up    down  MUT  MDT  rcost  MaxFR  Ppump  Stor  type  npump  ngen  Emin  Eini  Eend  area
    1    15     40.02  720   720   4    4    4.01   12.0   0      0     4     0      0     0     0     0     1;   % G1
    1    15     40.02  720   720   4    4    4.01    5.0   0      0     4     0      0     0     0     0     1;   % G2
    1    15     40.02  720   720   4    4    4.01    5.0   0      0     4     0      0     0     0     0     1;   % G3
    2    15     40.02  720   720   4    4    4.01   12.0   0      0     4     0      0     0     0     0     2;   % G4
    2    15     40.02  720   720   4    4    4.01    5.0   0      0     4     0      0     0     0     0     2;   % G5
    2    15     40.02  720   720   4    4    4.01    5.0   0      0     4     0      0     0     0     0     2;   % G6
    1    0.03   0      0     0     0    0    0       0     0      0     8     0      0     0     0     0     1;   % G7 wind
    2    0.03   0      0     0     0    0    0       0     0      0     8     0      0     0     0     0     2;   % G8 wind
];


%% BESS data (custom)
%  1-AC_bus   2-area   3-Pmax_MW   4-Emax_MWh   5-DODmax   6-eta_c   7-eta_d   8-E_init_MWh   9-E_final_MWh   10-DeployTime_s   11-ReserveCost_$_per_MW_h
mpc.bess = [
    1           1        40         93.3        0.793      0.9       0.9        20              20               0.2                15.3;
    2           2        30         70.0        0.793      0.9       0.9        15              15               0.2                15.3;
];




%% Electrolyzer data
%  1-AC_bus   2-area   3-Pmax_MW   4-Pmin_MW   5-eta_ely_MWh_per_kg   6-LoadFactor   7-max_hydrog_flow_kg   8-Smax_kg    9-Smin_kg   10-S0_kg   11-ST_kg   12-DeployTime_s   13-ReserveCost_£_per_MW_h   14-eta_c   15-eta_d   16-StartupCost_£   17-CompressEnergy_MWh_per_kg   18-Hydrogen_market_price_Eur_per_kg
mpc.elec = [
    1   1   55   7.5   0.058   0.8   1293.10   31034.48   310.34   7758.62   7758.62   0.2   15.3  0.9   0.9   855.5   0.00167   4;
    2   2   45   6.5   0.058   0.8   1120.68   26896.50   268.96   6724.13   6724.13   0.2   15.3   0.9   0.9   855.5   0.00167   4;
];

%% Rooftop solar data
% 1-AC_bus   2-area   3-Pmax_MW
% No rooftop solar in this system (0 MW in both areas).
mpc.solar_roof = [
    1   1   0;
    2   2   0;
];
