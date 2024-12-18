//-------------------------------------------------------------
//-- добавь валидацию tim и cc
//-- приведи код в порядок, cow в функцию, надо упростить
//APPLICATION DEFINED
int HEADER = 0x66FFC0DE,VERSION = 0x1
//CONFIG
int DATA_TYPE =0x1,BLK_HDR_SZ = 3,STP_ADD_SZ = 2,STP_REQ_SZ = 5,MAX_DAT_SZ = 262140
int CFG_OFST = 0,DAT_OFST = 1000,COM_ADD_SZ = 10,COM_REQ_SZ = 16
int MAX_PRG_CNT = 500, MAX_STP_CNT = 500, MAX_BUF_SZ = 288,RP_DAT_OFST=32
int BLK_CNT,BLK_PLD_SZ,BLK_SZ,MAX_BLK_CNT,COM_BLK_OFST,COM_BLK_CNT,RES_VAR,PRG_SEL_LOC
//-------------------------------------------------------------
int BO[3] = {0, 768, 792}, BITMAP[793]
short BUFF[289],NIL = -1
short RP_SAV_DAT = 1,RP_NEW_STP = 2,RP_DEL_BLK = 4,RP_SWP_BLK = 8,RP_NEW_PRG = 16,RESTORE = 0
//todo
//подумай на счёт того, чтобы добавить owner и modified флаг
//возможно стоит вернуть слоты, но только меняя CUR_BLK,PRV_BLK,NXT_BLK (Owner ??)
//todo
int  M_HEAD_LOC[2]
short M_BLK_CNT[2],M_HEAD_BLK[2],M_CUR_BLK[2],M_PRV_BLK[2],M_NXT_BLK[2]
short SEL=0,PRG=0,STP=1,LOC_OFST_HEAD=0,LOC_OFST_CNT=1
short RES_BLK,DIR_LEFT = -1,DIR_RIGHT =1
//-------------------------------------------------------------
//COMMON
bool  RES_STATE
char  ev_tbl[80]
short st_evt[24],st_opt[24],st_top = 0
//-------------------------------------------------------------
sub init_values()
  RES_STATE = 1
  BLK_PLD_SZ  = STP_ADD_SZ + STP_REQ_SZ
  BLK_PLD_SZ  = BLK_PLD_SZ -(BLK_PLD_SZ -128)*(BLK_PLD_SZ > 128)
  STP_REQ_SZ  = BLK_PLD_SZ - STP_ADD_SZ
  BLK_SZ      = BLK_HDR_SZ +BLK_PLD_SZ
  MAX_BLK_CNT = MAX_DAT_SZ /BLK_SZ
  MAX_BLK_CNT = MAX_BLK_CNT -(MAX_BLK_CNT -24576)*(MAX_BLK_CNT > 24576)
  COM_REQ_SZ   = COM_REQ_SZ -(COM_REQ_SZ -128)*(COM_REQ_SZ > 128)
  COM_BLK_OFST =(COM_ADD_SZ +(BLK_PLD_SZ -1))/(BLK_PLD_SZ)
  COM_BLK_CNT  =(COM_REQ_SZ +(BLK_PLD_SZ -1))/(BLK_PLD_SZ)
  COM_BLK_CNT  = COM_BLK_CNT+COM_BLK_OFST
  BLK_CNT = 0
  RES_BLK = NIL
  //COM_TIM = 0
  //COM_POS = 0
  //COM_REP = 0
  M_HEAD_LOC[PRG] = CFG_OFST +32 //тут два шорта, 1 - голова, 2 - количество блоков
  M_HEAD_LOC[STP] = CFG_OFST +34 //тут
  PRG_SEL_LOC     = CFG_OFST +36
  FILL(M_BLK_CNT [0],0,2) //стоит удалить и оставить только NIL, подгрузку сделать как load_head
  FILL(M_HEAD_BLK[0],NIL,2)
  FILL(M_CUR_BLK [0],NIL,2)
  FILL(M_PRV_BLK [0],NIL,2)
  FILL(M_NXT_BLK [0],NIL,2)
  FILL(BITMAP[0],-1,793)
end sub
//-------------------------------------------------------------
sub load_stp_from_prg_s() //load_head_s()
  if(RES_STATE) then
    M_HEAD_LOC[STP] = DAT_OFST+BLK_HDR_SZ+BLK_SZ*M_CUR_BLK[PRG]
    M_BLK_CNT [STP] = 0
    M_CUR_BLK [STP] = NIL
    M_PRV_BLK [STP] = NIL
    M_NXT_BLK [STP] = NIL
    GetData(M_HEAD_BLK[STP],"Local HMI",RW,M_HEAD_LOC[STP]+LOC_OFST_HEAD,1) 
  end if  
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
//sub get_prg_com_from_cur_s()
//  if(RES_STATE) then
    //COM_TIM =(BUFF[0]&0xFFFF)|(BUFF[1]<<16) //2,3
    //COM_POS = BUFF[2] //0
    //COM_REP = BUFF[3] //1
    //COM_TIM = COM_TIM -(COM_TIM -1)*(COM_TIM < 1)
    //COM_TIM = COM_TIM -(COM_TIM -(3600*24*365))*(COM_TIM > (3600*24*365))
    //todo
    //todo
    //todo
    //COM_POS = COM_POS -(COM_POS -0)*(COM_POS < 0) //вот херня
    //COM_POS = COM_POS -(COM_POS -W_BLK_CNT])*(COM_POS >= W_BLK_CNT])
    //COM_REP = COM_REP -(COM_REP -0)*(COM_REP < 0)
    //COM_REP = COM_REP -(COM_REP -999)*(COM_REP > 999)
  //end if
