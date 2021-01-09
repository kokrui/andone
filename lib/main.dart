import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import "dart:math";

int diffchosen = 2;

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) => Container(child:Align(
      alignment: Alignment.center,
      child: Text("LOADING...",
          style: TextStyle(
              fontSize: 80,
              color: Colors.black,
              decoration: TextDecoration.none))));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(),
        '/game': (context) => GameScreen(),
        '/fin': (context) => EndScreen(),
      },
      title: 'AND-ONE!!!',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //home: (title: 'Flutter Demo Home Page'),
    );
  }
}

class EndArguments {
  final int fails;
  final double latetot;

  EndArguments(this.fails, this.latetot);
}

class EndScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final EndArguments args = ModalRoute.of(context).settings.arguments;

    return Column(
      children: [
        Expanded(
            flex: 3,
            child: Align(
                alignment: Alignment.center,
                child: Text("GAME OVER",
                    style: TextStyle(
                        fontSize: 80,
                        color: Colors.black,
                        decoration: TextDecoration.none)))),
        Center(
            child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/',
                  );
                },
                child: Container(
                    margin: const EdgeInsets.only(left: 100, right: 100),
                    decoration: BoxDecoration(
                        border: Border.all(width: 5),
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        color: Colors.white),
                    child: Align(
                        alignment: Alignment.center,
                        child: Text("Main Menu",
                            style: TextStyle(
                                fontSize: 40,
                                color: Colors.black,
                                decoration: TextDecoration.none)))))),
        Expanded(
            flex: 2,
            child: Container(
                margin: EdgeInsets.only(left: 50, right: 50),
                child: Align(
                    alignment: Alignment.center,
                    child: Text(
                        "referees still suck, but looks like we all suck more. you finished with:",
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            decoration: TextDecoration.none))))),
        Expanded(
            flex: 2,
            child: Container(
                margin: EdgeInsets.only(left: 60, right: 60),
                child: Align(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(
                            text: args.latetot.toStringAsFixed(4),
                            style: TextStyle(
                                fontSize: 40,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: "s of delay in total",
                            style: TextStyle(
                                fontSize: 40,
                                color: Colors.black,
                                decoration: TextDecoration.none))
                      ]),
                    )))),
        Expanded(
            flex: 2,
            child: Container(
                margin: EdgeInsets.only(left: 60, right: 60, bottom: 30),
                child: Align(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(
                            text: args.fails.toString(),
                            style: TextStyle(
                                fontSize: 40,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: " Fails",
                            style: TextStyle(
                                fontSize: 40,
                                color: Colors.black,
                                decoration: TextDecoration.none))
                      ]),
                    )))),
      ],
    );
  }
}

class GameArguments {
  final int difficulty;

  GameArguments(this.difficulty);
}

class GameScreen extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<GameScreen> {
  final r = new Random();

  int numfails = 0;
  double totlate = 0.0;

  int qnum = 0;
  double vidpos = 0;
  double vidbuf = 0;
  Map<String, VideoPlayerController> _controllers = {};
  Map<int, VoidCallback> _listeners = {};

  List<String> lines = [];

  List<String> questions = [];

  double playerans = 0.0;
  double realans = 0.0;
  int realanstype = 0;
  int playanstype = 0;

  int intermission =
      0; // 0 is off, 1 is correct no call, 2 is correct call + late timing, 3 is wrong

  @override
  void initState() {
    super.initState();
    print("HEYY");

    loadAsset().then((String value) {
      print("WADIO");
      lines = value.split("\n");

      switch (diffchosen) {
        case 1:
          {
            questions = pop_med(lines);
          }
          break;
        case 2:
          {
            questions = pop_hard(lines);
          }
          break;
        case 3:
          {
            print('HARDEN SHIT HERE');
          }
          break;
        default:
          {
            questions = pop_easy(lines);
            break;
          }
      }
      print("\n\n\n\n\n\n\nQNS");
      // print(questions);
      // print(questions.length);
      print("QNS\n\n\n\n\n\n\n");

      if (questions.length > 0) {
        _initController(0).then((_) {
          _playController(0);
        });
      }

      if (questions.length > 1) {
        print("PRELOADING ALL ");
        // PRELOAD ALL LMAO
        for (int i = 1; i < 10; i++) {
          _initController(i).whenComplete(() => null);
        }
      }
    });
  }

