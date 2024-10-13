//-------------------------------------------------------------
//APPLICATION DEFINED
int HEADER = 0x66FFC0DE,VERSION = 0x1
//CONFIG
int DATA_TYPE =0x1,BLK_HDR_SZ = 3,STP_ADD_SZ = 2,STP_REQ_SZ = 5 ,MAX_DAT_SZ = 262140
int CFG_OFST = 0,DAT_OFST = 1000,TMP_OFST = 100,COM_ADD_SZ = 10,COM_REQ_SZ = 16
int MAX_PRG_CNT = 500, MAX_STP_CNT = 500
int BLK_SZ,MAX_BLK_CNT,COM_BLK_OFST,COM_BLK_CNT
//-------------------------------------------------------------
int BO[3] = {0, 768, 792}, BITMAP[793],SD[2]
short BUFF[256],SW[10],BLK_CNT,RES_BLK,NIL = -1
//todo
//подумай на счёт того, чтобы добавить owner и modified флаг
//возможно стоит вернуть слоты, но только меняя CUR_BLK,PRV_BLK,NXT_BLK (Owner ??)
//todo
short D_HEAD_LOC,W_BLK_CNT,W_HEAD_BLK,W_CUR_BLK,W_PRV_BLK,W_NXT_BLK
short DIR_LEFT = -1,DIR_RIGHT =1
//COMMON
int   COM_TIM
short COM_POS,COM_REP
bool  RES_STATE = 1,TYP_PRG=0,TYP_STP=1
//-------------------------------------------------------------
sub init_values()
  RES_STATE = 1
  STP_REQ_SZ  = STP_REQ_SZ -(STP_REQ_SZ -128)*(STP_REQ_SZ > 128)
  BLK_SZ      = BLK_HDR_SZ +STP_ADD_SZ +STP_REQ_SZ
  MAX_BLK_CNT = MAX_DAT_SZ /BLK_SZ
  MAX_BLK_CNT = MAX_BLK_CNT -(MAX_BLK_CNT -24576)*(MAX_BLK_CNT > 24576)
  COM_REQ_SZ   = COM_REQ_SZ -(COM_REQ_SZ -128)*(COM_REQ_SZ > 128)
  COM_BLK_OFST =(COM_ADD_SZ +(BLK_SZ -1))/BLK_SZ
  COM_BLK_CNT  =(COM_REQ_SZ +(BLK_SZ -1))/BLK_SZ
  COM_BLK_CNT  = COM_BLK_CNT+COM_BLK_OFST
  BLK_CNT = 0
  RES_BLK = -1
  D_HEAD_LOC = 0
  W_BLK_CNT  = 0
  W_HEAD_BLK = 2
  W_CUR_BLK  = 3
  W_PRV_BLK  = 4
  W_NXT_BLK  = 5
  COM_TIM = 0
  COM_POS = 0
  COM_REP = 0
  SD[0] = 100
  SD[1] = 101
  FILL(SW[0],0,2)
  FILL(SW[2],NIL,8)
  FILL(BITMAP[0],-1,793)
end sub
//-------------------------------------------------------------
sub switch_type(bool type)
  D_HEAD_LOC = 0 + type
  W_BLK_CNT  = 0 + type
  W_HEAD_BLK = 2 + 4*type
  W_CUR_BLK  = 3 + 4*type
  W_PRV_BLK  = 4 + 4*type
  W_NXT_BLK  = 5 + 4*type
end sub
//-------------------------------------------------------------
sub load_stp_from_prg_s()
  if(RES_STATE) then
    SD[1] = DAT_OFST+BLK_HDR_SZ+BLK_SZ*SW[3]
    SW[1] = 0
    FILL(SW[6],NIL,4)
    GetData(SW[6],"Local HMI",RW,SD[1],1) 
  end if  
