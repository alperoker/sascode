/* Code developed by ALPER OKER - BUSINESS CONSULTANT AND ANALYST AT EY - 26JAN2023 */
/**/
/* Missing over time, Mean value over time */

/*NOTE: WHEN CALCULATING MEAN VALUE, MISSING VALUES ARE EXCLUDED. */

/* Attribute binned and stacked over time */

/* Stacked bar chart with line between means - Box Plot */

/* Below library is for the definition of input table. */

libname stage '/sasdata/rcmd_botw_integ/LGD_EAD'; /* Library including input table -- Replace this statement with your library and directory */

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

ods graphics on / width=15in height=10in;

title j=left 
      font= 'Times New Roman' color=black bcolor= LightSteelBlue
      c=black bold italic "Missing Values Over &TIME_GROUP";

proc sgplot data=TIME_MISSING_&COLUMN;
vline &TIME_GROUP / response = MissingPct_&COLUMN lineattrs=(color=grey thickness=4) nostatlabel name='b'; 
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
create view final1 as
select f.&TIME_GROUP, f.&COLUMN.binned, f._FREQ_ as count, m.&COLUMN as mean
from freq f
left join means m
on f.&TIME_GROUP = m.&TIME_GROUP;

create view final2 as 
select &TIME_GROUP, &COLUMN.binned, count as bin_count, sum(count) as all_count,
count / sum(count) * 100 as bin_percentage, mean
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

vbarparm category=&TIME_GROUP response=bin_percentage / group=&COLUMN.binned  seglabel seglabelattrs=(size=4) datalabel  datalabelattrs=(size=4) groupdisplay=stack;
series x=&TIME_GROUP y=mean / y2axis lineattrs=(color=darkblue  thickness=2 pattern=MediumDash);
series x=&TIME_GROUP y=missing_percentage / lineattrs=(color=yellow  thickness=3 pattern=LongDash);
label mean="Mean&TIME_GROUP";
label bin_percentage='Bin&MissingPercentages';
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


%MEND;

/*Please enter your "libname.Table", "Column" to be analyzed, Name of the "Date column" for time series analysis and "time period" */
/* Code developed by ALPER OKER - BUSINESS CONSULTANT AND ANALYST AT EY - 26JAN2023 */
/*TIME_GROUP can be YEAR, YEARMONTH, YEARQUARTER */

%DQ_TIMESERIES(stage.EAD_US_NEW,N_UTILIZATION,DFT_DT,YEAR)

/* If they want to do format they have to specifically define format before they execute the query. */
/* For now equally divide each interval for example 5,6,7 etc.. */
/* For specific formats we will show it to client later */
/* 2 versions of this functions: 1) equal intervals and 2) proc formats. 