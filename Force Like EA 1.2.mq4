//+------------------------------------------------------------------+
//|                                     Vforce 1.2.1.mq4 |
//|                                      |
//|                                http: |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2017, "
#property link "http://www.tradingsystemforex.com"

//|----------------------------------------------you can modify this expert
//|----------------------------------------------you can change the name
//|----------------------------------------------you can add "modified by you"
//|----------------------------------------------but you are not allowed to erase the copyrights

#define EAName "Vforce 1.2.1"

extern string S1="---------------- Entry Settings";


// Fonctionnalité auto-tune 2017 EURUSD
extern bool AutoTune = false;

extern int  StochKPeriod  = 5;
extern int  StochDPeriod  = 3;
extern int  StochSlowing  = 3;
extern bool OnlyAtStochSignal=false;
extern int  RSIPeriod     = 14;
extern double  RSILevel   = 50.0;
extern bool OnlyAtRSISignal=false;
extern int  ADXPeriod     = 14;
extern bool OnlyAtADXSignal=false;
extern int  BearsPeriod   = 13;
extern bool OnlyAtBearsSignal=false;
extern int  BullsPeriod   = 13;
extern bool OnlyAtBullsSignal=false;
extern int  MACDFast      = 12;
extern int  MACDSlow      = 26;
extern int  MACDSMA       = 9;
extern bool OnlyAtMacdSignal=false;
extern int  RPeriod       = 10;
extern bool OnlyAtROCSignal=false;
extern int  BBPeriod      = 20;
extern bool OnlyAtBBSignal=false;
extern double Step        = 0.02;
extern double Maximum     = 0.2;
extern bool OnlyAtPSarSignal=false;



extern string S2="---------------- Money Management";

extern double Lots=0.1;//|-----------------------lots size
extern double LotsPercent1=80;
extern double LotsPercent2=20;
extern bool RiskMM=false;//|---------------------risk management
extern double RiskPercent=1;//|------------------risk percentage
extern bool Martingale=false;//|-----------------martingale
extern double Multiplier=2.0;//|-----------------multiplier martingale
extern double MinLots=0.01;//|-------------------minlots
extern double MaxLots=100;//|--------------------maxlots

/*
extern bool BasketProfitLoss=false;//|-----------use basket loss/profit
extern int BasketProfit=100000;//|---------------if equity reaches this level, close trades
extern int BasketLoss=9999;//|-------------------if equity reaches this negative level, close trades
*/

extern string S3="---------------- Order Management";

extern int MarginPips=10;
extern int StopLoss=0;//|------------------------stop loss
extern int TakeProfit=20;//|---------------------take profit
extern bool HideSL=false;//|---------------------hide stop loss
extern bool HideTP=false;//|---------------------hide take profit
extern int TrailingStop=50;//|-------------------trailing stop
extern int TrailingStep=0;//|--------------------trailing step
extern int BreakEven=0;//|-----------------------break even
extern int MaxOrders=100;//|---------------------maximum orders allowed
extern int Slippage=3;//|------------------------slippage
extern int Magic1=20091;//|----------------------magic number
extern int Magic2=20092;//|----------------------magic number

/*
extern string S4="---------------- MA Filter";

extern bool MAFilter=false;//|-------------------moving average filter
extern int MAPeriod=20;//|-----------------------ma filter period
extern int MAMethod=0;//|------------------------ma filter method
extern int MAPrice=0;//|-------------------------ma filter price
*/

/*
extern string S5="---------------- Time Filter";

extern bool TradeOnSunday=true;//|---------------time filter on sunday
extern bool MondayToThursdayTimeFilter=false;//|-time filter the week
extern int MondayToThursdayStartHour=0;//|-------start hour time filter the week
extern int MondayToThursdayEndHour=24;//|--------end hour time filter the week
extern bool FridayTimeFilter=false;//|-----------time filter on friday
extern int FridayStartHour=0;//|-----------------start hour time filter on friday
extern int FridayEndHour=21;//|------------------end hour time filter on friday
*/

extern string S6="---------------- Extras";

extern bool ReverseSystem=false;//|--------------buy instead of sell, sell instead of buy
extern int Expiration=60;//|--------------------expiration in minute for the reverse pending order

/*
extern bool Hedge=false;//|----------------------enter an opposite trade
extern int HedgeSL=0;//|-------------------------stop loss
extern int HedgeTP=0;//|-------------------------take profit
extern bool ReverseAtStop=false;//|--------------buy instead of sell, sell instead of buy
extern bool Comments=true;//|--------------------allow comments on chart
*/

datetime PreviousBarTime1;
datetime PreviousBarTime2;

double maxEquity,minEquity,Balance=0.0;
double LotsFactor=1;
double InitialLotsFactor=1;

/*
Application des équations d'auto-optimisation sur données 2017


*/

//|---------initialization

int init()
{

    // Initialisation du timer toutes les 20h
    
    if (AutoTune == True){
    EventSetTimer(20*3600); // Se référer a  OnTimer() 
    }
    
    
   //|---------martingale initialization
  
   int tempfactor,total=OrdersTotal();
   if(tempfactor==0 && total>0)
   {
      for(int cnt=0;cnt<total;cnt++)
      {
         if(OrderSelect(cnt,SELECT_BY_POS))
         {
            if(OrderSymbol()==Symbol() && ((OrderMagicNumber()==Magic1)||(OrderMagicNumber()==Magic2)))
            {
               tempfactor=NormalizeDouble(OrderLots()/Lots,1+(MarketInfo(Symbol(),MODE_MINLOT)==0.01));
               break;
            }
         }
      }
   }
   int histotal=OrdersHistoryTotal();

   if(tempfactor==0&&histotal>0)
   {
      for(cnt=0;cnt<histotal;cnt++)
      {
         if(OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY))
         {
            if(OrderSymbol()==Symbol() && ((OrderMagicNumber()==Magic1)||(OrderMagicNumber()==Magic2)))
            {
               tempfactor=NormalizeDouble(OrderLots()/Lots,1+(MarketInfo(Symbol(),MODE_MINLOT)==0.01));
               break;
            }
         }
      }
   }
   
   if (tempfactor>0)
   LotsFactor=tempfactor;

   /*if(Comments)Comment("\nLoading...");*/
   return(0);
}

//|---------deinitialization

/*int deinit()
{
  return(0);
}*/