end sub
//-------------------------------------------------------------
sub get_prg_com_from_cur_s()
  if(RES_STATE) then
	COM_TIM =(BUFF[0]&0xFFFF)|(BUFF[1]<<16)
	COM_POS = BUFF[2]
	COM_REP = BUFF[3]
    COM_TIM = COM_TIM -(COM_TIM -1)*(COM_TIM < 1)
	COM_TIM = COM_TIM -(COM_TIM -(3600*24*365))*(COM_TIM > (3600*24*365))
	//todo
	//todo
	//todo
	COM_POS = COM_POS -(COM_POS -0)*(COM_POS < 0) //надо адвансить к run slot cur stp
	COM_POS = COM_POS -(COM_POS -SW[W_BLK_CNT])*(COM_POS >= SW[W_BLK_CNT])
	COM_REP = COM_REP -(COM_REP -0)*(COM_REP < 0)
	COM_REP = COM_REP -(COM_REP -999)*(COM_REP > 999)	
  end if
end sub
//-------------------------------------------------------------
//todo
//delete bit check ??
//todo
sub load_data_s(int blk, int req)
  short i,j,prv,nxt,chk,dc = 0
  RES_STATE = RES_STATE and(req <= 256)
  while(dc < req and RES_STATE)
  	RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
    if(RES_STATE) then
  	  GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*blk,1)
  	  GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*blk,1)
  	  GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*blk,1)
  	  j = blk % 32
  	  i = blk / 32 + BO[0]
  	  RES_STATE = RES_STATE and not(BITMAP[i] & (1 << j))
  	  RES_STATE = RES_STATE and(chk ==(prv ^ nxt))
  	  i = BLK_SZ - BLK_HDR_SZ
  	  while(dc < req and i > 0)
  	    GetData(BUFF[dc],"Local HMI",RW,DAT_OFST+i+BLK_SZ*blk,1)
  	    i  = i  -1
  	    dc = dc +1
  	  wend
  	  blk = nxt
	end if
  wend
end sub
//-------------------------------------------------------------
sub load_config_s()
  int tmp_int
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +0,1)
  SetData(HEADER      ,"Local HMI",RW,CFG_OFST +0,1)
  RES_STATE = RES_STATE and(HEADER       == tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +2,1)
  SetData(VERSION     ,"Local HMI",RW,CFG_OFST +2,1)
  RES_STATE = RES_STATE and(VERSION      == tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +4,1)
  SetData(DATA_TYPE   ,"Local HMI",RW,CFG_OFST +4,1)
  RES_STATE = RES_STATE and(DATA_TYPE    == tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +6,1)
  SetData(STP_REQ_SZ  ,"Local HMI",RW,CFG_OFST +6,1)
  RES_STATE = RES_STATE and(STP_REQ_SZ   == tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +8,1)
  SetData(MAX_DAT_SZ  ,"Local HMI",RW,CFG_OFST +8,1)
  RES_STATE = RES_STATE and(MAX_DAT_SZ   >= tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST+10,1)
  SetData(DAT_OFST    ,"Local HMI",RW,CFG_OFST+10,1)
  RES_STATE = RES_STATE and(DAT_OFST     == tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST+12,1)
  SetData(MAX_PRG_CNT ,"Local HMI",RW,CFG_OFST+12,1)
  RES_STATE = RES_STATE and(MAX_PRG_CNT  >= tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST+14,1)
  SetData(MAX_STP_CNT ,"Local HMI",RW,CFG_OFST+14,1)
  RES_STATE = RES_STATE and(MAX_STP_CNT  >= tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST+16,1)
  SetData(COM_REQ_SZ  ,"Local HMI",RW,CFG_OFST+16,1)
  RES_STATE = RES_STATE and(COM_REQ_SZ   == tmp_int)
end sub
//-------------------------------------------------------------
sub reload_node_s(short blk, short prev_blk)
  short prv,nxt,chk
  prv = NIL
  nxt = NIL
  RES_STATE = RES_STATE and(blk >= NIL)and(blk < MAX_BLK_CNT)
  if(RES_STATE and blk > NIL) then
    GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*blk,1)
    GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*blk,1)
    GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*blk,1)
    RES_STATE = RES_STATE and(prv == prev_blk)
    RES_STATE = RES_STATE and(nxt >= NIL)and(nxt < MAX_BLK_CNT)
    RES_STATE = RES_STATE and(chk == (prv ^ nxt))
  end if
  if(RES_STATE) then
    SW[W_CUR_BLK] = blk
    SW[W_PRV_BLK] = prv
    SW[W_NXT_BLK] = nxt  
  end if
