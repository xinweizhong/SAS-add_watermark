
Options notes nomprint nosymbolgen nomlogic nofmterr nosource nosource2 missing=' ' noquotelenmax linesize=max noBYLINE;
dm "output;clear;log;clear;odsresult;clear;";
proc delete data=_all_; run;
%macro rootpath;
%global program_path program_name;
%if %symexist(_SASPROGRAMFILE) %then %let _fpath=%qsysfunc(compress(&_SASPROGRAMFILE,"'"));
	%else %let _fpath=%sysget(SAS_EXECFILEPATH);
%let program_path=%sysfunc(prxchange(s/(.*)\\.*/\1/,-1,%upcase(&_fpath.)));
%let program_name=%scan(&_fpath., -2, .\);
%put NOTE: ----[program_path = &program_path.]----;
%put NOTE: ----[program_name = &program_name.]----;
%mend rootpath;
%rootpath;


data anno;
   length label $200. anchor $12.;
   id='myid';
   drawspace="graphpercent";
   function='text'; 
   textweight='bold'; anchor='left'; 
   width=200; widthunit="pixel"; 
   textfont= "Times New Roman";
   textsize=10;
   x1=70; y1=70 ; label="AUC^{suB 0 - ^{unicode '221E'x}}"; output;

   x1=70; y1=60 ; label="C(*ESC*){sub'max'}"; output;
   x1=70; y1=55 ; label="Camrelizumab^{sup ^{unicode '00AE'x}}"; output;

   textstyle="italic";
   x1=70; y1=50 ; label="p"; output;
   textstyle="normal";
   x1=71; y1=50 ; label="<0.05"; output;
run;

**********************************************************************************;
*********** 添加SAS绘图水印 ****************;

data watermark;
	length function id x1space y1space textweight anchor $50. label $200.;
	function="text";
	id='myid';
	x1space="graphpercent";
	y1space="graphpercent";
	width=200;
	widthunit="percent";
	textsize=9;
	ROTATE=30;
	TRANSPARENCY=0.8;
	textweight="bold";
	anchor="center";
	label="涉密文件禁止外传";
	do x1=0 to 100 by 10;
		do y1=0 to 100 by 10;
			output;
		end;
	end;
run;	
data anno;
	set watermark anno;
run;


ODS ESCAPECHAR='^';
proc template;
	define statgraph dist6;
		begingraph;
			annotate / id="myid"; 
			layout lattice/columns=1 rowdatarange=data;
				cell;
					cellheader;
	
						entry "Distribution of Mileage (*ESC*){unicode '00AE'x} C"{sub'max'} /textattrs=(family='Times New Roman' size=10pt weight=bold);
						entry "Distribution of Mileage (*ESC*){unicode '00AE'x} kg/m"{sup'2'} /textattrs=(family='Times New Roman' size=10pt weight=bold);
					endcellheader;
					layout overlay /xaxisopts=(display=(line ticks tickvalues label)) yaxisopts=(display=(line ticks tickvalues));
						histogram mpg_city /binaxis=false;
						densityplot mpg_city/name='Normal';
						densityplot mpg_city /name='Kernel' kernel() lineattrs=graphfit2;
						discretelegend 'Normal' 'Kernel' / across=2 location=inside halign=right valign=top;

						drawtext textattrs=(family='Times New Roman' size=10pt weight=bold) "drawtext: C"{sub 'max'} /
							x=65 y=84 drawspace=WALLPERCENT width=240 widthunit=pixel anchor=left border=false ;

						drawtext textattrs=(family='Times New Roman' size=10pt weight=bold) "drawtext: kg/m"{sup '2'} /
							x=65 y=78 drawspace=WALLPERCENT width=240 widthunit=pixel anchor=left border=false ;

					endlayout;
				endcell;


				rowheaders;
					layout gridded/columns=2;
						entry "C"{sub 'max'}'/dose('{unicode mu}'g/mL/mg)'/textattrs=(family='Times New Roman' size=10pt weight=bold) rotate=90;

					endlayout;
				endrowheaders;
			endlayout;
		endgraph;
	end;
run;

ODS _all_ CLOSE;
goptions reset=all device=pdf; 
options topmargin=0.1in bottommargin=0.1 in leftmargin=0.1in rightmargin=0.1in;
options orientation=landscape nodate nonumber;
ods pdf file="&program_path.\SAS绘图水印.pdf"  style=trial nogtitle nogfoot;

