 
#property strict

 

#define SOCKET_LIBRARY_USE_EVENTS
#include <socket-library-mt4-mt5.mqh>

sinput string ____________________SettingServer ="Setting Server ";
input string   ID             = " Slow Breker Tesla";             
input ushort   Resiver_Port   = 45;  // Server port
sinput string ____________________SettingCalculation ="Setting Calculation ";
input int      Digits_Symbol  = 3   ;     
input int      GapAllow       = 10   ;//    Gap Allow For Trading Profit + Spread 
input int      GapMultipe     = -1;    //GapMultipe 1 OR -1
input int      Count1         = 500;  // Count For Gaps>...Pips
input int      Count2         = 1000;  // Count For Gaps>...Pips
input int      Count3         = 1500;  // Count For Gaps>...Pips
input int      Count4         = 2000;  // Count For Gaps>...Pips
input int      Count5         = 2500;  // Count For Gaps>...Pips
sinput string ____________________SettingTradeing ="Setting Trading ";
input int      OrderTypeRun   = 0 ; // Slippage / Fill or Kill = 0/1
input int      Slippage       = 100; 
input int      TP             = 100;
input int      SL             = 100;
input double   Lots           = 1.0;
input int      Sleep_         = 60000; // Sleep For Exit All

ushort   ServerPort = 23456;  // Server port
ushort magic_number = 0;

 
#define TIMER_FREQUENCY_MS    1

// Server socket
ServerSocket * glbServerSocket = NULL;

// Array of current clients
ClientSocket * glbClients[];

// Watch for need to create timer;
bool glbCreatedTimer = false;


// --------------------------------------------------------------------
// Initialisation - set up server socket
// --------------------------------------------------------------------
int dig =5;
int Array_Sprids[] ;
int MaxArraySprids = 10 ;
int iMaxArraySprids = 0 ;

int Array_Gaps[] ;
int MaxArrayGaps = 10 ;
int iMaxArrayGaps = 0 ;

string     GapsOn     = "OF";
string     TradeOn    = "OF";
int     Gap,MeanGap   = 0 ; 
string SellBuy        = "SellBuy";
int    iStart         = 50 ;

int count1,count2,count3,count4,count5=0;
void OnInit()
{  iStart = 50;
   ArrayResize(Array_Sprids,MaxArraySprids);
      ArrayFill(Array_Sprids,0,MaxArraySprids,-1 );
   ArrayResize(Array_Gaps,MaxArrayGaps);
      ArrayFill(Array_Gaps,0,MaxArrayGaps,-1 );
   
   ServerPort   = Resiver_Port;
   magic_number = Resiver_Port ;
   dig = int (SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)  );
   // If the EA is being reloaded, e.g. because of change of timeframe,
   // then we may already have done all the setup. See the 
   // termination code in OnDeinit.
   if (glbServerSocket) {
      Print("Reloading EA with existing server socket");
   } else {
      // Create the server socket
      glbServerSocket = new ServerSocket(ServerPort, false);
      if (glbServerSocket.Created()) {
         Print("Server socket created");
   
         // Note: this can fail if MT4/5 starts up
         // with the EA already attached to a chart. Therefore,
         // we repeat in OnTick()
         glbCreatedTimer = EventSetMillisecondTimer(TIMER_FREQUENCY_MS);
      } else {
         Print("Server socket FAILED - is the port already in use?");
      }
   }
}


// --------------------------------------------------------------------
// Termination - free server socket and any clients
// --------------------------------------------------------------------

void OnDeinit(const int reason)
{  
   iStart = 50;
   switch (reason) {
      case REASON_CHARTCHANGE:
         // Keep the server socket and all its clients if 
         // the EA is going to be reloaded because of a 
         // change to chart symbol or timeframe 
         break;
         
      default:
         // For any other unload of the EA, delete the 
         // server socket and all the clients 
         glbCreatedTimer = false;
         
         // Delete all clients currently connected
         for (int i = 0; i < ArraySize(glbClients); i++) {
            delete glbClients[i];
         }
         ArrayResize(glbClients, 0);
      
         // Free the server socket. *VERY* important, or else
         // the port number remains in use and un-reusable until
         // MT4/5 is shut down
         delete glbServerSocket;
         glbServerSocket = NULL;
         Print("Server socket terminated");
         break;
   }
}