int start()
{

//|---------trailing stop

   if(TrailingStop>0)MoveTrailingStop();

//|---------break even

   if(BreakEven>0)MoveBreakEven();
   
/*
//|---------basket profit loss

   if(BasketProfitLoss)
   {
      double CurrentProfit=0,CurrentBasket=0;
      CurrentBasket=AccountEquity()-AccountBalance();
      if(CurrentBasket>maxEquity)maxEquity=CurrentBasket;
      if(CurrentBasket<minEquity)minEquity=CurrentBasket;
      if(CurrentBasket>=BasketProfit||CurrentBasket<=(BasketLoss*(-1)))
      {
         CloseBuyOrders(Magic);
         CloseSellOrders(Magic);
         return(0);
      }
   }
*/

/*
//|---------time filter

   if((TradeOnSunday==false&&DayOfWeek()==0)||(MondayToThursdayTimeFilter&&DayOfWeek()>=1&&DayOfWeek()<=4&&!(Hour()>=MondayToThursdayStartHour&&Hour()<MondayToThursdayEndHour))||(FridayTimeFilter&&DayOfWeek()==5&&!(Hour()>=FridayStartHour&&Hour()<FridayEndHour)))
   {
      CloseBuyOrders(Magic);
      CloseSellOrders(Magic);
      return(0);
   }
*/

//|---------signal conditions

   int limit=1;
   for(int i=1;i<=limit;i++)
   {
   
/*
   //|---------moving average filter

      double MAF=iMA(Symbol(),0,MAPeriod,0,MAMethod,MAPrice,i);

      string MABUY="false";string MASELL="false";

      if((MAFilter==false)||(MAFilter&&Bid>MAF))MABUY="true";
      if((MAFilter==false)||(MAFilter&&Ask<MAF))MASELL="true";


   //|---------last price
   
      double LastBuyOpenPrice=0;
      double LastSellOpenPrice=0;
      int BuyOpenPosition=0;
      int SellOpenPosition=0;
      int TotalOpenPosition=0;
      int cnt=0;

      for(cnt=0;cnt<OrdersTotal();cnt++) 
      {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol()&&OrderMagicNumber()==Magic&&OrderCloseTime()==0) 
         {
            TotalOpenPosition++;
            if(OrderType()==OP_BUY) 
            {
               BuyOpenPosition++;
               LastBuyOpenPrice=OrderOpenPrice();
            }
            if(OrderType()==OP_SELL) 
            {
               SellOpenPosition++;
               LastSellOpenPrice=OrderOpenPrice();
            }
         }
      }
*/
 
      
      /* Debug des equations 
   		
   		Print ("Jour de année; StockKPeriod ; StochDPeriod ; StochSlowing ; RSIPeriod ; RSILevel ; ADXPeriod ; BearsPeriod ; BullsPeriod ; MACDFast ; MACDSlow ; MACDSMA ; RPeriod ; BBPeriod; MarginPips ; Takeprofits ; Magic1 ; Magic2 ; Expiration") ;
   		
		Print( DayOfYear(), " ; " , Eq_StochKPeriod() ," ; ", Eq_StochDPeriod() ," ; " , 
		Eq_StochSlowing(), " ; " ,  Eq_RSIPeriod() , " ; " ,  Eq_RSILevel() , " ; " ,
		Eq_ADXPeriod() , " ; " ,  Eq_BearsPeriod() , " ; " , Eq_BullsPeriod() , " ; ",
		Eq_MACDFast(),";", Eq_MACDSlow(),";",Eq_MACDSMA(),";",Eq_Rperiod(),";",Eq_BBPeriod(),";",
		Eq_MarginPips(),";",Eq_TakeProfit(),";",Eq_Magic1(),";",Eq_Magic2(),";",Eq_Expiration());
      
     }
*/
 
   //|---------main signal
 
      double StoMa=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_MAIN,i+1);
      double StoSa=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_SIGNAL,i+1);
      double StoM=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_MAIN,i);
      double StoS=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_SIGNAL,i);
      
      double RSIa=iRSI(NULL,0,RSIPeriod,PRICE_CLOSE,i+1);
      double RSI=iRSI(NULL,0,RSIPeriod,PRICE_CLOSE,i);
      
      double ADXPa=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,i+1);
      double ADXMa=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,i+1);
      double ADXP=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,i);
      double ADXM=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,i);
      
      double Bearsa=iBearsPower(NULL,0,BearsPeriod,PRICE_CLOSE,i+1);
      double Bullsa=iBullsPower(NULL,0,BullsPeriod,PRICE_CLOSE,i+1);
      double Bears=iBearsPower(NULL,0,BearsPeriod,PRICE_CLOSE,i);
      double Bulls=iBullsPower(NULL,0,BullsPeriod,PRICE_CLOSE,i);
      
      double MacdMa=iMACD(NULL,0,MACDFast,MACDSlow,MACDSMA,PRICE_CLOSE,MODE_MAIN,i+1);
      double MacdSa=iMACD(NULL,0,MACDFast,MACDSlow,MACDSMA,PRICE_CLOSE,MODE_SIGNAL,i+1);
      double MacdM=iMACD(NULL,0,MACDFast,MACDSlow,MACDSMA,PRICE_CLOSE,MODE_MAIN,i);
      double MacdS=iMACD(NULL,0,MACDFast,MACDSlow,MACDSMA,PRICE_CLOSE,MODE_SIGNAL,i);
      
      double CurrentClosea=iClose(NULL,0,i+RPeriod);
      double PrevClosea=iClose(NULL,0,i+RPeriod+RPeriod);
      double ROCa=CurrentClosea-PrevClosea;
      
      double CurrentClose=iClose(NULL,0,i);
      double PrevClose=iClose(NULL,0,i+RPeriod);
      double ROC=CurrentClose-PrevClose;
      
      double BBandsa=iMA(Symbol(),0,BBPeriod,0,MODE_SMA,PRICE_CLOSE,i+1);
      double BBands=iMA(Symbol(),0,BBPeriod,0,MODE_SMA,PRICE_CLOSE,i);
      
      double SARa=iSAR(NULL,0,Step,Maximum,i+1);
      double SAR=iSAR(NULL,0,Step,Maximum,i);
 
      string BUY="false";
      string SELL="false";

      if(
      ((OnlyAtStochSignal==false && StoM>StoS) || (OnlyAtStochSignal && StoMa<StoSa && StoM>StoS ))
      && ((OnlyAtRSISignal==false && RSI>RSILevel) || (OnlyAtRSISignal && RSIa<RSILevel && RSI>RSILevel ))
      && ((OnlyAtADXSignal==false && ADXP>ADXM) || (OnlyAtADXSignal && ADXPa<ADXMa && ADXP>ADXM ))
      && ((OnlyAtBearsSignal==false && Bears>0) || (OnlyAtBearsSignal && Bearsa<0 && Bears>0 ))
      && ((OnlyAtBullsSignal==false && Bulls>0) || (OnlyAtBullsSignal && Bullsa<0 && Bulls>0 ))
      && ((OnlyAtMacdSignal==false && MacdM>MacdS) || (OnlyAtMacdSignal && MacdMa<MacdSa && MacdM>MacdS ))
      && ((OnlyAtROCSignal==false && ROC>0) || (OnlyAtROCSignal && ROCa<0 && ROC>0 ))
      && ((OnlyAtBBSignal==false && Close[i]>BBands) || (OnlyAtBBSignal && Close[i+1]<BBandsa && Close[i]>BBands ))
      && ((OnlyAtPSarSignal==false && Open[i]>SAR) || (OnlyAtPSarSignal && Open[i+1]<SARa && Open[i]>SAR ))
      )BUY="true";
      if(
      ((OnlyAtStochSignal==false && StoM>StoS) || (OnlyAtStochSignal && StoMa>StoSa && StoM<StoS ))
      && ((OnlyAtRSISignal==false && RSI<RSILevel) || (OnlyAtRSISignal && RSIa>RSILevel && RSI<RSILevel ))
      && ((OnlyAtADXSignal==false && ADXP<ADXM) || (OnlyAtADXSignal && ADXPa>ADXMa && ADXP<ADXM ))
      && ((OnlyAtBearsSignal==false && Bears<0) || (OnlyAtBearsSignal && Bearsa>0 && Bears<0 ))
      && ((OnlyAtBullsSignal==false && Bulls<0) || (OnlyAtBullsSignal && Bullsa>0 && Bulls<0 ))
      && ((OnlyAtMacdSignal==false && MacdM<MacdS) || (OnlyAtMacdSignal && MacdMa>MacdSa && MacdM<MacdS ))
      && ((OnlyAtROCSignal==false && ROC<0) || (OnlyAtROCSignal && ROCa>0 && ROC<0 ))
      && ((OnlyAtBBSignal==false && Close[i]<BBands) || (OnlyAtBBSignal && Close[i+1]>BBandsa && Close[i]<BBands ))
      && ((OnlyAtPSarSignal==false && Open[i]<SAR) || (OnlyAtPSarSignal && Open[i+1]>SARa && Open[i]<SAR ))
      )SELL="true";
      
      string SignalBUY="false";
      string SignalSELL="false";
      
      if(BUY=="true"/*&&MABUY=="true"*/)if(ReverseSystem)SignalSELL="true";else SignalBUY="true";
      if(SELL=="true"/*&&MASELL=="true"*/)if(ReverseSystem)SignalBUY="true";else SignalSELL="true";
      
   }

