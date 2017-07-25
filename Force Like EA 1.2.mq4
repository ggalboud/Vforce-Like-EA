//+------------------------------------------------------------------+
//|                                     _expert advisor template.mq4 |
//|                              Copyright © 2009, TradingSytemForex |
//|                                http://www.tradingsystemforex.com |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2009, TradingSytemForex"
#property link "http://www.tradingsystemforex.com"

//|----------------------------------------------you can modify this expert
//|----------------------------------------------you can change the name
//|----------------------------------------------you can add "modified by you"
//|----------------------------------------------but you are not allowed to erase the copyrights

#define EAName "_expert advisor template"

extern string S1="---------------- Entry Settings";

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

//|---------initialization

int init()
{
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