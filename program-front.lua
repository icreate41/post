//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
int evt,opt,p,sel
int out[2] = {0,0}
char prgname[32]
short buff[128]
//-------------------------------------------------------------
if(INIT() == true) then
  sel = 0
end if
GetData(evt,"Local HMI","Program_Front_Evt",1)
GetData(opt,"Local HMI","Program_Front_Opt",1)
p = 0
SetData(p  ,"Local HMI","Program_Front_Evt",1)
if not(evt) then
  return
end if
//-------------------------------------------------------------
TRACE("FRONT: EVT = [%d]:[%d]",evt,opt)
if     (evt == 10) then //advance window
  out[0] = 4
  out[1] = opt
else if(evt == 30) then
  GetData(buff[0],"Local HMI","Program_window_view_begin",4) //wnd part
  if     (sel == 0) then //set prg
    out[0] = 1 +4
    out[1] = buff[0] +opt -buff[3] //pw - ps + x
  else if(sel == 1) then //insert prg
    out[0] = 20
    out[1] = opt
    FILL(prgname[0],0,32)
    UnicodeCopy("Новая программа",prgname[0])
    SetData(prgname[0],"Local HMI","Program_default_com",32) //com part    
  else if(sel == 2) then //delete prg
    out[0] = 25
    out[1] = opt
  else if(sel == 3) then //rename
    out[0] = 40
    out[1] = opt
    GetData(buff[0],"Local HMI","Program_window_view_string_tmp",16) //16 to const
    SetData(buff[0],"Local HMI","Program_default_com",16)  //com part     
  end if
else if(evt == 50) then
  if(opt > 3) then
    opt = 3
  end if
  if(opt == sel) then
    sel = 0
  else
    sel = opt
  end if
end if
//-------------------------------------------------------------
GetData(buff[0],"Local HMI","Program_window_view_begin",4)
p = buff[2] +(sel == 1)
SetData(p,"Local HMI","Program_Front_Sel",1)
p = buff[3] -buff[0]
if(p < 0 or p > 7) then
  p = -1
end if
SetData(p,"Local HMI","Program_Front_Sel_Prg",1)
SetData(sel,"Local HMI","Program_Front_Sel_Typ",1)

SetData(out[0],"Local HMI","Program_Back_Evt",2)


//-------------------------------------------------------------
end macro_command