end sub
//-------------------------------------------------------------
sub load_node_s(short blk, short prev_blk)
  short prv,nxt,chk
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
  if(RES_STATE) then
    GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*blk,1)
    GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*blk,1)
    GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*blk,1)
    RES_STATE = RES_STATE and(prv == prev_blk)
    RES_STATE = RES_STATE and(nxt >= NIL)and(nxt < MAX_BLK_CNT)
    RES_STATE = RES_STATE and(chk == (prv ^ nxt))
  end if
  if(RES_STATE) then
    SW[W_BLK_CNT] = SW[W_BLK_CNT] +1
    SW[W_CUR_BLK] = blk
    SW[W_PRV_BLK] = prv
    SW[W_NXT_BLK] = nxt
  end if  
end sub
//-------------------------------------------------------------
sub advance_s(short shift)
  short prv,nxt,chk
  while(RES_STATE and shift)
    prv = NIL
    nxt = NIL
    RES_STATE = RES_STATE and not((SW[W_PRV_BLK]>NIL)and(SW[W_CUR_BLK]<=NIL)and(SW[W_NXT_BLK]>NIL))
    if(shift > 0) then
      RES_STATE = RES_STATE and((SW[W_CUR_BLK] > NIL)or(SW[W_NXT_BLK] > NIL))
      if(SW[W_NXT_BLK] > NIL) then
        GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*SW[W_NXT_BLK],1)
        GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*SW[W_NXT_BLK],1)
        GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*SW[W_NXT_BLK],1)
        RES_STATE = RES_STATE and(prv == SW[W_CUR_BLK])
        RES_STATE = RES_STATE and(nxt >= NIL)and(nxt < MAX_BLK_CNT)
        RES_STATE = RES_STATE and(chk == (prv ^ nxt))
      end if
      if(RES_STATE) then
        SW[W_PRV_BLK] = SW[W_CUR_BLK]
        SW[W_CUR_BLK] = SW[W_NXT_BLK]
        SW[W_NXT_BLK] = nxt
      end if
    else if(shift < 0) then
      RES_STATE = RES_STATE and((SW[W_CUR_BLK] > NIL)or(SW[W_PRV_BLK] > NIL))
      if(SW[W_PRV_BLK] > NIL) then
        GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*SW[W_PRV_BLK],1)
        GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*SW[W_PRV_BLK],1)
        GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*SW[W_PRV_BLK],1)
        RES_STATE = RES_STATE and(prv >= NIL)and(prv < MAX_BLK_CNT)      
        RES_STATE = RES_STATE and(nxt == SW[W_CUR_BLK])
        RES_STATE = RES_STATE and(chk == (prv ^ nxt))
      end if
      if(RES_STATE) then
      	SW[W_NXT_BLK] = SW[W_CUR_BLK]
        SW[W_CUR_BLK] = SW[W_PRV_BLK]
        SW[W_PRV_BLK] = prv
      end if      
    end if
    shift = shift -(shift > 0) +(shift < 0)
  wend
end sub
//-------------------------------------------------------------
sub insert_node_s(short blk) //shift_next
  short prv,nxt,chk
  RES_STATE = RES_STATE and not((SW[W_PRV_BLK]> NIL)and(SW[W_CUR_BLK]<=NIL)and(SW[W_NXT_BLK]>NIL))
  RES_STATE = RES_STATE and not((SW[W_PRV_BLK]<=NIL)and(SW[W_CUR_BLK]<=NIL)and(SW[W_NXT_BLK]>NIL))
  if not(RES_STATE) then
    return
  end if  
  if(SW[W_PRV_BLK] > NIL) then
    GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*SW[W_PRV_BLK],1)
    chk = prv ^ blk
    SetData(blk,"Local HMI",RW,DAT_OFST+1+BLK_SZ*SW[W_PRV_BLK],1)
    SetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*SW[W_PRV_BLK],1)
  else
    SW[W_HEAD_BLK] = blk
    SetData(SW[W_HEAD_BLK],"Local HMI",RW,SD[D_HEAD_LOC],1)
  end if
  if(SW[W_CUR_BLK] > NIL) then
    SetData(blk ,"Local HMI",RW,DAT_OFST+0+BLK_SZ*SW[W_CUR_BLK],1)
    GetData(nxt ,"Local HMI",RW,DAT_OFST+1+BLK_SZ*SW[W_CUR_BLK],1)
    chk = nxt ^ blk
    SetData(chk ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*SW[W_CUR_BLK],1)
  end if
  SW[W_BLK_CNT] = SW[W_BLK_CNT] +1
  SW[W_NXT_BLK] = SW[W_CUR_BLK]
  SW[W_CUR_BLK] = blk
  chk = SW[W_PRV_BLK] ^ SW[W_NXT_BLK]
  SetData(SW[W_PRV_BLK],"Local HMI",RW,DAT_OFST+0+BLK_SZ*SW[W_CUR_BLK],1)
  SetData(SW[W_NXT_BLK],"Local HMI",RW,DAT_OFST+1+BLK_SZ*SW[W_CUR_BLK],1)
  SetData(chk          ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*SW[W_CUR_BLK],1)
