/* Code developed by ALPER OKER - BUSINESS CONSULTANT AND ANALYST AT EY - 26JAN2023 */

/*NOTE: WHEN CALCULATING MEAN VALUE, MISSING VALUES ARE EXCLUDED. */

/* Below library is for the definition of input table. */

libname stage '/sasdata/rcmd_botw_integ/LGD_EAD'; /* Library including input table -- Replace this statement with your library and directory */

/* This Macro expects "TABLE NAME", "COLUMN NAME", "DATE COLUMN NAME" AND "TIME PERIOD" AS INPUT FROM THE USER" */

%MACRO DQ_TIMESERIES (DATA, COLUMN, DATE_COLUMN, TIME_GROUP,NUM_BIN);

/*Create new columns for YEAR, YEARQUARTER AND YEARMONTH */

data DATA_TIME;
set &DATA;
YEAR = year(&DATE_COLUMN);
YEARQUARTER = put(&DATE_COLUMN, yyq6.);
YEARMONTH = put(&DATE_COLUMN,yymmn6.); 
run;

/* CREATE THE TIME-MISSING COUNT TABLE */

PROC SQL;
CREATE VIEW TIME_MISSING_&COLUMN AS
SELECT &TIME_GROUP, COUNT(*) as TotalCount, COUNT(*) - COUNT(&COLUMN) as MissingCount_&COLUMN, COUNT(&COLUMN) as NonMissingCount, (calculated MissingCount_&COLUMN) / (calculated TotalCount) * 100 
as MissingPct_&COLUMN
FROM DATA_TIME
GROUP BY &TIME_GROUP;
QUIT;

/* Plot the graph in which x=time period y=missing_pct */

ods graphics on / width=10in height=5in;

ODS EXCLUDE ALL;

PROC HPBIN DATA=DATA_TIME output=binned1_&COLUMN numbin=&NUM_BIN bucket;
ID &TIME_GROUP;
input &COLUMN;
run;

data binned_&COLUMN;
set binned1_&COLUMN;
if bin_&COLUMN = 0 then bin_&COLUMN = .;
run;

ODS EXCLUDE NONE;

title j=left 
      font= 'Times New Roman' color=black bcolor= LightSteelBlue
      c=black bold italic "Box Plot with Mean values connected";

proc sgplot data=DATA_TIME;
vbox &COLUMN / category=&TIME_GROUP CONNECT=MEAN CONNECTATTRS=(thickness=2 color=black);
xaxis valueattrs=(size=13pt color=black) labelattrs=(size=15pt weight=bold) offsetmin=0;
yaxis labelattrs=(size=15pt weight=bold) valueattrs=(size=15pt color=black) offsetmin=0;
run;

title;

ODS EXCLUDE ALL;

proc sort data=DATA_TIME out=sorted;
by &TIME_GROUP;
run;

proc sort data=binned_&COLUMN out=sorted2;
by &TIME_GROUP bin_&COLUMN;
run;

proc means data=sorted;
by &TIME_GROUP;
output out=means mean=;
run;

proc means data=sorted2;
by &TIME_GROUP bin_&COLUMN;
output out=freq;
run;

proc sql;
create view final1 as
select f.&TIME_GROUP, f.bin_&COLUMN, f._FREQ_ as count, sum(f._FREQ_) as all, m.&COLUMN as mean
from freq f
left join means m
on f.&TIME_GROUP = m.&TIME_GROUP;

create view final2 as 
select &TIME_GROUP, bin_&COLUMN, count as bin_count, sum(count) as all_count,
count / sum(count) * 100 as bin_percentage, mean, calculated all_count / all * 100 as population_percentage
from final1
group by &TIME_GROUP;

create view final as
select f.*, t.MissingPct_&COLUMN as missing_percentage
from final2 f
left join TIME_MISSING_&COLUMN t
on f.&TIME_GROUP = t.&TIME_GROUP;
quit;