//|---------risk management

   if(RiskMM)CalculateMM();

//|---------open orders

   double SL,TP,SLH,TPH,SLP,TPP,OPP,ILots,ILots1,ILots2;
   int Ticket1,Ticket2,TicketH,TicketP,Expire=0;
   if(Expiration>0)Expire=TimeCurrent()+(Expiration*60)-5;
   
   if((CountOrders(OP_BUY,Magic1)+CountOrders(OP_SELL,Magic1)+CountOrders(OP_BUY,Magic2)+CountOrders(OP_SELL,Magic2))<MaxOrders)
   {  
      if(SignalBUY=="true"&&NewBarBuy())
      {
         if(HideSL==false&&StopLoss>0){SL=Low[i]-(MarginPips+StopLoss)*Point;/*OPP=Bid-StopLoss*Point;SLP=Bid;*/}else {SL=0;/*SLP=0;*/}
         if(HideTP==false&&TakeProfit>0){TP=High[i]+(MarginPips+TakeProfit)*Point;/*TPP=Bid-(TakeProfit*2)*Point;*/}else {TP=0;/*TPP=0;*/}
         /*if(HideSL==false&&HedgeSL>0)SLH=Bid+HedgeSL*Point;else SLH=0;
         if(HideTP==false&&HedgeTP>0)TPH=Bid-HedgeTP*Point;else TPH=0;*/
         if(Martingale)ILots=NormalizeDouble(Lots*MartingaleFactor(),2);else ILots=Lots;
         if(ILots<MinLots)ILots=MinLots;if(ILots>MaxLots)ILots=MaxLots;
         ILots1=NormalizeDouble(ILots*(LotsPercent1/100),2);
         ILots2=NormalizeDouble(ILots*(LotsPercent2/100),2);
         
         Ticket1=OrderSend(Symbol(),OP_BUYSTOP,ILots1,High[i]+MarginPips*Point,Slippage,SL,TP,EAName,Magic1,Expire,Blue);
         Ticket2=OrderSend(Symbol(),OP_BUYSTOP,ILots2,High[i]+MarginPips*Point,Slippage,SL,0,EAName,Magic2,Expire,Blue);
         /*if(Hedge)TicketH=OrderSend(Symbol(),OP_SELL,ILots,Bid,Slippage,SLH,TPH,EAName,Magic,0,Red);
         if(ReverseAtStop&&StopLoss>0)TicketP=OrderSend(Symbol(),OP_SELLSTOP,Lots,OPP,Slippage,SLP,TPP,EAName,Magic,Expire,Red);*/
      }
      if(SignalSELL=="true"&&NewBarSell())
      {
         if(HideSL==false&&StopLoss>0){SL=High[i]+(MarginPips+StopLoss)*Point;/*OPP=Ask+StopLoss*Point;SLP=Ask;*/}else {SL=0;/*SLP=0;*/}
         if(HideTP==false&&TakeProfit>0){TP=Low[i]-(MarginPips+TakeProfit)*Point;/*TPP=Ask+(TakeProfit*2)*Point;*/}else {TP=0;/*TPP=0;*/}
         /*if(HideSL==false&&HedgeSL>0)SLH=Ask-HedgeSL*Point;else SLH=0;
         if(HideTP==false&&HedgeTP>0)TPH=Ask+HedgeTP*Point;else TPH=0;*/
         if(Martingale)ILots=NormalizeDouble(Lots*MartingaleFactor(),2);else ILots=Lots;
         if(ILots<MinLots)ILots=MinLots;if(ILots>MaxLots)ILots=MaxLots;
         ILots1=NormalizeDouble(ILots*(LotsPercent1/100),2);
         ILots2=NormalizeDouble(ILots*(LotsPercent2/100),2);
         
         Ticket1=OrderSend(Symbol(),OP_SELLSTOP,ILots1,Low[i]-MarginPips*Point,Slippage,SL,TP,EAName,Magic1,Expire,Red);
         Ticket2=OrderSend(Symbol(),OP_SELLSTOP,ILots2,Low[i]-MarginPips*Point,Slippage,SL,0,EAName,Magic2,Expire,Red);
         /*if(Hedge)TicketH=OrderSend(Symbol(),OP_BUY,ILots,Ask,Slippage,SLH,TPH,EAName,Magic,0,Blue);
         if(ReverseAtStop&&StopLoss>0)TicketP=OrderSend(Symbol(),OP_BUYSTOP,Lots,OPP,Slippage,SLP,TPP,EAName,Magic,Expire,Red);*/
      }
   }