//end sub
//-------------------------------------------------------------
sub create_rp_s(int op, int opt, int count)
  short dc
  dc = RP_DAT_OFST
  if not(RES_STATE) then
    return
  end if
  LOWORD(M_HEAD_LOC[SEL],BUFF[8]) //тут
  HIWORD(M_HEAD_LOC[SEL],BUFF[9]) //тут
  BUFF[10] = M_BLK_CNT [SEL]
  BUFF[11] = M_HEAD_BLK[SEL]
  BUFF[12] = M_CUR_BLK [SEL]
  BUFF[13] = M_PRV_BLK [SEL]
  BUFF[14] = M_NXT_BLK [SEL]
  BUFF[15] = BLK_CNT
  BUFF[16] = RES_BLK
  if     (op&RP_NEW_PRG) then
    BUFF[10] = M_BLK_CNT[SEL] +1 //simulate successful insertion
    BUFF[12] = opt               //simulate CUR_BLK
    BUFF[14] = M_CUR_BLK[SEL]    //simulate NXT_BLK
  else if(op&RP_SAV_DAT) then
    dc = dc  + count
  else if(op&RP_SWP_BLK) then
    BUFF[24] = opt               //shift
    dc = dc  + 2*BLK_PLD_SZ
  end if
  BUFF[0] = dc
  BUFF[1] = VERSION
  BUFF[2] = DATA_TYPE
  BUFF[3] = op
  CRC(BUFF[0],BUFF[dc],dc)
  SetData(BUFF[0],"Local HMI",RW,CFG_OFST+64,dc +1)
end sub
//-------------------------------------------------------------
sub load_rp_s()
  short chk
  int dw
  RESTORE = RES_STATE
  if(RESTORE) then
    GetData(BUFF[0],"Local HMI",RW,CFG_OFST+64,MAX_BUF_SZ)
    RESTORE = RESTORE and(BUFF[0] >= RP_DAT_OFST)and(BUFF[0] < MAX_BLK_CNT)
    RESTORE = RESTORE and(BUFF[1] == VERSION)
    RESTORE = RESTORE and(BUFF[2] == DATA_TYPE)
  end if
  if(RESTORE) then
    CRC(BUFF[0],chk,BUFF[0])
    RESTORE = RESTORE and(chk == BUFF[BUFF[0]])
    dw = (BUFF[8]&0xFFFF)|(BUFF[9]<<16)
    RESTORE = RESTORE and(dw > CFG_OFST)and(dw < (DAT_OFST + MAX_DAT_SZ))
    RESTORE = RESTORE and(BUFF[10] >= 0  )and(BUFF[10] <= MAX_BLK_CNT)
    RESTORE = RESTORE and(BUFF[11] >= NIL)and(BUFF[11] <  MAX_BLK_CNT)
    RESTORE = RESTORE and(BUFF[12] >= NIL)and(BUFF[12] <  MAX_BLK_CNT)
    RESTORE = RESTORE and(BUFF[13] >= NIL)and(BUFF[13] <  MAX_BLK_CNT)
    RESTORE = RESTORE and(BUFF[14] >= NIL)and(BUFF[14] <  MAX_BLK_CNT)
    RESTORE = RESTORE and(BUFF[15] >= 0  )and(BUFF[15] <= MAX_BLK_CNT)
    RESTORE = RESTORE and(BUFF[16] >= NIL)and(BUFF[16] <  MAX_BLK_CNT)
    if     (BUFF[3]&RP_SAV_DAT) then
      RES_VAR = BUFF[0] -RP_DAT_OFST
    else if(BUFF[3]&RP_SWP_BLK) then
      RES_VAR = BUFF[24]
    end if
    //TRACE("Restore Point Was Found, ALLOW = %d", RESTORE)
  end if
  if(RESTORE) then
    RESTORE = BUFF[3]
    M_HEAD_LOC[SEL] = dw //тут
    M_BLK_CNT [SEL] = BUFF[10]
    M_HEAD_BLK[SEL] = BUFF[11]
    M_CUR_BLK [SEL] = BUFF[12]
    M_PRV_BLK [SEL] = BUFF[13]
    M_NXT_BLK [SEL] = BUFF[14]
    BLK_CNT = BUFF[15]
    RES_BLK = BUFF[16]
    //todo
    //не плохо бы тут сохранить информацию о восстановлении
  end if
end sub
//-------------------------------------------------------------
sub remove_rp_s()
  //todo
  //лучше тут, потому что есть RES_STATE восстановления
  if(RES_STATE) then
    SetData(BITMAP[0],"Local HMI",RW,CFG_OFST+64,16)
  end if
end sub
//-------------------------------------------------------------
sub update_retain_s()
  int i
  if(RES_STATE) then
  	i = 1
    SetData(i,"Local HMI",LB,9029,1)
    //for i = 0 to 999
    //next
    //DELAY(50) //--todo: restore delay
	i = 0
	SetData(i,"Local HMI",LB,9029,1)
  end if
end sub
//-------------------------------------------------------------
sub load_store_data_s(int op, int ofst, int req)
  short tmp,blk,prv,nxt,chk,dc = 0
  RES_STATE = RES_STATE and((req +ofst) <= MAX_BUF_SZ)and(req >=0)and(ofst >=0)
  blk = M_CUR_BLK[SEL]
  prv = M_PRV_BLK[SEL]
  while(RES_STATE and dc < req)
    RES_STATE = RES_STATE and(blk > NIL)and(blk < MAX_BLK_CNT)
    if(RES_STATE) then
      GetData(tmp,"Local HMI",RW,DAT_OFST+0+BLK_SZ*blk,1)
      GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*blk,1)
      GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*blk,1)
      RES_STATE = RES_STATE and(tmp == prv)
      RES_STATE = RES_STATE and(chk ==(tmp ^ nxt))
      RES_STATE = RES_STATE and(nxt >= NIL)and(nxt < MAX_BLK_CNT)
    end if
    if(RES_STATE) then
      tmp = req - dc
      tmp = tmp -(tmp -BLK_PLD_SZ)*(tmp > BLK_PLD_SZ)
      if(op == 'L') then
        GetData(BUFF[ofst],"Local HMI",RW,DAT_OFST+BLK_HDR_SZ+BLK_SZ*blk,tmp)
      else
        SetData(BUFF[ofst],"Local HMI",RW,DAT_OFST+BLK_HDR_SZ+BLK_SZ*blk,tmp)
      end if
      ofst = ofst +tmp
      dc   = dc   +tmp
    end if
    prv = blk
    blk = nxt
  wend
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
    M_CUR_BLK[SEL] = blk
    M_PRV_BLK[SEL] = prv
    M_NXT_BLK[SEL] = nxt  
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
    M_BLK_CNT[SEL] = M_BLK_CNT[SEL] +1 //вот тут бы проверчку сделать...
    M_CUR_BLK[SEL] = blk
    M_PRV_BLK[SEL] = prv
    M_NXT_BLK[SEL] = nxt
  end if  