ODS EXCLUDE NONE;

title j=left 
      font= 'Times New Roman' color=black bcolor= LightSteelBlue
      c=black bold italic "Stacked Bar Plot through &TIME_GROUP";

proc sgplot data=final;

vbarparm category=&TIME_GROUP response=bin_percentage / group=bin_&COLUMN  seglabel seglabelattrs=(size=4) datalabel  datalabelattrs=(size=4) groupdisplay=stack;
series x=&TIME_GROUP y=mean / y2axis lineattrs=(color=darkblue  thickness=2 pattern=MediumDash);
series x=&TIME_GROUP y=missing_percentage / lineattrs=(color=yellow  thickness=3 pattern=LongDash);
series x=&TIME_GROUP y=population_percentage / lineattrs=(color=orange  thickness=3 pattern=ShortDash);
label mean="&TIME_GROUP.LYMean_&COLUMN";
label bin_percentage='Percentages';
xaxis valueattrs=(size=13pt color=black) labelattrs=(size=15pt weight=bold) offsetmin=0;
yaxis labelattrs=(size=15pt weight=bold) valueattrs=(size=15pt color=black) offsetmin=0;
y2axis labelattrs=(size=15pt weight=bold) valueattrs=(size=15pt color=black) offsetmin=0;
keylegend / valueattrs=(size=15pt) titleattrs=(size=18pt);

run;
title;

ODS EXCLUDE ALL;

proc sql;
select min(&DATE_COLUMN), MAX(&DATE_COLUMN)
INTO: MIN_DATE, :MAX_DATE
FROM &DATA;
QUIT;

data monthlist;
date=&MIN_DATE;
do while (date<=&MAX_DATE);
    output;
    date=intnx('month', date, 1, 's');
end;
run;

data MONTH_LIST;
set MONTHLIST;
keep yearmonth;
YEARMONTH = put(DATE,yymmn6.); 
run;

ODS EXCLUDE NONE;

title j=left 
      font= 'Times New Roman' color=black bcolor= LightSteelBlue
      c=black bold italic "MONTHS WHICH DO NOT HAVE ANY RECORDS";

proc sql;
select ml.yearmonth AS YEARMONTH_NOSNAPSHOTS
FROM month_list ml
left join DATA_TIME d
on ml.yearmonth = d.yearmonth
having d.yearmonth is missing;
quit;

TITLE;


%MEND DQ_TIMESERIES;

/* Code developed by ALPER OKER - BUSINESS CONSULTANT AND ANALYST AT EY - 26JAN2023 */
/*%DQ_TIMESERIES(stage.EAD_US_NEW,N_UTILIZATION,DFT_DT,YEARQUARTER,5) */

/*TIME_GROUP can be YEAR, YEARMONTH, YEARQUARTER */
/*Please enter your "libname.Table", "Column" to be analyzed, Name of the "Date column" for time series analysis and "time period" */
%DQ_TIMESERIES(stage.EAD_US_NEW, N_UTILIZATION, DFT_DT, YEAR, 6)
%MACRO DQ_TIMESERIES_LOOP (DATA, DATE_COLUMN, TIME_GROUP, NUM_BIN);

PROC CONTENTS DATA=&DATA out=metadata;
RUN;

data numerical_vars;
set metadata;
keep Name;
if (Type=1 and Format ne 'DATE') then output;
run;

data _null_;
set numerical_vars;
call symputx(cats('num_vars',_n_),NAME);
run;

proc sql;
select count(*) as num_len
into: num_len
from numerical_vars;
quit;

%do i=1 %to 1;

%DQ_TIMESERIES(stage.EAD_US_NEW, N_UTILIZATION, DFT_DT, YEAR, 6)

%end;



%MEND DQ_TIMESERIES_LOOP;

%DQ_TIMESERIES_LOOP(stage.EAD_US_NEW,DFT_DT,YEAR,6)
