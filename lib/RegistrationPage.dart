import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:be_project/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:record_mp3/record_mp3.dart';




Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) exit(1);
  };
  runApp( RegistrationPage());
}
bool audioexists = false;
final username = TextEditingController();
bool _isUploading = true;
bool isLoading = false;
final email = TextEditingController();
late bool isactive = false;
String statusText = "";
bool isComplete = false;
final storage = FirebaseStorage.instance;
late File audioFile;
var user = username.text;
final storageRef = storage.ref('audio');
final recorder = FlutterSoundRecorder();
class RegistrationPage extends StatefulWidget {
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}
class _RegistrationPageState extends State<RegistrationPage> {
// function to write data to firebase Users Collection
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  FlutterSoundRecorder flutterSoundRecorder = new FlutterSoundRecorder();
  late String audioFilePath;
  @override
  void initState() {
    super.initState();
    _initSpeech();
    username.addListener(_updateVariable);

  }
  void _updateVariable(){
    setState(() {
      user = username.text;
    });
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  bool showProgress = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text("Register a new account"),
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            setState(() {
              isLoading = false;
            });
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                Container(
                  padding: EdgeInsets.all(MediaQuery
                      .of(context)
                      .size
                      .width*0.1),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery
                        .of(context)
                        .size
                        .width*0.01),
                    child: Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.8,
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.3,
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
                  padding: EdgeInsets.only(
                      left: MediaQuery
                          .of(context)
                          .size
                          .width*0.15, right: MediaQuery
                      .of(context)
                      .size
                      .width*0.15, top: MediaQuery
                      .of(context)
                      .size
                      .width*0.022),
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

                Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery
                          .of(context)
                          .size
                          .width*0.15, right: MediaQuery
                      .of(context)
                      .size
                      .width*0.15, top: MediaQuery
                      .of(context)
                      .size
                      .width*0.04, bottom: MediaQuery
                      .of(context)
                      .size
                      .width*0.04),
                  child:
                  TextField(
                    controller: email,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple)),
                      labelText: 'Email address',
                      hintText: 'Enter Email id',
                      labelStyle: TextStyle(color: Colors.deepPurpleAccent),
                      hintStyle: TextStyle(color: Colors.purple[800]),
                      fillColor: Colors.purple[100],
                      focusColor: Colors.purple[100],
                      hoverColor: Colors.purple[100],
                    ),
                  ),
                ),
                StreamBuilder<RecordingDisposition>(
                    stream: recorder.onProgress,
                    builder: (context, snapshot) {
                      final duration = snapshot.hasData? snapshot.data!.duration : Duration.zero;
                      return TextButton(
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
                            }else if(email.text.isEmpty || email == null){
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Error"),
                                    content: Text("You must enter email first"),
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
                          } else {
                              audioexists=true;
                              isactive = !isactive;
                              if (isactive) {

                                playAudio();
                                startRecord();

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
                                child: Icon(Icons.mic, size: MediaQuery.of(context).size.width * 0.1, color: Colors.red),
                              ),
                              Visibility(
                                visible: isactive,
                                child: Text('Recording', style: TextStyle(
                                    color: Colors.black, fontSize: MediaQuery.of(context).size.width * 0.03),),
                              ),
                              Visibility(
                                visible: !isactive,
                                //icon for record button
                                child: Icon(Icons.mic, size: MediaQuery.of(context).size.width * 0.1, color: Colors.black),
                              ),


                            ],
                          )
                      );
                    }
                ),


                isLoading ? Center(child: Column(
                  children: [
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .width*0.022),
                    CircularProgressIndicator(),

                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .width*0.022),
                    Text("Please wait while we are uploading your voice",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),),

                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .width*0.022),
                  ],
                )):Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery
                      .of(context)
                      .size
                      .width*0.4),
                  child: Container(
                    width: MediaQuery.of(context).size.width*0.25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.purple),
                    child:Column(

                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () async {

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
                             else if(audioexists==false){
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
                              } else if(email.text.isEmpty || email == null){
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Error"),
                                      content: Text("You must enter email first"),
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
                              }
                              else if(audioexists==true){
                                setState(() {
                                  isLoading = true;
                                });
                              String filePathLocal = 'storage/emulated/0/Documents/$user/audio.mp3';
                              File file = File(filePathLocal);
                              List<int> audioDataFire = await file.readAsBytes();

                              user = username.text;

                                FirebaseStorage storage = FirebaseStorage
                                    .instance;
                                var reference = storage.ref().child(
                                    'audio/$user/audio.mp3');
                                var uploadTask = reference.putFile(file);
                                await uploadTask.whenComplete(() =>
                                    print('File Uploaded'));
                                //delete user folder and audio file inside 'storage/emulated/0/Documents/$user/audio.mp3';
                                final path = 'storage/emulated/0/Documents/$user';
                                final audioFile = File('$path/audio.mp3');
                                final audioFile1 = File(
                                    '$storage/emulated/0/Documents/audio.mp3');
                              setState(() {
                                isLoading = false;
                              });
                              if(await audioFile.exists()){
                                setState(() {
                                  isLoading = true;
                                });
                              }else{
                                  setState(() {
                                    isLoading = false;
                                  });

                              }





                              // if (await audioFile1.exists()) {
                              //   await audioFile1.delete();
                              // }
                              // if (await audioFile.exists()) {
                              //   await audioFile.delete();
                              // }
                              //
                              // final directory = Directory(path);
                              // if (await directory.exists()) {
                              //   await directory.delete(recursive: true);
                              // }
                              //check if the user exists in firebaseFirestore
                              //initState();
                              FirebaseFirestore.instance.collection('users').doc(user).get().then((value) {

                                if(user==null || user==" "){
                                  setState(() {
                                    isLoading = false;
                                  });
                                  return showDialog(context: context, builder: (context) {
                                    return AlertDialog(
                                      title: Text('User is null'),
                                      content: Text(
                                          'Please try again with a valid username'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {

                                            Navigator.of(context).pop();
                                          },
                                          child: Text('OK'),
                                        )
                                      ],
                                    );
                                  });
                                }

                                if (value.exists) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  print('User already exists');

                                  return showDialog(context: context, builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                      title: Text('User already exists', style: TextStyle(color: Colors.purple)),
                                      content: Text('Please try again with a different username'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('OK'),
                                        )
                                      ],
                                    );
                                  });

                                } else {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  print('User does not exist');
                                  FirebaseFirestore.instance.collection('users').doc(user).set({
                                    'username': user,
                                    'email': email.text
                                  }).then((value) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    print('User added');
                                    print('User added');

                                    return showDialog(context: context, builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                        title: Text('User added', style: TextStyle(color: Colors.purple)),
                                        content: Text('Registration successful'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('OK'),
                                          )
                                        ],
                                      );
                                    });
                                  });
                                }
                              });
                              setState(() {
                                isLoading = false;
                              });
                              }
                            },
                            child: Text(
                              "Register",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width*0.04,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),

                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    await uploadTask.whenComplete(() => print('File Uploaded')).then((value) => print('File not Uploaded'));
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







