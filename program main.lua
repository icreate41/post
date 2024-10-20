//-------------------------------------------------------------
//нужна кс для ...
//загрузка последней программы как текущей
//load_node_s - проверка кол ва шагов
//замени type на проверку base[p] == p
//APPLICATION DEFINED
int HEADER = 0x66FFC0DE,VERSION = 0x1
//CONFIG
int DATA_TYPE =0x1,BLK_HDR_SZ = 3,STP_ADD_SZ = 2,STP_REQ_SZ = 5,MAX_DAT_SZ = 262140
int CFG_OFST = 0,DAT_OFST = 1000,COM_ADD_SZ = 10,COM_REQ_SZ = 16
int MAX_PRG_CNT = 500, MAX_STP_CNT = 500, MAX_BUF_SZ = 300,RP_DAT_OFST=32
int BLK_PLD_SZ,BLK_SZ,MAX_BLK_CNT,COM_BLK_OFST,COM_BLK_CNT,RES_VAR,PRG_SEL_LOC
//-------------------------------------------------------------
int BO[3] = {0, 768, 792}, BITMAP[793]
short BUFF[300],NIL = -1
short RP_SAV_DAT = 1,RP_NEW_STP = 2,RP_DEL_BLK = 4,RP_SWP_BLK = 8,RP_NEW_PRG = 16,RESTORE = 0
//todo
//подумай на счёт того, чтобы добавить owner и modified флаг
//возможно стоит вернуть слоты, но только меняя CUR_BLK,PRV_BLK,NXT_BLK (Owner ??)
//todo
int  M_HEAD_LOC[2]
short M_BLK_CNT[2],M_HEAD_BLK[2],M_CUR_BLK[2],M_PRV_BLK[2],M_NXT_BLK[2]
short SEL=0,PRG=0,STP=1,LOC_OFST_HEAD=0,LOC_OFST_CNT=1
short BLK_CNT,RES_BLK,DIR_LEFT = -1,DIR_RIGHT =1
//COMMON
int   COM_TIM
short COM_POS,COM_REP
bool  RES_STATE
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
  COM_TIM = 0
  COM_POS = 0
  COM_REP = 0
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
    //COM_TIM =(BUFF[0]&0xFFFF)|(BUFF[1]<<16)
    //COM_POS = BUFF[2]
    //COM_REP = BUFF[3]
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
    TRACE("Restore Point Was Found, ALLOW = %d", RESTORE)
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
    //DELAY(50) //todo: restore delay
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
  SetData(chk               ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_CUR_BLK[SEL],1)
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
    SetData(chk               ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_PRV_BLK[SEL],1)
  else
    M_HEAD_BLK[SEL] = M_NXT_BLK[SEL]
    SetData(M_HEAD_BLK[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_HEAD,1)
  end if
  if(M_NXT_BLK[SEL] > NIL) then
    SetData(M_PRV_BLK[SEL],"Local HMI",RW,DAT_OFST+0+BLK_SZ*M_NXT_BLK[SEL],1)
    GetData(nxt               ,"Local HMI",RW,DAT_OFST+1+BLK_SZ*M_NXT_BLK[SEL],1)
    chk = nxt ^ M_PRV_BLK[SEL]
    SetData(chk               ,"Local HMI",RW,DAT_OFST+2+BLK_SZ*M_NXT_BLK[SEL],1)
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
//-------------------------------------------------------------
//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
short position[6],base[6],type[6]
short ps_stp=0,pw_stp=1,pr_stp=2,ps_prg=3,pw_prg=4,pr_prg=5
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//testing stack
int st_cmd[10],st_opt[10],st_pos = 1, st_cnt = 1,pre_cmd_done = 0
int cmd_advance = 10, cmd_insert = 20, cmd_view = 1000
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
int p,k,cmd = 0,opt = 0
int tr_update,tr_st_before
short def_stp_src = 100,def_com_src = 200
bool  run
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if(INIT() == true) then
  FILL(position[0],0,6)
  base[ps_stp] = ps_prg
  type[ps_stp] = STP
  base[pw_stp] = ps_prg
  type[pw_stp] = STP
  base[pr_stp] = pr_prg
  type[pr_stp] = STP
  base[ps_prg] = ps_prg
  type[ps_prg] = PRG
  base[pw_prg] = pw_prg
  type[pw_prg] = PRG
  base[pr_prg] = pr_prg
  type[pr_prg] = PRG
  run = 0
  //
  init_values()
  load_config_s()
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
      RES_STATE = RES_STATE and(M_BLK_CNT[SEL] > COM_BLK_CNT)
      SEL = PRG //to prg
      RES_STATE = RES_STATE and(M_BLK_CNT[SEL] <= MAX_PRG_CNT)
    wend
    SetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
    RES_STATE = RES_STATE and(M_BLK_CNT[SEL] > 0)
    GetData(position[ps_prg],"Local HMI",RW,PRG_SEL_LOC,1)
  else
    TRACE("CONFIG: created")
  end if
  if(RES_STATE) then
    TRACE("loaded: blk [%d], prgs [%d]",BLK_CNT,M_BLK_CNT[SEL])
  //create structure on failure - - - - - - - - - - - - - - - - - -
  else  
    init_values()
    SEL = PRG
    while(RES_STATE and M_BLK_CNT[SEL] < 1)
      new_block_s()
      set_block_s(RES_BLK)
      insert_node_s(RES_BLK)
      load_stp_from_prg_s() //to stps
      SEL = STP
      M_HEAD_BLK[SEL] = NIL
      GetData(BUFF[0],"Local HMI",LW,def_stp_src,BLK_PLD_SZ) //check this line pos
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
      GetData(BUFF[0],"Local HMI",LW,def_com_src,COM_REQ_SZ)
      load_store_data_s('S',0,COM_REQ_SZ)
      SEL = PRG
    wend
    SetData(position[ps_prg],"Local HMI",RW,PRG_SEL_LOC,1)
    TRACE("created: [%d], prgs [%d]",BLK_CNT,M_BLK_CNT[SEL])
  end if
end if
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if(not RES_STATE) then
  TRACE("FAILURE")
  return
end if
GetData(cmd,"Local HMI",LW,0,1)
GetData(opt,"Local HMI",LW,2,1)
p = 0
SetData(p,"Local HMI",LW,0,1)
if(cmd) then
  st_cmd[st_cnt] = cmd
  st_opt[st_cnt] = opt
  st_cnt = st_cnt +1
end if
st_cmd[st_cnt] = cmd_view + PRG
st_cnt = st_cnt +1
st_cmd[st_cnt] = cmd_view + STP
st_cnt = st_cnt +1
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
tr_st_before = trig_change_w(tr_st_before,0)
while(st_pos < st_cnt)     //todo: check run state 
  tr_st_before = trig_change_w(tr_st_before,st_pos)
  cmd = st_cmd[st_pos]
  opt = st_opt[st_pos]
  p = var_range(cmd,10,5)
  if(p >= 0) then //advance_s
    TRACE(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
    TRACE("p: [%d], opt :[%d]",p,opt)
    SEL = PRG //to prg
    GetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    TRACE("head: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    TRACE("PRG BLK CNT: [%d]",M_BLK_CNT[SEL])
    k = base[p] //base
    tr_update = trig_change_w(tr_update,position[k])
    TRACE("want: [%d]",position[k] +opt*(type[p] == PRG))
    position[k] = LIM(position[k] +opt*(type[p] == PRG),0,M_BLK_CNT[SEL] -1)
    TRACE("GET: [%d]",position[k])
    tr_update = trig_change_w(tr_update,position[k])
    advance_s(position[k])
    TRACE("prg: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    if((p == ps_prg)and trig_edge_w(tr_update)) then
      SetData(position[ps_prg],"Local HMI",RW,PRG_SEL_LOC,1)
      position[ps_stp] = 0 //todo: load from this from com
      position[pw_stp] = 0
      TRACE("   update")
    end if
    if(type[p] == STP) then
      load_stp_from_prg_s() //to stps
      SEL = STP
      GetData(M_BLK_CNT[SEL],"Local HMI",RW,M_HEAD_LOC[SEL]+LOC_OFST_CNT,1)
      reload_node_s(M_HEAD_BLK[SEL],NIL)
      TRACE("stp head: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      TRACE("STP BLK CNT: [%d]",M_BLK_CNT[SEL])
      TRACE("want: [%d]",position[p]+opt)
      position[p] = LIM(position[p]+opt,0,M_BLK_CNT[SEL] -COM_BLK_CNT -1)
      TRACE("GET: [%d]",position[p])
      advance_s(COM_BLK_CNT+position[p])
      TRACE("stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    end if
  end if
  //-------------------------------------------------------------
  p = var_range(cmd,cmd_insert+PRG,1)
  if(p >= 0) then //insert prg
    if not(pre_cmd_done) then
      st_pos = st_pos + DIR_LEFT
      st_cmd[st_pos] = cmd_advance + pw_prg
      st_opt[st_pos] = 0
      continue
    end if
    SEL = PRG //to prg
    if not((M_BLK_CNT[SEL] < MAX_PRG_CNT)and((BLK_CNT +COM_BLK_CNT +1) < MAX_BLK_CNT)) then
      st_pos = st_pos + DIR_RIGHT
      continue
    end if
    TRACE("!!!INSERTION PRG!!!")
    opt = LIM(position[pw_prg] +opt,0,M_BLK_CNT[SEL]) //allow shift to the end()
    advance_s(opt -position[pw_prg])
    new_block_s()
    set_block_s(RES_BLK)
    create_rp_s(RP_NEW_PRG,RES_BLK,NIL) //create restore point
    update_retain_s()
    TRACE("   before prg: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    insert_node_s(RES_BLK)
    TRACE("   insertion prg: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    load_stp_from_prg_s() //to stps
    SEL = STP
    M_HEAD_BLK[SEL] = NIL
    GetData(BUFF[0],"Local HMI",LW,def_stp_src,BLK_PLD_SZ) //check this line pos
    while(RES_STATE and M_BLK_CNT[SEL] < (COM_BLK_CNT +1))
      new_block_s()
      set_block_s(RES_BLK)
      TRACE("      before    stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      insert_node_s(RES_BLK)
      TRACE("      insertion stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      load_store_data_s('S',0,BLK_PLD_SZ)
    wend
    reload_node_s(M_HEAD_BLK[SEL],NIL)
    FILL(BUFF[0],0,COM_ADD_SZ)
    load_store_data_s('S',0,COM_ADD_SZ)
    advance_s(COM_BLK_OFST)
    GetData(BUFF[0],"Local HMI",LW,def_com_src,COM_REQ_SZ)
    load_store_data_s('S',0,COM_REQ_SZ)
    SEL = PRG
    remove_rp_s() //delete restore point
    TRACE("!!!INSERTION DONE!!!")
  end if
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  p = var_range(cmd,cmd_insert+STP,1)
  if(p >= 0) then //insert stp
    if not(pre_cmd_done) then
      st_pos = st_pos + DIR_LEFT
      st_cmd[st_pos] = cmd_advance + pw_stp
      st_opt[st_pos] = 0
      continue
    end if
    SEL = STP //to stps
    if not((M_BLK_CNT[SEL] < (MAX_STP_CNT-COM_BLK_CNT))and(BLK_CNT < MAX_BLK_CNT)) then
      st_pos = st_pos + DIR_RIGHT
      continue
    end if
    TRACE("!!!INSERTION STP!!!")
    opt = LIM(position[pw_stp] +opt,0,M_BLK_CNT[SEL] -COM_BLK_CNT) //allow shift to the end()
    advance_s(opt -position[pw_stp])
    new_block_s()
    set_block_s(RES_BLK)
    GetData(BUFF[RP_DAT_OFST],"Local HMI",LW,def_stp_src,BLK_PLD_SZ)
    create_rp_s(RP_NEW_STP|RP_SAV_DAT,RES_BLK,BLK_PLD_SZ) //create restore point
    update_retain_s()
    TRACE("   before    stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    insert_node_s(RES_BLK)
    load_store_data_s('S',RP_DAT_OFST,BLK_PLD_SZ)
    TRACE("   insertion stp: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
    remove_rp_s() //delete restore point
    TRACE("!!!INSERTION DONE!!!")
  end if
  //-------------------------------------------------------------
  p = var_range(cmd,cmd_view+PRG,1)
  if(p >= 0) then //view prg
    if not(pre_cmd_done) then
      st_pos = st_pos + DIR_LEFT
      st_cmd[st_pos] = cmd_advance + pw_prg
      st_opt[st_pos] = 0
      continue
    end if
    p = 0
    TRACE(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
    SEL = PRG
    while((M_CUR_BLK[SEL] > NIL)and(p < 10))
      TRACE("print prg!!!: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      advance_s(DIR_RIGHT)
      p = p +1
    wend
  end if
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  p = var_range(cmd,cmd_view+STP,1)
  if(p >= 0) then //view stp
    if not(pre_cmd_done) then
      st_pos = st_pos + DIR_LEFT
      st_cmd[st_pos] = cmd_advance + pw_stp
      st_opt[st_pos] = 0
      continue
    end if
    p = 0
    TRACE(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
    SEL = STP
    while((M_CUR_BLK[SEL] > NIL)and(p < 5))
      TRACE("   print stp!!!: [%d] : [%d,%d]",M_CUR_BLK[SEL],M_PRV_BLK[SEL],M_NXT_BLK[SEL])
      advance_s(DIR_RIGHT)
      p = p +1
    wend
  end if
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  pre_cmd_done = trig_edge_w(tr_st_before) < 0
  st_pos = st_pos +1
wend
TRACE("OK = %d",RES_STATE)
//-------------------------------------------------------------
end macro_command