  List<String> pop_easy(List<String> inplines) {
    List<String> ez = [];
    for (int i = 0; i < 10; i++) {
      int rind = r.nextInt(inplines.length);
      String candi = inplines[rind];
      while (!((candi.split(',')[2] == '6' && candi.split(',')[3] == '2') ||
          candi.split(',')[2] == '1')) {
        candi = inplines[rind++ % (inplines.length)];
      }
      ez.add(candi);
    }
    ez.shuffle();
    return ez;
  }

  List<String> pop_med(List<String> inplines) {
    List<String> med = [];
    for (int i = 0; i < 10; i++) {
      int rind = r.nextInt(inplines.length);

      String candi = inplines[r.nextInt(rind)];
      while (!(candi.split(',')[2] == '6' ||
          candi.split(',')[2] == '1' ||
          candi.split(',')[2] == '2')) {
        candi = inplines[rind++ % (inplines.length)];
      }
      med.add(candi);
    }
    med.shuffle();
    return med;
  }

  List<String> pop_hard(List<String> inplines) {
    List<String> hard = [];
    // make sure minimum 4 fouls + 1 3SECVIOL + 1 turnover
    for (int i = 0; i < 5; i++) {
      // 5 FOULS
      int rind = r.nextInt(inplines.length);

      String candi = inplines[rind];
      while (!(candi.split(',')[2] == '6' || candi.split(',')[2] == '5')) {
        candi = inplines[rind++ % inplines.length];
      }
      hard.add(candi);
    }
    for (int i = 0; i < 3; i++) {
      // 3 RANDOM
      String candi = inplines[r.nextInt(inplines.length)];
      hard.add(candi);
    }

    for (int i = 0; i < 1; i++) {
      // 1 3SECVIOL
      int rind = r.nextInt(inplines.length);

      String candi = inplines[rind];
      while (!((candi.split(',')[2] == '6' && candi.split(',')[3] == '17') ||
          (candi.split(',')[2] == '5' && candi.split(',')[3] == '8'))) {
        candi = inplines[rind++ % inplines.length];
      }
      hard.add(candi);
    }

    for (int i = 0; i < 1; i++) {
      // 1 GOALTEND
      int rind = r.nextInt(inplines.length);

      String candi = inplines[rind];
      while (!(candi.split(',')[2] == '7')) {
        candi = inplines[rind++ % inplines.length];
      }
      hard.add(candi);
    }
    hard.shuffle();
    return hard;
  }

  Future<String> loadAsset() async {
    //print(rootBundle);
    return await rootBundle.loadString('assets/gamedata.csv');
  }

  VideoPlayerController _controller(int index) {
    return _controllers[questions[index].split(',')[6]];
  }

  Future<void> _initController(int index) async {
    var controller =
        VideoPlayerController.network(questions[index].split(',')[6]);
    _controllers[questions[index].split(',')[6]] = controller;
    await controller.initialize();
  }

  void _stopController(int index) {
    _controller(index).removeListener(_listeners[index]);
    _controller(index).pause();
    _controller(index).seekTo(Duration(milliseconds: 0));
  }

  void _playController(int index) async {
    if (!_listeners.keys.contains(index)) {
      _listeners[index] = _listenerSpawner(index);
    }
    _controller(index).addListener(_listeners[index]);
    await _controller(index).setVolume(0);
    await _controller(index).play();
    setState(() {});
  }

  void _removeController(int index) {
    _controller(index).dispose();
    _controllers.remove(questions[index].split(',')[6]);
    _listeners.remove(index);
  }