end sub
//-------------------------------------------------------------
sub erase_node_s() //shift_next
  short prv,nxt,chk
  RES_STATE = RES_STATE and(SW[W_CUR_BLK] > NIL)
  if not(RES_STATE) then
    return
  end if
  prv = NIL
  nxt = NIL
  if(SW[W_PRV_BLK] > NIL) then
	GetData(prv          ,"Local HMI",RW,DAT_OFST+0+BLK_SZ*SW[W_PRV_BLK],1)
	chk = prv ^ SW[W_NXT_BLK]
    SetData(SW[W_NXT_BLK],"Local HMI",RW,DAT_OFST+1+BLK_SZ*SW[W_PRV_BLK],1)
    SetData(chk          ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*SW[W_PRV_BLK],1)
  else
    SW[W_HEAD_BLK] = SW[W_NXT_BLK]
    SetData(SW[W_HEAD_BLK],"Local HMI",RW,SD[D_HEAD_LOC],1)   
  end if
  if(SW[W_NXT_BLK] > NIL) then
    SetData(SW[W_PRV_BLK],"Local HMI",RW,DAT_OFST+0+BLK_SZ*SW[W_NXT_BLK],1)
    GetData(nxt          ,"Local HMI",RW,DAT_OFST+1+BLK_SZ*SW[W_NXT_BLK],1)
    chk = nxt ^ SW[W_PRV_BLK]
    SetData(chk          ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*SW[W_NXT_BLK],1)
  end if
  RES_BLK = SW[W_CUR_BLK]
  SW[W_BLK_CNT] = SW[W_BLK_CNT] -1
  SW[W_CUR_BLK] = SW[W_NXT_BLK]
  SW[W_NXT_BLK] = nxt
end sub
//-------------------------------------------------------------
sub set_block_s(int blk)
  int b,p,s,k
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
  if(RES_STATE) then
    b = blk % 32
    s = blk / 32 + BO[0]
    RES_STATE = RES_STATE and(BITMAP[s] & (1 << b)) 
    p = blk
    for k = 0 to 2
      b = p % 32
      p = p / 32
      s = p + BO[k]
      BITMAP[s] = BITMAP[s] & ~(1 << b)
      if(BITMAP[s]) then
        break
      end if
    next
    BLK_CNT = BLK_CNT +RES_STATE
  end if  
end sub
//-------------------------------------------------------------
sub del_block_s(int blk)
  int b,p,s,k
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
  if(RES_STATE) then
    b = blk % 32
    s = blk / 32 + BO[0]
    RES_STATE = RES_STATE and not(BITMAP[s] & (1 << b))
    p = blk
    for k = 0 to 2
      b = p % 32
      p = p / 32
      s = p + BO[k]
      BITMAP[s] = BITMAP[s] | (1 << b)
    next
    BLK_CNT = BLK_CNT -RES_STATE
  end if    
