import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:hardware_buttons/hardware_buttons.dart' as HardwareButtons;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager/wallpaper_manager.dart';


class QClock{
  var display_char=[
    'I','T','L','I','S','A','S','A','M','P','M',
    'A','C','Q','U','A','R','T','E','R','D','C',
    'T','W','E','N','T','Y','F','I','V','E','X',
    'H','A','L','F','B','T','E','N','F','T','O',
    'P','A','S','T','E','R','U','N','I','N','E',
    'O','N','E','S','I','X','T','H','R','E','E',
    'F','O','U','R','F','I','V','E','T','W','O',
    'E','I','G','H','T','E','L','E','V','E','N',
    'S','E','V','E','N','T','W','E','L','V','E',
    'T','E','N','S','E','O','C','L','O','C','K'
  ];
  var display_char_flag=List.filled(110,0);
  Map<int,String> words= {
    1: 'ONE',2:'TWO',3:'THREE',4:'FOUR',5:'FIVE',6:'SIX',7:'SEVEN',8:'EIGHT',9:'NINE',10:'TEN',11:'ELEVEN',12:'TWELVE',
    15:'QUARTER PAST',20:'TWENTY PAST',25:'TWENTYFIVE PAST',30:'HALF PAST',35:'TWENTYFIVE TO',40:'TWENTY TO',45:'QUARTER TO',50:'TEN TO',55:'FIVE TO',0:'OCLOCK'
  };
  void reset_char_flag(){
    for(var i=0;i<110;i++){
      display_char_flag[i]=0;
    }
  }
  void set_letters(String time_now){
    reset_char_flag();
    var k=0,i=0;
    while(i<110){
      var j=k;
      while(i+j-k<110){
        if(time_now[j]!=display_char[i+j-k]){
          break;
        }
        j++;
      }
      if(time_now[j]==' '){
        var temp=j-k;
        k=j+1;
        while(temp!=0){
          display_char_flag[i]=1;
          i++;
          temp--;
        }
      }
      if(time_now[k]=='Z'){
        break;
      }
      i++;
    }
  }
  void get_current_time(){
    DateTime curr=DateTime.now();
    var hour=(curr.hour%12==0)?12:curr.hour%12,minute=((curr.minute~/5)*5).toInt();
    var time_now="";
    if(minute==0){
      time_now=words[hour]+" "+words[minute];
    }else{
      time_now+=words[minute];
    if(minute==5 || minute==10){
      time_now+=' PAST';
    }
    if(minute>30){
      hour=((hour+1)%12)==0?12:((hour+1)%12);
    }
    time_now+=' '+words[hour];
    }
    set_letters('IT IS '+time_now+' Z');
  }
  QClock(){get_current_time();}

}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static GlobalKey screen = new GlobalKey();
  String path='/storage/emulated/0/Android/data/com.example.crosswordclock/files/screenshot.png';
  File imgFile = new File('/storage/emulated/0/Android/data/com.example.crosswordclock/files/screenshot.png');

  bool bg_flag=true;int letter_colors_index=0;
  QClock myqclock=QClock();
  List letter_colors=[Colors.lightGreenAccent[400],Colors.lightBlueAccent[400],Colors.deepOrangeAccent[200],Colors.yellowAccent[200]];

  StreamSubscription<HardwareButtons.VolumeButtonEvent> _volumeButtonSubscription;
  StreamSubscription<HardwareButtons.HomeButtonEvent> _homeButtonSubscription;
  StreamSubscription<HardwareButtons.LockButtonEvent> _lockButtonSubscription;

  @override
  void initState() {
    super.initState();
    _volumeButtonSubscription = HardwareButtons.volumeButtonEvents.listen((event) {
      setState(() {
        if(event==HardwareButtons.VolumeButtonEvent.VOLUME_UP){
          letter_colors_index=(letter_colors_index+1)%(letter_colors.length);
        }else{
          letter_colors_index=(letter_colors.length+letter_colors_index-1)%(letter_colors.length);
        }
        myqclock.get_current_time();
      });
    });

    _homeButtonSubscription = HardwareButtons.homeButtonEvents.listen((event) {
      setState(() {
        ;
      });
    });

    _lockButtonSubscription = HardwareButtons.lockButtonEvents.listen((event) {
      setState(() {
        Screenshot();
        myqclock.get_current_time();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _volumeButtonSubscription?.cancel();
    _homeButtonSubscription?.cancel();
    _lockButtonSubscription?.cancel();
  }


  void Screenshot() async{
    //myqclock.get_current_time();
    RenderRepaintBoundary boundary = screen.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();

    imgFile.writeAsBytes(pngBytes);
    await WallpaperManager.setWallpaperFromFile(path, WallpaperManager.LOCK_SCREEN);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: screen,
      child: Scaffold(
        backgroundColor: (!bg_flag)?Colors.white:Colors.black,
        body:SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(30,200,30,0),
            child: Container(
              child:GridView.builder(
                  itemCount: myqclock.display_char.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 11),
                  itemBuilder: (BuildContext context,int index){
                    return Center(
                      child: Text(
                          myqclock.display_char[index],
                          style:TextStyle(
                            color: myqclock.display_char_flag[index]==0?Colors.blueGrey[600]:letter_colors[letter_colors_index],
                            fontSize: 18,
                            fontWeight: myqclock.display_char_flag[index]==0?FontWeight.normal:FontWeight.bold,
                          ),
                      ),
                    );
                  }
              )
            ),
          ),
        )
      ),
    );
  }
}
