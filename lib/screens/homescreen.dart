import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' ;
import 'package:avatar_glow/avatar_glow.dart';
class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {

  late SpeechToText _speech;
  bool _isListening = false;
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  String _text = 'Press the button and start speaking';

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:  Scaffold(
        appBar: AppBar(
          title: Text('Speech To Text'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
          animate: _isListening,
          glowColor: Theme.of(context).primaryColor,
          endRadius: 75.0,
          duration: const Duration(milliseconds: 2000),
          repeatPauseDuration: const Duration(milliseconds: 100),
          repeat: true,
          child: FloatingActionButton(
            onPressed: _listen,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
            child: SelectableText(
               _text,
            ),
          ),
        ),
      ),
    );

  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(

        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenFor: Duration(seconds: 30),
          onResult: (val) => setState(() {
            _text = val.recognizedWords;


          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}