//-------------------------------------------------------------
//APPLICATION DEFINED
int HEADER = 0x66FFC0DE,VERSION = 0x1
//CONFIG
int DATA_TYPE =0x1,BLK_PTR_SZ = 2,BLK_TIM_SZ = 2,BLK_REQ_SZ = 6,MAX_DAT_SZ = 262140
int CFG_OFST = 0,DAT_OFST = 1000, COM_OFST = 100, COM_REQ_SZ = 16
int MAX_PRG_CNT = 500, MAX_STP_CNT = 500
int BLK_SZ,MAX_BLK_CNT,COM_SZ,PRG_COM_BLK_SZ
//-------------------------------------------------------------
int BO[3] = {0, 768, 792}, BITMAP[793]
short BLK_CNT,NIL = -1
short P_HEAD_BLK=0,P_CUR_BLK=1,P_NEW_BLK=2,P_PREV_BLK=3,P_NEXT_BLK=4
short ST[10],SEL_PRG=0,SEL_STPS=1
bool TRY_IGNORE = 0,RES_STATE = 1
//-------------------------------------------------------------
sub init_values()
  RES_STATE = 1
  BLK_REQ_SZ  = BLK_REQ_SZ -(BLK_REQ_SZ -128)*(BLK_REQ_SZ > 128)  
  BLK_SZ      = BLK_REQ_SZ +BLK_PTR_SZ +BLK_TIM_SZ //check this shit
  MAX_BLK_CNT = MAX_DAT_SZ /BLK_SZ
  MAX_BLK_CNT = MAX_BLK_CNT -(MAX_BLK_CNT -24576)*(MAX_BLK_CNT > 24576)
  COM_REQ_SZ  = COM_REQ_SZ -(COM_REQ_SZ -128)*(COM_REQ_SZ > 128)
  COM_SZ      = COM_REQ_SZ + 0x1 //fixme
  PRG_COM_BLK_SZ = (COM_SZ + (BLK_SZ -1))/BLK_SZ
  BLK_CNT = 0
  P_HEAD_BLK = 0
  P_CUR_BLK  = 1
  P_NEW_BLK  = 2
  P_PREV_BLK = 3
  P_NEXT_BLK = 4 
  FILL(ST[0],NIL,10)
  FILL(BITMAP[0],-1,793)
end sub
sub load_config()
  int tmp_int
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +0,1)
  SetData(HEADER      ,"Local HMI",RW,CFG_OFST +0,1)
  RES_STATE = RES_STATE and(HEADER       == tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +2,1)
  SetData(VERSION     ,"Local HMI",RW,CFG_OFST +2,1)
  RES_STATE = RES_STATE and(VERSION      >= tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +4,1)
  SetData(DATA_TYPE   ,"Local HMI",RW,CFG_OFST +4,1)
  RES_STATE = RES_STATE and(DATA_TYPE    == tmp_int)
  GetData(tmp_int     ,"Local HMI",RW,CFG_OFST +6,1)
  SetData(BLK_REQ_SZ  ,"Local HMI",RW,CFG_OFST +6,1)
  RES_STATE = RES_STATE and(BLK_REQ_SZ   == tmp_int)
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
  
  GetData(ST[P_HEAD_BLK],"Local HMI",RW,CFG_OFST+100,1)
end sub
sub load_block_data(int blk, int req) //todo validate with bitmap, prev and set next
  short prv,nxt,word,i,bc = 0
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)  
  while(bc < req and RES_STATE)
  	for i = BLK_PTR_SZ to BLK_SZ -1
  	  GetData(word,"Local HMI",RW,DAT_OFST+BLK_SZ*blk+i,1)
  	  SetData(word,"Local HMI",LW,COM_OFST+(BLK_SZ -BLK_PTR_SZ)*bc+i,1)
  	next
  	GetData(nxt,"Local HMI",RW,DAT_OFST+BLK_SZ*blk+1,1)
  	blk = nxt
  	
  	RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT) //fix this
  	bc = bc + RES_STATE
  wend
  RES_STATE = RES_STATE and(bc == req)
end sub
sub load_com() //todo
  
