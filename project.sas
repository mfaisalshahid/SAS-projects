libname lib '/folders/myfolders';

/* Question 1 */
proc freq data=lib.schdata;
	tables race / chisq TESTP=(0.45,0.2,0.35) nocum plots=NONE;
run;

/* Question 2 */
proc freq data=lib.schdata;
	tables gender / chisq nocum plots=None;
run;

/* Question 3 */
proc format;
value ScoreFmt  
      low  -  40   = 1
       40  -  46   = 2
       46  -  48   = 3
       48  -  52   = 4
       52  - high  = 5;
run;

proc freq data=lib.schdata;
	format read ScoreFmt.;
	tables read / NOCUM NOPERCENT out=ReadSplit;
run;

data ReadSplit;
	set ReadSplit;
	if _n_ = 1 then do; a = -999; b = 40; end;
	else if _n_ = 2 then do; a = 40; b = 46; end;
	else if _n_ = 3 then do; a = 46; b = 48; end;
	if _n_ = 4 then do; a = 48; b = 52; end;
	if _n_ = 5 then do; a = 52; b = 999; end;
run;

proc print data=ReadSplit; run;

*Calculate expected counts based on normal distribution N(47.8, 8.8^2);
data ReadSplit;
	set ReadSplit;
	bb=(b-47.8)/8.8;
	aa=(a-47.8)/8.8;
	if _n_=1 then exp_count=55*probnorm(bb);
	if _n_=5 then exp_count=55*(1-probnorm(aa));
	exp_count=55*(probnorm(bb)-probnorm(aa));
run;

* Computer Chi-square test statistic;
data ReadSplit;
set ReadSplit;
	chisq=(count-exp_count)**2/exp_count;
run;

proc means data=ReadSplit noprint;
	var chisq;
	output out=aa sum=sum_chisq;
run;

* Computer p-value for test normal distribution based on observed
* counts. df=g-k-1=number of groups - number of parameters for the
* distribution -1;
data aa;
	set aa;
	p_value = 1-probchi(sum_chisq, 2);
run;

proc print data=aa noobs;
	var sum_chisq p_value;
run;

/* Question 4 */
ODS select TTests Equality Statistics;
proc ttest data=lib.schdata;
	title "T-test for means comparison";
	class gender;
	var read write math science socst;
run;
ODS select off;

/* Question 5 */
data female;
	set lib.schdata;
	if gender = 1 then delete;
run;

proc sql;
	create table scimath as
	select science as score, 'science' as name from female
	union all
	select math as score, 'math' as name from female;
quit;

proc sql;
	create table writesoc as
	select write as score, 'write' as name from female
	union all
	select socst as score, 'socst' as name from female;
quit;

ODS Select WilcoxonTest;
proc NPAR1WAY data=scimath wilcoxon;
	title "Nonparametric test to compare equality between science and maths";
	class name;
	var score;
	exact wilcoxon / MC N=100000;
run;

ODS Select WilcoxonTest;
proc NPAR1WAY data=writesoc wilcoxon;
	title "Nonparametric test to compare equality between write and socst";
	class name;
	var score;
	exact wilcoxon / MC N=100000;
run;