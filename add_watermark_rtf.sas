/*********************************************************
     Author: Xinwei.zhong  Create Date:2024-04-17
*********************************************************/

%macro add_watermark_rtf(rtfloc=
					,rtfname=
					,watermarktext=
					,wmtextSize=
					,wmtextFont=
					,wmfillColor=
					,wmfillOpacity=  /* Opacity*1000 */
					,wmshapeType=  /*136~175*/
					,wmrotation=   /*0, angle*100*1000 */
					,outpath=
					,outputname=
					,orientation=
					,xy_wknum=
					,xy_width=
					,debug=);
%put NOTE: -------------------- Macro[&SYSMACRONAME.] Start --------------------;
%put @@-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*@@;
%put   Purpose: Modify the fonts of an rtf document generated by SAS | Author: xinwei.zhong 2024-04-11;
%put @@-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*@@;

%************************************************************************************;
%if %length(&rtfloc.)=0 %then %do;
	%put ERROR: Parameter[rtfloc] is uninitialized, please check!!; %return;
%end;
%let rtfloc=%sysfunc(tranwrd(&rtfloc.,\,/));
%if %sysfunc(fileexist(&rtfloc.))=0 %then %do; 
	%put ERROR: Path[rtfloc=&rtfloc.] no exist, please check!; 
%end;
%if %length(&outpath.)=0 %then %let outpath=%str(&rtfloc.);
%let outpath=%sysfunc(tranwrd(&outpath.,\,/));

%if %length(&rtfname.)>0 %then %do;
	%if %index(&rtfname.,%str(.))=0 %then %let rtfname=%str(&rtfname..rtf);
		%else %if "%upcase(%scan(&rtfname.,-1,.))"^="RTF" %then %do;
			 %put ERROR: File[&rtfloc./&rtfname.] no rtf file, please check!; %return;
		%end;
	%if %sysfunc(fileexist(&rtfloc./&rtfname.))=0 %then %do; 
		%put ERROR: File[&rtfloc./&rtfname.] no exist, please check!;  %return;
	%end;
	%if %length(&outputname.)=0 %then %let outputname=%scan(&rtfname.,1,%str(.))_modify.rtf;
	%if %index(&outputname.,%str(.))=0 %then %let outputname=%str(&outputname..rtf);
	%put &rtfname. | &outputname.;
%end; %else %do;
	%put ERROR: Parameter[rtfname] is uninitialized, please check!!; %return;
%end;
%if %length(&watermarktext.)=0 %then %do;
	%put ERROR: Parameter[watermarktext] is uninitialized, please check!!; %return;
%end;
%if %length(&wmtextSize.)=0 %then %let wmtextSize=%str(65536);
%if %length(&wmtextFont.)=0 %then %let wmtextFont=%str(SimSun);
%if %length(&wmfillColor.)=0 %then %let wmfillColor=%str(black);

%if %length(&wmshapeType.)=0 %then %let wmshapeType=%str(136);
%if %length(&wmrotation.)=0 %then %let wmrotation=%str(20643840);
%if %length(&orientation.)=0 %then %let orientation=%sysfunc(getoption(orientation));
%let orientation=%upcase(&orientation.);