end sub
sub switch_sel(int what)
  P_HEAD_BLK = what*5 +0
  P_CUR_BLK  = what*5 +1
  P_NEW_BLK  = what*5 +2
  P_PREV_BLK = what*5 +3
  P_NEXT_BLK = what*5 +4
end sub
sub load_step_head()
  if(RES_STATE) then
  	FILL(ST[5],NIL,5)
    GetData(ST[5],"Local HMI",RW,DAT_OFST+BLK_SZ*ST[P_CUR_BLK]+2,1) 
  end if  
end sub
sub load_node(int blk, int prv_blk)
  short prv,nxt
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
  if(RES_STATE) then
    GetData(prv,"Local HMI",RW,DAT_OFST+BLK_SZ*blk+0,1)
    GetData(nxt,"Local HMI",RW,DAT_OFST+BLK_SZ*blk+1,1)
    RES_STATE = RES_STATE and(prv == prv_blk)
    RES_STATE = RES_STATE and(nxt > NIL)and(nxt < MAX_BLK_CNT)    
  end if
  if(RES_STATE) then
    ST[P_CUR_BLK ] = blk
    ST[P_PREV_BLK] = prv
    ST[P_NEXT_BLK] = nxt
  end if  
end sub
sub del_node(int blk, int prv_blk, int nxt_blk)
  short word
  //RES_STATE = RES_STATE +TRY_IGNORE
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
  RES_STATE = RES_STATE and(prv_blk >= NIL)and(prv_blk < MAX_BLK_CNT)
  RES_STATE = RES_STATE and(nxt_blk >= NIL)and(nxt_blk < MAX_BLK_CNT)
  if(RES_STATE and prv_blk > NIL) then
    word = nxt_blk
    SetData(word,"Local HMI",RW,DAT_OFST+BLK_SZ*blk+1,1)
  end if
  if(RES_STATE and nxt_blk > NIL) then
    word = prv_blk
    SetData(word,"Local HMI",RW,DAT_OFST+BLK_SZ*blk+0,1)
  end if
  if(RES_STATE and blk == ST[P_HEAD_BLK]) then
    ST[P_HEAD_BLK] = nxt_blk
    //WARN_HEAD_CHANGE = 1 //if nil ???
  end if
  if(RES_STATE and blk == ST[P_CUR_BLK]) then
    if     (nxt_blk <> NIL) then
      ST[P_CUR_BLK] = nxt_blk
    else if(prv_blk <> NIL) then
      ST[P_CUR_BLK] = prv_blk
    else
      ST[P_CUR_BLK] = NIL
    end if
    //WARN_CUR_CHANGE = 1 //if nil ???
  end if
end sub
sub set_block(int blk)
  int b,p,s,k
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
  if not(RES_STATE) then
    return
  end if
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
end sub
sub del_block(int blk)
  int b,p,s,k
  //RES_STATE = RES_STATE +TRY_IGNORE
  RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
  if not(RES_STATE) then
    return
  end if
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
end sub
sub new_block()
  int k,s,m,b=0,res=0
  RES_STATE = RES_STATE and(BLK_CNT < MAX_BLK_CNT)
  if not(RES_STATE) then
    ST[P_NEW_BLK] = NIL
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
  ST[P_NEW_BLK] = res
end sub

