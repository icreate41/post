//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
int evt,opt,p,typ,sel
int window_sz[2] = {8,5},send_evt=0,send_opt=0
char prgname[32]
short buff[128],header[15],elmnts[2],wndpos[2],selpos[2],runpos[2],run
int pw_stp=0,ps_stp=1,pr_stp=2,pw_prg=3,ps_prg=4,pr_prg=5
int ev_set_pos = 1 ,ev_get_pos = 11,ev_insert  = 20,ev_erase = 25
int ev_sav_pos = 30,ev_rld_dat = 35,ev_sav_dat = 40,ev_swap = 45
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
//-------------------------------------------------------------
GetData(evt,"Local HMI","Program_Front_Evt",1)
GetData(opt,"Local HMI","Program_Front_Opt",1)
p = 0
SetData(p  ,"Local HMI","Program_Front_Evt",1)
GetData(header[0],"Local HMI","Program_header",15)
GetData(elmnts[0],"Local HMI","Program_header[0]",2)
GetData(wndpos[0],"Local HMI","Program_header[2]",2)
GetData(selpos[0],"Local HMI","Program_header[4]",2)
GetData(runpos[0],"Local HMI","Program_header[6]",2)
GetData(run      ,"Local HMI","Program_header[12]",1)
if not(evt) then
  return
end if
//-------------------------------------------------------------
TRACE("FRONT: EVT = [%d]:[%d]",evt,opt)
if     (evt == 10) then //advance window prg
  send_evt = ev_get_pos +if_((sel),pw_stp,pw_prg)
  send_opt = opt
else if(evt == 30) then
  if     (typ == 0) then //set prg
    send_evt = ev_set_pos +if_((sel),ps_stp+run,ps_prg)
    send_opt = wndpos[sel] -selpos[sel] +opt
  else if(typ == 1) then //insert prg
    send_evt = ev_insert  +sel
    send_opt = opt
  else if(typ == 2) then //delete prg
    send_evt = ev_erase   +sel
    send_opt = opt
  else if(typ == 3) then //rename
    send_evt = ev_sav_dat +sel
    send_opt = opt
  else if(typ == 4) then //swap
    send_evt = ev_swap +sel
    send_opt = wndpos[sel] -selpos[sel] +opt
  end if
else if(evt == 50) then
  opt = lim(opt,0,4)
  typ = if_((opt == typ),0,opt)
  send_evt = ev_get_pos +pw_prg
  send_opt = 0
else if(evt == 55) then
  p = 10 +(opt or 0)
  SetData(p,"Local HMI",LW,3000,1)
  if(opt) then
    send_evt = ev_get_pos +pw_prg
    send_opt = 0
  end if  
else if(evt == 60) then
  sel = lim(opt,0,1)
  p = 11 +sel
  SetData(p,"Local HMI",LW,3000,1)
  p = selpos[sel] -wndpos[sel]
  if(p < 0 or p >= window_sz[sel]) then
    send_evt = ev_get_pos +if_((sel),pw_stp,pw_prg)
    send_opt = p
  end if
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
  //DELAY(50)
  ASYNC_TRIG_MACRO(0)
end if
//-------------------------------------------------------------
end macro_command