%if %length(&xy_wknum.)=0 %then %let xy_wknum=%str(1|1);
%let xy_wknum=%sysfunc(tranwrd(&xy_wknum.,#,|));
%let x_wknum=%scan(&xy_wknum.,1,|);
%let y_wknum=%scan(&xy_wknum.,2,|);
%if %length(&x_wknum.)=0 %then %let x_wknum=%str(1);
%if %length(&y_wknum.)=0 %then %let y_wknum=%str(1);
%if &y_wknum.>2 %then %let y_wknum=%eval(&y_wknum.-1);
%if %length(&debug.)=0 %then %let debug=0;

%if %length(&xy_width.)=0 %then %let xy_width=%str(2400|400);
%let xy_width=%sysfunc(tranwrd(&xy_width.,#,|));
%let xwidth=%scan(&xy_width.,1,|);
%let ywidth=%scan(&xy_width.,2,|);
%if %length(&xwidth.)=0 %then %let xwidth=%str(2400);
%if %length(&ywidth.)=0 %then %let ywidth=%str(400);

*********************************************************;
%let _headern=0; 
%let _margheadfootoptn=0; 
data __rtff; 
	infile "&rtfloc./&rtfname." length=linelen lrecl=5000 recfm=v;
	input linein $varying5000. linelen;
	n=_n_;
	if index(linein,'{\header\') then do;
		call symputx('_headern',cats(n));
	end;
	if prxmatch('#(\\marg)([^\\]+)(\\)#',linein) and (prxmatch('#(\\headery)(\d+)(\\)#',linein) or prxmatch('#(\\footery)(\d+)(\\)#',linein)) then do;
		call symputx('_margheadfootoptn',cats(n));
	end;
	linein=prxchange("s/(\\c)(l|h)(cbpat\d+)(\\)/$4/",-1,linein);
run;
/*%put &=_headern. | &=_margheadfootoptn.;*/

%let xmin=-1400; %let ymin=0;
%if "&orientation."="LANDSCAPE" %then %do; %let xmax=15400; %let ymax=9000; %end;
	%else %do; %let xmax=9000; %let ymax=15400; %end;
%let xstep=%sysfunc(floor(%sysevalf((&xmax.-&xmin.)/&x_wknum.)));
%let ystep=%sysfunc(floor(%sysevalf((&ymax.-&ymin.)/&y_wknum.)));

%let posh=0; %let posv=0;

%if &x_wknum.=1 and &y_wknum.=1 %then %do; 
	%if %length(&wmfillOpacity.)=0 %then %let wmfillOpacity=%str(21500);
	%let posh=2; %let posv=2;
	%let xwidth=9600; %let ywidth=1200;
	%let xmin=&xmax.; %let ymin=&ymax.;
%end;
%put &=xstep. &=ystep.;

%if %length(&wmfillOpacity.)=0 %then %let wmfillOpacity=%str(31500);

data __watermark(drop=wmtext);
	length linein $5000. wmtext $1000.;
	linein=%if &_headern.=0 %then %do;'{\header\pard\plain\qc{'|| %end; '{\rtlch\fcs1 \af0 \ltrch\fcs0 \lang1024\langfe1024\noproof\insrsid4725392'; output;  

%do x=&xmin. %to &xmax. %by &xstep.;
	%do y=&ymin. %to &ymax. %by &ystep.;
	%let leftn=%eval(&x.);  %let rightn=%eval(&leftn.+&xwidth.);
	%let topn=%eval(&y.);;   %let bottomn=%eval(&topn.+&ywidth.);
	%if &bottomn.<&xmax. %then %do;
	linein="{\shp{\*\shpinst\shpleft&leftn.\shptop&topn.\shpright&rightn.\shpbottom&bottomn.\shpfhdr0\shpbxcolumn\shpbxignore\shpbypara\shpbyignore\shpwr3\shpwrk0\shpfblwtxt0\shpz2\shplid1027"; output; 
		linein="{\sp{\sn shapeType}{\sv &wmshapeType.}}{\sp{\sn fFlipH}{\sv 0}}{\sp{\sn fFlipV}{\sv 0}}{\sp{\sn rotation}{\sv &wmrotation.}}"; output; 
		wmtext="&watermarktext.";
		if lengthn(wmtext)^=klength(wmtext) then wmtext=tranwrd(unicodec(wmtext,'ncr'),'&#','\u');
		linein="{\sp{\sn gtextUNICODE}{\sv "||strip(wmtext)||"}}"; output; 
		linein="{\sp{\sn gtextSize}{\sv &wmtextSize.}}{\sp{\sn gtextFont}{\sv &wmtextFont.}}{\sp{\sn gtextFReverseRows}{\sv 0}}"; output; 
		linein="{\sp{\sn fGtext}{\sv 1}}{\sp{\sn gtextFNormalize}{\sv 0}}{\sp{\sn fillColor}{\sv &wmfillColor.}}{\sp{\sn fillOpacity}{\sv &wmfillOpacity.}}"; output;
		linein="{\sp{\sn fFilled}{\sv 1}}{\sp{\sn fLine}{\sv 0}}{\sp{\sn wzName}{\sv WaterMark}}{\sp{\sn posh}{\sv &posh.}}"; output;
		linein="{\sp{\sn posrelh}{\sv 0}}{\sp{\sn posv}{\sv &posv.}}{\sp{\sn posrelv}{\sv 0}}{\sp{\sn dhgt}{\sv 251663360}}"; output;
		linein="{\sp{\sn fLayoutInCell}{\sv 0}}{\sp{\sn fBehindDocument}{\sv 1}}}}" ; output; 
	%end;
	%end;
%end;


	linein='}'; output; 
%if &_headern.=0 %then %do;
	linein='}}'; output; 
%end; 
run;
%let _splitn=%str(&_headern.);
%if &_splitn.=0 %then %let _splitn=%str(&_margheadfootoptn.);

data __rtff;
	set __rtff(where=(n<=&_splitn.)) __watermark __rtff(where=(n>&_splitn.));;
run;

%if "&debug."="0" %then %do;
data _null_;
	set __rtff;
	file "&outpath.\&outputname." lrecl = 32767;						
	linelen =length(linein);
	put linein $varying5000. linelen;
run;

proc datasets nolist;
	delete __watermark: __rtff: ;
quit;
%end;

%put NOTE: -------------------- Macro[&SYSMACRONAME.] End --------------------;

%mend add_watermark_rtf;

/*
dm "output;clear;log;clear;";
proc delete data=_all_; run;
%add_watermark_rtf(rtfloc=%str(D:\zxw\SAS macro study\watermark\testdata)
					,rtfname=%str(t-02-dm.rtf)
					,watermarktext=%str(涉密文件禁止外传)
					,wmtextSize=
					,wmtextFont=%str(SimSun)
					,wmfillColor=
					,wmfillOpacity=  
					,wmshapeType=  
					,wmrotation=   
					,outpath=
					,outputname=
					,orientation=landscape
					,xy_wknum=%str(8|6)
					,debug=);

*/
