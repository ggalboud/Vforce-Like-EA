Timer
//+------------------------------------------------------------------+
//|                                                       Timer1.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   EventSetTimer(1); //each second we'll refer to OnTimer() 
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer(); // canceling of timer reference must be called at exit  
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   MqlDateTime str1;
   TimeGMT(str1); // new function to get GMT time
   Comment(str1.hour,":",
           str1.min,":",
           str1.sec," ",
           str1.day,".",
           str1.mon,".",
           str1.year," ",
           str1.day_of_year," ",
           str1.day_of_week
           );
  }
