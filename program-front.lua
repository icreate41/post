//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
int evt,opt,p
int out[2]
short buff[128]
//-------------------------------------------------------------
GetData(evt,"Local HMI","Program_Front_Evt",1)
GetData(opt,"Local HMI","Program_Front_Opt",1)
p = 0
SetData(p  ,"Local HMI","Program_Front_Evt",1)
if not(evt) then
  return
end if
//-------------------------------------------------------------
TRACE("FRONT: EVT = [%d]:[%d]",evt,opt)
if     (evt == 10) then
  out[0] = 4
  out[1] = opt
  SetData(out[0],"Local HMI","Program_Back_Evt",2)
else if(evt == 20) then
  GetData(buff[0],"Local HMI","Program_window_view_string_tmp",16) //16 to const
  SetData(buff[0],"Local HMI","Program_default_com",16)
  out[0] = 50
  out[1] = 1
  SetData(out[0],"Local HMI","Program_Back_Evt",2)
else if(evt == 30) then
   GetData(buff[0],"Local HMI","Program_window_view_begin",4)
   out[0] = 1 +4
   out[1] = buff[0] +opt -buff[3]
   SetData(out[0],"Local HMI","Program_Back_Evt",2)
end if




//-------------------------------------------------------------
end macro_command