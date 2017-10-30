Traversing the XML tree

 SAS/Python

  INPUT

    <component apiversion="" class="BSP" condition="" group="Board" subgroup="s7g2_sk" >
      <description>SK Board Support Files</description>
      <originalPack>board_s7g2_sk.1.3.0.pack</originalPack>
    </component>


  PROCESS (we want the subgroup text "s7g2_sk")

     tree = ET.parse("d:/xml/tree.xml");
     root = tree.getroot();
     print(root.attrib["subgroup"]);

     * I updated utlsubmit_py64 to return a SAS macro variable;
     sasmacrovariable = root.attrib["subgroup"];

  OUTPUT

     SAS macro variable sasmacrovariable from python

     %put &=sasmacrovariable;

     SASMACROVARIABLE=s7g2_sk


github updated utl_submit_py64

see
https://stackoverflow.com/questions/46984061/how-can-i-get-value-in-xml-using-python

Nilo profile
https://stackoverflow.com/users/3246135/nilo

from lxml import etree

data _null_;
   file "d:/xml/tree.xml";
   input;
   put _infile_;
cards4;
<component apiversion="" class="BSP" condition="" group="Board" subgroup="s7g2_sk" variant="" vendor="balabala" version="1.1.1.1">
      <description>SK Board Support Files</description>
      <originalPack>board_s7g2_sk.1.3.0.pack</originalPack>
    </component>
;;;;
run;quit;

%utl_submit_py64('
import xml.etree.ElementTree as ET;
tree = ET.parse("d:/xml/tree.xml");
root = tree.getroot();
sasmacrovariable = root.attrib["subgroup"];
'
,returnVar=Y
);

%put &=sasmacrovariable;


* this is also on github see utl_submit_py64_v3 and utl_submit_py64_c3_example;

%macro utl_submit_py64(
      pgm
     ,returnVar=N           /* set to Y if you want a return SAS macro variable from python */
     )/des="Semi colon separated set of python commands - drop down to python";

  * write the program to a temporary file;
  filename py_pgm "%sysfunc(pathname(work))/py_pgm.py" lrecl=32766 recfm=v;
  data _null_;
    length pgm  $32755 cmd $1024;
    file py_pgm ;
    if upcase(substr("&returnVar",1,1))='Y' then
       pgm=cats('import pyperclip;',&pgm,"pyperclip.copy(sasmacrovariable);");
    else
       pgm=&pgm;
    semi=countc(pgm,';');
      do idx=1 to semi;
        cmd=cats(scan(pgm,idx,';'));
        if cmd=:'. ' then
           cmd=trim(substr(cmd,2));
         put cmd $char384.;
         putlog cmd $char384.;
      end;
  run;quit;
  %let _loc=%sysfunc(pathname(py_pgm));
  %put &_loc;
  filename rut pipe  "C:\Python_27_64bit/python.exe &_loc";
  data _null_;
    file print;
    infile rut;
    input;
    put _infile_;
  run;
  filename rut clear;
  filename py_pgm clear;

  * use the clipboard to create macro variable;
  %if %upcase(%substr(&returnVar.,1,1))=Y %then %do;
    filename clp clipbrd ;
    data _null_;
     length txt $200;
     infile clp;
     input;
     putlog "*******  " _infile_;
     call symputx("sasmacrovariable",_infile_,"G");
    run;quit;
  %end;

%mend utl_submit_py64;


