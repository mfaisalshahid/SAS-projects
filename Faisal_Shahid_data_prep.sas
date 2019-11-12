/* Question 1 */
/* Use your own path to import data  */
/* proc import datafile = '/folders/myfolders/ASSIGN_DATA.csv' */
 out = mydata
 dbms = csv
 replace;
run;

proc sql;
	create table decile (Decile numeric, TPC numeric, FPC numeric, FNC numeric, TNC numeric);
	insert into decile
		values (1, 49929, 49816, 16, 239)
		values (2, 49345, 47386, 600, 2669)
		values (3, 47071, 40677, 2874, 9378)
		values (4, 41958, 30607, 7987, 19448)
		values (5, 31951, 18725, 17994, 31330)
		values (6, 17816, 7201, 32129, 42854)
		values (7, 9737, 2263, 40208, 47792)
		values (8, 6565, 1040, 43380, 49015)
		values (9, 670, 57, 49275, 49998);
	select * from decile; 
quit;

proc means data=decile noprint;
   class Decile;
   types Decile;
   var True_Target Posterior_Probability;
   output out=LogiDecileOut mean=TrueMeam PredMean lclm=True_TargetLower uclm=True_TargetUpper;
run;

data decilesesp;
	set decile;
	Sensitivity = TPC/(TPC + FNC);
	False_Alarm_Rate = 1-(TNC/(TNC + FPC));
run;

proc sgplot data=decilesesp;
	title "ROC Curve (Decile level)";
	series x=False_Alarm_Rate y=Sensitivity / Legendlabel="ROC";
	lineparm x=0 y=0 slope=1 / TRANSPARENCY=0.6 LEGENDLABEL="Random";
run;


proc rank data=mydata out=percentile ties=low descending groups=100;
	var Posterior_Probability;
	ranks percentile;
run;

proc sql noprint;
select sum(True_Target) into: total_positive from percentile;
select &total_positive/count(*) into: TPP from percentile;

create table lift_table as
select
	percentile + 1 as percentile,
	count(*) as freq,
	sum(True_Target) as TPC,
	sum(True_Target)/(count(*)*&TPP) as lift
from percentile
group by percentile
order by percentile
;
run;

data lift_table;
	set lift_table;
	CTPC + TPC;
	cum_freq + freq;
	cum_lift = CTPC/(cum_freq*0.49945);
run;

proc sgplot data=lift_table;
	title "Lift Chart (Percentile level)";
	series x=percentile y=lift;
	series x=percentile y=cum_lift;
	refline 1 / axis=y label="Reference" lineattrs=(Pattern=ShortDash);
run;


%let i = 3;
proc sql;
	Select *
    From
	(select count(*) from mydata where Posterior_Probability>&i/10 and True_Target=1) as TP,
	(select count(*) from mydata where Posterior_Probability>&i/10 and True_Target=0) as FP,
	(select count(*) from mydata where Posterior_Probability<&i/10 and True_Target=0) as TN,
	(select count(*) from mydata where Posterior_Probability<&i/10 and True_Target=1) as FN;
run;

data confusion_1;
input _ $ Positive Negative;
datalines;
True 49929 16
False 49816 239
;

proc print data=confusion_1; run;

data confusion_2;
input _ $ Positive Negative;
datalines;
True 49345 600
False 47386 2669
;

proc print data=confusion_2; run;

data confusion_3;
input _ $ Positive Negative;
datalines;
True 47071 2874
False 40677 9378
;

proc print data=confusion_3; run;
