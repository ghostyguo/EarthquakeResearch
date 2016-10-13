// AirView
// Plot the graph of the air voltage from Arduino
// to predict earthquakes.
// Dyson Lin dysonlin@gmail.com
// 2016-07-30 05:58 UTC+8 V1.0
// 2016-08-10 15:42 UTC+8 V2.1.3 20x data compression. Change background to Black.
// 2016-08-16 21:56 UTC+8 V2.1.9 Plot select range area.
// 2016-08-16 22:17 UTC+8 V2.2.0 Adjust text sizes.
// 2016-08-17 23:43 UTC+8 V2.2.1 Use noLoop() and redraw() to plot graph only after reading new data.
// 2016-08-19 18:40 UTC+8 V2.2.2 10K-Ohom-R Voltage!
// 2016-08-19 19:14 UTC+8 V2.2.3 Water Voltage!
// 2016-08-20 21:04 UTC+8 V2.2.4 220-Ohom-R Voltage!
// 2016-08-24 04:25 UTC+8 V2.2.5 Air Voltage.
// 2016-08-26 17:10 UTC+8 V2.2.6 Fix the minData and maxData bug.
// 2016-08-27 03:53 UTC+8 V2.2.7 Modify plotData(), plotSelectRange().
// 2016-08-29 01:31 UTC+8 V2.2.8 Comment out noLoop() and redraw().
// 2016-08-29 02:23 UTC+8 V2.2.9 Make the window resizable.
// 2016-09-05 22:39 UTC+8 V2.2.9g Save sampled data to file for analysis, modifided by ghosty
// 2016-09-20 22:30 UTC+8 V1.0.0 Save more data to file for analysis, modifided by ghosty

import processing.serial.*;

int runningNumber=1; //added by ghosty, modify this number for multiple arduino boards

int startTime = 0;
int currentTime = 0;

String timeStringStart = null;
String dateStringStart = null;
String timeStringNow = null;
String dateStringNow = null;

int graphLeft = 0;
int graphRight = 0;
int graphTop = 0;
int graphBottom = 0;

int selectRangeLeft = 0;
int selectRangeRight = 0;
int selectRangeTop = 0;
int selectRangeBottom = 0;

int isFirstRead = 1;

int maxData = 0;
int minData = 0;
int maxTime = 0;
int minTime = 0;

final int compressionRatio = 20;
final int bufferLimit = 2 * compressionRatio; // compression ratio = bufferLimit/2. So bufferLimit must be even.
int [] buffer = new int[bufferLimit];
int [] bufferTime = new int[bufferLimit];
int bufferNumber = 0;

int dataLimit = 1000000;
int[] data = new int[dataLimit];
int[] dataTime = new int[dataLimit];
int dataNumber = 0;

boolean mouseInZoomArea(int x, int y)
{
  boolean inZoomArea = false;
  int zoomAreaLength = 10;
  int zoomLeft = width - zoomAreaLength;;
  int zoomRight = width;
  int zoomBottom = height;
  int zoomTop = height - zoomAreaLength;

  if ((x >= zoomLeft) && (x <= zoomRight) && (y <= zoomBottom) && (y >= zoomTop))
  {
    inZoomArea = true;
  }

  return inZoomArea;
}


//void mouseDragged()
//{
//  if (mouseInZoomArea(mouseX, mouseY))
//  {
//    int newWidth = width + (mouseX - pmouseX);
//    int newHeight = height + (mouseY - pmouseY);

//    surface.setSize(newWidth, newHeight);
//  }
//}

void setup()
{
  size(1300, 720);
  surface.setResizable(true);

  openSerialPort();
  setStartTimeStamp();
}

void openSerialPort()
{
  Serial myPort;  // The serial port

  myPort = new Serial(this, "COM3", 9600);
  myPort.clear(); // Clear buffer
  myPort.bufferUntil(0x0A); // Trigger serialEvent() only after linefeed is read.
}

void setStartTimeStamp()
{
  startTime = millis();
  timeStringStart = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  dateStringStart = year() + "-" + nf(month(), 2) + "-" + nf(day(), 2);
}

void setTimeStamp()
{
  currentTime = millis();
  timeStringNow = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  dateStringNow = year() + "-" + nf(month(), 2) + "-" + nf(day(), 2);
}

