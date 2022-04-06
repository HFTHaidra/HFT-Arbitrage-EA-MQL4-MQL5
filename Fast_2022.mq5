
#property strict

#include <socket-library-mt4-mt5.mqh>


// --------------------------------------------------------------------
// EA user inputs
// --------------------------------------------------------------------
//input Channel_Sender 
sinput string ____________________SettingServer ="Setting Server ";
input string      ID             = "Darwinex Fast" ;
input ushort      Sender_Port    = 10; // Server Global Port
sinput string ____________________ServerCPP =" Servers To Sende ";
input ushort      MultipleServerStrat    = 1; //Multiple Server Strat From port Global + iMin
input ushort      MultipleServerEnd      = 9; // Multiple Server Strat From port Global + iMax

string            Hostname       = "localhost";    // Server hostname or IP address
int               dig            = 5;

string            connection      = " No Connecting....!";
// --------------------------------------------------------------------
// Global variables and constants
// --------------------------------------------------------------------

ClientSocket * glbClientSocket = NULL;
ClientSocket * glbClientSocket_1 = NULL;
ClientSocket * glbClientSocket_2 = NULL;
ClientSocket * glbClientSocket_3 = NULL;
ClientSocket * glbClientSocket_4 = NULL;
ClientSocket * glbClientSocket_5 = NULL;
ClientSocket * glbClientSocket_6 = NULL;
ClientSocket * glbClientSocket_7 = NULL;
ClientSocket * glbClientSocket_8 = NULL;
ClientSocket * glbClientSocket_9 = NULL;

// --------------------------------------------------------------------
// Initialisation (no action required)
// --------------------------------------------------------------------

void OnInit() {
                  dig = int (SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)  );
                  }

void OnDeinit(const int reason)
{     
      if (glbClientSocket) {  delete glbClientSocket;   glbClientSocket = NULL;   }
      if (glbClientSocket_1) {  delete glbClientSocket_1;   glbClientSocket_1 = NULL;   }
      if (glbClientSocket_2) {  delete glbClientSocket_2;   glbClientSocket_2 = NULL;   }
      if (glbClientSocket_3) {  delete glbClientSocket_3;   glbClientSocket_3 = NULL;   }
      if (glbClientSocket_4) {  delete glbClientSocket_4;   glbClientSocket_4 = NULL;   }
      if (glbClientSocket_5) {  delete glbClientSocket_5;   glbClientSocket_5 = NULL;   }
      if (glbClientSocket_6) {  delete glbClientSocket_6;   glbClientSocket_6 = NULL;   }
      if (glbClientSocket_7) {  delete glbClientSocket_7;   glbClientSocket_7 = NULL;   }
      if (glbClientSocket_8) {  delete glbClientSocket_8;   glbClientSocket_8 = NULL;   }
      if (glbClientSocket_9) {  delete glbClientSocket_9;   glbClientSocket_9 = NULL;   }
}

double ask,bid;
void OnTick()
{  
    string res = Symbol()+ "   Send To ID = "+IntegerToString(Sender_Port)+"         Eta :  "  + connection;
    ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
    bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
    //printf("Sending");
    sendOnTikit(Sender_Port);
    //for(int i = MultipleServerStrat ; i<=MultipleServerEnd;i++){sendOnTikit_V2(i);}
    
    //printf("End Sending");
    Comment(res);
}


//********************************************************************************************
// Client Sideeeeeeeeeeeeeeeee
void sendOnTikit( ushort ServerPort ){
       if (!glbClientSocket) {
      glbClientSocket = new ClientSocket(Hostname, ServerPort);
      if (glbClientSocket.IsSocketConnected()) {
            //Print("Client connection succeeded");
            connection = "Client connection succeeded";
      } else {  
            //Print("Client connection failed");
            connection = "Client connection failed";
       }
  }
   if (glbClientSocket.IsSocketConnected()) {
      // Send the current price as a CRLF-terminated message
      string strMsg = structuringmsg();
      glbClientSocket.Send(strMsg);   
   } else {
      // Either the connection above failed, or the socket has been closed since an earlier
      // connection. We handle this in the next block of code...
   }
   // If the socket is closed, destroy it, and attempt a new connection
   // on the next call to OnTick()
   if (!glbClientSocket.IsSocketConnected()) {
      // Destroy the server socket. A new connection
      // will be attempted on the next tick
      //Print("Client disconnected. Will retry.");
       connection = "Client disconnected. Will retry.";
      delete glbClientSocket;
      glbClientSocket = NULL;
   }
}

