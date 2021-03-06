//+------------------------------------------------------------------+
//|                                                   AlligatorEA.mq4 |
//|                                                          Song100 |
//|                                                         鳄鱼三线 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
/*
货币对：当前
时间周期：当前
技术指标：鳄鱼三线 8,5,3
          趋势指标+震荡指标
开仓条件：买入条件  鳄鱼三线成顺序
          用Force指标过滤盘整行情
平仓条件：鳄鱼线交叉
*/

#property copyright "Song100"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern int StopLoss=40;
extern int TakeProfit=0;
extern double MaxRisk=30;//资金风险 1=1%
extern double Filter=0.35;//Force 指标过滤参数
double Alligator_jaw,Alligator_teeth,Alligator_lips,Envelops21_upper,Envelops21_lower,Force3;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int start()
  {
//---
   OrderSelect(0,SELECT_BY_POS);//选当前订单
   //显示市场信息
   SetLable("时间栏","星期"+DayOfWeek()+" 市场时间: "+Year()+"-"+Month()+"-"+Day()
            +" "+Hour()+":"+Minute()+":"+Seconds(),200,0,9,"Verdana",Red);
   SetLable("信息栏","市场信号："+ReturnMarketInformation()+
            "  当前订单盈利："+DoubleToStr(OrderProfit(),2),5,20,10,"Verdana",Blue);
   //周五20点停止交易，盈利订单平仓
//   if(DayOfWeek()==5&&Hour()>=20&&Minute()>=0)
//   {
//      if(OrderProfit()>0) OrderClose(OrderTicket(),OrderLots(),Ask,0);
//      return(0);
//   }
   
   //新开仓订单时间不足一个时间周期，不做任何操作返回
   //if(TimeCurrent()-OrderOpenTime()<=PERIOD_M30*60)return(0);
   double sl_buy=Ask-StopLoss*Point;
   double tp_buy=Ask+TakeProfit*Point;
   double sl_sell=Bid+StopLoss*Point;
   double tp_sell=Bid-TakeProfit*Point;
   if(StopLoss==0){sl_buy=0;sl_sell=0;}
   if(TakeProfit==0){tp_buy=0;tp_sell=0;}
   
   //开仓操作
   if(OrdersTotal()==0)//没有订单，则开仓
   {
      if(ReturnMarketInformation()=="Buy")
         OrderSend(Symbol(),OP_BUY,LotsOptimized(MaxRisk),Ask,0,sl_buy,tp_buy);
      if(ReturnMarketInformation()=="Sell")
         OrderSend(Symbol(),OP_SELL,LotsOptimized(MaxRisk),Bid,0,sl_sell,tp_sell);
   }
   //平仓操作
   
   if(OrderProfit()>0)//止盈操作
   {
      if(OrdersTotal()==1 && OrderType()==OP_BUY && ReturnMarketInformation()=="DownCross")
         OrderClose(OrderTicket(),OrderLots(),Bid,0);
      if(OrdersTotal()==1 && OrderType()==OP_SELL && ReturnMarketInformation()=="UpCross")
         OrderClose(OrderTicket(),OrderLots(),Ask,0);  
   }
   if(OrderProfit()<0)//止损操作
   {
      if(OrdersTotal()==1 && OrderType()==OP_BUY && Alligator_lips<Alligator_jaw)
         OrderClose(OrderTicket(),OrderLots(),Bid,0);
      if(OrdersTotal()==1 && OrderType()==OP_SELL && Alligator_lips>Alligator_jaw)
         OrderClose(OrderTicket(),OrderLots(),Ask,0);
   
   }
   
   //移动止损
   if(OrderProfit()>StopLoss*2 && OrderType()==OP_BUY && OrderStopLoss()<OrderOpenPrice())
      {
         OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+Point*StopLoss*0.5,OrderTakeProfit(),0);
      }
   if(OrderProfit()>StopLoss*2 && OrderType()==OP_SELL && OrderStopLoss()>OrderOpenPrice())
      {
         OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-Point*StopLoss*0.5,OrderTakeProfit(),0);
      }
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+