//|---------close orders
/* 
   if(Hedge==false&&SELL=="true")
   {
      if(ReverseSystem)CloseSellOrders(Magic);else CloseBuyOrders(Magic);
   }
   if(Hedge==false&&BUY=="true")
   {
      if(ReverseSystem)CloseBuyOrders(Magic);else CloseSellOrders(Magic);
   }
   
   //|---------hidden sl-tp
   
   if(Hedge==false&&HideSL&&StopLoss>0)
   {
      CloseBuyOrdersHiddenSL(Magic);CloseSellOrdersHiddenSL(Magic);
   }
   if(Hedge==false&&HideTP&&TakeProfit>0)
   {
      CloseBuyOrdersHiddenTP(Magic);CloseSellOrdersHiddenTP(Magic);
   }
*/
//|---------not enough money warning

   int err=0;
   if(Ticket1<0&&Ticket2<0)
   {
      if(GetLastError()==134)
      {
         err=1;
         Print("Not enough money!");
      }
      return (-1);
   }
   
/*
   if(Comments)
   {
      Comment("\nCopyright © 2009, TradingSytemForex",
              "\n\nL o t s                   =  " + DoubleToStr(Lots,2),
              "\nB a l a n c e         =  " + DoubleToStr(AccountBalance(),2),
              "\nE q u i t y            =  " + DoubleToStr(AccountEquity(),2));
   }
*/

   return(0);
}

//|---------close buy orders

int CloseBuyOrders(int Magic)
{
  int total=OrdersTotal();

  for (int cnt=total-1;cnt>=0;cnt--)
  {
    OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if(OrderMagicNumber()==Magic&&OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_BUY)
      {
        OrderClose(OrderTicket(),OrderLots(),Bid,3);
      }
    }
  }
  return(0);
}

int CloseBuyOrdersHiddenTP(int Magic)
{
  int total=OrdersTotal();

  for (int cnt=total-1;cnt>=0;cnt--)
  {
    OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if(OrderMagicNumber()==Magic&&OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_BUY&&Bid>(OrderOpenPrice()+TakeProfit*Point))
      {
        OrderClose(OrderTicket(),OrderLots(),Bid,3);
      }
    }
  }
  return(0);
}

int CloseBuyOrdersHiddenSL(int Magic)
{
  int total=OrdersTotal();

  for (int cnt=total-1;cnt>=0;cnt--)
  {
    OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if(OrderMagicNumber()==Magic&&OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_BUY&&Bid<(OrderOpenPrice()-StopLoss*Point))
      {
        OrderClose(OrderTicket(),OrderLots(),Bid,3);
      }
    }
  }
  return(0);
}

//|---------close sell orders

int CloseSellOrders(int Magic)
{
  int total=OrdersTotal();

  for(int cnt=total-1;cnt>=0;cnt--)
  {
    OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if(OrderMagicNumber()==Magic&&OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_SELL)
      {
        OrderClose(OrderTicket(),OrderLots(),Ask,3);
      }
    }
  }
  return(0);
}

int CloseSellOrdersHiddenTP(int Magic)
{
  int total=OrdersTotal();

  for(int cnt=total-1;cnt>=0;cnt--)
  {
    OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if(OrderMagicNumber()==Magic&&OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_SELL&&Ask<(OrderOpenPrice()-TakeProfit*Point))
      {
        OrderClose(OrderTicket(),OrderLots(),Ask,3);
      }
    }
  }
  return(0);
}

int CloseSellOrdersHiddenSL(int Magic)
{
  int total=OrdersTotal();

  for(int cnt=total-1;cnt>=0;cnt--)
  {
    OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if(OrderMagicNumber()==Magic&&OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_SELL&&Ask>(OrderOpenPrice()+StopLoss*Point))
      {
        OrderClose(OrderTicket(),OrderLots(),Ask,3);
      }
    }
  }
  return(0);
}

//|---------count orders

int CountOrders(int Type,int Magic)
{
   int _CountOrd;
   _CountOrd=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
      {
         if((OrderType()==Type&&(OrderMagicNumber()==Magic)||Magic==0))_CountOrd++;
      }
   }
   return(_CountOrd);
}

//|---------trailing stop

void MoveTrailingStop()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&((OrderMagicNumber()==Magic2)))
      {
         if(OrderType()==OP_BUY&&NormalizeDouble((Ask-OrderOpenPrice()),Digits)>TrailingStop*Point)
         {
            if(TrailingStop>0&&Ask>NormalizeDouble(OrderOpenPrice(),Digits))  
            {                 
               if((NormalizeDouble(OrderStopLoss(),Digits)<NormalizeDouble(Bid-Point*(TrailingStop+TrailingStep),Digits))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-Point*TrailingStop,Digits),OrderTakeProfit(),0,Blue);
                  return(0);
               }
            }
         }
         if(OrderType()==OP_SELL&&NormalizeDouble((OrderOpenPrice()-Bid),Digits)>TrailingStop*Point)
         {
            if(TrailingStop>0&&Bid<NormalizeDouble(OrderOpenPrice(),Digits))  
            {                 
               if((NormalizeDouble(OrderStopLoss(),Digits)>(NormalizeDouble(Ask+Point*(TrailingStop+TrailingStep),Digits)))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask+Point*TrailingStop,Digits),OrderTakeProfit(),0,Red);
                  return(0);
               }
            }
         }
      }
   }
}

//|---------break even