//-------------------------------------------------------------
//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
//if(INIT() == true) then

  init_values()
  load_config()

  //testing cases
  //######################################################################## 
  if(true) then //testing bitmap loading with value = 3205
    TRACE("Test case set_block with 3205")
    BITMAP[100] = 1 << 5 // 3205 /32 = 100 (+0)   , 3205 %32 = 5
    BITMAP[771] = 1 << 4 // 100  /32 = 3 (+768)   , 100  %32 = 4
    BITMAP[792] = 1 << 3 // 3    /32 = 0 (+768+24), 3    %32 = 3
    set_block(3205) //try...
    if(BITMAP[100] or BITMAP[771] or BITMAP[792] or not RES_STATE) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[100], BITMAP[771], BITMAP[792])
    else
      TRACE("OK")
    end if
    init_values()
  end if
  //######################################################################## 
  if(true) then //testing bitmap loading with value = 9369
    TRACE("Test case set_block with 9369")
    BITMAP[292] = 1 << 25 // 9369 /32 = 292 (+0)   , 3205 %32 = 25
    BITMAP[777] = 1 << 4  // 292  /32 = 9 (+768)   , 292  %32 = 4
    BITMAP[792] = 1 << 9  // 9    /32 = 0 (+768+24), 9    %32 = 9
    set_block(9369) //try...
    if(BITMAP[292] or BITMAP[777] or BITMAP[792] or not RES_STATE) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[292], BITMAP[777], BITMAP[792])
    else
      TRACE("OK")
    end if
    init_values()
  end if  
  //########################################################################
  if(true) then //testing bitmap get value = 3205
    TRACE("Test case new_block")
    FILL(BITMAP[0],0,793) //simulate full load ecxept of one element
    BITMAP[100] = 1 << 5 // 3205 /32 = 100 (+0)   , 3205 %32 = 5
    BITMAP[771] = 1 << 4 // 100  /32 = 3 (+768)   , 100  %32 = 4
    BITMAP[792] = 1 << 3 // 3    /32 = 0 (+768+24), 3    %32 = 3
    new_block() //try...
    if(ST[P_NEW_BLK] <> 3205 or not RES_STATE) then
      TRACE("Failed, incorrect value %d", ST[P_NEW_BLK])
    else
      TRACE("OK")
    end if
    init_values()
  end if
  //######################################################################## 
  if(true) then //testing bitmap delete with value = 3205
    TRACE("Test case del_block with 3205")
    set_block(3205)
    del_block(3205) //try...
    if(BITMAP[100] <> -1 or BITMAP[771] <> -1 or BITMAP[792] <> -1 or not RES_STATE) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[100], BITMAP[771], BITMAP[792])
    else
      TRACE("OK")
    end if
    init_values()
  end if    
  //########################################################################
  if(true) then //testing bitmap perfomance
  	TRACE("Test case bitmap performance")
  	RES_STATE = 1
  	int start,stop
  	float res
  	//1
  	GetData(start,"Local HMI",LW,9030,1)
  	//while(BLK_CNT < MAX_BLK_CNT) //try...
  	int i = 0
  	for i = 0 to 999
        new_block()
  		set_block(ST[P_NEW_BLK])
  		//del_block(ST[P_NEW_BLK])
  		//set_block(ST[P_NEW_BLK])
  	next
  	//wend
  	GetData(stop,"Local HMI",LW,9030,1)
  	res = (stop - start)/10.0
  	TRACE("time =  %f s", res)
  	res = BLK_CNT/res
  	TRACE("perf =  %f op/s", res)	
  	TRACE("last block %d", ST[P_NEW_BLK])
  	TRACE("count %d", BLK_CNT)
    if not(RES_STATE) then
      TRACE("Failed")
    else
      TRACE("OK")
    end if  	
  	init_values()
  end if  
  //######################################################################## 
	
  return
  
  int loaded_progs = 0
  ST[P_NEXT_BLK] = ST[P_HEAD_BLK]
  while(ST[P_NEXT_BLK] <> NIL and RES_STATE)
    set_block(ST[P_NEXT_BLK])
    load_node(ST[P_NEXT_BLK], ST[P_CUR_BLK])

	load_step_head()
	switch_sel(SEL_STPS)
	ST[P_NEXT_BLK] = ST[P_HEAD_BLK]
	
	int loaded_steps = 0
	while(ST[P_NEXT_BLK] <> NIL and RES_STATE)
      set_block(ST[P_NEXT_BLK])
      load_node(ST[P_NEXT_BLK], ST[P_CUR_BLK])
  	  loaded_steps = loaded_steps + RES_STATE
  	  RES_STATE = RES_STATE and(loaded_steps <= MAX_STP_CNT)
	wend
	load_block_data(ST[P_HEAD_BLK],PRG_COM_BLK_SZ)
	load_com()
	switch_sel(SEL_PRG)
  	loaded_progs = loaded_progs + RES_STATE
  	RES_STATE = RES_STATE and(loaded_progs <= MAX_PRG_CNT)	
  wend
  
  if not(RES_STATE) then
    init_values()
  end if
//end if
//-------------------------------------------------------------
end macro_command