  VoidCallback _listenerSpawner(index) {
    return () {
      int dur = _controller(index).value.duration.inMilliseconds;
      int pos = _controller(index).value.position.inMilliseconds;
      int buf = _controller(index).value.buffered.last.end.inMilliseconds;

      setState(() {
        vidpos = pos / dur;
        vidbuf = buf / dur;
      });
      if (dur - pos < 1) {
        if (index < 10) {
          submitAns(0);
        }
      }
    };
  }

  void onEventKey(RawKeyEvent event) async {
    // only active if video is being played
    //print("KEYPRESSEDDDD");
    if (event.runtimeType.toString() == 'RawKeyDownEvent') {
      if (event.isKeyPressed(LogicalKeyboardKey.space)) {
        submitAns(_controller(qnum).value.position.inMilliseconds);
      }
    }
  }

  void hackysubmitAns() {
    // for button lmfao cos it cant have input for some gotforsaken reason
    submitAns(_controller(qnum).value.position.inMilliseconds);
  }

  void submitAns(int ms) async {
    print(questions);
    if (ms > 0) {
      _controller(qnum).pause();
    }
    print(ms);

    realanstype = int.parse(questions[qnum].split(',')[4]);
    realans = double.parse(questions[qnum].split(',')[7]);

    playanstype = ms > 0 ? 1 : 0;
    playerans = ms / 1000.0;

    if (realanstype == 0) {
      if (playanstype == 0) {
        intermission = 1;
      } else {
        intermission = 3;
        numfails++;
      }
    } else {
      if (playanstype == 1) {
        if (playerans < realans && playerans + 1 > realans) {
          intermission = 1;
        } else if (playerans > realans && playerans - 2 < realans) {
          intermission = 2;
          totlate += playerans - realans;
        } else {
          intermission = 3;
          numfails++;
        }
      } else {
        intermission = 3;
        numfails++;
      }
    }
    print(intermission);
    await sleep_for_inter3();

    if (qnum < 10) {
      intermission = 0;
    }
    _nextVideo();
  }

  void _nextVideo() async {
    _stopController(qnum);
    if (qnum == 9) {
      //gameEnded = true;
    } else {
      if (qnum > 0) {
        _removeController(qnum - 1);
      } // save memory
      qnum++;

      _playController(qnum);
      /* if (qnum!=9){
      // PRELOAD
      _initController(qnum+1).whenComplete(() => null);
    }*/

    }
  }

  Future sleep_for_inter3() {
    return new Future.delayed(const Duration(seconds: 3), () => "1");
  }

  Future finalsleep() {
    return new Future.delayed(const Duration(seconds: 5), () => "2");
  }

