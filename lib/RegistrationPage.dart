import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:be_project/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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




void main() => runApp(RegistrationPage());
final username = TextEditingController();
bool _isUploading = true;
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
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: Center(


        child: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Container(
                padding: EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
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
                              'https://us.123rf.com/450wm/katflare/katflare1810/katflare181000027/116860015-vector-flat-voice-recognition-illustration-with-smartphone-screen-dynamic-microphone-icon-on-it-soun.jpg?ver=6'),
                          fit: BoxFit.fill
                      ),
                    ),
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.only(
                    left: 50.0, right: 50, top: 10),
                child: TextField(
                  controller: username,

                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    hintText: 'Enter Username',
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                    left: 50.0, right: 50, top: 10, bottom: 20),
                child: TextField(
                  controller: email,

                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email address',
                    hintText: 'Enter Email id',
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
                          isactive = !isactive;
                          if (isactive) {
                            playAudio();
                            startRecord();
                          } else {
                            stopRecord();
                            stopAudio();
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


              Padding(
                padding: const EdgeInsets.only(bottom: 150.0),
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
                            String filePathLocal = 'storage/emulated/0/Documents/$user/audio.mp3';
                            File file = File(filePathLocal);
                            List<int> audioDataFire = await file.readAsBytes();
                            //initState();
                            user = username.text;
                            FirebaseStorage storage = FirebaseStorage.instance;
                            var reference = storage.ref().child('audio/$user/audio.mp3');
                            var uploadTask = reference.putFile(file);
                            await uploadTask.whenComplete(() => print('File Uploaded'));
                            //delete user folder and audio file inside 'storage/emulated/0/Documents/$user/audio.mp3';
                            final path = 'storage/emulated/0/Documents/$user';
                            final audioFile = File('$path/audio.mp3');
                            final audioFile1 = File('$storage/emulated/0/Documents/audio.mp3');
                            if (await audioFile.exists()) {
                              await audioFile.delete();
                            }
                            if (await audioFile1.exists()) {
                              await audioFile1.delete();
                            }
                            final directory = Directory(path);
                            if (await directory.exists()) {
                              await directory.delete(recursive: true);
                            }
                            //check if the user exists in firebaseFirestore
                            //initState();
                            FirebaseFirestore.instance.collection('users').doc(user).get().then((value) {
                              if (value.exists) {
                                print('User already exists');
                                return showDialog(context: context, builder: (context) {
                                  return AlertDialog(
                                    title: Text('User already exists'),
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
                                print('User does not exist');
                                FirebaseFirestore.instance.collection('users').doc(user).set({
                                  'username': user,
                                  'email': email.text
                                }).then((value) {
                                  print('User added');
                                  print('User added');
                                  return showDialog(context: context, builder: (context) {
                                    return AlertDialog(
                                      title: Text('User added'),
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

                          },
                          child: Text(
                            "Register",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
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