/*
函数：优化保证金，确定开仓量，进行风险控制
      根据风险值RistValue计算开仓量
      如果出现亏损单，则下一单开仓量减半
*/
double LotsOptimized(double RistValue)
{
   double iLots=NormalizeDouble((AccountBalance()*RistValue/100)/MarketInfo(Symbol(),MODE_MARGINREQUIRED),2);//最大可开仓手数
   OrderSelect(OrdersHistoryTotal()-1,SELECT_BY_POS,MODE_HISTORY);
   Print("AccoutBalance="+AccountBalance());
   Print("Marginrequired="+MarketInfo(Symbol(),MODE_MARGINREQUIRED));
   Print("Ilot="+iLots);
   if(OrderProfit()<0)iLots=iLots/2;
   if(iLots<0.01){iLots=0;Print("保证金金额不足！");}
   return(iLots);
}

/*
函数：返回市场信息
      获取技术指标参数，通过比对，返回市场信息：
      Buy-买入信号， sell-卖出信号， Rise-涨势行情， Fall-跌势行情，
      UpCross-向上翻转， DownCross-向下反转,反转信号为平仓信号
*/
string ReturnMarketInformation()
{
   string MktInfo="N/A";
   //读取指标数值
   //当前柱子的值
   Alligator_jaw=NormalizeDouble(iAlligator(Symbol(),0,13,0,8,0,5,0,MODE_EMA,PRICE_MEDIAN,MODE_GATORJAW,0),4); 
   Alligator_teeth=NormalizeDouble(iAlligator(Symbol(),0,13,0,8,0,5,0,MODE_EMA,PRICE_MEDIAN,MODE_GATORTEETH,0),4); 
   Alligator_lips=NormalizeDouble(iAlligator(Symbol(),0,13,0,8,0,5,0,MODE_EMA,PRICE_MEDIAN,MODE_GATORLIPS,0),4); 
   //前一个柱子的值
   double Alligator_jaw_1=NormalizeDouble(iAlligator(Symbol(),0,13,0,8,0,5,0,MODE_EMA,PRICE_MEDIAN,MODE_GATORJAW,1),4); 
   double Alligator_teeth_1=NormalizeDouble(iAlligator(Symbol(),0,13,0,8,0,5,0,MODE_EMA,PRICE_MEDIAN,MODE_GATORTEETH,1),4); 
   double Alligator_lips_1=NormalizeDouble(iAlligator(Symbol(),0,13,0,8,0,5,0,MODE_EMA,PRICE_MEDIAN,MODE_GATORLIPS,1),4); 
   
   Force3=NormalizeDouble(iForce(Symbol(),0,4,MODE_EMA,PRICE_WEIGHTED,0),4); 
   //指标分析，返回市场信息 || Force3<-Filter  Force3>Filter ||  
   if (Alligator_lips>Alligator_teeth && Alligator_lips_1<=Alligator_teeth_1)MktInfo="UpCross";
   if (Alligator_lips<Alligator_teeth && Alligator_lips_1>=Alligator_teeth_1)MktInfo="DownCross";
   if (Alligator_lips>Alligator_teeth && Alligator_teeth>Alligator_jaw)MktInfo="Rise";
   if (Alligator_lips<Alligator_teeth && Alligator_teeth<Alligator_jaw)MktInfo="Fall";
   if (Force3>Filter && MktInfo=="Rise" && !(Alligator_lips_1>Alligator_teeth_1 && Alligator_teeth_1>Alligator_jaw_1))MktInfo="Buy";
   if (Force3<-Filter && MktInfo=="Fall" && !(Alligator_lips_1<Alligator_teeth_1 && Alligator_teeth_1<Alligator_jaw_1))MktInfo="Sell";
   return(MktInfo);
}


/*
函数：在屏幕上显示标签
参数说明： LableName：标签名称； LableDoc：文本内容； LableX：标签 X 位置； LableY：标
签 Y 位置； DocSize：文本字号； DocStyle：文本字体； DocColor：文本颜色
*/
void SetLable(string LableName,string LableDoc,int LableX,int LableY,
int DocSize,string DocStyle,color DocColor)
 {
   ObjectCreate(LableName, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(LableName,LableDoc,DocSize,DocStyle,DocColor);
   ObjectSet(LableName, OBJPROP_XDISTANCE, LableX);
   ObjectSet(LableName, OBJPROP_YDISTANCE, LableY);
 }