void draw()
{
  background(0);  // black background
  stroke(255);
  fill(255);

  // Set the location of graph
  graphLeft = 50;
  graphRight = width - 50;
  graphTop = 50;
  graphBottom = height - 100;
  maxTime = graphRight - graphLeft;

  background(0);
  setTimeStamp();
  plotSelectRange();
  plotAxes();
  //plotData();
  plotData(graphLeft+3, graphRight, graphBottom-3, graphTop);
  plotZero();
}

void plotData(int leftBorder, int rightBorder, int bottomBorder, int topBorder) {
  float x1 = 0;
  float y1 = 0;
  float x2 = 0;
  float y2 = 0;

  if (dataNumber < 2) {
    return;
  }

  stroke(255);

  // set first point
  //x1 = graphLeft+3;
  //y1 = map(data[0], minData, maxData, graphBottom-3, graphTop);
  x1 = leftBorder;
  y1 = map(data[0], minData, maxData, bottomBorder, topBorder);

  // plot lines
  for (int i=1; i<dataNumber; i++)
  {
    //x2 = map(i, 0, dataNumber-1, graphLeft+3, graphRight); // auto range
    //y2 = map(data[i], minData, maxData, graphBottom-3, graphTop); // auto range
    x2 = map(i, 0, dataNumber-1, leftBorder, rightBorder); // auto range
    y2 = map(data[i], minData, maxData, bottomBorder, topBorder); // auto range
    line(x1, y1, x2, y2);
    x1 = x2;
    y1 = y2;
  }
}

void plotSelectRange()
{
  // Set the location of graph
  selectRangeLeft = 100;
  selectRangeRight = width - 100;
  selectRangeBottom = height - 15;
  selectRangeTop = height - 48;

  int textSize = 12;
  textSize(textSize);

  stroke(0, 128, 0, 128);
  fill(0, 128, 0, 128);
  rect(selectRangeLeft, selectRangeTop, selectRangeRight - selectRangeLeft, selectRangeBottom - selectRangeTop);

  stroke(255);
  fill(255);

  textAlign(CENTER);
  text(timeStringStart, graphLeft, selectRangeTop + textSize*1);
  text(dateStringStart, graphLeft, selectRangeTop + textSize*2.5);

  textAlign(CENTER);
  text(timeStringNow, graphRight, selectRangeTop + textSize*1);
  text(dateStringNow, graphRight, selectRangeTop + textSize*2.5);

  plotData(selectRangeLeft, selectRangeRight, selectRangeBottom, selectRangeTop);
}

void plotAxes() {
  int textSize = 12;
  float minVoltage = 0;
  float maxVoltage = 0;

  textAlign(CENTER);
  textSize = 24;
  textSize(textSize);
  text("Air Voltage "+runningNumber, (graphLeft+graphRight)/2, graphTop - textSize);

  textSize = 16;
  textSize(textSize);
  text("Time", (graphRight + graphLeft)/2, graphBottom + textSize * 3);
  text("V (mV)", graphLeft, graphTop - textSize);

  // plot x-axis
  textSize = 12;
  textSize(textSize);

  stroke(0, 128, 0);
  line(graphLeft, graphBottom, graphLeft, graphTop);
  textAlign(RIGHT);
  minVoltage = map(minData, -1023, 1023, -5000, 5000);
  text(round(minVoltage), graphLeft - textSize/2, graphBottom);

  maxVoltage = map(maxData, -1023, 1023, -5000, 5000);
  text(round(maxVoltage), graphLeft - textSize/2, graphTop + textSize);

  textAlign(CENTER);
  text(timeStringStart, graphLeft, graphBottom + textSize*1.5);
  text(dateStringStart, graphLeft, graphBottom + textSize*2.5);

  textAlign(CENTER);
  text(timeStringNow, graphRight, graphBottom + textSize*1.5);
  text(dateStringNow, graphRight, graphBottom + textSize*2.5);

  // plot y-axis
  line(graphLeft, graphBottom, graphRight, graphBottom);
  textAlign(CENTER);

  textSize = 16;
  textSize(textSize);
  textAlign(CENTER);
  text("Time", (graphRight + graphLeft)/2, graphBottom + textSize * 3);
  text("V (mV)", graphLeft, graphTop - textSize);
}

