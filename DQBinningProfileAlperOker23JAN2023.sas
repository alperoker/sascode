/* Code developed by ALPER OKER - BUSINESS CONSULTANT AND ANALYST AT EY - 23JAN2023 */

/* Missing over time, Mean value over time */

/* Attribute binned over time */

/* Stacked bar chart with line between means - Box Plot */

/*Below the first library is for the definition of input table. The second is to load output tables */

libname stage '/sasdata/rcmd_botw_integ/LGD_EAD'; /* Library including input table */

/* This Macro expects "TABLE NAME", "COLUMN NAME", "DATE COLUMN NAME" AND "TIME PERIOD" AS INPUT FROM THE USER" */

%MACRO DQ_TIMESERIES (DATA, COLUMN, DATE_COLUMN, TIME_GROUP);

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

ods graphics on / width=25in height=15in;

title j=left 
      font= 'Times New Roman' color=black bcolor= LightSteelBlue
      c=black bold italic "Missing Values Over Time";

proc sgplot data=TIME_MISSING_&COLUMN;
vline &TIME_GROUP / response = MissingPct_&COLUMN lineattrs=(color=lightred thickness=4) nostatlabel name='b'; 
xaxis valueattrs=(size=13pt color=black) labelattrs=(size=15pt weight=bold) offsetmin=0;
yaxis labelattrs=(size=15pt weight=bold) valueattrs=(size=15pt color=black) offsetmin=0;
keylegend / valueattrs=(size=15pt) titleattrs=(size=18pt);
run;

title;

data binned_&COLUMN;
set DATA_TIME;
keep &TIME_GROUP &COLUMN.binned;

/*USER IS EXPECTED TO MODIFY HERE TO CALIBRATE IT BASED ON SPECIFIC ANALYSIS NEEDS */         
                                                                                               
if (&COLUMN >= 0) and (&COLUMN < 0.2) then &COLUMN.binned = 1;                         
if (&COLUMN >= 0.2) and (&COLUMN < 0.4) then &COLUMN.binned = 2;                           
if (&COLUMN >= 0.4) and (&COLUMN < 0.6) then &COLUMN.binned = 3;                      
if (&COLUMN >= 0.6) and (&COLUMN < 0.8) then &COLUMN.binned = 4;                          
if (&COLUMN >= 0.8) and (&COLUMN <= 1) then &COLUMN.binned = 5;                       
 
/*  USER IS EXPECTED TO MODIFY HERE TO CALIBRATE IT BASED ON SPECIFIC ANALYSIS NEEDS  */
run;

title j=left 
      font= 'Times New Roman' color=black bcolor= LightSteelBlue
      c=black bold italic "Box Plot with Mean values connected";

proc sgplot data=DATA_TIME;
vbox &COLUMN / category=&TIME_GROUP CONNECT=MEAN CONNECTATTRS=(thickness=3 color=darkgreen);
xaxis valueattrs=(size=13pt color=black) labelattrs=(size=15pt weight=bold) offsetmin=0;
yaxis labelattrs=(size=15pt weight=bold) valueattrs=(size=15pt color=black) offsetmin=0;
run;

title;

title j=left 
      font= 'Times New Roman' color=black bcolor= LightSteelBlue
      c=black bold italic "Stacked Bar Plot";

ODS EXCLUDE ALL;

proc sort data=binned_&COLUMN out=sorted;
by &TIME_GROUP;
run;

proc sort data=binned_&COLUMN out=sorted2;
by &TIME_GROUP &COLUMN.binned;
run;

proc means data=sorted;
by &TIME_GROUP;
output out=means mean=;
run;

proc means data=sorted2;
by &TIME_GROUP &COLUMN.binned;
output out=freq;
run;

proc sql;
create view final as
select f.&TIME_GROUP, f.&COLUMN.binned, f._FREQ_/sum(f._FREQ_) * 100 as percentage, m.&COLUMN.binned as mean
from freq f
left join means m
on f.&TIME_GROUP = m.&TIME_GROUP;
run;
quit;

ODS EXCLUDE NONE;

proc sgplot data=final;

vbarparm category=&TIME_GROUP response=percentage / group=&COLUMN.binned  seglabel seglabelattrs=(size=4) datalabel  datalabelattrs=(size=4) groupdisplay=stack;
series x=&TIME_GROUP y=mean/ y2axis lineattrs=(color=lightred thickness=4);
xaxis valueattrs=(size=13pt color=black) labelattrs=(size=15pt weight=bold) offsetmin=0;
yaxis labelattrs=(size=15pt weight=bold) valueattrs=(size=15pt color=black) offsetmin=0;
y2axis labelattrs=(size=15pt weight=bold) valueattrs=(size=15pt color=black) offsetmin=0;
keylegend / valueattrs=(size=15pt) titleattrs=(size=18pt);

run;
title;


%MEND;

/*Please enter your "libname.Table", "Column" to be analyzed, Name of the "Date column" for time series analysis and "time period" */
/*TIME_GROUP can be YEAR, YEARMONTH, YEARQUARTER */

%DQ_TIMESERIES(stage.EAD_US_NEW,N_UTILIZATION,DFT_DT,YEARQUARTER)

/* Code developed by ALPER OKER - BUSINESS CONSULTANT AND ANALYST AT EY - 23JAN2023 */

/* Replace count with percentage in stack bar. */

Alper Oker 3rd 4th aa