  @override
  Widget build(BuildContext context) {
    final GameArguments args = ModalRoute.of(context).settings.arguments;
    // if no args, go back to welcome

    return RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: intermission == 0
            ? onEventKey
            : null, // only care abt keypresses when playing
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Visibility(
                // ALLGOOD
                visible: intermission == 1,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(width: 5),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      color: Colors.lightGreenAccent),
                  child: Center(
                    child: Column(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text("Not Bad...",
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none),
                                    textAlign: TextAlign.center))),
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.topCenter,
                                child:
                                    Text("You probably just got lucky though..",
                                        style: TextStyle(
                                          color: Colors.black,
                                          decoration: TextDecoration.none,
                                        ),
                                        textAlign: TextAlign.center))),
                        qnum != 9
                            ? Expanded(
                                flex: 2,
                                child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                        "Clip " +
                                            (qnum + 1).toString() +
                                            ":\n" +
                                            questions[qnum]
                                                .split(',')[9]
                                                .trim(),
                                        style: TextStyle(
                                            color: Colors.black,
                                            decoration: TextDecoration.none),
                                        textAlign: TextAlign.center)))
                            : Expanded(
                                flex: 2,
                                child: Column(children: [
                                  Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                          "Clip " +
                                              (qnum + 1).toString() +
                                              ":\n" +
                                              questions[qnum]
                                                  .split(',')[9]
                                                  .trim(),
                                          style: TextStyle(
                                              color: Colors.black,
                                              decoration: TextDecoration.none),
                                          textAlign: TextAlign.center)),
                                  GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/fin',
                                            arguments: EndArguments(
                                              numfails,
                                              totlate,
                                            ));
                                      },
                                      child: Container(
                                          margin: const EdgeInsets.all(30),
                                          decoration: BoxDecoration(
                                              border: Border.all(width: 5),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20.0)),
                                              color: Colors.white),
                                          child: Align(
                                              alignment: Alignment.center,
                                              child: Text("END GAME",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      decoration: TextDecoration
                                                          .none)))))
                                ]))
                      ],
                    ),
                  ),
                )),
            Visibility(
                // LATE
                visible: intermission == 2,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(width: 5),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      color: Colors.orange),
                  child: Center(
                    child: Column(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text("Well, better late than never...",
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none),
                                    textAlign: TextAlign.center))),
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                    "Whistle delayed by " +
                                        (playerans - realans)
                                            .toStringAsFixed(4) +
                                        "s!",
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none),
                                    textAlign: TextAlign.center))),
                        qnum != 9
                            ? Expanded(
                                flex: 2,
                                child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                        "Clip " +
                                            (qnum + 1).toString() +
                                            ":\n" +
                                            questions[qnum]
                                                .split(',')[9]
                                                .trim(),
                                        style: TextStyle(
                                            color: Colors.black,
                                            decoration: TextDecoration.none),
                                        textAlign: TextAlign.center)))
                            : Expanded(
                                flex: 2,
                                child: Column(children: [
                                  Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                          "Clip " +
                                              (qnum + 1).toString() +
                                              ":\n" +
                                              questions[qnum]
                                                  .split(',')[9]
                                                  .trim(),
                                          style: TextStyle(
                                              color: Colors.black,
                                              decoration: TextDecoration.none),
                                          textAlign: TextAlign.center)),
                                  GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/fin',
                                            arguments: EndArguments(
                                              numfails,
                                              totlate,
                                            ));
                                      },
                                      child: Container(
                                          margin: const EdgeInsets.all(30),
                                          decoration: BoxDecoration(
                                              border: Border.all(width: 5),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20.0)),
                                              color: Colors.white),
                                          child: Align(
                                              alignment: Alignment.center,
                                              child: Text("END GAME",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      decoration: TextDecoration
                                                          .none)))))
                                ]))
                      ],
                    ),
                  ),
                )),
            Visibility(
                // WRONG
                visible: intermission == 3,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(width: 5),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      color: Colors.red),
                  child: Center(
                    child: Column(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text("FAIL",
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none),
                                    textAlign: TextAlign.center))),
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(":(",
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none),
                                    textAlign: TextAlign.center))),
                        qnum != 9
                            ? Expanded(
                                flex: 2,
                                child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                        "Clip " +
                                            (qnum + 1).toString() +
                                            ":\n" +
                                            questions[qnum]
                                                .split(',')[9]
                                                .trim(),
                                        style: TextStyle(
                                            color: Colors.black,
                                            decoration: TextDecoration.none),
                                        textAlign: TextAlign.center)))
                            : Expanded(
                                flex: 2,
                                child: Column(children: [
                                  Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                          "Clip " +
                                              (qnum + 1).toString() +
                                              ":\n" +
                                              questions[qnum]
                                                  .split(',')[9]
                                                  .trim(),
                                          style: TextStyle(
                                              color: Colors.black,
                                              decoration: TextDecoration.none),
                                          textAlign: TextAlign.center)),
                                  GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/fin',
                                            arguments: EndArguments(
                                              numfails,
                                              totlate,
                                            ));
                                      },
                                      child: Container(
                                          margin: const EdgeInsets.all(30),
                                          decoration: BoxDecoration(
                                              border: Border.all(width: 5),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20.0)),
                                              color: Colors.white),
                                          child: Align(
                                              alignment: Alignment.center,
                                              child: Text("END GAME",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      decoration: TextDecoration
                                                          .none)))))
                                ]))
                      ],
                    ),
                  ),
                )),
            Visibility(
                // LATE
                visible: intermission == 4,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(width: 5),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      color: Colors.orange),
                  child: Center(
                    child: Column(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text("GAME OVER",
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none)))),
                        Expanded(
                            flex: 1,
                            child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                    "LATE! By " +
                                        (playerans - realans)
                                            .toStringAsFixed(4) +
                                        "s!",
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none)))),
                        Expanded(
                            flex: 2,
                            child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                    "Clip " +
                                        (qnum + 1).toString() +
                                        ":\n" +
                                        questions[qnum].split(',')[9].trim(),
                                    style: TextStyle(
                                        color: Colors.black,
                                        decoration: TextDecoration.none))))
                      ],
                    ),
                  ),
                )),
            Visibility(
                visible: intermission == 0,
                child: Column(children: [
                  Expanded(
                      flex: 4,
                      child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: _controller(qnum).value.initialized
                              ? AspectRatio(
                                  aspectRatio: 16.0 /
                                      9.0, // every video same aspect ratio
                                  child: questions.length > 0
                                      ? VideoPlayer(_controller(qnum))
                                      : null)
                              : Container())),
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          child: SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                  onTap: hackysubmitAns,
                                  child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20.0)),
                                          color: Colors.white),
                                      child: Align(
                                          alignment: Alignment.center,
                                          child: Text("FOUL",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  decoration: TextDecoration
                                                      .none))))))))
                ]))
          ],
        ));
  }
}