end sub
//-------------------------------------------------------------
sub advance_s(int shift)
  short prv,nxt,chk
  while(RES_STATE and shift)
    prv = NIL
    nxt = NIL
    RES_STATE = RES_STATE and not((M_PRV_BLK[SEL]>NIL)and(M_CUR_BLK[SEL]<=NIL)and(M_NXT_BLK[SEL]>NIL))
    if(shift > 0) then
      RES_STATE = RES_STATE and((M_CUR_BLK[SEL] > NIL)or(M_NXT_BLK[SEL] > NIL))
      if(M_NXT_BLK[SEL] > NIL) then
        GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_NXT_BLK[SEL],1)
        GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_NXT_BLK[SEL],1)
        GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_NXT_BLK[SEL],1)
        RES_STATE = RES_STATE and(prv == M_CUR_BLK[SEL])
        RES_STATE = RES_STATE and(nxt >= NIL)and(nxt < MAX_BLK_CNT)
        RES_STATE = RES_STATE and(chk == (prv ^ nxt))
      end if
      if(RES_STATE) then
        M_PRV_BLK[SEL] = M_CUR_BLK[SEL]
        M_CUR_BLK[SEL] = M_NXT_BLK[SEL]
        M_NXT_BLK[SEL] = nxt
      end if
    else if(shift < 0) then
      RES_STATE = RES_STATE and((M_CUR_BLK[SEL] > NIL)or(M_PRV_BLK[SEL] > NIL))
      if(M_PRV_BLK[SEL] > NIL) then
        GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_PRV_BLK[SEL],1)
        GetData(nxt,"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_PRV_BLK[SEL],1)
        GetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_PRV_BLK[SEL],1)
        RES_STATE = RES_STATE and(prv >= NIL)and(prv < MAX_BLK_CNT)
        RES_STATE = RES_STATE and(nxt == M_CUR_BLK[SEL])
        RES_STATE = RES_STATE and(chk == (prv ^ nxt))
      end if
      if(RES_STATE) then
        M_NXT_BLK[SEL] = M_CUR_BLK[SEL]
        M_CUR_BLK[SEL] = M_PRV_BLK[SEL]
        M_PRV_BLK[SEL] = prv
      end if
    end if
    shift = shift -(shift > 0) +(shift < 0)
  wend