void MoveBreakEven()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&((OrderMagicNumber()==Magic2)))
      {
         if(OrderType()==OP_BUY)
         {
            if(BreakEven>0)
            {
               if(NormalizeDouble((Bid-OrderOpenPrice()),Digits)>BreakEven*Point)
               {
                  if(NormalizeDouble((OrderStopLoss()-OrderOpenPrice()),Digits)<0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()+0*Point,Digits),OrderTakeProfit(),0,Blue);
                     return(0);
                  }
               }
            }
         }
         else
         {
            if(BreakEven>0)
            {
               if(NormalizeDouble((OrderOpenPrice()-Ask),Digits)>BreakEven*Point)
               {
                  if(NormalizeDouble((OrderOpenPrice()-OrderStopLoss()),Digits)<0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()-0*Point,Digits),OrderTakeProfit(),0,Red);
                     return(0);
                  }
               }
            }
         }
      }
   }
}

//|---------allow one action per bar

bool NewBarBuy()
{
   if(PreviousBarTime1<Time[0])
   {
      PreviousBarTime1=Time[0];
      return(true);
   }
   return(false);
}

bool NewBarSell()
{
   if(PreviousBarTime2<Time[0])
   {
      PreviousBarTime2=Time[0];
      return(true);
   }
   return(false);
}

//|---------calculate money management

void CalculateMM()
{
   double MinLots=MarketInfo(Symbol(),MODE_MINLOT);
   double MaxLots=MarketInfo(Symbol(),MODE_MAXLOT);
   Lots=AccountFreeMargin()/100000*RiskPercent;
   Lots=MathMin(MaxLots,MathMax(MinLots,Lots));
   if(MinLots<0.1)Lots=NormalizeDouble(Lots,2);
   else
   {
     if(MinLots<1)Lots=NormalizeDouble(Lots,1);
     else Lots=NormalizeDouble(Lots,0);
   }
   if(Lots<MinLots)Lots=MinLots;
   if(Lots>MaxLots)Lots=MaxLots;
   return(0);
}

//|---------martingale

int MartingaleFactor()
{
   int histotal=OrdersHistoryTotal();
   if (histotal>0)
   {
      for(int cnt=histotal-1;cnt>=0;cnt--)
      {
         if(OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY))
         {
            if(OrderSymbol()==Symbol() && ((OrderMagicNumber()==Magic1)||(OrderMagicNumber()==Magic2)))
            {
               if(OrderProfit()<0)
               {
                  LotsFactor=LotsFactor*Multiplier;
                  return(LotsFactor);
               }
               else
               {
                  LotsFactor=InitialLotsFactor;
                  if(LotsFactor<=0)
                  {
                     LotsFactor=1;
                  }
                  return(LotsFactor);
               }
            }
         }
      }
   }
   return (LotsFactor);
}



//List of optimisation Function


int Eq_StochKPeriod(){
//Goodness of fit:
//SSE: 336.8
//R-square: 0.7493
//Adjusted R-square: 0.3619
//RMSE: 5.533
     int x;
     double a0, a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3,b4,b5,b6,b7,b8,w;
     double y ;
     x = DayOfYear();
       
       a0 = 13.31;
       a1 = 0.8433;
       b1 = 1.006;
       a2 = 0.0533;
       b2 = -0.05971;  
       a3 = -1.441;
       b3 = -0.08717;  
       a4 = 0.2425;  
       b4 = -4.252;  
       a5 = 1.697;  
       b5 = 2.366;  
       a6 = 1.045;  
       b6 = -1.489;  
       a7 = 4.052;  
       b7 = -0.1961;  
       a8 = -4.44;  
       b8 = -0.9603; 
       w = 4.705;  
  
       y = a0 + a1*cos(x*w) + b1*sin(x*w) + a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) +  a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) + a8*cos(8*x*w) + b8*sin(8*x*w);
       return y;

}

 
int Eq_StochDPeriod(){

     int x;
     double a0, a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3,b4,b5,b6,b7,b8,w;
     double y ;
     x = DayOfYear();
       
       a0 =       12.51 ;
       a1 =      -1.156  ;
       b1 =       2.208 ;
       a2 =    -0.03334  ;
       b2 =      -8.089 ;
       a3 =       2.252  ;
       b3 =       1.375  ;
       a4 =    -0.07121  ;
       b4 =       1.552  ;
       a5 =     -0.2147  ;
       b5 =      -3.812  ;
       a6 =     -0.7352  ;
       b6 =      0.1344  ;
       a7 =       0.152  ;
       b7 =      -1.612;
       a8 =       1.538 ;
       b8 =       2.224  ;
       w =       9.449  ;

  
       y = a0 + a1*cos(x*w) + b1*sin(x*w) + a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) +  a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) + a8*cos(8*x*w) + b8*sin(8*x*w);
       return y;
}

int Eq_StochSlowing(){

     int x;
     double a0, a1, a2, a3, a4, a5, a6, a7, a8 ;
     double b1, b2, b3, b4, b5, b6, b7, b8 ;
     double w;
     double y ;
     x = DayOfYear();
       
       a0 =       12.51 ;
       a1 =      -1.156 ;
       b1 =       2.208  ;
       a2 =    -0.03334  ;
       b2 =      -8.089  ;
       a3 =       2.252 ;
       b3 =       1.375  ;
       a4 =    -0.07121  ;
       b4 =       1.552 ;
       a5 =     -0.2147  ;
       b5 =      -3.812  ;
       a6 =     -0.7352 ;
       b6 =      0.1344 ;
       a7 =       0.152 ;
       b7 =      -1.612 ;
       a8 =       1.538  ;
       b8 =       2.224 ;
       w =       9.449  ;

  
       y = a0 + a1*cos(x*w) + b1*sin(x*w) + a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) +  a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) + a8*cos(8*x*w) + b8*sin(8*x*w);
       return y;
}


