/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*This is a small SAS program to perform nonparametric bootstraps for a regression						*/
/*It is not efficient nor general																		*/
/*Inputs: 																								*/
/*	- NumberOfLoops: the number of bootstrap iterations													*/
/*	- Dataset: A SAS dataset containing the response and covariate										*/
/*	- XVariable: The covariate for our regression model (gen. continuous numeric)						*/
/*	- YVariable: The response variable for our regression model (gen. continuous numeric)				*/
/*Outputs:																								*/
/*	- ResultHolder: A SAS dataset with NumberOfLoops rows and two columns, RandomIntercept & RandomSlope*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

%macro regBoot(NumberOfLoops, DataSet, XVariable, YVariable);

/*Number of rows in my dataset*/
 	data _null_;
  	set &DataSet NOBS=size;
  	call symput("NROW",size);
 	stop;
 	run;

/*loop over the number of randomisations required*/
%do i=1 %to &NumberOfLoops;

	/*Sample my data with replacement*/
 	/*suggestion is to generate NRow * NumberOfLoops in a single dataset*/
	/*and then perform regression model split BY NRowsn*/

	proc surveyselect data=&DataSet out=bootData seed=-180029290 method=urs noprint sampsize=&NROW;
	run;

	/*Conduct a regression on this randomised dataset and get parameter estimates*/
	proc reg data=bootData outest=ParameterEstimates  noprint;
	Model &YVariable=&XVariable;
	run;
	quit;

	/*Extract just the columns for slope and intercept for storage*/
	data Temp;
	set ParameterEstimates;
	keep Intercept &XVariable;
	run;

	/*Create a new results dataset if the first iteration, append for following iterations*/
	data ResultHolder;
		%if &i=1 %then %do;
			set Temp;
		%end;
		%else %do;
			set ResultHolder Temp;
		%end;
	run;
%end;
/*Rename the results something nice*/
data ResultHolder;
set ResultHolder;
rename Intercept=RandomIntercept &XVariable=RandomSlope;
run;
%mend;


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*Our Team SAS macro - name and comments to be added by the group once Sam has stepped through			*/
/*what the macro actual does																			*/
/*Inputs: 																								*/
/*	- NumberOfLoops: the number of bootstrap iterations													*/
/*	- Dataset: A SAS dataset containing the response and covariate										*/
/*	- XVariable: The covariate for our regression model (gen. continuous numeric)						*/
/*	- YVariable: The response variable for our regression model (gen. continuous numeric)				*/
/*Outputs:																								*/
/*	- RTF file: */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
%macro regBootTwo(NumberOfLoops, DataSet, XVariable, YVariable);

	/* I would like to use this in some way however appears to slow the macro down when low number of 	*/
	/* NumberOfLoops are passed ( ~ < 100000 ) 															*/

	/* sasfile &Dataset load; */

	proc surveyselect data = &DataSet out = bootData2
		seed = 180029290
		method = urs
		noprint 
		samprate = 100
		rep = &NumberOfLoops;
	run;

	/* sasfile &Dataset close; */

	proc reg data = bootdata2 outest = parameterestimates  noprint;
		by Replicate;
		model &yvariable = &xvariable;
	run;

	data ResultHolder2;
		set ParameterEstimates;
		keep Intercept &XVariable;
		rename Intercept = RandomIntercept &XVariable = RandomSlope;
	run;

	ods listing close;
	ods rtf file = 'C:\Users\Samwise\Documents\MT5763\Assignment #02\teamOutput.rtf';
		proc means data = ResultHolder2 mean lclm uclm alpha = 0.05;
			var RandomIntercept RandomSlope;
		run;
	ods rtf close;
	ods listing;

%mend;

/*
proc univariate data=resultholder2;  
var randomslope;  output out=final pctlpts=2.5, 97.5 pctlpre=ci;
run;
 
proc mean data=resultholder2;
var randomslope;  output out=final;
run;
*/


data work.Test;
       infile 'C:\Users\Samwise\Documents\MT5763\Assignment #02\fitness.csv' dlm = ',' firstobs = 2;
       input Age Weight Oxygen RunTime RestPulse RunPulse MaxPulse;
run;

options nonotes;

/*Run the macro*/

/* Start timer */
%let _timer_start = %sysfunc(datetime());

/*%regBoot(NumberOfLoops=100, DataSet=Work.Sasdataset, XVariable=Age, YVariable=Weight);*/
%regBootTwo(NumberOfLoops = 100, DataSet = work.Test, XVariable = Age, YVariable = Weight);

/* Stop timer */
data _null_;
  dur = datetime() - &_timer_start;
  put 30*'-' / ' TOTAL DURATION:' dur time13.2 / 30*'-';
run;