end sub
//-------------------------------------------------------------
sub new_block_s()
  int k,s,m,b=0,res=0
  RES_STATE = RES_STATE and(BLK_CNT < MAX_BLK_CNT)
  if not(RES_STATE) then
    RES_BLK = NIL
    return
  end if 
  for k = 2 down 0 
    POW(32,k +1,m)
    s = res/m + BO[k]
    b = 0
    //while(not(BITMAP[s]&(1 << b)))
    //  b = b +1
    s = BITMAP[s]
    m = 16
    while(m)
      if not(s & ~(-1 << m)) then
      	b = b + m
      	s = s >> m
      end if	
      m  = m  >> 1
    wend
    POW(32,k,m)   
    res = res + b*m
  next
  RES_BLK = res
end sub
//-------------------------------------------------------------
//-------------------------------------------------------------
//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
//if(INIT() == true) then

  init_values()
  load_config_s()

  //testing cases
  int ii,ij,test_count = 0, passed_count = 0
  //######################################################################## 
  if(true) then //testing bitmap loading with value = 3205
    test_count = test_count +1
    TRACE("Test case set_block with 3205 failure")
    BITMAP[100] = ~(1 << 5) // 3205 /32 = 100 (+0)   , 3205 %32 = 5
    BITMAP[771] = ~(1 << 4) // 100  /32 = 3 (+768)   , 100  %32 = 4
    BITMAP[792] = ~(1 << 3) // 3    /32 = 0 (+768+24), 3    %32 = 3
    set_block_s(3205) //try...
    if(RES_STATE) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[100], BITMAP[771], BITMAP[792])
    else
      passed_count = passed_count +1
      TRACE("OK")
    end if
    init_values()
  end if  
  //######################################################################## 
  if(true) then //testing bitmap loading with value = 3205
    test_count = test_count +1
    TRACE("Test case set_block with 3205")
    BITMAP[100] = 1 << 5 // 3205 /32 = 100 (+0)   , 3205 %32 = 5
    BITMAP[771] = 1 << 4 // 100  /32 = 3 (+768)   , 100  %32 = 4
    BITMAP[792] = 1 << 3 // 3    /32 = 0 (+768+24), 3    %32 = 3
    set_block_s(3205) //try...
    if(BITMAP[100] or BITMAP[771] or BITMAP[792] or not RES_STATE) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[100], BITMAP[771], BITMAP[792])
    else
      passed_count = passed_count +1
      TRACE("OK")
    end if
    init_values()
  end if
  //######################################################################## 
  if(true) then //testing bitmap loading with value = 9369
    test_count = test_count +1
    TRACE("Test case set_block with 9369")
    BITMAP[292] = 1 << 25 // 9369 /32 = 292 (+0)   , 3205 %32 = 25
    BITMAP[777] = 1 << 4  // 292  /32 = 9 (+768)   , 292  %32 = 4
    BITMAP[792] = 1 << 9  // 9    /32 = 0 (+768+24), 9    %32 = 9
    set_block_s(9369) //try...
    if(BITMAP[292] or BITMAP[777] or BITMAP[792] or not RES_STATE) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[292], BITMAP[777], BITMAP[792])
    else
      passed_count = passed_count +1
      TRACE("OK")
    end if
    init_values()
  end if  
  //########################################################################
  if(true) then //testing bitmap get value = 3205
    test_count = test_count +1
    TRACE("Test case new_block")
    FILL(BITMAP[0],0,793) //simulate full load ecxept of one element
    BITMAP[100] = 1 << 5 // 3205 /32 = 100 (+0)   , 3205 %32 = 5
    BITMAP[771] = 1 << 4 // 100  /32 = 3 (+768)   , 100  %32 = 4
    BITMAP[792] = 1 << 3 // 3    /32 = 0 (+768+24), 3    %32 = 3
    new_block_s() //try...
    if(RES_BLK <> 3205 or not RES_STATE) then
      TRACE("Failed, incorrect value %d", RES_BLK)
    else
      passed_count = passed_count +1
      TRACE("OK")
    end if
    init_values()
  end if
  //######################################################################## 
  if(true) then //testing bitmap delete with value = 3205
    test_count = test_count +1
    TRACE("Test case del_block with 3205")
    set_block_s(3205)
    del_block_s(3205) //try...
    if(BITMAP[100] <> -1 or BITMAP[771] <> -1 or BITMAP[792] <> -1 or not RES_STATE) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[100], BITMAP[771], BITMAP[792])
    else
      passed_count = passed_count +1
      TRACE("OK")
    end if
    init_values()
  end if    
  //########################################################################
  if(false) then //testing bitmap perfomance
    test_count = test_count +1
  	TRACE("Test case bitmap performance")
  	RES_STATE = 1
  	int start,stop
  	float res
  	//1
  	GetData(start,"Local HMI",LW,9030,1)
  	//while(BLK_CNT < MAX_BLK_CNT) //try...
  	for ii = 0 to 999
        new_block_s()
  		set_block_s(RES_BLK)
  		insert_node_s(RES_BLK)
  		//del_block_s(RES_BLK)
  		//set_block_s(RES_BLK)
  	next
  	//wend
  	GetData(stop,"Local HMI",LW,9030,1)
  	res = (stop - start)/10.0
  	TRACE("time =  %f s", res)
  	res = BLK_CNT/res
  	TRACE("perf =  %f op/s", res)	
  	TRACE("last block %d", RES_BLK)
  	TRACE("count %d", BLK_CNT)
    if not(RES_STATE) then
      TRACE("Failed")
    else
      passed_count = passed_count +1
      TRACE("OK")
    end if  	
  	init_values()
  end if
  //######################################################################## 
  if(true) then //testing node functions
    test_count = test_count +1
    TRACE("Testing node functions")
    for ii = 0 to 2
      new_block_s()
      set_block_s(RES_BLK)
      insert_node_s(RES_BLK)
      advance_s(1)
    next
    advance_s(-2) //advance_s(0 - ii)
    erase_node_s()
    del_block_s(RES_BLK)
    
    //TRACE("delete  [%d] %d %d %d",ii,SW[W_PRV_BLK],SW[W_CUR_BLK],SW[W_NXT_BLK])     
    if(SW[W_BLK_CNT] <> (ii -1) or not RES_STATE) then
      TRACE("Failed")
    else
      passed_count = passed_count +1
      TRACE("OK")
    end if
    init_values()
  end if
  //######################################################################## 
  if(true) then //Combine test
    test_count = test_count +1
    TRACE("Combine test")
    TRACE("#1 load test")
    //firstly create list of 5 nodes
    ii = 5
    while(SW[W_BLK_CNT] < ii)
      new_block_s()
      set_block_s(RES_BLK)
      insert_node_s(RES_BLK)
    wend
    //than clear data
    init_values()
    //and read saved list
    //begin-----------------------------------------------------------------
    GetData(SW[W_HEAD_BLK],"Local HMI",RW,SD[D_HEAD_LOC],1)
    SW[W_NXT_BLK] = SW[W_HEAD_BLK]
    while(RES_STATE and SW[W_NXT_BLK] > NIL)
      set_block_s(SW[W_NXT_BLK])
      load_node_s(SW[W_NXT_BLK],SW[W_CUR_BLK])
      TRACE("   loaded: [%d] : [%d,%d]",SW[W_CUR_BLK],SW[W_PRV_BLK],SW[W_NXT_BLK])
      RES_STATE = RES_STATE and(SW[W_BLK_CNT] <= MAX_PRG_CNT)
    wend
    reload_node_s(SW[W_HEAD_BLK],NIL) //to begin, safe version of //advance_s(DIR_LEFT*(SW[W_BLK_CNT] -1))
    //end-------------------------------------------------------------------
    TRACE("begin: [%d] : [%d,%d]",SW[W_CUR_BLK],SW[W_PRV_BLK],SW[W_NXT_BLK])
    TRACE("count %d",SW[W_BLK_CNT])
    //check result
    if(SW[W_BLK_CNT] <> ii or not RES_STATE) then
      TRACE("Failed - #1 load test, breaking...")
    else
      passed_count = passed_count +1
      TRACE("OK - #1 load test")
    end if
    //2nd
    if(true and RES_STATE) then
      test_count = test_count +1
      TRACE("#2 insert test")
      ii = SW[W_BLK_CNT] +1
      ij = 3 //insert position
      //begin---------------------------------------------------------------
      reload_node_s(SW[W_HEAD_BLK],NIL)
      if(ij >= 0 and ij <= SW[W_BLK_CNT]) then
        advance_s(DIR_RIGHT*ij)
        TRACE("insertion at: [%d] : [%d,%d]",SW[W_CUR_BLK],SW[W_PRV_BLK],SW[W_NXT_BLK])
        new_block_s()
        set_block_s(RES_BLK)
        insert_node_s(RES_BLK)
      end if
      //end-----------------------------------------------------------------
      TRACE("count %d",SW[W_BLK_CNT])
      //view
      reload_node_s(SW[W_HEAD_BLK],NIL)
      while(RES_STATE and SW[W_CUR_BLK] > NIL)
        TRACE("   view: [%d] : [%d,%d]",SW[W_CUR_BLK],SW[W_PRV_BLK],SW[W_NXT_BLK])
        advance_s(DIR_RIGHT)
      wend      
      //check result
      if(SW[W_BLK_CNT] <> ii or not RES_STATE) then
        TRACE("Failed - #2 insert test, breaking...")
      else
        passed_count = passed_count +1
        TRACE("OK - #2 insert test")
      end if      
    end if
    //3rd
    if(true and RES_STATE) then
      test_count = test_count +1
      TRACE("#3 deletion test")
      ii = SW[W_BLK_CNT] -1
      ij = 3 //deletion position
      //begin---------------------------------------------------------------
      reload_node_s(SW[W_HEAD_BLK],NIL)
      if(ij >= 0 and ij < SW[W_BLK_CNT]) then
        advance_s(DIR_RIGHT*ij)
        TRACE("deletion at: [%d] : [%d,%d]",SW[W_CUR_BLK],SW[W_PRV_BLK],SW[W_NXT_BLK])
        erase_node_s()
        del_block_s(RES_BLK)
      end if
      //end-----------------------------------------------------------------
      TRACE("count %d",SW[W_BLK_CNT])
      //view
      reload_node_s(SW[W_HEAD_BLK],NIL)
      while(RES_STATE and SW[W_CUR_BLK] > NIL)
        TRACE("   view: [%d] : [%d,%d]",SW[W_CUR_BLK],SW[W_PRV_BLK],SW[W_NXT_BLK])
        advance_s(DIR_RIGHT)
      wend        
      //check result
      if(SW[W_BLK_CNT] <> ii or not RES_STATE) then
        TRACE("Failed - #3 deletion test, breaking...")
      else
        passed_count = passed_count +1
        TRACE("OK - #3 deletion test")
      end if      
    end if
    init_values()
  end if  
  //########################################################################
  if(test_count > 0) then
    if(passed_count == test_count) then
      TRACE("ALL TESTS PASSED!")
    else
      TRACE("ONLY %d FROM %d TESTS PASSED!",passed_count,test_count)
    end if
  end if
  //########################################################################
	
  return
  GetData(SW[W_HEAD_BLK],"Local HMI",RW,SD[D_HEAD_LOC],1)
  SW[W_NXT_BLK] = SW[W_HEAD_BLK]
  SW[W_BLK_CNT] = 0
  while(SW[W_NXT_BLK] > NIL and RES_STATE)
    set_block_s(SW[W_NXT_BLK])
    load_node_s(SW[W_NXT_BLK],SW[W_CUR_BLK])
	load_stp_from_prg_s()
	switch_type(TYP_STP)
	SW[W_NXT_BLK] = SW[W_HEAD_BLK]
	SW[W_BLK_CNT] = 0
	while(SW[W_NXT_BLK] > NIL and RES_STATE)
      set_block_s(SW[W_NXT_BLK])
      load_node_s(SW[W_NXT_BLK],SW[W_CUR_BLK])
  	  RES_STATE = RES_STATE and(SW[W_BLK_CNT] <= MAX_STP_CNT +COM_BLK_CNT)
	wend
	RES_STATE = RES_STATE and(SW[W_BLK_CNT] > COM_BLK_CNT)
	switch_type(TYP_PRG)
  	RES_STATE = RES_STATE and(SW[W_BLK_CNT] <= MAX_PRG_CNT)
  wend
  
  if not(RES_STATE) then
    init_values()
  end if
  SetData(SW[W_HEAD_BLK],"Local HMI",RW,SD[D_HEAD_LOC],1)
  
  
//end if
//-------------------------------------------------------------
end macro_command