// --------------------------------------------------------------------
// Timer - accept new connections, and handle incoming data from clients.
// Secondary to the event-driven handling via OnChartEvent(). Most
// socket events should be picked up faster through OnChartEvent()
// rather than being first detected in OnTimer()
// --------------------------------------------------------------------

void OnTimer()
{
   HandleOrders();
   // Accept any new pending connections
   AcceptNewConnections();
   
   // Process any incoming data on each client socket,
   // bearing in mind that HandleSocketIncomingData()
   // can delete sockets and reduce the size of the array
   // if a socket has been closed

   for (int i = ArraySize(glbClients) - 1; i >= 0; i--) {
      HandleSocketIncomingData(i);
   }
}


// --------------------------------------------------------------------
// Accepts new connections on the server socket, creating new
// entries in the glbClients[] array
// --------------------------------------------------------------------

void AcceptNewConnections()
{
   // Keep accepting any pending connections until Accept() returns NULL
   ClientSocket * pNewClient = NULL;
   do {
      pNewClient = glbServerSocket.Accept();
      if (pNewClient != NULL) {
         int sz = ArraySize(glbClients);
         ArrayResize(glbClients, sz + 1);
         glbClients[sz] = pNewClient;
         Print("New client connection");
         
         pNewClient.Send("Ru is Connecting wthi ID : "+ IntegerToString(ServerPort) );
      }
      
   } while (pNewClient != NULL);
}


// --------------------------------------------------------------------
// Handles any new incoming data on a client socket, identified
// by its index within the glbClients[] array. This function
// deletes the ClientSocket object, and restructures the array,
// if the socket has been closed by the client
// --------------------------------------------------------------------

void HandleSocketIncomingData(int idxClient)
{
   ClientSocket * pClient = glbClients[idxClient];

   // Keep reading CRLF-terminated lines of input from the client
   // until we run out of new data
   bool bForceClose = false; // Client has sent a "close" message
   string strCommand;
   do {
      strCommand = pClient.Receive();
      if(StringLen(strCommand)>6  ){
         runOrder(strCommand , pClient );
      }
      
      
       
   } while (strCommand != "");

   // If the socket has been closed, or the client has sent a close message,
   // release the socket and shuffle the glbClients[] array
   if (!pClient.IsSocketConnected() || bForceClose) {
      Print("Client has disconnected");

      // Client is dead. Destroy the object
      delete pClient;
      
      // And remove from the array
      int ctClients = ArraySize(glbClients);
      for (int i = idxClient + 1; i < ctClients; i++) {
         glbClients[i - 1] = glbClients[i];
      }
      ctClients--;
      ArrayResize(glbClients, ctClients);
   }
}


// --------------------------------------------------------------------
// Use OnTick() to watch for failure to create the timer in OnInit()
// --------------------------------------------------------------------
double ask,bid,New_Ask,New_Bid;
double oNew_Ask = 0;
int spread,New_Spread;
void OnTick()
{  
   ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   spread = toPoints( ask-bid);
   if (!glbCreatedTimer) glbCreatedTimer = EventSetMillisecondTimer(TIMER_FREQUENCY_MS);
}

// --------------------------------------------------------------------
// Event-driven functionality, turned on by #defining SOCKET_LIBRARY_USE_EVENTS
// before including the socket library. This generates dummy key-down
// messages when socket activity occurs, with lparam being the 
// .GetSocketHandle()
// --------------------------------------------------------------------

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if (id == CHARTEVENT_KEYDOWN) {
      // If the lparam matches a .GetSocketHandle(), then it's a dummy
      // key press indicating that there's socket activity. Otherwise,
      // it's a real key press
         
      if (lparam == glbServerSocket.GetSocketHandle()) {
         // Activity on server socket. Accept new connections
         Print("New server socket event - incoming connection");
         AcceptNewConnections();

      } else {
         // Compare lparam to each client socket handle
         for (int i = 0; i < ArraySize(glbClients); i++) {
            if (lparam == glbClients[i].GetSocketHandle()) {
               HandleSocketIncomingData(i);
               return; // Early exit
            }
         }
         
         // If we get here, then the key press does not seem
         // to match any socket, and appears to be a real
         // key press event...
      }
   }
}


