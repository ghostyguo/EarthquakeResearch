// 測量A0對A1的空氣電壓
// 修改自地震預測研究所所長 林湧森 2016-07-28 04:29 UTC+8
// 修改者:ghostyguo
// 使用最快取樣速度, 每隔1000ms送出最大與最小值
// 紀錄最大與最小值時的A0與A1
// 2016-08-20 22:30 UTC+8 by 
// 2016_09_20 22:00 UCT+8 by ghosty

#define runSimulation  false

int sampleCount;
int maxValue, minValue; //keep extreme value
int maxA0, maxA1, maxTick; //A0&A1 when maxValue is captures
int minA0, minA1, minTick; //A0&A1 when minValue is captures
int whoIsLast = 0; //-1=min, 1=max, 0=undefined;
int sampleCountLimit;

void setup()
{
    Serial.begin(9600);
    SetupRunningParameters();
    startNewCycle();
}

void SetupRunningParameters()
{
    // find sampleCountLimit in 1000ms
    unsigned long startMicros=micros();
    startNewCycle();
    while (micros()-startMicros<1000000L) {
        sampling();
    }
    sampleCountLimit = sampleCount;
    // uncomment the following lines to see the sampleCountLimit
    //Serial.print("sampleCountLimit="); 
    //Serial.println(sampleCountLimit);
}

void startNewCycle()
{
    maxValue = maxA0 = maxA1 = -10000; //12bit ADC < -1024
    minValue = minA0 = minA1 = 10000;  //12bit ADC > 1024
    maxTick = minTick = -1; //undefined
    whoIsLast = 0;
    sampleCount = 0;
}

void loop()
{
    sampling();
    if (sampleCount>sampleCountLimit) { 
        #if (runSimulation)
            outputRandomValue1();
            outputRandomValue2();
        #else        
            if (whoIsLast == -1) { //min is last          
                outputMaxValue();        
                outputMinValue();  
            } else if (whoIsLast == 1) { //max is last
                outputMinValue();            
                outputMaxValue();
            } else {
                Serial.println("Extreme Value Error");    
            }
        #endif        
        startNewCycle();
    }
}

void outputMaxValue()
{
    Serial.print(maxTick);
    Serial.print(",");
    Serial.print(maxValue);
    Serial.print(",");
    Serial.print(maxA0);     
    Serial.print(",");
    Serial.println(maxA1); 
}
void outputMinValue()
{   
    Serial.print(minTick);
    Serial.print(",");
    Serial.print(minValue);
    Serial.print(",");
    Serial.print(minA0);     
    Serial.print(",");
    Serial.println(minA1);     
}

#if (runSimulation)
void outputRandomValue1()
{
    Serial.print(random(1024));
    Serial.print(",");
    Serial.print(random(1024));
    Serial.print(",");
    Serial.print(random(1024));     
    Serial.print(",");
    Serial.println(random(1024));     
}
void outputRandomValue2()
{
    Serial.print(-random(1024));
    Serial.print(",");
    Serial.print(-random(512));
    Serial.print(",");
    Serial.print(random(1024));     
    Serial.print(",");
    Serial.println(random(1024));     
}
#endif

void sampling()
{
    int A0 = analogRead(A0);    
    int A1 = analogRead(A1);
    int sampleValue = A0 - A1;
    if (minValue > sampleValue) {
        minValue = sampleValue;
        minA0 = A0;
        minA1 = A1;
        minTick = sampleCount;
        whoIsLast = -1;
    }
    if (maxValue < sampleValue) {
        maxValue = sampleValue;
        maxA0 = A0;
        maxA1 = A1;
        maxTick = sampleCount;
        whoIsLast = 1;
    }
    ++sampleCount;
}
