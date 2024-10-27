//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
int evt,opt,p,typ,sel
int send_evt=0,send_opt=0
char prgname[32]
short buff[128],header[15]
float f
//-------------------------------------------------------------
if(INIT() == true) then
  typ = 0
  sel = 0
  FILL(prgname[0],0,32)
  UnicodeCopy("Новая программа",prgname[0])
  SetData(prgname[0],"Local HMI","Program_default_com",32) //com part
  p = 3600
  LOWORD(p,buff[0])
  HIWORD(p,buff[1])
  p = C2I(20.0)
  LOWORD(p,buff[2])
  HIWORD(p,buff[3])
  p = C2I(98.0)
  LOWORD(p,buff[4])
  HIWORD(p,buff[5])
  buff[6] = 3
  SetData(buff[0],"Local HMI","Program_default_stp",7)  
end if
GetData(evt,"Local HMI","Program_Front_Evt",1)
GetData(opt,"Local HMI","Program_Front_Opt",1)
p = 0
SetData(p  ,"Local HMI","Program_Front_Evt",1)
GetData(header[0],"Local HMI","Program_header",15)
if not(evt) then
  return
end if
//-------------------------------------------------------------
TRACE("FRONT: EVT = [%d]:[%d]",evt,opt)
if     (evt == 10) then //advance window prg
  send_evt = 4 -3*sel
  send_opt = opt
else if(evt == 30) then
  if     (typ == 0) then //set prg
    send_evt = 1 +4 -3*sel
    send_opt = if_((sel),header[3]-header[5],header[2]-header[4]) +opt  //pw - ps + x
  else if(typ == 1) then //insert prg
    send_evt = 20 +sel
    send_opt = opt
  else if(typ == 2) then //delete prg
    send_evt = 25 +sel
    send_opt = opt
  else if(typ == 3) then //rename
    send_evt = 40 +sel
    send_opt = opt
  end if
else if(evt == 50) then
  opt = if_((opt < 0), 0,opt)
  opt = if_((opt > 3), 3,opt)
  typ = if_((opt == typ), 0,opt)
else if(evt == 60) then
  sel = opt or 0
  p = 11 +sel
  SetData(p,"Local HMI",LW,3000,1)
end if
//-------------------------------------------------------------
if (sel == 0) then
  p = header[0] +(typ == 1)
  SetData(p,"Local HMI","Program_Front_Sel",1)
  p = header[4] -header[2]
  if(p < 0 or p > 7) then
    p = -1
  end if
  SetData(p,"Local HMI","Program_Front_Sel_Prg",1)
else
  p = header[1] +(typ == 1)
  SetData(p,"Local HMI","Program_Front_Sel",1)
  p = header[5] -header[3]
  if(p < 0 or p > 5) then
    p = -1
  end if
  SetData(p,"Local HMI","Program_Front_Sel_Prg",1)  
end if    
SetData(typ,"Local HMI","Program_Front_Sel_Typ",1)
if(send_evt) then
  SetData(send_evt,"Local HMI","Program_Back_Evt",1)
  SetData(send_opt,"Local HMI","Program_Back_Opt",1)
  DELAY(50)
  ASYNC_TRIG_MACRO(0)
end if
//-------------------------------------------------------------
end macro_command