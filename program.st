//-------------------------------------------------------------
//APPLICATION DEFINED
int HEADER = 0x66FFC0DE,VERSION = 0x1
//CONFIG
int DATA_TYPE =0x1,BLOCK_DATA = 6,DATA_SIZE = 262140
int OFFSET_CONF = 0
int OFFSET_DATA = 1000
//CALCULATED
int BLOCK_SIZE,BLOCK_COUNT
//-------------------------------------------------------------
int BO[3] = {0, 768, 792}, BITMAP[793]
unsigned short PL_HEAD,PD_HEAD,COUNT,NIL = 24576
unsigned short CUR_NODE,NEW_NODE,PREV_NODE,NEXT_NODE
int INT_TMP,FUNC_RESULT = 1
//-------------------------------------------------------------
sub init_values()
  FILL(BITMAP[0],-1,793)
  PL_HEAD = NIL
  PD_HEAD = NIL
  CUR_NODE = NIL
  PREV_NODE = NIL
  NEXT_NODE = NIL
  COUNT = 0
  FUNC_RESULT = 1
end sub
sub load_config()
  GetData(INT_TMP    ,"Local HMI",RW,OFFSET_CONF +0,1)
  SetData(HEADER     ,"Local HMI",RW,OFFSET_CONF +0,1)
  FUNC_RESULT = FUNC_RESULT and(HEADER      == INT_TMP)
  GetData(INT_TMP    ,"Local HMI",RW,OFFSET_CONF +2,1)
  SetData(VERSION    ,"Local HMI",RW,OFFSET_CONF +2,1)
  FUNC_RESULT = FUNC_RESULT and(VERSION     >= INT_TMP)
  GetData(INT_TMP    ,"Local HMI",RW,OFFSET_CONF +4,1)
  SetData(DATA_TYPE  ,"Local HMI",RW,OFFSET_CONF +4,1)
  FUNC_RESULT = FUNC_RESULT and(DATA_TYPE   == INT_TMP)
  GetData(INT_TMP    ,"Local HMI",RW,OFFSET_CONF +6,1)
  SetData(BLOCK_DATA ,"Local HMI",RW,OFFSET_CONF +6,1)
  FUNC_RESULT = FUNC_RESULT and(BLOCK_DATA  == INT_TMP)
  GetData(INT_TMP    ,"Local HMI",RW,OFFSET_CONF +8,1)
  SetData(DATA_SIZE  ,"Local HMI",RW,OFFSET_CONF +8,1)
  FUNC_RESULT = FUNC_RESULT and(DATA_SIZE   >= INT_TMP)
  GetData(INT_TMP    ,"Local HMI",RW,OFFSET_CONF+10,1)
  SetData(OFFSET_DATA,"Local HMI",RW,OFFSET_CONF+10,1)
  FUNC_RESULT = FUNC_RESULT and(OFFSET_DATA == INT_TMP)
  GetData(PL_HEAD   ,"Local HMI",RW,OFFSET_CONF+100,1)
  GetData(PD_HEAD   ,"Local HMI",RW,OFFSET_CONF+101,1)  
end sub
sub load_node(unsigned short cur, unsigned short prev) //fixme
  CUR_NODE = cur
  GetData(PREV_NODE,"Local HMI",RW,OFFSET_DATA+BLOCK_SIZE*cur+0,1)
  GetData(NEXT_NODE,"Local HMI",RW,OFFSET_DATA+BLOCK_SIZE*cur+1,1)
  FUNC_RESULT = FUNC_RESULT and(PREV_NODE == prev)
end sub
sub set_node(int node)
  int b,p,s,k
  FUNC_RESULT = FUNC_RESULT and(node >= 0)and(node < BLOCK_COUNT)
  if not(FUNC_RESULT) then
    return
  end if
  b = node % 32
  s = node / 32 + BO[0]
  FUNC_RESULT = FUNC_RESULT and(BITMAP[s] & (1 << b)) 
//TRACE("begin set_node")
  p = node
  for k = 0 to 2
//TRACE("loop = %d", k)  
    b = p % 32
    p = p / 32
    s = p + BO[k] 
//TRACE("mod = %d", b)
//TRACE("div = %d", p)
//TRACE("pos = %d", s)
    BITMAP[s] = BITMAP[s] & ~(1 << b)
    if(BITMAP[s]) then
      break
    end if
  next
  COUNT = COUNT +1