end sub
//-------------------------------------------------------------
sub insert_node_s(short blk) //shift_next
  short prv,nxt,chk
  RES_STATE = RES_STATE and(blk > NIL)
  RES_STATE = RES_STATE and not((M_PRV_BLK[SEL]> NIL)and(M_CUR_BLK[SEL]<=NIL)and(M_NXT_BLK[SEL]>NIL))
  RES_STATE = RES_STATE and not((M_PRV_BLK[SEL]<=NIL)and(M_CUR_BLK[SEL]<=NIL)and(M_NXT_BLK[SEL]>NIL))
  if not(RES_STATE) then
    return
  end if
  if(M_PRV_BLK[SEL] > NIL) then
    GetData(prv,"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_PRV_BLK[SEL],1)
    chk = prv ^ blk
    SetData(blk,"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_PRV_BLK[SEL],1)
    SetData(chk,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_PRV_BLK[SEL],1)
  else
    M_HEAD_BLK[SEL] = blk
    SetData(M_HEAD_BLK[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_HEAD,1)
  end if
  if(M_CUR_BLK[SEL] > NIL) then
    SetData(blk ,"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_CUR_BLK[SEL],1)
    GetData(nxt ,"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_CUR_BLK[SEL],1)
    chk = nxt ^ blk
    SetData(chk ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_CUR_BLK[SEL],1)
  end if
  M_BLK_CNT[SEL] = M_BLK_CNT[SEL] +1
  SetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
  M_NXT_BLK[SEL] = M_CUR_BLK[SEL]
  M_CUR_BLK[SEL] = blk
  chk = M_PRV_BLK[SEL] ^ M_NXT_BLK[SEL]
  SetData(M_PRV_BLK[SEL],"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_CUR_BLK[SEL],1)
  SetData(M_NXT_BLK[SEL],"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_CUR_BLK[SEL],1)
  SetData(chk           ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_CUR_BLK[SEL],1)
end sub
//-------------------------------------------------------------
sub erase_node_s() //shift_next    
  short prv,nxt,chk
  RES_STATE = RES_STATE and(M_CUR_BLK[SEL] > NIL)
  if not(RES_STATE) then
    return
  end if
  prv = NIL
  nxt = NIL
  if(M_PRV_BLK[SEL] > NIL) then
    GetData(prv          ,"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_PRV_BLK[SEL],1)
    chk = prv ^ M_NXT_BLK[SEL]
    SetData(M_NXT_BLK[SEL],"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_PRV_BLK[SEL],1)
    SetData(chk           ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_PRV_BLK[SEL],1)
  else
    M_HEAD_BLK[SEL] = M_NXT_BLK[SEL]
    SetData(M_HEAD_BLK[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_HEAD,1)
  end if
  if(M_NXT_BLK[SEL] > NIL) then
    SetData(M_PRV_BLK[SEL],"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_NXT_BLK[SEL],1)
    GetData(nxt           ,"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_NXT_BLK[SEL],1)
    chk = nxt ^ M_PRV_BLK[SEL]
    SetData(chk           ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_NXT_BLK[SEL],1)
  end if
  RES_BLK = M_CUR_BLK[SEL]
  M_BLK_CNT[SEL] = M_BLK_CNT[SEL] -1
  SetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
  M_CUR_BLK[SEL] = M_NXT_BLK[SEL]
  M_NXT_BLK[SEL] = nxt
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
sub to_stack(int evt, int ovr, int opt)
  if(evt > 0 and evt < 79) then
    st_evt[st_top] = evt
    st_opt[st_top] = opt
    st_top = st_top +1
    while(ev_tbl[evt] or ovr)
      evt = ovr*(ovr > 0) + ev_tbl[evt]*(not ovr)
      ovr = 0
      st_evt[st_top] = evt
      st_opt[st_top] = 0
      st_top = st_top +1
    wend
  end if
end sub
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub set_ev_dep(int evt, int dep)
  ev_tbl[evt] = dep
end sub
//-------------------------------------------------------------
//-------------------------------------------------------------
//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
short position[6],pos_hdl[6],sc_blk[6],sp_blk[6],header[20]
int pw_stp=0,ps_stp=1,pr_stp=2,pw_prg=3,ps_prg=4,pr_prg=5
int ev_set_pos = 1 ,ev_get_pos = 11,ev_insert  = 20,ev_erase = 25
int ev_sav_pos = 30,ev_rld_dat = 35,ev_sav_dat = 40
int ev_swap = 45,ev_control=55,ev_view = 60,ev_sav_com = 65,ev_tick = 75
int dm = 0,dm_stp = 7,dm_prg = 56
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
int stim,ctim,cc,bits,p,k,evt = 0,opt = 0,cow = 0
short prg_wnd_dat = 510,stp_wnd_dat = 1000
bool  run
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if(INIT() == true) then
  init_values()
  load_config_s()
  //
  FILL(ev_tbl  [0],0,80)
  FILL(position[0],0,6)
  FILL(pos_hdl [0],0,6)
  FILL(sc_blk[0],NIL,6)
  FILL(sp_blk[0],NIL,6)
  pos_hdl[ps_prg] = ev_rld_dat +PRG
  pos_hdl[ps_stp] = ev_rld_dat +STP
  pos_hdl[pr_stp] = ev_rld_dat +STP //--change ??
  set_ev_dep(ev_get_pos +ps_stp,ev_get_pos +ps_prg)
  set_ev_dep(ev_get_pos +pw_stp,ev_get_pos +ps_prg)
  set_ev_dep(ev_get_pos +pr_stp,ev_get_pos +pr_prg)
  set_ev_dep(ev_set_pos +ps_stp,ev_get_pos +ps_prg)
  set_ev_dep(ev_set_pos +pw_stp,ev_get_pos +ps_prg)
  set_ev_dep(ev_set_pos +pr_stp,ev_get_pos +pr_prg)
  set_ev_dep(ev_insert  +PRG   ,ev_get_pos +pw_prg)
  set_ev_dep(ev_insert  +STP   ,ev_get_pos +pw_stp)
  set_ev_dep(ev_erase   +PRG   ,ev_get_pos +pw_prg)
  set_ev_dep(ev_erase   +STP   ,ev_get_pos +pw_stp)
  set_ev_dep(ev_swap    +PRG   ,ev_get_pos +ps_prg)
  set_ev_dep(ev_swap    +STP   ,ev_get_pos +ps_stp)
  set_ev_dep(ev_sav_pos +PRG   ,ev_get_pos +ps_prg)
  set_ev_dep(ev_sav_pos +STP   ,ev_get_pos +ps_stp)
  set_ev_dep(ev_sav_dat +PRG   ,ev_get_pos +pw_prg)
  set_ev_dep(ev_sav_dat +STP   ,ev_get_pos +pw_stp)
  set_ev_dep(ev_rld_dat +STP   ,ev_sav_pos +STP   ) //-- fixme
  set_ev_dep(ev_rld_dat +PRG   ,ev_sav_pos +PRG   ) //-- fixme
  set_ev_dep(ev_view    +PRG   ,ev_get_pos +pw_prg)
  set_ev_dep(ev_view    +STP   ,ev_get_pos +pw_stp)
  set_ev_dep(ev_view    +pr_stp,ev_get_pos +pr_stp)
  set_ev_dep(ev_control        ,ev_get_pos +ps_prg)
  set_ev_dep(ev_sav_com +ps_prg,ev_get_pos +ps_prg)
  set_ev_dep(ev_sav_com +pr_prg,ev_get_pos +pr_prg)
  set_ev_dep(ev_tick           ,ev_get_pos +pr_stp)
  run  = 0
  stim = 0
  ctim = 0
  cc   = 0
  //try to restore
  load_rp_s()
  if     (RESTORE&RP_DEL_BLK) then
    //erase_node_s()
  else if(RESTORE&RP_NEW_PRG) then
    //erase_node_s()
  else if(RESTORE&RP_NEW_STP) then
    //insert_node_s(RES_BLK)
  else if(RESTORE&RP_SWP_BLK) then
    //load_store_data_s('S',RP_DAT_OFST+BLK_PLD_SZ,BLK_PLD_SZ)
    //advance_s(RES_VAR)
    //load_store_data_s('S',RP_DAT_OFST,BLK_PLD_SZ)
  end if
  if     (RESTORE&RP_SAV_DAT) then
    //load_store_data_s('S',RP_DAT_OFST,RES_VAR)
  end if
  remove_rp_s()
  //load structure - - - - - - - - - - - - - - - - - - - - - - - 
  if(RES_STATE) then
    init_values()
    SEL = PRG
    GetData(M_HEAD_BLK[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_HEAD,1)
    M_NXT_BLK[SEL] = M_HEAD_BLK[SEL]
    while(RES_STATE and M_NXT_BLK[SEL] > NIL)
      set_block_s(M_NXT_BLK[SEL])
      load_node_s(M_NXT_BLK[SEL],M_CUR_BLK[SEL])
      load_stp_from_prg_s()
      SEL = STP //to stps
      M_NXT_BLK[SEL] = M_HEAD_BLK[SEL]
      while(RES_STATE and M_NXT_BLK[SEL] > NIL)
        set_block_s(M_NXT_BLK[SEL])
        load_node_s(M_NXT_BLK[SEL],M_CUR_BLK[SEL])
        RES_STATE = RES_STATE and(M_BLK_CNT[SEL] <= MAX_STP_CNT +COM_BLK_CNT)
      wend
      SetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
//TRACE("PRG USER STP CNT: [%d]",M_BLK_CNT[SEL] -COM_BLK_CNT)
      RES_STATE = RES_STATE and(M_BLK_CNT[SEL] > COM_BLK_CNT)
      SEL = PRG //to prg
      RES_STATE = RES_STATE and(M_BLK_CNT[SEL] <= MAX_PRG_CNT)
    wend
    SetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
    RES_STATE = RES_STATE and(M_BLK_CNT[SEL] > 0)
    GetData(position[ps_prg],"Local HMI",RW,PRG_SEL_LOC,1)
    GetData(position[pw_prg],"Local HMI",RW,PRG_SEL_LOC,1)
  else
    //TRACE("CONFIG: created")
  end if
  if(RES_STATE) then
    //TRACE("loaded: blk [%d], prgs [%d]",BLK_CNT,M_BLK_CNT[SEL])
  //create structure on failure - - - - - - - - - - - - - - - - - -
  else  
    init_values()
    SEL = PRG
    while(RES_STATE and M_BLK_CNT[SEL] < 1)
      new_block_s()
      set_block_s(RES_BLK)
      insert_node_s(RES_BLK)
      load_stp_from_prg_s() //--TO STPS
      SEL = STP
      M_HEAD_BLK[SEL] = NIL
      GetData(BUFF[0],"Local HMI","Program_default_stp",BLK_PLD_SZ)
      while(RES_STATE and M_BLK_CNT[SEL] < (COM_BLK_CNT +1))
        new_block_s()
        set_block_s(RES_BLK)
        insert_node_s(RES_BLK)
        load_store_data_s('S',0,BLK_PLD_SZ)
      wend
      reload_node_s(M_HEAD_BLK[SEL],NIL)
      FILL(BUFF[0],0,COM_ADD_SZ)
      load_store_data_s('S',0,COM_ADD_SZ)
      advance_s(COM_BLK_OFST)
      GetData(BUFF[0],"Local HMI","Program_default_com",COM_REQ_SZ)
      load_store_data_s('S',0,COM_REQ_SZ)
      SEL = PRG
    wend
    SetData(position[ps_prg],"Local HMI",RW,PRG_SEL_LOC,1)
    //TRACE("created: [%d], prgs [%d]",BLK_CNT,M_BLK_CNT[SEL])
  end if
  to_stack(ev_view+PRG,0,0)
  to_stack(ev_rld_dat +PRG,0,0)
end if
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
GetData(evt,"Local HMI","Program_Back_Evt",1)
GetData(opt,"Local HMI","Program_Back_Opt",1)
p = 0
SetData(p  ,"Local HMI","Program_Back_Evt",1)
if(not RES_STATE) then
  //TRACE("FAILURE")
  return
end if
to_stack(if_((st_top),0,ev_view+PRG)+0,0,0)
to_stack(if_((evt == 0 and run),ev_tick,0)+0,0,1)
to_stack(evt,0,opt)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
while(RES_STATE and st_top > 0) //-- STACK MACHINE
  st_top = st_top -1
  evt = st_evt[st_top]
  opt = st_opt[st_top]
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  p = evt -ev_set_pos*(evt <  ev_get_pos) //ev_set_pos = 1
  p = p   -ev_get_pos*(evt >= ev_get_pos) //ev_get_pos = 11
  if(p >= pw_stp and p <= pr_prg ) then //-- ADVANCE
    //TRACE("advance: [%d], opt :[%d]",p,opt)
    SEL = p/3 == pw_stp/3
    if(SEL == STP) then
      load_stp_from_prg_s()
    end if
    GetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
    //TRACE("PRG BLK CNT: [%d]",M_BLK_CNT[SEL])
    //TRACE("want: [%d]",position[p] +opt)
    opt = lim(position[p] +opt,0,M_BLK_CNT[SEL] -COM_BLK_CNT*SEL -1)
    //TRACE("GET : [%d]",opt)
    if(sc_blk[p] > NIL) then
      reload_node_s(sc_blk[p],sp_blk[p])
      //TRACE("before: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      advance_s(opt -position[p])
    else
      reload_node_s(M_HEAD_BLK[SEL],NIL)
      //TRACE("head: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      advance_s(COM_BLK_CNT*SEL +opt)
    end if
    //TRACE("after: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    position[p] = opt
    sc_blk[p] = M_CUR_BLK[SEL]
    sp_blk[p] = M_PRV_BLK[SEL]
    if(evt < ev_get_pos) then
      to_stack(pos_hdl[p],0,0)
      cow = p == ps_stp //-- pr_prg ?
    end if
  //-------------------------------------------------------------
  else if(evt == (ev_insert +PRG)) then //-- INSERT PRG
    SEL = PRG //to prg
    if((M_BLK_CNT[SEL] < MAX_PRG_CNT)and((BLK_CNT +COM_BLK_CNT +1) < MAX_BLK_CNT)) then
      //TRACE("!!!INSERTION PRG!!!")
      opt = lim(position[pw_prg] +opt,0,M_BLK_CNT[SEL]) //allow shift to the end()
      advance_s(opt -position[pw_prg])
      new_block_s()
      set_block_s(RES_BLK)
      create_rp_s(RP_NEW_PRG,RES_BLK,NIL) //create restore point
      update_retain_s()
      //TRACE("   before prg: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      insert_node_s(RES_BLK)
      //TRACE("   insertion prg: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      load_stp_from_prg_s() //to stps
      SEL = STP
      M_HEAD_BLK[SEL] = NIL
      GetData(BUFF[0],"Local HMI","Program_default_stp",BLK_PLD_SZ)
      while(RES_STATE and M_BLK_CNT[SEL] < (COM_BLK_CNT +1))
        new_block_s()
        set_block_s(RES_BLK)
        //TRACE("      before    stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
        insert_node_s(RES_BLK)
        //TRACE("      insertion stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
        load_store_data_s('S',0,BLK_PLD_SZ)
      wend
      reload_node_s(M_HEAD_BLK[SEL],NIL)
      FILL(BUFF[0],0,COM_ADD_SZ)
      load_store_data_s('S',0,COM_ADD_SZ)
      advance_s(COM_BLK_OFST)
      GetData(BUFF[0],"Local HMI","Program_default_com",COM_REQ_SZ)
      load_store_data_s('S',0,COM_REQ_SZ)
      SEL = PRG
      remove_rp_s() //delete restore point
      //TRACE("!!!INSERTION DONE!!!")
      position[ps_prg] = position[ps_prg] +(opt <= position[ps_prg])
      position[pr_prg] = position[pr_prg] +(opt <= position[pr_prg])
      to_stack(ev_sav_pos +PRG,0,0)
      dm = dm_prg
    end if
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else if(evt == (ev_insert +STP)) then //-- INSERT STP
    SEL = STP //to stps
    if((M_BLK_CNT[SEL] < (MAX_STP_CNT+COM_BLK_CNT))and(BLK_CNT < MAX_BLK_CNT)) then
      //TRACE("!!!INSERTION STP!!!")
      opt = lim(position[pw_stp] +opt,0,M_BLK_CNT[SEL] -COM_BLK_CNT) //allow shift to the end()
      advance_s(opt -position[pw_stp])
      new_block_s()
      set_block_s(RES_BLK)
      GetData(BUFF[RP_DAT_OFST],"Local HMI","Program_default_stp",BLK_PLD_SZ)
      create_rp_s(RP_NEW_STP|RP_SAV_DAT,RES_BLK,BLK_PLD_SZ) //create restore point
      update_retain_s()
      //TRACE("   before    stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      insert_node_s(RES_BLK)
      load_store_data_s('S',RP_DAT_OFST,BLK_PLD_SZ)
      //TRACE("   insertion stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      remove_rp_s() //delete restore point
      //TRACE("!!!INSERTION DONE!!!")
      position[ps_stp] = position[ps_stp] +(opt <= position[ps_stp]) //смена либо sprg или rprg
      to_stack(ev_sav_pos +STP,0,0)
      dm = dm_stp
      cow = true
    end if
  //-------------------------------------------------------------
  else if(evt == (ev_erase +PRG)) then //-- ERASE PRG
    SEL = PRG //to prg
    if(M_BLK_CNT[SEL] > 1) then
      opt = lim(position[pw_prg] +opt,0,M_BLK_CNT[SEL] -1)
      if(run and opt == position[pr_prg]) then
        continue
      end if
      //TRACE("!!!ERASE PRG!!!")
      //TRACE("blk cnt: [%d]",BLK_CNT)
      advance_s(opt -position[pw_prg])
      create_rp_s(RP_DEL_BLK,NIL,NIL) //create restore point
      update_retain_s()
      load_stp_from_prg_s() //to stps
      SEL = STP
      GetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
      //TRACE("STP BLK CNT: [%d]",M_BLK_CNT[SEL])
      M_NXT_BLK[SEL] = M_HEAD_BLK[SEL]
      while(RES_STATE and M_NXT_BLK[SEL] > NIL)
        reload_node_s(M_NXT_BLK[SEL],M_CUR_BLK[SEL])
        //TRACE("   stp deletion at: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
        del_block_s(M_CUR_BLK[SEL])
      wend
      SEL = PRG //to prg
      //TRACE("prg deletion at: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      erase_node_s()
      //TRACE("prg after: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      del_block_s(RES_BLK)
      remove_rp_s() //delete restore point
      //TRACE("!!!ERASE DONE!!!")
      //TRACE("blk cnt: [%d]",BLK_CNT)
      position[ps_prg] = position[ps_prg] -(opt < position[ps_prg])
      position[pr_prg] = position[pr_prg] -(opt < position[pr_prg])
      to_stack(if_((opt==position[ps_prg]),ev_rld_dat+PRG,ev_sav_pos+PRG)+0,0,0)
      dm = dm_prg
    end if
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else if(evt == (ev_erase +STP)) then //-- ERASE STP
    SEL = STP //to stps
    if(M_BLK_CNT[SEL] > (COM_BLK_CNT +1)) then
      opt = lim(position[pw_stp] +opt,0,M_BLK_CNT[SEL] -COM_BLK_CNT -1)
      //TRACE("!!!ERASE STP!!!")
      //TRACE("stp blk cnt: [%d]",M_BLK_CNT[SEL])
      advance_s(opt -position[pw_stp])
      create_rp_s(RP_DEL_BLK,NIL,NIL) //create restore point
      update_retain_s()
      //TRACE("stp deletion at: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      erase_node_s()
      //TRACE("stp after: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      del_block_s(RES_BLK)
      remove_rp_s() //delete restore point
      //TRACE("!!!ERASE DONE!!!")
      //TRACE("stp blk cnt: [%d]",M_BLK_CNT[SEL])
      position[ps_stp] = position[ps_stp] -(opt < position[ps_stp]) //меняем либо sstep или rstep
      //-- to_stack(if_((opt==position[ps_stp]),ev_rld_dat+STP,ev_sav_pos+STP)+0,0,0)
      to_stack(ev_sav_pos +STP,0,0)
      to_stack(if_((opt==position[ps_stp]),ev_rld_dat+STP,0)+0,0,0)
      dm = dm_stp
      cow = true
    end if
  //-------------------------------------------------------------
  else if(evt == (ev_swap +PRG)) then //-- SWAP PRG
    opt = lim(position[ps_prg] +opt,0,M_BLK_CNT[SEL] -1)
    if(opt == position[ps_prg]) then
      continue
    end if
    load_store_data_s('L',RP_DAT_OFST,BLK_PLD_SZ)
    advance_s(opt -position[ps_prg])
    load_store_data_s('L',RP_DAT_OFST+BLK_PLD_SZ,BLK_PLD_SZ)
    //create_rp_s(...)
    //update_retain_s()
    load_store_data_s('S',RP_DAT_OFST,BLK_PLD_SZ)
    advance_s(position[ps_prg] -opt)
    load_store_data_s('S',RP_DAT_OFST+BLK_PLD_SZ,BLK_PLD_SZ)
    //remove_rp_s() //delete restore point
    k = position[ps_prg]
    p = position[pr_prg]
    position[ps_prg] = opt
    position[pr_prg] = if_((p == k  ),opt,position[pr_prg])
    position[pr_prg] = if_((p == opt),k  ,position[pr_prg])
    to_stack(ev_sav_pos +PRG,0,0)
    dm = dm_prg
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else if(evt == (ev_swap +STP)) then //-- SWAP STP
    opt = lim(position[ps_stp] +opt,0,M_BLK_CNT[SEL] -COM_BLK_CNT -1)
    if(opt == position[ps_stp]) then
      continue
    end if
    load_store_data_s('L',RP_DAT_OFST,BLK_PLD_SZ)
    advance_s(opt -position[ps_stp])
    load_store_data_s('L',RP_DAT_OFST+BLK_PLD_SZ,BLK_PLD_SZ)
    //create_rp_s(...)
    //update_retain_s()
    load_store_data_s('S',RP_DAT_OFST,BLK_PLD_SZ)
    advance_s(position[ps_stp] -opt)
    load_store_data_s('S',RP_DAT_OFST+BLK_PLD_SZ,BLK_PLD_SZ)
    //remove_rp_s() //delete restore point
    position[ps_stp] = opt
    to_stack(ev_sav_pos +STP,0,0)
    dm = dm_stp
    cow = true
  //-------------------------------------------------------------
  else if(evt == (ev_sav_dat +PRG)) then //-- SAVE PRG DATA
    opt = lim(position[pw_prg] +opt,0,M_BLK_CNT[SEL] -1)
  	advance_s(opt -position[pw_prg])
    load_stp_from_prg_s()
    SEL = STP //to stp
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    advance_s(COM_BLK_OFST)
    GetData(BUFF[0],"Local HMI","Program_window_updated_com",COM_REQ_SZ)
    load_store_data_s('S',0,COM_REQ_SZ)
    if(opt == position[ps_prg]) then
      SetData(BUFF[0],"Local HMI","Program_sel_com",COM_REQ_SZ)
    end if 
    if(opt == position[pr_prg]) then
      SetData(BUFF[0],"Local HMI","Program_run_com",COM_REQ_SZ)
    end if  
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    
  else if(evt == (ev_sav_pos +PRG)) then //-- SAVE PRG POS
    p = ps_prg + run
    SetData(position[p],"Local HMI",RW,PRG_SEL_LOC,1)
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else if(evt == (ev_rld_dat +PRG)) then //-- RELOAD PRG [ps_prg]
    load_stp_from_prg_s()
    SEL = STP //to stp
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    load_store_data_s('L',0,COM_ADD_SZ)
    position[ps_stp] = BUFF[0] //-- загружаем позицию
    position[pw_stp] = BUFF[0] //--
    advance_s(COM_BLK_OFST)
    load_store_data_s('L',0,COM_REQ_SZ)
    SetData(BUFF[0],"Local HMI","Program_sel_com",COM_REQ_SZ)
    dm = dm_stp
  //-------------------------------------------------------------
  else if(evt == (ev_sav_dat +STP)) then //save stp data
    opt = lim(position[pw_stp] +opt,0,M_BLK_CNT[SEL] -COM_BLK_CNT -1)
    advance_s(opt -position[pw_stp])
    GetData(BUFF[0],"Local HMI","Program_window_updated_stp",BLK_PLD_SZ)
    load_store_data_s('S',0,BLK_PLD_SZ)
    to_stack(ev_rld_dat+STP,ev_get_pos+pr_stp,0) //-- override
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else if(evt == (ev_sav_pos +STP)) then //-- SAVE STP POS
    //-- проблема
    //-- надо подумать над восстановлением prev, cur, next
    short tcur, tprv
    tcur = M_CUR_BLK[SEL]
    tprv = M_PRV_BLK[SEL]

    SEL = STP //to stp
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    //think about RP
    load_store_data_s('L',0,COM_ADD_SZ) //-- todo - prepare COM
    BUFF[0] = position[ps_stp] //--0 это текущий шаг, дальше идёт таймер и циклы..
    load_store_data_s('S',0,COM_ADD_SZ)

    //-- надо подумать над восстановлением prev, cur, next
    reload_node_s(tcur,tprv)
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
  else if(evt == (ev_rld_dat +STP)) then //-- RELOAD STP
    if(run and position[ps_prg] == position[pr_prg]) then
      SEL = STP //to stp

      position[ps_stp] = position[pr_stp]
      sc_blk  [ps_stp] = sc_blk  [pr_stp]
      sp_blk  [ps_stp] = sp_blk  [pr_stp]
      
      //-- dm = dm_stp

      load_store_data_s('L',0,BLK_PLD_SZ)
      ctim = if_((opt > 0),ctim,0)
      stim = to_int(BUFF[0],BUFF[1])
    end if
  //-------------------------------------------------------------
  else if(evt == (ev_view +PRG)) then //-- VIEW PRG
    p = 0
    SEL = PRG
    while((M_CUR_BLK[SEL] > NIL)and(p < 8))
      load_stp_from_prg_s()
      SEL = STP //to stp
      reload_node_s(M_HEAD_BLK[SEL],NIL)
      advance_s(COM_BLK_OFST) //-- скип шага, таймера, циклов
      load_store_data_s('L',0,COM_REQ_SZ)
      SetData(BUFF[0],"Local HMI",LW,COM_REQ_SZ*p +prg_wnd_dat,COM_REQ_SZ)
      //TRACE("print prg!!!: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      SEL = PRG
      advance_s(DIR_RIGHT)
      p = p +1
    wend
    to_stack(ev_view+STP,0,0)
    header[ 0] = p
    header[ 2] = position[pw_prg]
    header[ 4] = position[ps_prg]
    header[ 6] = position[pr_prg]
    header[ 8] = M_BLK_CNT[PRG]
    header[10] = position[ps_prg] -position[pw_prg]
    header[12] = run
    LOWORD(ctim, header[13])
    HIWORD(ctim, header[14])
    header[15] = cc

    //-- в функцию магию с битами
    //-- ~(-1 <<(p))
    //-- ~(-1 <<(p +1))
    //-- ~(-1 <<(p)) & (5 << (position[ps_prg]-position[pw_prg])) >> 1
    //-- foo(p, position[ps_prg]-position[pw_prg], arrpos)
    
    GetData(k,"Local HMI","Program_Front_Sel_Typ",1)
    bits = ~(-1 <<(p +(k == 1)))
    bits = bits & if_((k == 4),(5 << (position[ps_prg]-position[pw_prg])) >> 1,-1)
    SetData(bits,"Local HMI","Program_Front_Prg_Typ",1)
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else if(evt == (ev_view +STP)) then
    p = 0
    SEL = STP
    while((M_CUR_BLK[SEL] > NIL)and(p < 5))
      load_store_data_s('L',0,BLK_PLD_SZ)
      SetData(BUFF[0],"Local HMI",LW,BLK_PLD_SZ*p +stp_wnd_dat,COM_REQ_SZ) //OUT
      //TRACE("   print stp!!!: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      advance_s(DIR_RIGHT)
      p = p +1
    wend
    if(run) then //-- в таблицу, проверка на ран в обработчик
      to_stack(ev_view+pr_stp,0,0)
    end if
    header[ 1] = p
    header[ 3] = position[pw_stp]
    header[ 5] = position[ps_stp]
    header[ 7] = position[pr_stp]
    header[ 9] = M_BLK_CNT[STP] -COM_BLK_CNT
    header[11] = position[ps_stp] -position[pw_stp]
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    load_store_data_s('L',0,COM_ADD_SZ)
    header[16] = BUFF[3]
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  else if(evt == (ev_view +pr_stp)) then
    SEL = STP
    load_store_data_s('L',0,BLK_PLD_SZ)
    SetData(BUFF[0],"Local HMI","Program_run_stp",BLK_PLD_SZ)
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    advance_s(COM_BLK_OFST)
    load_store_data_s('L',0,COM_REQ_SZ)
    SetData(BUFF[0],"Local HMI","Program_run_com",COM_REQ_SZ)
  //-------------------------------------------------------------
  else if(evt == ev_control) then
    if(run == (opt > 0)) then
      continue
    end if
    run = opt
    //TRACE("ev_control: [%d]",opt)
    //--to_stack(ev_tick,0,0)
    to_stack(ev_rld_dat+STP,0,(opt > run))
    to_stack(ev_sav_com +pr_prg,0,0) //--checkme
    //--to_stack(ev_sav_com +if_((run > 0),pr_prg,ps_prg),0,0) //--checkme
    load_stp_from_prg_s()
    SEL = STP
    if(run) then
      reload_node_s(M_HEAD_BLK[SEL],NIL)
      load_store_data_s('L',0,COM_ADD_SZ)
      cc   = BUFF[3]
      ctim = to_int(BUFF[1],BUFF[2])
      ctim = if_((opt > run),ctim,0)
      position[pr_prg] = position[ps_prg]
      sc_blk  [pr_prg] = NIL
      position[ps_stp] = if_((opt > run),position[ps_stp],0)
      sc_blk  [ps_stp] = NIL
      cow = true
    end if
  //-------------------------------------------------------------
  else if(evt == (ev_sav_com + ps_prg)) then
    //TRACE("update cc selected")
    load_stp_from_prg_s()
    SEL = STP
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    load_store_data_s('L',0,COM_ADD_SZ)
    BUFF[3] = opt
    load_store_data_s('S',0,COM_ADD_SZ)
    if(run and position[ps_prg] == position[pr_prg]) then
      cc = opt
    end if
  else if(evt == (ev_sav_com + pr_prg)) then
    //TRACE("update running COM")
    load_stp_from_prg_s()
    SEL = STP
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    load_store_data_s('L',0,COM_ADD_SZ)
    BUFF[0] = position[pr_stp] //-- проверь
    LOWORD(ctim, BUFF[1])
    HIWORD(ctim, BUFF[2])
    BUFF[3] = cc
    load_store_data_s('S',0,COM_ADD_SZ)
  //-------------------------------------------------------------
  else if(evt == ev_tick and run) then
    SEL = STP
    ctim = ctim + opt
    TRACE("PRG {%d} STP {%d}/{%d} cc [%d]",position[pr_prg],position[pr_stp],M_BLK_CNT[SEL] -COM_BLK_CNT -1, cc)
    TRACE("TICK!!! {%d}/{%d}",ctim,stim)
    if(ctim >= stim) then
       ctim = 0
       TRACE("TRY NEXT STEP")
       to_stack(ev_sav_com+pr_prg,0,0)
       to_stack(ev_rld_dat+STP,ev_get_pos+pr_stp,0) //-- override
       if(position[pr_stp] < M_BLK_CNT[SEL] -COM_BLK_CNT -1) then
          TRACE("NEXT")
          to_stack(ev_set_pos+pr_stp,0,1)
       else
          if(cc > 0) then
             TRACE("TO BEGIN")
             to_stack(ev_set_pos+pr_stp,0,0-position[pr_stp])
             cc = cc -1
          else
             TRACE("STOP")
             to_stack(ev_control,0,0)
             to_stack(ev_set_pos+pr_stp,0,0-position[pr_stp])
          end if
       end if
    end if
  end if
  //-------------------------------------------------------------
  if(position[ps_prg] == position[pr_prg]and run and cow) then
      cow = 0
      position[pr_stp] = position[ps_stp]
      sc_blk  [pr_stp] = sc_blk  [ps_stp]
      sp_blk  [pr_stp] = sp_blk  [ps_stp]
  end if
  //-------------------------------------------------------------
  if(dm) then
    for k = pw_stp to pr_prg
      if(dm & (1 << k)) then
        sc_blk[k] = NIL
        sp_blk[k] = NIL
      end if
    next
    dm = 0
  end if
wend
TRACE("OK = %d",RES_STATE)
SetData(header[0],"Local HMI","Program_header",20)
SetData(MAX_BLK_CNT,"Local HMI","Program_blk_info[0]",1)
SetData(BLK_CNT    ,"Local HMI","Program_blk_info[1]",1)
//-------------------------------------------------------------
p = 1 + RES_STATE
SetData(p,"Local HMI","Program_Front_Evt ",1)
SetData(p,"Local HMI","Program_Front_Evt",1)
//DELAY(50)
ASYNC_TRIG_MACRO(1)
//-------------------------------------------------------------
end macro_command