string structuringmsg(){
   string msg="#*1"+ID+"#*2"+Ask_(ask)+"#*3"+Ask_(bid)+"#*4" ;
         
   return msg;
}
string Ask_( double ask_ ){
   string aa =DoubleToString(ask_);  
     aa = StringSubstr(aa, 0 , StringFind(aa,".")+1+dig)    ;
   return aa;

}
string Profit_( double Profit_ ){
   string aa =DoubleToString(Profit_);
   aa = StringSubstr(aa, 0 , StringFind(aa,".")+1+2)    ;     
   return aa;
}
void c( string str ){Print(str);}
// multiple Connection
void sendOnTikit_V2( int V  ){
   if(V==1){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_1) {
            glbClientSocket_1 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_1.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_1.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_1.Send(strMsg); }  
      if (!glbClientSocket_1.IsSocketConnected()) { delete glbClientSocket_1; glbClientSocket_1 = NULL;  }
   }
   
  
  
   if(V==2){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_2) {
            glbClientSocket_2 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_2.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_2.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_2.Send(strMsg); }  
      if (!glbClientSocket_2.IsSocketConnected()) { delete glbClientSocket_2; glbClientSocket_2 = NULL;  }
   }
   
   if(V==3){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_3) {
            glbClientSocket_3 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_3.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_3.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_3.Send(strMsg); }  
      if (!glbClientSocket_3.IsSocketConnected()) { delete glbClientSocket_3; glbClientSocket_3 = NULL;  }
   }
   
   if(V==4){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_4) {
            glbClientSocket_4 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_4.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_4.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_4.Send(strMsg); }  
      if (!glbClientSocket_4.IsSocketConnected()) { delete glbClientSocket_4; glbClientSocket_4 = NULL;  }
   }
   
   if(V==5){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_5) {
            glbClientSocket_5 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_5.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_5.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_5.Send(strMsg); }  
      if (!glbClientSocket_5.IsSocketConnected()) { delete glbClientSocket_5; glbClientSocket_5 = NULL;  }
   }
   
   if(V==6){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_6) {
            glbClientSocket_6 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_6.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_6.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_6.Send(strMsg); }  
      if (!glbClientSocket_6.IsSocketConnected()) { delete glbClientSocket_6; glbClientSocket_6 = NULL;  }
   }
   
   if(V==7){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_7) {
            glbClientSocket_7 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_7.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_7.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_7.Send(strMsg); }  
      if (!glbClientSocket_7.IsSocketConnected()) { delete glbClientSocket_7; glbClientSocket_7 = NULL;  }
   }
   
    if(V==8){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_8) {
            glbClientSocket_8 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_8.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_8.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_8.Send(strMsg); }  
      if (!glbClientSocket_8.IsSocketConnected()) { delete glbClientSocket_8; glbClientSocket_8 = NULL;  }
   }
   
    if(V==9){
      ushort ServerPort = ushort(Sender_Port + V) ;
      if (!glbClientSocket_9) {
            glbClientSocket_9 = new ClientSocket(Hostname, ServerPort);
            if (glbClientSocket_9.IsSocketConnected()) {Print("Client connection succeeded");}   }
      if (glbClientSocket_9.IsSocketConnected()) {
            string strMsg = structuringmsg();
            glbClientSocket_9.Send(strMsg); }  
      if (!glbClientSocket_9.IsSocketConnected()) { delete glbClientSocket_9; glbClientSocket_9 = NULL;  }
   }
   
   
       
}