//--- modify by ghosty --- begin
void plotZero()
{
  // ploy x-zero line 
  int textSize=16;
  if (maxData>minData) { //plot only if data is OK
    int zero=(minData*graphTop-maxData*graphBottom)/(minData-maxData);
    stroke(0, 128, 0);  
    line(graphLeft, zero, graphRight, zero);
    textSize(12);
    text("0", graphLeft - textSize/2, zero+textSize/2); //zero 
  }  
}
//--- modify by ghosty --- end


void serialEvent(Serial whichPort) {

  String inString = trim(whichPort.readStringUntil(0x0A)); // Input string from serial port
  //println(inString); //debug
  if (inString == null)
  {  
    return;
  }

  //--- modify by ghosty --- begin
  String[] list = split(inString, ','); 
  int tick = int(trim(list[0]));
  int voltage = int(trim(list[1]));
  int A0 = int(trim(list[2]));
  int A1 = int(trim(list[3]));
  saveData(tick,voltage, A0, A1);  
  //--- modify by ghosty --- end

  if (isFirstRead == 1)
  {
    print("Discard first read: ");
    println(inString);
    isFirstRead = 0;
    return;
  }

  buffer[bufferNumber] = voltage;
  bufferTime[bufferNumber] = millis();

  if (bufferNumber < bufferLimit-1)
  {
    bufferNumber++; 
  } else
  {
    // bufferNumber == bufferLimit-1
    // That means buffer is full
    // Compress data:
    // keep the max and min
    // also keep their order
    int xMax = 0;
    int yMax = 0;
    int xMin = 0;
    int yMin = 0;
    int i = 0;
    String s = null;

    yMax = buffer[0];
    xMax = 0;
    yMin = buffer[0];
    xMin = 0;

    for (i=1; i<bufferLimit; i++)
    {
      if (buffer[i] > yMax)
      {
        yMax = buffer[i];
        xMax = i;
      }

      if (buffer[i] < yMin)
      {
        yMin = buffer[i];
        xMin = i;
      }
    }

    bufferNumber = 0;

    if (dataNumber == 0)
    {
      maxData = yMax;
      minData = yMin;
    } else {
      if (yMax > maxData)
      {
        maxData = yMax;
      }

      if (yMin < minData)
      {
        minData = yMin;
      }
    }

    if (xMin < xMax)
    {
      data[dataNumber] = yMin;
      s = "data[" + dataNumber + "] = " + data[dataNumber] + "  Max: " + maxData + "  Min: " + minData;
      println(s);
      dataNumber++;

      data[dataNumber] = yMax;
      s = "data[" + dataNumber + "] = " + data[dataNumber] + "  Max: " + maxData + "  Min: " + minData;
      println(s);
      dataNumber++;
    } else
    {
      data[dataNumber] = yMax;
      s = "data[" + dataNumber + "] = " + data[dataNumber] + "  Max: " + maxData + "  Min: " + minData;
      println(s);
      dataNumber++;

      data[dataNumber] = yMin;
      s = "data[" + dataNumber + "] = " + data[dataNumber] + "  Max: " + maxData + "  Min: " + minData;
      println(s);
      dataNumber++;
    }
  }
}

/*
   modify by ghosty : save data to file
*/
import java.io.*;
String rootDir="D:\\Earthquake Research\\SampledData\\";
void saveData(int tick, int voltage, int A0, int A1)
{
  BufferedWriter output = null;
  try {
    String fileName = rootDir+String.format("air%d_%04d-%02d-%02d.txt", runningNumber, year(), month(), day());
    output = new BufferedWriter(new FileWriter(fileName, true)); //the true will append the new data
    output.write(String.format("%04d-%02d-%02d %02d:%02d:%02d, %4d, %5d, %4d, %4d", year(), month(), day(), hour(), minute(), second(), 
                  tick, voltage, A0, A1));
    output.newLine();
  }
  catch (IOException e) {
    println("It Broke");
    e.printStackTrace();
  }
  finally {
    if (output != null) {
      try {
        output.close();
      } catch (IOException e) {
        println("Error while closing the writer");
      }
    }
  }
}