ods graphics on; 
ods graphics /reset  noborder MAXLEGENDAREA=55  IMAGEFMT =pdf HEIGHT =6.5 in WIDTH = 10.2in  ATTRPRIORITY=NONE;

proc sgrender data=sashelp.cars template=dist6 sganno=anno;
	where type ne 'Hybrid';
run;

ods pdf close;
ODS LISTING;


******************************************************************************************;
*********** SAS PDF表格中增加水印 ****************;

*********** 1. 生成水印图片 *************;
data watermark;
	length function id x1space y1space textweight anchor $50. label $200.;
	function="text";
	id='myid';
	x1space="graphpercent";
	y1space="graphpercent";
	width=200;
	widthunit="percent";
	textsize=9;
	ROTATE=30;
	TRANSPARENCY=0.8;
	textweight="bold";
	anchor="center";
	label="涉密文件禁止外传";
	do x1=0 to 100 by 10;
		do y1=0 to 100 by 10;
			output;
		end;
	end;
run;	
proc template;
define statgraph draw_circles; 
	begingraph/AXISLINEEXTENT=FULL pad=0;
	layout overlay / walldisplay=none
		xaxisopts=(display=none offsetmin=0 offsetmax=0 linearopts=(viewmin=0 viewmax=30
					tickvaluesequence=(start=0 end=30 increment=5)) ) 
		yaxisopts=(display=none offsetmin=0 offsetmax=0 linearopts=(viewmin=0 viewmax=30
					tickvaluesequence=(start=0 end=30 increment=5)) ) 
		;
		annotate / id="myid"; 
		textplot x=x y=y text=text/textattrs=(color=black family="Arial/simsun" size=12 style=normal weight=bold);
	endlayout;
	endgraph;
end;
run;


data __final;
	x=-10; y=-10; text=' ';
run;

title;footnote;
ods listing gpath="&program_path." image_dpi=255; 
%put %sysfunc(getoption(orientation));
****** orientation=portrait时使用 width=22cm height=30cm ******;
ods graphics on/width=30cm height=22cm imagename="watermark" /*注意不要设置reset=index不然每次生成的图片的名称可能会变*/  outputfmt=png noborder;

proc sgrender data=__final template=draw_circles sganno=watermark;
run;
ods graphics /reset=all;
ods graphics off;


*************** 2.定义PDF输出时用的style（并设置背景图为前面生成的水印图片） *******************;

ods path (prepend) work.template(update) sashelp.tmplmst;
proc template;
   define style watermark_pearl;
     parent=styles.rtf;
      style Table from Table /
         cellpadding = 5pt
         borderspacing = .05pt
         borderwidth = .1pt
         frame = box
         bordercolor = cx919191
         bordercollapse = collapse
         backgroundcolor=_undef_  ;
      class Header /
         color = cx000000
         backgroundcolor = _undef_
         bordercolor = cxB0B7BB
         bordercollapse = collapse;
	 style Body from Document /                                              
         marginleft = 0.3in                                                   
         marginright = 0.3in                                                  
         margintop = 0.3in                                                    
         marginbottom = 0.3in; 

    class body from document /
			background=_undef_
          backgroundimage="&program_path.\watermark.png"; *******设置背景图为前面生成的水印图片*******;
   end;
run;

ods _all_ close;
options nobyline device=pdf;
options topmargin=0.3in bottommargin=0.3 in leftmargin=0.3in rightmargin=0.3in;
title; footnote;
options nodate nonumber papersize=a4 missing='' orientation=landscape lrecl=10000;

ods pdf file="&program_path.\watermark.pdf" nogtitle nogfootnote style=watermark_pearl;

proc report data = sashelp.Springs(obs=50) nowd;
run;

goptions transparency; ******设置图片背景为透明*****;

proc gchart data=sashelp.class;
	vbar age;
run;
quit;
ods pdf close;
ods listing;


******************************************************************************************;
*********** SAS RTF表格中增加水印 ****************;
/*dm "output;clear;log;clear;";*/
/*proc delete data=_all_; run;*/

%add_watermark_rtf(rtfloc=%str(&program_path.\testdata)
					,rtfname=%str(t-02-dm.rtf)
					,watermarktext=%str(涉密文件禁止外传)
					,wmtextSize=
					,wmtextFont=%str()
					,wmfillColor=
					,wmfillOpacity=  
					,wmshapeType=  
					,wmrotation=   
					,outpath=
					,outputname=
					,orientation=landscape
					,xy_wknum=%str(8|6)
					,debug=);
