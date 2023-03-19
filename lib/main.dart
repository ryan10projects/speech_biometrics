import 'dart:convert';
import 'dart:io';
import 'package:sizer/sizer.dart';
import 'package:be_project/Record.dart';
import 'package:be_project/RegistrationPage.dart';
import 'package:be_project/SecondRoute.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_sound/flutter_sound.dart';

var result = "";
bool check = false;
late bool isactive = false;
var recordFilePath;
final username = TextEditingController();
FlutterSound flutterSound = FlutterSound();
bool isRecording = false;
bool isLoading = false;
String recordingPath = '';
String user = username.text;
bool audioexists = false;
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp( MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech authentication',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String statusText = "";
  bool isComplete = false;

  @override
  void initState() {
    super.initState();
    username.addListener(_updateVariable);
  }

  void _updateVariable() {
    setState(() {
      user = username.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery
                    .of(context)
                    .size
                    .width*0.1),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.7,
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * 0.28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: NetworkImage(
                            'https://firebasestorage.googleapis.com/v0/b/be-project-2d61a.appspot.com/o/icon.png?alt=media&token=697f3b5e-81a9-4a14-aa3b-da31e942c3f6'),
                        fit: BoxFit.fill
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding:  EdgeInsets.only(
                  left: MediaQuery
                      .of(context)
                      .size
                      .width*0.1, right: MediaQuery
                  .of(context)
                  .size
                  .width*0.1, top: MediaQuery
                  .of(context)
                  .size
                  .width*0.1),
              child: TextField(
                controller: username,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple)),
                  labelText: 'Username',
                  hintText: 'Enter Username',
                  labelStyle: TextStyle(color: Colors.deepPurpleAccent),
                  hintStyle: TextStyle(color: Colors.purple[800]),
                  fillColor: Colors.purple[100],
                  focusColor: Colors.purple[100],
                  hoverColor: Colors.purple[100],
                ),
              ),
            ),


            TextButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(
                      Colors.blue),
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered))
                        return Colors.blue.withOpacity(0.04);
                      if (states.contains(MaterialState.focused) ||
                          states.contains(MaterialState.pressed))
                        return Colors.blue.withOpacity(0.12);
                      return null; // Defer to the widget's default.
                    },
                  ),
                ),
                onPressed: () async {
                  if (username == null || username.text.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Error"),
                          content: Text("Username cannot be empty"),
                          actions: [
                            TextButton(
                              child: Text("OK"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
                  else {
                    isactive = !isactive;
                    if (isactive) {

                      playAudio();
                      startRecord();
                      audioexists=true;
                    } else {
                      stopRecord();
                      stopAudio();
                    }
                  }
                },
                child: Column(
                  children: [

                    Visibility(
                      visible: isactive,
                      child: GestureDetector(
                          child: Icon(Icons.mic, size: MediaQuery
                              .of(context)
                              .size
                              .width * 0.1, color: Colors.red)),
                    ),
                    Visibility(
                      visible: isactive,
                      child: Text('Recording', style: TextStyle(
                          color: Colors.black, fontSize: MediaQuery
                          .of(context)
                          .size
                          .width * 0.03),),
                    ),
                    Visibility(
                      visible: !isactive,
                      //icon for record button
                      child: Icon(Icons.mic, size: MediaQuery
                          .of(context)
                          .size
                          .width * 0.1, color: Colors.black),
                    ),

                  ],
                )
            ),


            isLoading ? Center(child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height*0.01),
                CircularProgressIndicator(),

                SizedBox(height: MediaQuery.of(context).size.height*0.02),
                Text("Please wait while we are processing your voice",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),),

                SizedBox(height:MediaQuery.of(context).size.height*0.2),
              ],
            )) : Row(
              children: [
                SizedBox(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.26,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery
                      .of(context)
                      .size
                      .width*0.6),
                  child: GestureDetector(
                    onTap: () async {

                      user = username.text;
                      if (username == null || username.text.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Error"),
                              content: Text("Username cannot be empty"),
                              actions: [
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                     return;
                      }else if(audioexists==false){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Error"),
                              content: Text("You must record audio first"),
                              actions: [
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        return;
                    } else  {
                        setState(() {
                          isLoading = true;
                        });
                        FirebaseFirestore.instance.collection("users")
                            .doc(user)
                            .get()
                            .then((doc) async {
                          if (doc.exists) {
                            print("usss");

                            //  final filePath = 'storage/emulated/0/Documents/audio.mp3';
                            //    File file2 = File(filePath);
                            //recordFilePath = getFilePath();
                            //List<int> audioData = utf8.encode(recordFilePath);
                            // if (audioData != null) {
                            //   await file2.writeAsBytes(audioData);
                            // }
                            String filePathLocal = 'storage/emulated/0/Documents/$user/audio.mp3';
                            File file = File(filePathLocal);
                            List<int> audioDataFire = await file.readAsBytes();
                            // FirebaseStorage storage = FirebaseStorage.instance;
                            //
                            // var reference = storage.ref().child('audio/$user/audio.mp3');
                            // var uploadTask = reference.putFile(file);
                            // await uploadTask.whenComplete(() => print('File Uploaded'));

//                       File audio = File(recordingPath.toString());
//                       //send audio file to an http server
//                       // The server URL
                            final String url = 'https://beproject.loca.lt/';
                            //add a timer to wait for the server to process the audio file
                            final http.MultipartRequest request = http
                                .MultipartRequest('POST', Uri.parse(url));
// Add the audio file to the request
                            final file3 = await http.MultipartFile.fromPath(
                                'file', file.path);
                            request.files.add(file3);
                            // Add the username to the request
                            user = username.text;
                            request.fields['username'] = user;
// Send the request

                            final response = await request.send();
                            // Check the response
                            if (response.statusCode == HttpStatus.ok) {
                              print("Uploaded");
                              FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user)
                                  .get()
                                  .then((documentSnapshot) {
                                if (documentSnapshot.exists &&
                                    documentSnapshot["isSignedIn"] == true) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  showDialog(
                                      context: context, builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              20.0)),
                                      title: Text("User logged in!",
                                          style: TextStyle(
                                              color: Colors.purple)),
                                      content: Text("Welcome back $user!",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      actions: [
                                        TextButton(onPressed: () {
                                          Navigator.pop(context);
                                        },
                                            child: Text("OK", style: TextStyle(
                                                color: Colors.purple)))
                                      ],
                                    );
                                  });
                                  // Document exists and signedin field is true
                                } else {
                                  setState(() {
                                    isLoading = false;
                                    print(isLoading);
                                  });
                                  showDialog(
                                      context: context, builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                          "Try again, your voice did not match!",
                                          style: TextStyle(
                                              color: Colors.purple)),
                                      content: Text(
                                          "Failed to match audio for $user!"),
                                      actions: [
                                        TextButton(onPressed: () {
                                          Navigator.pop(context);
                                        },
                                            child: Text("OK", style: TextStyle(
                                                color: Colors.purple)))
                                      ],
                                    );
                                  });
                                  // Document does not exist or signedin field is false
                                }
                              });
                            } else {
                              print('Failed to upload file');
                            }
                          } else {
                            setState(() {
                              isLoading = false;
                            });
                            print("User with ID " + user + " doesn't exists!");
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            20.0)),
                                    title: Text("User with ID " + user +
                                        " doesn't exists!",
                                        style: TextStyle(color: Colors.purple)),
                                    content: Text(
                                        "Please enter a different username",
                                        style: TextStyle(color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                    backgroundColor: Colors.grey[200],
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text("OK", style: TextStyle(
                                            color: Colors.purple)),
                                      )
                                    ],
                                  );
                                }

                            );
                          }
                        });