int       OrderIsOpend    = 0;
string    OrderTypeOpend  = "SELL";
int       order_ticket    = 0;
string    Trade_ID        = "N0Gap0";
double    Trade_Price     = 0 ;
double    Trade_SL        = 0 ;
double    Trade_TP        = 0 ;
void HandleOrders(){
     if(OrderIsOpend==1){
         int magic_number_Delete = magic_number*1000+order_ticket ;
         if(OrderTypeOpend=="SELL"){
            if(ask>Trade_SL){
               //DeleteAllOrdersByMagic( magic_number_Delete);
               //Print("Close Loss SELL");
               OrderIsOpend = 0 ;
            }
            if(ask<Trade_TP){
               //DeleteAllOrdersByMagic( magic_number_Delete);
               Print("Close Win SELL");
               OrderIsOpend = 0 ;
            }
         }
         
          if(OrderTypeOpend=="BUY"){
            if(bid>Trade_TP){
               //DeleteAllOrdersByMagic( magic_number_Delete);
               Print("Close Win Buy");
               OrderIsOpend = 0 ;
            }
            if(bid<Trade_SL){
               //DeleteAllOrdersByMagic( magic_number_Delete);
               Print("Close Loss Buy");
               OrderIsOpend = 0 ;
            }
         }
         
         
     }
     
}











//*********************************************************************************************************************
//*********************************************************************************************************************
//*********************************************************************************************************************
//*********************************************************************************************************************
ulong time = GetTickCount();

void runOrder(string msg__ , ClientSocket * pClient){   

        New_Ask                 =  getAsk( msg__ );
        New_Bid                 =  getBid( msg__ );
        New_Spread              = toPoints( New_Ask-New_Bid )   ;
        int       NewGap        = toPoints(New_Ask - ask)*GapMultipe ;
        
        
        RunSpreads(spread);
        
        string stats = RunStats(NewGap);
        RunSell(getID(msg__));
        RunBuy(getID(msg__));     
        
        string msg = separ+"\n";
               msg += "------------------------------------------        Port : "+IntegerToString(ServerPort);
               msg += "                   iStart : "+IntegerToString(iStart);
               msg+="               -----------------------------------------------------------------------------"+"\n"+separ+"\n";
               msg+= Heder+"\n\n" ;
               
               setPo(1,ID,20);setPo(1,Ask_(ask),50);setPo(1,Ask_(bid),80);setPo(1,IntegerToString(spread),110);
               setPo(2,getID(msg__),20);setPo(2,Ask_(New_Ask),50);setPo(2,Ask_(New_Bid),80);setPo(2,IntegerToString(New_Spread),110);
                          
               msg+= Line1+"\n\n";
               msg+= Line2+"\n\n";
               msg+= separ+"\n\n"; 
               msg+= getArraySpreds()+"\n";
               msg+= getArrayGaps()+"\n";
               msg+= stats;
               msg+= "\n"+separ+"\n";
               msg+= getCounts(Gap);          
               
        oNew_Ask =  New_Ask ;   
        RunGaps(NewGap);       
        Comment(msg);
        
}

void RunBuy(string id_){
   if(iStart<=0&&Gap>=GapAllow&&TradeOn=="ON"&&GapsOn=="ON"&&SellBuy=="Buy"&&OrderIsOpend==0){
         Print("Buy_Ask:"+Ask_(bid));
         SendOrderMT5("BUY");      
         iStart  = 1000;
   }
   if(iStart>=0){iStart  = iStart - 1 ;}
}

void RunSell(string id_){
   if(iStart<=0&&Gap>=GapAllow&&TradeOn=="ON"&&GapsOn=="ON"&&SellBuy=="Sell"&&OrderIsOpend==0){
       
       SendOrderMT5("SELL");
       iStart   = 1000;
       
   }
   if(iStart>=0){iStart  = iStart - 1 ;}
}
void SendOrderMT5(string Type_){
         order_ticket = order_ticket + 1;
         Trade_ID     = "P"+IntegerToString(ServerPort)+"N"+IntegerToString(order_ticket) + "G="+IntegerToString(Gap) ; 
         OrderIsOpend    = 1 ;
         
         int magic__=magic_number*1000+order_ticket;                  // ORDER_MAGIC
         double price__ = 0;   
      //--- form the order type
         if(Type_=="BUY"){
              price__ = bid;
              Trade_SL = bid - fromPoints(SL);
              Trade_TP = bid + fromPoints(TP);
              OrderTypeOpend = "BUY";
              int ticket = OrderSend(Symbol(),OP_BUY,Lots ,bid,Slippage,Trade_SL,Trade_TP,Trade_ID,magic__);
         }else{
             price__ = ask;
             Trade_SL = ask + fromPoints(SL);
             Trade_TP = ask - fromPoints(TP);
             OrderTypeOpend = "SELL";
             int ticket = OrderSend(Symbol(),OP_SELL,Lots ,ask,Slippage,Trade_SL,Trade_TP,Trade_ID,magic__);
         }
      
      
         
         
         Print(__FUNCTION__,":",Trade_ID,"_",OrderTypeOpend,":",price__,"TP:",Trade_TP,"SL:",Trade_SL);
         
        
}