end sub
sub new_node()
  FUNC_RESULT = FUNC_RESULT and(COUNT < BLOCK_COUNT)
  if not(FUNC_RESULT) then
  	NEW_NODE = NIL
    return
  end if
//TRACE("begin new_node")  
  int mul,k,s,b=0,ans=0
  for k = 2 down 0
//TRACE("loop = %d", k)  
    POW(32,k +1,mul)
//TRACE("pow div = %d", mul) 
    s = ans/mul + BO[k]
//TRACE("pos = %d", s)     
//TRACE("num = %d", s - BO[k])
//TRACE("bm[pos] = 0x%x", BITMAP[s])
    b = 0
    while(not(BITMAP[s]&(1 << b)))
      b = b +1
    wend
//TRACE("bit n = %d", b)
    POW(32,k,mul)
//TRACE("pow mul = %d", mul)    
    ans = ans + b*mul
//TRACE("ans = %d", ans)    
  next
  NEW_NODE = ans
end sub

//-------------------------------------------------------------
//-------------------------------------------------------------
macro_command main()
//-------------------------------------------------------------
//if(INIT() == true) then
  BLOCK_SIZE = BLOCK_DATA +4
  BLOCK_COUNT = LIM(DATA_SIZE/BLOCK_SIZE,0,NIL)
  
  init_values()
  load_config()

  //testing cases
  //#########1######### testing bitmap loading with value = 3205
  if(true) then
    TRACE("Test case set_node")
    BITMAP[100] = 1 << 5 // 3205 /32 = 100 (+0)   , 3205 %32 = 5
    BITMAP[771] = 1 << 4 // 100  /32 = 3 (+768)   , 100  %32 = 4
    BITMAP[792] = 1 << 3 // 3    /32 = 0 (+768+24), 3    %32 = 3
    NEW_NODE = 3205
    set_node(3205) //try...
    if(BITMAP[100] or BITMAP[771] or BITMAP[792]) then
      TRACE("Failed, values 0x%x 0x%x 0x%x", BITMAP[100], BITMAP[771], BITMAP[792])
    else
      TRACE("OK")
    end if
    init_values()
  end if
  //#########2######### testing bitmap get value = 3205
  if(true) then
    TRACE("Test case new_node")
    FILL(BITMAP[0],0,793)
    BITMAP[100] = 1 << 5 // 3205 /32 = 100 (+0)   , 3205 %32 = 5
    BITMAP[771] = 1 << 4 // 100  /32 = 3 (+768)   , 100  %32 = 4
    BITMAP[792] = 1 << 3 // 3    /32 = 0 (+768+24), 3    %32 = 3
    new_node() //try...
    if(NEW_NODE <> 3205) then
      TRACE("Failed, incorrect value %d", NEW_NODE)
    else
      TRACE("OK")
    end if
    init_values()
  end if
  //#########3######### testing bitmap perfomance
  if(true) then
  	TRACE("Test case bitmap performance")
  	FUNC_RESULT = 1
  	int start,stop
  	float res
  	//1
  	GetData(start,"Local HMI",LW,9030,1)
  	//while(COUNT < BLOCK_COUNT) //try...
  	for INT_TMP = 0 to 999
  		new_node()
  		set_node(NEW_NODE)
  	next
  	//wend
  	GetData(stop,"Local HMI",LW,9030,1)
  	res = (stop - start)/10.0
  	TRACE("time =  %f s", res)
  	res = COUNT/res
  	TRACE("perf =  %f op/s", res)	
  	TRACE("last node %d", NEW_NODE)
  	TRACE("count %d", COUNT)
    if not(FUNC_RESULT) then
      TRACE("Failed")
    else
      TRACE("OK")
    end if  	
  	init_values()
  end if  
  //#########testing done#########
	
  return
  PREV_NODE = NIL
  NEXT_NODE = PL_HEAD
  while(FUNC_RESULT)
    set_node(NEXT_NODE)
    load_node(NEXT_NODE, PREV_NODE)
  wend
  
  if not(FUNC_RESULT) then
    init_values()
  end if
//end if
//-------------------------------------------------------------
end macro_command
