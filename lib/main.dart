import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(const MyApp());
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();
  @override
  void initState() {
    super.initState();
  }
  Future<void> initSpeechState() async {
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
      );
      if (hasSpeech) {
        _localeNames = await speech.locales();
        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Speech To Text'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            const HeaderWidget(),
            Container(
              child: Column(
                children: <Widget>[
                  InitSpeechWidget(_hasSpeech, initSpeechState),
                  SpeechControlWidget(_hasSpeech, speech.isListening,
                      startListening, stopListening, cancelListening),
                  SessionOptionsWidget(
                    _currentLocaleId,
                    _switchLang,
                    _localeNames,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: RecognitionResultsWidget(lastWords: lastWords, level: level),
            ),
            SpeechStatusWidget(speech: speech),
          ]),
        ),
      ),
    );
  }
  void startListening() {
    lastWords = '';
    lastError = '';
    speech.listen(
        listenFor: const Duration(minutes: 2),
        onResult: resultListener,
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: false,
        listenMode: ListenMode.deviceDefault);
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }
  void resultListener(SpeechRecognitionResult result) {

    setState(() {
      lastWords = '${result.recognizedWords}';
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {

    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {

    setState(() {
      lastStatus = '$status';
    });
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    if (kDebugMode) {
      print(selectedVal);
    }
  }

}
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tap On Initialize to start the app',
        style: TextStyle(fontSize: 22.0),
      ),
    );
  }
}
class InitSpeechWidget extends StatelessWidget {
  const InitSpeechWidget(this.hasSpeech, this.initSpeechState, {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final Future<void> Function() initSpeechState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: hasSpeech ? null : initSpeechState,
          child: const Text('Initialize'),
        ),
      ],
    );
  }
}
class SpeechControlWidget extends StatelessWidget {
  const SpeechControlWidget(this.hasSpeech, this.isListening,
      this.startListening, this.stopListening, this.cancelListening,
      {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final bool isListening;
  final void Function() startListening;
  final void Function() stopListening;
  final void Function() cancelListening;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed:!hasSpeech || isListening ? null : startListening,
          child: const Text('Start'),
        ),
        TextButton(
          onPressed: isListening ? stopListening : null,
          child: const Text('Stop'),
        ),
        TextButton(
          onPressed: isListening ? cancelListening : null,
          child: const Text('Cancel'),
        )
      ],
    );
  }
}
class SessionOptionsWidget extends StatelessWidget {
  const SessionOptionsWidget(
      this.currentLocaleId,
      this.switchLang,
      this.localeNames,
      {Key? key})
      : super(key: key);

  final String currentLocaleId;
  final void Function(String?) switchLang;
  final List<LocaleName> localeNames;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              const Text('Language: '),
              DropdownButton<String>(
                onChanged: (selectedVal) => switchLang(selectedVal),
                value: currentLocaleId,
                items: localeNames
                    .map(
                      (localeName) => DropdownMenuItem(
                    value: localeName.localeId,
                    child: Text(localeName.name),
                  ),
                )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class RecognitionResultsWidget extends StatelessWidget {
  const RecognitionResultsWidget({
    Key? key,
    required this.lastWords,
    required this.level,
  }) : super(key: key);

  final String lastWords;
  final double level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Center(
          child: Text(
            'Result',
            style: TextStyle(fontSize: 32.0,fontWeight: FontWeight.w400),
          ),
        ),
        SizedBox(height: 10,),
        Expanded(
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height*0.4,
                  width: MediaQuery.of(context).size.width*0.8,
                  color: Theme.of(context).selectedRowColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 10),
                    child: SelectableText(
                      lastWords,
                      style: TextStyle(
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                bottom: MediaQuery.of(context).size.height*0.13,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            blurRadius: .26,
                            spreadRadius: level * 1.5,
                            color: Colors.black.withOpacity(.05))
                      ],
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () => null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class SpeechStatusWidget extends StatelessWidget {
  const SpeechStatusWidget({
    Key? key,
    required this.speech,
  }) : super(key: key);

  final SpeechToText speech;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Theme.of(context).backgroundColor,
      child: Center(
        child: speech.isListening
            ? const Text(
          "I'm listening...",
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : const Text(
          'Not listening',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}