string getCounts(int NewGap){
      if(TradeOn=="ON"&&GapsOn=="ON"){
      if(NewGap>=Count1){count1++;}
      if(NewGap>=Count2){count2++;}
      if(NewGap>=Count3){count3++;}
      if(NewGap>=Count4){count4++;}
      if(NewGap>=Count5){count5++;}
      }
      
      string res = " Gap > "+s(Count1)+" = "+s(count1)+"        ";
             res+= " Gap > "+s(Count2)+" = "+s(count2)+"        ";
             res+= " Gap > "+s(Count3)+" = "+s(count3)+"        ";
             res+= " Gap > "+s(Count4)+" = "+s(count4)+"        ";
             res+= " Gap > "+s(Count5)+" = "+s(count5)+"        ";
      return res;
   }
string s(int double_){return IntegerToString(double_); }
string RunStats(int NewGap ){
     MeanGap =  getMeanGaps(); 
     Gap = MathAbs(MeanGap - NewGap);
     if(New_Ask>oNew_Ask){SellBuy="Buy";}else{SellBuy="Sell";}
     
     string stats = "         Stats --  Gap : "+GapsOn+" Trade :  "+TradeOn+" MeanGaps = "+IntegerToString(MeanGap);  
            stats+= "    ************* Gap For Trading = ("+IntegerToString(Gap)+"/"+IntegerToString(GapAllow)+") Signel : "+SellBuy;
   return stats ;
}

void RunGaps(int newGap){
   if(New_Spread>0&&spread>0){
       if(iMaxArrayGaps>=MaxArrayGaps){
            iMaxArrayGaps = 0 ;
            GapsOn = "ON";
         }
       Array_Gaps[iMaxArrayGaps] = newGap ;
       iMaxArrayGaps++;
   }
   
}

int getMeanGaps(){
   double m = 0 ;
   for(int i = 0;i<MaxArrayGaps;i++){
      m+=Array_Gaps[i] ;
   }
   return int(m/MaxArrayGaps) ;
}

void RunSpreads(int newSpread){
   if(iMaxArraySprids>=MaxArraySprids){
      iMaxArraySprids = 0 ;
      TradeOn = "ON";
   }
   Array_Sprids[iMaxArraySprids] = newSpread ;
   iMaxArraySprids++;
   
}
string getArraySpreds(){
   string res = " Spreads Of Slow Broker : [";
   for(int i = 0;i<MaxArraySprids;i++){
      res+=""+IntegerToString(Array_Sprids[i])+",";
   }
   res +="] (Max="+IntegerToString(GetMaxSpread() )+")";
  return res;
}

string getArrayGaps(){
   string res = " Gaps (Fast-Slow) : [";
   for(int i = 0;i<MaxArrayGaps;i++){
      res+=""+IntegerToString(Array_Gaps[i])+",";
   }
   res +="]";
  return res;
}

int GetMaxSpread(){
   
   int max = 0 ;
   for(int i=0;i<MaxArrayGaps;i++){
      if(Array_Sprids[i]>max) {max =Array_Sprids[i]; }
   }
   return max ;
}

string DToS(double a){ return DoubleToString(a); }
string getID(string msg){
      return   StringSubstr(msg, 3 , StringFind(msg,"#*2")-3 ) ;
}
int toPoints(double spred){
    double point = spred;
    if(Digits_Symbol==0){point = point*1;}
    if(Digits_Symbol==1){point = point*10;}
    if(Digits_Symbol==2){point = point*100;}
    if(Digits_Symbol==3){point = point*1000;}
    if(Digits_Symbol==4){point = point*10000;}
    if(Digits_Symbol==5){point = point*100000;}
    return int(point) ;
}