// // Close the HTTP client
                        //listen to request
                        //store the user  in firebase firestore
                        //store the audio file in firebase storage
                        // Add a new document with the user's name as the key

                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.22,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(MediaQuery
                              .of(context)
                              .size
                              .width*0.22),
                          color: Colors.purple),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(MediaQuery
                                .of(context)
                                .size
                                .width*0.022),
                            child: Text("LOGIN", textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),),
                          ),
                          // create a text widget and print result

                        ],
                      ),
                    ),
                  ),
                ),


                SizedBox(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.03,
                ),


                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery
                      .of(context)
                      .size
                      .width*0.6),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationPage()),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.22,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(MediaQuery
                              .of(context)
                              .size
                              .width*0.22),
                          color: Colors.purple),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(MediaQuery
                                .of(context)
                                .size
                                .width*0.025),
                            child: Text("REGISTER", textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),),
                          ),
                          // create a text widget and print result

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed:
      //   // If not yet listening for speech start, otherwise stop
      //   _speechToText.isNotListening ? _startListening : _stopListening,
      //   tooltip: 'Listen',
      //   child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      // ),
    );
  }

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      statusText = "Recording...";
      recordFilePath = await getFilePath();
      isComplete = false;
      RecordMp3.instance.start(recordFilePath, (type) {
        statusText = "Record error--->$type";
        setState(() {});
      });
    } else {
      statusText = "No microphone permission";
    }
    setState(() {});
  }

  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "Recording...";
        setState(() {});
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "Recording pause...";
        setState(() {});
      }
    }
  }

  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    if (s) {
      statusText = "Record complete";
      isComplete = true;
      setState(() {});
    }
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "Recording...";
      setState(() {});
    }
  }


  void play() {
    if (recordFilePath != null && File(recordFilePath!).existsSync()) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(recordFilePath);
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = "storage/emulated/0/Documents/$user";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/audio.mp3";
  }

  FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> uploadFile(String filePath, String username) async {
    Directory tempDir = await getTemporaryDirectory();
    File file = File('${tempDir.path}/audio.mp3');
    var reference = storage.ref().child('audio/$username/audio.mp3');
    print('Uploading file...');
    var uploadTask = reference.putFile(File(filePath));
    await uploadTask.whenComplete(() => print('File Uploaded')).then((value) =>
        print('File not Uploaded'));
  }

  Future<void> playAudio() async {
    AudioPlayer player = AudioPlayer();
    String audioasset = "assets/start.mp3";
    ByteData bytes = await rootBundle.load(audioasset); //load sound from assets
    Uint8List  soundbytes = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    int result = await player.playBytes(soundbytes);
    if(result == 1){ //play success
      print("Sound playing successful.");
    }else{
      print("Error while playing sound.");
    }
  }
  Future<void> stopAudio() async {
    AudioPlayer player = AudioPlayer();
    String audioasset = "assets/stop.mp3";
    ByteData bytes = await rootBundle.load(audioasset); //load sound from assets
    Uint8List  soundbytes = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    int result = await player.playBytes(soundbytes);
    if(result == 1){ //play success
      print("Sound playing successful.");
    }else{
      print("Error while playing sound.");
    }
  }
}

