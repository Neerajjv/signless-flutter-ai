import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'gemini_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(SpeechToTextApp());
}

class SpeechToTextApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _transcribedText = "";
  String _aiResponse = "";
  List<String> _choices = [];
  String _selectedSentiment = "";
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.speech,
    ].request();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
        });
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _askSentiment() {
    setState(() => _aiResponse = "How would you like to respond?");
  }

  void _fetchResponse(String sentiment) async {
    if (_transcribedText.isEmpty) return;
    setState(() {
      _aiResponse = "Generating responses...";
      _choices = [];
      _selectedSentiment = sentiment;
    });

    Map<String, dynamic> result = await _geminiService.getResponseWithChoices(_transcribedText, sentiment);

    setState(() {
      _aiResponse = "Select a response:";
      _choices = result["choices"];
    });
  }

  void _speak(String text) async {
    await _tts.speak(text);

    // When speaking completes, reset and restart listening
    _tts.setCompletionHandler(() {
      setState(() {
        _transcribedText = "";
        _aiResponse = "";
        _choices = [];
        _selectedSentiment = "";
      });

      _startListening(); // Automatically start new input
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Project SignLess", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.blueGrey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  blur: 10,
                  color: Colors.white.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text("Press the button and start speaking:", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)),
                        SizedBox(height: 10),
                        Text(
                          _transcribedText.isEmpty ? "Listening..." : _transcribedText,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_transcribedText.isNotEmpty && _aiResponse.isEmpty)
                  ElevatedButton(
                    onPressed: _askSentiment,
                    child: Text("How would you like to respond?"),
                  ),
                if (_aiResponse.isNotEmpty)
                  Text(_aiResponse, style: GoogleFonts.poppins(fontSize: 18)),
                if (_aiResponse == "How would you like to respond?") ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _fetchResponse("positive"),
                        child: Text("Positive"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => _fetchResponse("negative"),
                        child: Text("Negative"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                        onPressed: () => _fetchResponse("neutral"),
                        child: Text("Neutral"),
                      ),
                    ],
                  ),
                ],
                if (_choices.isNotEmpty) ...[
                  Column(
                    children: _choices.map((choice) {
                      return ElevatedButton(
                        onPressed: () => _speak(choice),
                        child: Text(choice),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