int Eq_RSIPeriod(){

//Goodness of fit:
//SSE: 204.1
//R-square: 0.7698
//Adjusted R-square: 0.6608
//RMSE: 3.277

     int x;
     double a0, a1, a2, a3, a4 ; //, a5, a6, a7, a8
     double b1, b2, b3, b4 ; //, b5, b6, b7, b8
     double w;
     double y ;
     
     x = DayOfYear();
       
        a0 =       20.54 ;
       a1 =      -1.369 ;
       b1 =       5.147  ;
       a2 =      -2.442  ;
       b2 =      -1.731  ;
       a3 =      -1.827 ;
       b3 =    -0.07791  ;
       a4 =       1.216 ;
       b4 =      -0.312  ;
       w =       1.561 ;
      // a5 =     -0.2147  ;
      // b5 =      -3.812  ;
      // a6 =     -0.7352 ;
      // b6 =      0.1344 ;
      // a7 =       0.152 ;
      // b7 =      -1.612 ;
      // a8 =       1.538  ;
      // b8 =       2.224 ;
      // w =       9.449  ;

  
       y = a0 + a1*cos(x*w) + b1*sin(x*w) + a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) +  a4*cos(4*x*w) + b4*sin(4*x*w);
       return y;
       
 }
 
 
 int Eq_RSILevel(){
//Goodness of fit:
// SSE: 2941
// R-square: 0.8193
// Adjusted R-square: 0.6108
// RMSE: 15.04

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7;
     double b1, b2, b3, b4 , b5, b6, b7 ;
     double w;
     double y ;
     
     x = DayOfYear();
       
       a0 =       58.47;  //(52.36, 64.59)
       a1 =       12.49 ; //(3.896, 21.08)
       b1 =      -8.251;  //(-16.94, 0.4369)
       a2 =       3.052;  //(-6.498, 12.6)
       b2 =       -19.1;  //(-28.06, -10.13)
       a3 =       2.421;  //(-6.969, 11.81)
       b3 =        2.57;  //(-6.123, 11.26)
       a4 =      -10.93;  //(-19.41, -2.437)
       b4 =       1.335;  //(-7.529, 10.2)
       a5 =      -3.343;  //(-12.86, 6.171)
       b5 =       3.643;  //(-5.054, 12.34)
       a6 =      -6.657;  //(-15.17, 1.853)
       b6 =       1.408;  //(-7.271, 10.09)
       a7 =      -9.824;  //(-18.31, -1.341)
       b7 =      -5.691;  //(-14.62, 3.241)
       w =       5.729;  //(5.598, 5.859)

       y =  a0 + a1*cos(x*w) + b1*sin(x*w) + a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w);
       
       return y;
       
 }
 
 
  int Eq_ADXPeriod(){
//Goodness of fit:
 // SSE: 225.7
  //R-square: 0.6196
 // Adjusted R-square: 0.03183
//  RMSE: 4.53
     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7, a8;
     double b1, b2, b3, b4 , b5, b6, b7, b8 ;
     double w;
     double y ;
     
       a0 =       18.86; // (17, 20.71)
       a1 =      0.7902; //(-1.836, 3.416)
       b1 =       3.289;  //(0.6762, 5.902)
       a2 =      0.3932;  //(-2.234, 3.02)
       b2 =      0.1891;  //(-2.425, 2.803)
       a3 =      0.3912;  //(-2.235, 3.018)
       b3 =      0.5039;  //(-2.11, 3.118)
       a4 =    -0.05979;  //(-2.693, 2.574)
       b4 =     0.08366;  //(-2.545, 2.712)
       a5 =     -0.2204;  //(-2.861, 2.42)
       b5 =      0.2853;  //(-2.416, 2.986)
       a6 =       0.683;  //(-1.945, 3.311)
       b6 =      -0.423;  //(-3.281, 2.435)
       a7 =      -1.372;  //(-4.691, 1.947)
       b7 =       2.331;  //(-0.2895, 4.951)
       a8 =      -2.181;  //(-5.045, 0.6824)
       b8 =      -0.562;  //(-3.825, 2.701)
       w =       1.836 ; //(1.672, 2.001)
     
     x = DayOfYear();
       y =  a0 + a1*cos(x*w) + b1*sin(x*w) + 
       a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
          a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) +
               a8*cos(8*x*w) + b8*sin(8*x*w);
       
       return y;
       
 }
 
 
   int Eq_BearsPeriod(){
/*Goodness of fit:
  SSE: 267.3
  R-square: 0.6787
  Adjusted R-square: 0.4708
  RMSE: 3.966*/

     int x;
     double a0, a1, a2, a3, a4 , a5;//, a6, a7, a8;
     double b1, b2, b3, b4 , b5;//, b6, b7, b8 ;
     double w;
     double y ;
     
     x = DayOfYear();
     
        a0 =       19.25;//  (17.58, 20.91)
       a1 =      -0.699 ;// (-3.419, 2.021)
       b1 =       3.917 ;// (1.615, 6.22)
       a2 =      -4.232 ;// (-6.453, -2.012)
       b2 =      -1.386;//  (-3.755, 0.9825)
       a3 =      0.8731 ;// (-2.05, 3.796)
       b3 =       0.806 ;// (-1.741, 3.353)
       a4 =       0.929  ;//(-1.768, 3.626)
       b4 =   -0.006612 ;// (-2.841, 2.828)
       a5 =     -0.9604 ;// (-3.209, 1.288)
       b5 =      -1.628;//  (-3.838, 0.5816)
       w =       2.031  ;//(1.711, 2.352)
     
     
       y = a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w);
       return y;
       
 }
 
 
    int Eq_BullsPeriod(){

     int x;
     double a0, a1, a2, a3, a4 , a5;
     double b1, b2, b3, b4 , b5;
     double w;
     double y ;
     
     x = DayOfYear();
          a0 =        18.1 ;// (16.65, 19.56)
       a1 =      -1.718 ;// (-3.798, 0.3627)
       b1 =       3.844 ;// (1.781, 5.907)
       a2 =      0.3541 ;// (-1.766, 2.474)
       b2 =      -0.483 ;// (-2.561, 1.595)
       a3 =      -1.688 ;// (-4.215, 0.8387)
       b3 =       2.138 ;// (0.03911, 4.236)
       a4 =      -2.114  ;//(-4.713, 0.484)
       b4 =      -3.339 ;// (-5.784, -0.8947)
       a5 =       2.191  ;//(0.1067, 4.276)
       b5 =     -0.7027 ;// (-3.455, 2.049)
       w =       1.846  ;//(1.686, 2.007)
       
      y =  a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w);
           
           return y;
       
 }
 
int Eq_MACDFast(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7, a8;
     double b1, b2, b3, b4 , b5, b6, b7, b8 ;
     double w;
     double y ;
     
     a0 =       17.71;//  (15.13, 20.28)
       a1 =      0.8217 ;// (-3.544, 5.187)
       b1 =       3.482 ;// (0.5498, 6.415)
       a2 =     -0.3788 ;// (-5.222, 4.464)
       b2 =       1.379 ;// (-1.585, 4.343)
       a3 =       -2.14 ;// (-6.59, 2.31)
       b3 =        1.18 ;// (-1.893, 4.253)
       a4 =      0.2957  ;//(-3.796, 4.388)
       b4 =      0.1376 ;// (-2.877, 3.152)
       a5 =     -0.6882 ;// (-5.154, 3.778)
       b5 =     -0.8591 ;// (-4.868, 3.149)
       a6 =       1.812  ;//(-2.062, 5.685)
       b6 =     -0.7872 ;// (-6.065, 4.49)
       a7 =      -2.143 ;// (-6.593, 2.307)
       b7 =       2.185 ;// (-1.542, 5.913)
       a8 =      -1.147 ;// (-5.523, 3.229)
       b8 =      -1.716 ;// (-5.214, 1.781)
       w =       1.739  ;//(1.475, 2.003)
     
     x = DayOfYear();
     y =   a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) + 
               a8*cos(8*x*w) + b8*sin(8*x*w);
        return y;
       
 }
 
 