// if (documentSnapshot.exists) {
//   print('Document exists on the database');
//   showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Error"),
//           content: Text("Username already exists"),
//           actions: [
//             TextButton(
//               child: Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             )
//           ],
//         );
//       });
// } else {
//regex on username and email
//if username and email are valid then add to database
//else show error
// if (username.text.length < 6) {
//   showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Error"),
//           content: Text(
//               "Username should be atleast 6 characters"),
//           actions: [
//             TextButton(
//               child: Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             )
//           ],
//         );
//       });
// }
// else if (email.text.length < 6) {
//   showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Error"),
//           content: Text(
//               "Email should be atleast 6 characters"),
//           actions: [
//             TextButton(
//               child: Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             )
//           ],
//         );
//       });
// }
// } else if (!email.text.contains('@')) {
//   showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Error"),
//           content: Text("Email should contain @"),
//           actions: [
//             TextButton(
//               child: Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             )
//           ],
//         );
//       });
// } else if (!email.text.contains('.')) {
//   showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Error"),
//           content: Text("Email should contain ."),
//           actions: [
//             TextButton(
//               child: Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             )
//           ],
//         );
//       });
// }

//add to database
// FirebaseFirestore.instance
//     .collection('Users')
//     .doc(username.text)
//     .set({
// 'username': username.text,
// 'email': email.text,
//
// });