double fromPoints(int p){
    double point = p;
    if(Digits_Symbol==0){point = point/1;}
    if(Digits_Symbol==1){point = point/10;}
    if(Digits_Symbol==2){point = point/100;}
    if(Digits_Symbol==3){point = point/1000;}
    if(Digits_Symbol==4){point = point/10000;}
    if(Digits_Symbol==5){point = point/100000;}
    return point ;
}
double getAsk(string msg){
      int i1 = StringFind(msg,"#*2")  +3  ;
      int leng = StringFind(msg,"#*3") - i1 +1   ;
      double ask_ =  Price_Double( StringSubstr(msg, i1 , leng ) )  ;
      return  ask_;
}
double getBid(string msg){
      int i1 = StringFind(msg,"#*3")  +3  ;
      int leng = StringFind(msg,"#*4") - i1 +1   ;
      double ask_ =  Price_Double( StringSubstr(msg, i1 , leng ) )  ;
      return  ask_;
}

void setPo(int ID_Of_Line,string var,int position){

      if(ID_Of_Line==1){
         //aa = StringSubstr(aa, 0 , StringFind(aa,".")+1+Digits_Symbol )    ;
         Line1 = StringSubstr(Line1,0,position) + var + Line ;
         //Line1 = StringSetChar(Line1,i,StringGetChar(var,j) );
         //Line1 = StringSetCharacter(Line1,i,StringGetCharacter(var,j));
           
        
      }
      if(ID_Of_Line==2){
         Line2 = StringSubstr(Line2,0,position) + var + Line ;
        
      }
}













double Price_Double( string ask_ ){
   string aa  = ask_ ;
   
   aa = StringSubstr(aa, 0 , StringFind(aa,".")+1+Digits_Symbol )    ;
   
   return StoD( aa ) ;

}


double StoD(string a){return StringToDouble(a); }

string Ask_( double ask_ ){
   string aa =DoubleToString(ask_);
   
   aa = StringSubstr(aa, 0 , StringFind(aa,".")+1+Digits_Symbol )    ;
   
   return aa;

}




void c( string str ){
   
   Print(str);

}

string Heder = "                    Server/Breker                  ASK                            Bid                            Spread                                                                                                                        ";
string Line  = "                                                                           ";
string Line1 = "                                                                           ";
string Line2 = "                                                                           ";

string separ  = "--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------";



















/*




void CloseOrder( string comm , ClientSocket * pClient ){
      
      
       for(int order_counter = 0; order_counter < OrdersTotal(); order_counter ++)
      {  
         if(OrderSelect(order_counter, SELECT_BY_POS, MODE_TRADES) == true && OrderSymbol() == Symbol())
         {
             if( OrderComment() == comm ){ 
                  
                  //int m = OrderClose( OrderTicket() ,OrderLots(),0 ,4,Red);
                  double Price = Ask;
                  if(OrderType()==0) Price=Bid;
                  
                  
                  //*******************************************
                  time = GetTickCount();
                  ulong timeout = time + 1 ;  
                  bool OrderOpen = false ;
                  c("------------------------------Close for Slippage : "+Ask_(Price));
                  for(;!OrderOpen;){
                        double Price2 = Ask;  if(OrderType()==0) Price2=Bid;
                        int ticket = OrderClose(OrderTicket(),OrderLots(),Price2,10000,Red);
                  
                        if(ticket==true){
                                       OrderOpen = true;
                                       string msgRes  = "Close OK " + Symbol()+" at:"+Ask_(Price2);
                                       msgRes += "Slippage="+Ask_(Price - Price2)+"Execution="+IntegerToString(GetTickCount()-time) ;
                                       pClient.Send(msgRes);  
                                       c( msgRes  );  
                                       c("------------------------------Close for Slippage : "+Ask_(Price2));   
                            }else{
                            
                                           if( GetTickCount()>timeout ){
                                                   c("Time Out For Closeing Order ");
                                                   pClient.Send("TimeOut="+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) );
                                                   c("-------------------------"+IntegerToString(GetTickCount()-time));
                                                   OrderOpen = true;
                                                }  
                            
                            
                            
                            }
                  
                  
                  }//Fin For Loop
                  
                  
                  
                  
             } 
         }
         
      }   
      
}





int isTradeExixt( string comm){
      int res = 0;// Non 

       for(int order_counter = 0; order_counter < OrdersTotal(); order_counter ++)
      {  
         if(OrderSelect(order_counter, SELECT_BY_POS, MODE_TRADES) == true && OrderSymbol() == Symbol())
         {
             if( OrderComment() == comm ){
                  res = OrderTicket() ;// Yes 
             } 
         }
         
      }   
      return res ;
}




*/


void CloseOrders()
{
  
}