/*intermissionCard(BuildContext context) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        Future.delayed(Duration(seconds: 5), () {
          Navigator.of(context).pop(true);
        });
        return AlertDialog(
          title: Text('Title'),
        );
      });
}*/

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int dialog_choice = 0;


  void viewEasy(){
    setState((){
      dialog_choice = 2;
    });
  }

  void openHelpDialog(){
    openDialog(1);
  }

  void openEasyDialog(){
    openDialog(2);
  }

  void openMedDialog(){
    openDialog(3);
  }
  void openHardDialog(){
    openDialog(4);
  }
  void openHardenDialog(){
    openDialog(5);
  }
  void openDialog(int choice){
    setState((){dialog_choice = choice;});
  }
  /*void _incrementCounter() {
    setState(() {

    });
  }
*/
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/bg.png"), fit: BoxFit.cover)),
        width: double.infinity,
        height: double.infinity,
        child: Stack(children: [

          Align(
              alignment: Alignment.center,
              child: Row(
                children: [
                  Container(margin:const EdgeInsets.only(left:20),child:
                  ConstrainedBox(

                      constraints: const BoxConstraints(
                          maxHeight: 375,
                          maxWidth: 500,
                          minHeight: 100,
                          minWidth: 150),

                      //height:375,width:500,
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        children: [
                          GestureDetector(
                              onTap: openEasyDialog,
                              child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      border: Border.all(width: 5),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      color: Colors.white),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Text("EASY",
                                          style: TextStyle(
                                              color: Colors.black,
                                              decoration:
                                                  TextDecoration.none))))),
                          GestureDetector(
                              onTap: openMedDialog,
                              child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      border: Border.all(width: 5),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      color: Colors.white),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Text("MEDIUM",
                                          style: TextStyle(
                                              color: Colors.black,
                                              decoration:
                                                  TextDecoration.none))))),
                          GestureDetector(
                              onTap: openHardDialog,
                              child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      border: Border.all(width: 5),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      color: Colors.white),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Text("HARD",
                                          style: TextStyle(
                                              color: Colors.black,
                                              decoration:
                                                  TextDecoration.none))))),
                          GestureDetector(
                              onTap: openHardenDialog,
                              child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      border: Border.all(width: 5),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      color: Colors.white),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Text("HARDEN",
                                          style: TextStyle(
                                              color: Colors.black,
                                              decoration:
                                                  TextDecoration.none))))),
                        ],
                      ))),
                  Expanded(flex:1,child:Visibility(
                      // ALLGOOD
                      visible: dialog_choice > 0,
                      child: Container(
                          margin: const EdgeInsets.only(top: 100,bottom:100,left:40,right:40),
                          padding: const EdgeInsets.all(5),
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              border: Border.all(width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20.0)),
                              color: Colors.amberAccent),
                          child: Center(child: Column(children: [

                              Expanded(flex:1,child:(){
                            //TITLES

                                if(dialog_choice == 1){
                                  return(Text("Context & Help",style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }
                                if(dialog_choice == 2){
                                  return(Text("Easy Mode",style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }
                                if(dialog_choice == 3){
                                  return(Text("Medium Mode",style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }
                                if(dialog_choice == 4){
                                  return(Text("Hard Mode",style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }
                                if(dialog_choice == 5){
                                  return(Text("Harden Mode",style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.red,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }
                              }()),

                            Expanded(flex:6, child:SingleChildScrollView( child: (){
                                if(dialog_choice == 1){
                                  return(Text("The title of the project, \"AND ONE\", technically refers to a special type of play in basketball - where a player is fouled in the act of scoring, but scores anyways, and therefore has the opportunity to earn AN extra ONE point for his team by taking the foul throws. However, the phrase is now commonly screamed by players when they feel like they are being fouled, as a sort of war cry/exclamation to bring up energy levels while also letting the referees know of the player's belief that he was fouled.\n\nHowever, these requests are (as one can guess), ignored by the referees. As a result, emotional players and salty fans alike hold referees in contempt. As someone who watches an unhealthy amount of organised basketball since my 11 ankle ligament tears prevent me from actually playing any, I've always wondered how difficult it really is to be a referee.\n\nRead: very difficult.\n\n",style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }

                                if(dialog_choice == 2){
                                  return(Text("The game is simple - if you see a foul/violation/any stoppage of play, press the Spacebar or Click the \"FOUL\" button. There will be 10 random (out of a possible 9000+) clips playing consecutively, so stay alert! Don't call a foul too early, don't call a foul too late, and don't call a foul when there is no foul at all. P.S. No audio from the clips - that'd be too easy!\n\nEASY Difficulty is suitable for those who have 0 experience with basketball. \n\nEVERY CLIP will either be a successful score, OR a Shooting Foul. You score a basketball when you throw it and it lands through the opposing hoop. A shooting foul is committed when the offensive player is ALREADY in the act of shooting, and a defensive player makes \"illegal\" contact with the player. Illegal contact may mean that excessive force is used, the defender is \"impeding\" on the offensive player's space, or just generally if the defender has their hands on the offensive player WHILE SHOOTING.",style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }

                                if(dialog_choice == 3){
                                  return(Text("The game is simple - if you see a foul/violation/any stoppage of play, press the Spacebar or Click the \"FOUL\" button. There will be 10 random (out of a possible 9000+) clips playing consecutively, so stay alert! Don't call a foul too early, don't call a foul too late, and don't call a foul when there is no foul at all. P.S. No audio from the clips - that'd be too easy!\n\nMEDIUM Difficulty is suitable for those who have some experience with playing basketball - especially if it's mostly pick-up basketball.\n\nEVERY CLIP can now either be a shot attempt (score or miss), OR any Foul (Shooting, Personal, Offensive - violations eg. shot clock/3-second/backcourt do not count).\n\nMost recreational basketball players will probably know what these are - more importantly, they will know how ambiguous some of these foul calls may be.",style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }

                                if(dialog_choice == 4){
                                  return(Text("The game is simple - if you see a foul/violation/any stoppage of play, press the Spacebar or Click the \"FOUL\" button. There will be 10 random (out of a possible 9000+) clips playing consecutively, so stay alert! Don't call a foul too early, don't call a foul too late, and don't call a foul when there is no foul at all. P.S. No audio from the clips - that'd be too easy!\n\nHARD Difficulty is suitable for those who are familiar with some of the less commonly-seen fouls/rules in NBA basketball - you've likely watched a decent number of NBA games in your life, or maybe you've played a few NBA 2K video games.\n\nEVERY CLIP can now be literally any play in basketball that is tracked by the NBA, EXCEPT for Free Throws, Tips, Substitutions etc.\n\nGood Luck! :D",style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }

                                if(dialog_choice == 5){
                                  return(Text("This was gonna be a good meme I swear but getting + doing spectral analysis on all the clips from all games from 2020-21 season alone took my script 9 hours. Also I'm a one-man team :o. But this is legit going to be WIP, even after the hackathon!",style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,fontWeight: FontWeight.bold)));
                                }
                              }())),

                            Expanded(flex:1,child:
                            (){
                              if(dialog_choice == 1){
                                return GestureDetector(
                                    onTap: () {
                                      viewEasy();
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.only(left: 100, right: 100),
                                        decoration: BoxDecoration(
                                            border: Border.all(width: 5),
                                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                            color: Colors.white),
                                        child: Align(
                                            alignment: Alignment.center,
                                            child: Text("View Easy",
                                                style: TextStyle(
                                                    fontSize: 40,
                                                    color: Colors.black,
                                                    decoration: TextDecoration.none)))));
                              }
                              if(dialog_choice == 2){
                                return GestureDetector(
                                    onTap: () {
                                      diffchosen = 0;
                                      Navigator.pushNamed(context, '/game');
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.only(left: 100, right: 100),
                                        decoration: BoxDecoration(
                                            border: Border.all(width: 5),
                                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                            color: Colors.white),
                                        child: Align(
                                            alignment: Alignment.center,
                                            child: Text("Play Easy",
                                                style: TextStyle(
                                                    fontSize: 40,
                                                    color: Colors.black,
                                                    decoration: TextDecoration.none)))));
                              }

                              if(dialog_choice == 3){
                                return GestureDetector(
                                    onTap: () {
                                      diffchosen = 1;
                                      Navigator.pushNamed(context, '/game');
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.only(left: 100, right: 100),
                                        decoration: BoxDecoration(
                                            border: Border.all(width: 5),
                                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                            color: Colors.white),
                                        child: Align(
                                            alignment: Alignment.center,
                                            child: Text("Play Medium",
                                                style: TextStyle(
                                                    fontSize: 40,
                                                    color: Colors.black,
                                                    decoration: TextDecoration.none)))));
                              }
                              if(dialog_choice == 4){
                                return GestureDetector(
                                    onTap: () {
                                      diffchosen = 2;
                                      Navigator.pushNamed(context, '/game');
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.only(left: 100, right: 100),
                                        decoration: BoxDecoration(
                                            border: Border.all(width: 5),
                                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                            color: Colors.white),
                                        child: Align(
                                            alignment: Alignment.center,
                                            child: Text("Play Hard",
                                                style: TextStyle(
                                                    fontSize: 40,
                                                    color: Colors.black,
                                                    decoration: TextDecoration.none)))));
                              }
                              if(dialog_choice == 5){
                                return GestureDetector(
                                    onTap: () {1+1;
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.only(left: 100, right: 100),
                                        decoration: BoxDecoration(
                                            border: Border.all(width: 5),
                                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                            color: Colors.white),
                                        child: Align(
                                            alignment: Alignment.center,
                                            child: Text("WIP.",
                                                style: TextStyle(
                                                    fontSize: 40,
                                                    color: Colors.black,
                                                    decoration: TextDecoration.none)))));
                              }



                            }()
                            )



                          ]))))
                  )],
                // This trailing comma makes auto-formatting nicer for build methods.
              ))
        ,Align(
              alignment: Alignment.topCenter,
              child: Text("AAAND OOOONE!",
                  style: TextStyle(
                      fontSize: 80,
                      color: Colors.black,
                      decoration: TextDecoration.none))),
          Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                  margin: const EdgeInsets.all(20),
                  child: FloatingActionButton.extended(
                      onPressed: openHelpDialog,
                      heroTag: null,
                      icon: Icon(Icons.help_center),
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      label: Text(
                        'Context & Help',
                      )))),
          Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  margin: const EdgeInsets.all(20),
                  child: FloatingActionButton.extended(
                      heroTag: null,
                      icon: Icon(Icons.volume_mute_rounded),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.yellow,
                      label: Text(
                        '(IF U SEE THIS, WIP) Toggle Volume',
                      )))),]));
  }
}
