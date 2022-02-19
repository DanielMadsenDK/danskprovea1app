import 'dart:async';
import 'dart:math';

import 'package:just_audio/just_audio.dart';
import 'package:flutter_quiz_app/models/question.dart';
import 'package:flutter_quiz_app/models/quiz.dart';

typedef OnQuizNext = void Function(Question question);
typedef OnQuizCompleted = void Function(
    Quiz quiz, double totalCorrect, Duration takenTime);
typedef OnQuizStop = void Function(Quiz quiz);
typedef OnQuizTimerStart = void Function();
typedef OnQuizPause = void Function();
typedef OnQuizResume = void Function();
typedef OnQuizDispose = void Function();

class QuizEngine {
  int questionIndex = 0;
  int questionDuration = 0;
  bool isRunning = false;
  bool takeNewQuestion = true;
  bool audioQuestionPlaying = false;
  bool isAudioQuestion = false;
  DateTime examStartTime = DateTime.now();
  DateTime questionStartTime = DateTime.now();
  AudioPlayer audioPlayer = AudioPlayer();

  Quiz quiz;
  List<int> takenQuestions = [];
  Map<int, bool> questionAnswer = {};

  OnQuizNext onNext;
  OnQuizCompleted onCompleted;
  OnQuizStop onStop;
  OnQuizTimerStart onQuizTimerStart;

  QuizEngine(this.quiz, this.onNext, this.onCompleted, this.onStop,
      this.onQuizTimerStart);

  void start() async {
    questionIndex = 0;
    questionDuration = 0;
    takenQuestions = [];
    questionAnswer = {};
    isRunning = true;
    takeNewQuestion = true;

    Future.doWhile(() async {
      Question? question;
      questionStartTime = DateTime.now();
      examStartTime = DateTime.now();

      do {
        if (takeNewQuestion) {
          question = _nextQuestion(quiz, questionIndex);
          if (question != null) {
            isAudioQuestion = question.audio.isNotEmpty;
            audioQuestionPlaying = false;
            takeNewQuestion = false;
            questionIndex++;

            if (!isAudioQuestion) {
              onNext(question);
              questionStartTime = DateTime.now();
              onQuizTimerStart;
            } else {
              onNext(question);

              await audioPlayer.setAsset(question.audio);
              await audioPlayer.play();
              questionStartTime = DateTime.now();
              if (!takeNewQuestion) {
                onQuizTimerStart();
              }
            }
          }
        }
        if (question != null ||
            (isAudioQuestion &&
                !audioPlayer.playerState.playing &&
                question != null)) {
          var questionTimeEnd =
              questionStartTime.add(Duration(seconds: question!.duration));
          var timeDiff = questionTimeEnd.difference(DateTime.now()).inSeconds;
          if (timeDiff <= 0) {
            takeNewQuestion = true;
            disposeAudioplayer(true);
          }
        }

        if (question == null ||
            quiz.questions.length == questionAnswer.length) {
          double totalCorrect = 0.0;
          questionAnswer.forEach((key, value) {
            if (value == true) {
              totalCorrect++;
            }
          });
          var takenTime = examStartTime.difference(DateTime.now());
          onCompleted(quiz, totalCorrect, takenTime);
        }

        await Future.delayed(Duration(milliseconds: 900));
      } while (question != null && isRunning);
      return false;
    });
  }

  void disposeAudioplayer(bool recreate) {
    if (isAudioQuestion) {
      audioPlayer.stop();
      audioPlayer.dispose();
      if (recreate) {
        audioPlayer = AudioPlayer();
      }
    }
  }

  void stop() {
    takeNewQuestion = false;
    isRunning = false;
    onStop(quiz);
    disposeAudioplayer(false);
  }

  void next() {
    takeNewQuestion = true;
    disposeAudioplayer(true);
  }

  void updateAudioQuestionPlaying(bool state) {
    if (!state) questionStartTime = DateTime.now();
    audioQuestionPlaying = state;
  }

  void updateAnswer(int questionIndex, int answer) {
    var question = quiz.questions[questionIndex];
    questionAnswer[questionIndex] = question.options[answer].isCorrect;
  }

  Question? _nextQuestion(Quiz quiz, int index) {
    while (true) {
      if (takenQuestions.length >= quiz.questions.length) {
        return null;
      }
      if (quiz.shuffleQuestions) {
        index = Random().nextInt(quiz.questions.length);
        if (takenQuestions.contains(index) == false) {
          takenQuestions.add(index);
          return quiz.questions[index];
        }
      } else {
        if (index >= quiz.questions.length) {
          return null;
        }
        return quiz.questions[index];
      }
    }
  }

  void onPause() async {
    if (isAudioQuestion) {
      await audioPlayer.pause();
    }
  }

  void onResume() async {
    if (isAudioQuestion) {
      await audioPlayer.play();
    }
  }

  void onDispose() {
    audioPlayer.stop();
    audioPlayer.dispose();
  }
}