int Eq_MACDSlow(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7, a8;
     double b1, b2, b3, b4 , b5, b6, b7, b8 ;
     double w;
     double y ;
     
          a0 =        27.8 ;// (26.52, 29.09)
       a1 =      -2.057 ;// (-4.024, -0.08965)
       b1 =       1.047 ;// (-0.5823, 2.677)
       a2 =     -0.4069 ;// (-2.462, 1.648)
       b2 =       1.661 ;// (-0.03477, 3.356)
       a3 =     -0.1962 ;// (-2.511, 2.119)
       b3 =       1.124 ;// (-0.3097, 2.557)
       a4 =     0.04195  ;//(-2.267, 2.351)
       b4 =      0.8182 ;// (-0.8535, 2.49)
       a5 =       2.001 ;// (0.4582, 3.544)
       b5 =     0.08908 ;// (-1.98, 2.158)
       a6 =       1.636 ;// (0.02009, 3.252)
       b6 =     -0.3866 ;// (-1.928, 1.155)
       a7 =       1.245 ;// (-0.3747, 2.864)
       b7 =       -0.67 ;// (-2.159, 0.8192)
       a8 =     -0.5733  ;//(-2.245, 1.099)
       b8 =      -0.859 ;// (-2.464, 0.7458)
       w =       17.23  ;// (17.05, 17.42)
     
     x = DayOfYear();
       y =   a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) + 
               a8*cos(8*x*w) + b8*sin(8*x*w);
               
        return y;
       
 }
 
 
      int Eq_MACDSMA(){

     int x;
     double a0, a1, a2, a3;//, a4 , a5, a6, a7, a8;
     double b1, b2, b3;//, b4 , b5, b6, b7, b8 ;
     double w;
     double y ;
     
     x = DayOfYear();
    
    
        a0 =       14.41 ;// (13.06, 15.76)
       a1 =      -1.768 ;// (-3.782, 0.2459)
       b1 =       4.285  ;//(2.355, 6.215)
       a2 =      -1.899 ;// (-3.917, 0.1188)
       b2 =      -2.768 ;// (-4.725, -0.81)
       a3 =       1.608;//  (-0.2898, 3.506)
       b3 =       1.229;//  (-0.9372, 3.396)
       w =       1.876;//  (1.696, 2.055)

       
     
       y=  a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w);
       return y;        
 }
 
      int Eq_Rperiod(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7;//, a8;
     double b1, b2, b3, b4 , b5, b6, b7;//, b8 ;
     double w;
     double y ;
     
         a0 =       29.76 ;// (25.58, 33.93)
       a1 =      -1.413 ;//  (-7.165, 4.34)
       b1 =      -1.146 ;//  (-7.184, 4.892)
       a2 =        9.73 ;//  (3.709, 15.75)
       b2 =     -0.6997  ;// (-6.496, 5.096)
       a3 =      -1.979  ;// (-7.897, 3.94)
       b3 =       4.326  ;// (-1.609, 10.26)
       a4 =       5.473  ;// (-0.3854, 11.33)
       b4 =       1.235  ;// (-4.779, 7.248)
       a5 =      -5.165  ;// (-13.66, 3.326)
       b5 =      -14.14  ;// (-23.46, -4.809)
       a6 =       6.837 ;//  (1.283, 12.39)
       b6 =       1.647  ;// (-7.154, 10.45)
       a7 =       5.793 ;//  (-1.421, 13.01)
       b7 =      -6.303 ;//  (-16.91, 4.305)
       w =       4.354  ;// (4.251, 4.458)
     
     x = DayOfYear();
     y =     a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) ;  
         return y;
       
 }
 
 
      int Eq_BBPeriod(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7;//, a8;
     double b1, b2, b3, b4 , b5, b6, b7;//, b8 ;
     double w;
     double y ;
     
     a0 =        37.4 ;// (31.04, 43.76)
       a1 =      -4.002;//  (-12.92, 4.913)
       b1 =       3.417;//  (-5.596, 12.43)
       a2 =       5.229;//  (-3.85, 14.31)
       b2 =      -5.735 ;// (-14.65, 3.178)
       a3 =       5.029;//  (-3.884, 13.94)
       b3 =       9.032;//  (-0.007646, 18.07)
       a4 =       -1.24;//  (-10.78, 8.294)
       b4 =      0.6368;//  (-8.375, 9.649)
       a5 =        7.65;//  (-1.962, 17.26)
       b5 =     -0.0285;//  (-10.78, 10.73)
       a6 =       6.346;//  (-2.302, 14.99)
       b6 =       12.87;//  (-2.215, 27.95)
       a7 =       3.609;//  (-6.434, 13.65)
       b7 =      -4.538;//  (-14.1, 5.027)
       w =       4.582;//  (4.463, 4.701)
     
     x = DayOfYear();
     y =         a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) ;
          return y;
       
 }
 
 
      int Eq_MarginPips(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7;//, a8;
     double b1, b2, b3, b4 , b5, b6, b7;//, b8 ;
     double w;
     double y ;
     
           a0 =       44.78 ;// (37.38, 52.18)
       a1 =       10.25;//  (-0.359, 20.85)
       b1 =       14.97;//  (4.475, 25.46)
       a2 =      -5.391;//  (-18.03, 7.25)
       b2 =      -4.697;//  (-15.12, 5.729)
       a3 =      -2.352 ;// (-15.82, 11.12)
       b3 =       7.501;//  (-2.869, 17.87)
       a4 =       4.618;//  (-5.934, 15.17)
       b4 =       -6.72 ;// (-18.49, 5.052)
       a5 =       4.214 ;// (-6.679, 15.11)
       b5 =       7.439 ;// (-14.04, 28.91)
       a6 =      -1.428 ;// (-20.79, 17.93)
       b6 =       5.773 ;// (-14.52, 26.07)
       a7 =      -8.967 ;// (-20.4, 2.464)
       b7 =      -2.886 ;// (-13.4, 7.633)
       w =       1.826;//  (1.477, 2.175)

     
     x = DayOfYear();
     y=      a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) ; 
       return y;
       
 }
 
      int Eq_TakeProfit(){

     int x;
     double a0, a1, a2, a3, a4;// , a5, a6, a7, a8;
     double b1, b2, b3, b4;// , b5, b6, b7, b8 ;
     double w;
     double y ;
     
         a0 =       609.4 ;//  (441.9, 777)
       a1 =        -169 ;// (-403.4, 65.29)
       b1 =       134.8 ;// (-118.1, 387.7)
       a2 =       81.72;//  (-153.1, 316.5)
       b2 =       58.37;//  (-180, 296.7)
       a3 =      -27.44 ;// (-254.4, 199.5)
       b3 =      -156.9 ;// (-402.5, 88.82)
       a4 =      -90.68 ;// (-324.5, 143.1)
       b4 =       221.4 ;// (-18.17, 461)
       w =       17.15 ;// (16.93, 17.38)

     
     x = DayOfYear();
     y=  a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) ; 
       return y;
       
 }
 
 
      int Eq_Magic1(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7, a8;
     double b1, b2, b3, b4 , b5, b6, b7, b8 ;
     double w;
     double y ;
     
     x = DayOfYear();
     
          a0 =   25010 ;// (2.383e+04, 2.619e+04)
       a1 =       -1227  ;// (-2892, 438.9)
       b1 =      -350.5  ;// (-2010, 1309)
       a2 =      -353.7  ;// (-2019, 1312)
       b2 =        1820  ;// (110, 3529)
       a3 =      -484.5  ;// (-2151, 1181)
       b3 =       515.6  ;// (-1320, 2351)
       a4 =      -27.99  ;// (-1701, 1645)
       b4 =      -836.9  ;// (-2499, 825.4)
       a5 =      -9.275  ;// (-1676, 1657)
       b5 =      -601.9  ;// (-2310, 1106)
       a6 =       794.5  ;// (-1070, 2659)
       b6 =      -342.7  ;// (-2389, 1703)
       a7 =        1389 ;//  (-293.7, 3073)
       b7 =        1381 ;//  (-295.2, 3057)
       a8 =       352.1  ;// (-1440, 2144)
       b8 =      -709.3  ;// (-2698, 1280)
       w =       1.835   ;//(1.663, 2.008)

     
     y= a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) + 
               a8*cos(8*x*w) + b8*sin(8*x*w) ;
                 
        return y;
       
 }
 
      int Eq_Magic2(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7;//, a8;
     double b1, b2, b3, b4 , b5, b6, b7;//, b8 ;
     double w;
     double y ;
     
          a0 =   24440 ;//  (2.376e+04, 2.513e+04)
       a1 =      -271.4;//  (-1217, 674)
       b1 =       -1666 ;// (-2669, -662.8)
       a2 =      -80.01 ;// (-1044, 883.9)
       b2 =        -853 ;// (-1841, 134.8)
       a3 =       -1113 ;// (-2093, -134.1)
       b3 =       44.21 ;// (-941.1, 1030)
       a4 =      -149.8 ;// (-1140, 840.3)
       b4 =       -1399 ;// (-2366, -432.4)
       a5 =      -283.2 ;// (-1274, 707.3)
       b5 =      -638.7 ;// (-1625, 347.4)
       a6 =       191.4 ;// (-1516, 1899)
       b6 =        1020 ;// (-1482, 3522)
       a7 =         423 ;// (-1473, 2319)
       b7 =        1784 ;// (-558, 4125)
       w =       4.055  ;//(3.935, 4.176)

     
     
     x = DayOfYear();
         y=       a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w);
     return y;
       
 }
 
 
      int Eq_Expiration(){

     int x;
     double a0, a1, a2, a3, a4 , a5, a6, a7, a8;
     double b1, b2, b3, b4 , b5, b6, b7, b8 ;
     double w;
     double y ;
     
       a0 =       61.16 ;// (56.92, 65.41)
       a1 =      0.1505;//  (-5.811, 6.112)
       b1 =       15.17 ;// (9.093, 21.24)
       a2 =      -3.547 ;// (-9.489, 2.395)
       b2 =       -2.37 ;// (-8.709, 3.97)
       a3 =       1.568 ;// (-4.362, 7.497)
       b3 =      -4.304 ;// (-10.57, 1.96)
       a4 =      0.5435 ;// (-5.39, 6.476)
       b4 =      0.5984 ;// (-5.658, 6.855)
       a5 =        4.07 ;// (-1.887, 10.03)
       b5 =      -5.409 ;// (-11.55, 0.7296)
       a6 =       0.794 ;// (-5.343, 6.931)
       b6 =       1.979 ;// (-4.078, 8.036)
       a7 =      -1.629 ;// (-7.593, 4.334)
       b7 =      0.3825 ;// (-5.871, 6.636)
       a8 =       1.549 ;// (-4.375, 7.474)
       b8 =       8.017;//  (1.919, 14.12)
       w =       1.897 ;// (1.815, 1.978)
     
     x = DayOfYear();
     y=   a0 + a1*cos(x*w) + b1*sin(x*w) + 
               a2*cos(2*x*w) + b2*sin(2*x*w) + a3*cos(3*x*w) + b3*sin(3*x*w) + 
               a4*cos(4*x*w) + b4*sin(4*x*w) + a5*cos(5*x*w) + b5*sin(5*x*w) + 
               a6*cos(6*x*w) + b6*sin(6*x*w) + a7*cos(7*x*w) + b7*sin(7*x*w) + 
               a8*cos(8*x*w) + b8*sin(8*x*w) ;  
        return y;
       
 }
 
 // Se référer dans init() 
 void Ontimer(){
 
      
      StochKPeriod = Eq_StochKPeriod();
      StochDPeriod = Eq_StochDPeriod();
      StochSlowing = Eq_StochSlowing();
      
      RSIPeriod = Eq_RSIPeriod();
      RSILevel = Eq_RSILevel();
      
      ADXPeriod = Eq_ADXPeriod();
      
      BullsPeriod = Eq_BullsPeriod();
      
      BearsPeriod = Eq_BearsPeriod() ; 
      
      BBPeriod = Eq_BBPeriod();
      RPeriod = Eq_Rperiod();
      
      MACDFast = Eq_MACDFast();
      MACDSlow = Eq_MACDSlow() ; 
      MACDSMA = Eq_MACDSMA() ; 
      
      MarginPips = Eq_MarginPips();
      
      TakeProfit = Eq_TakeProfit();
      
      Magic1 = Eq_Magic1();
      Magic2 = Eq_Magic2();
      
      Expiration = Eq_Expiration();
 
 
 }
