import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_keiko/widgets/bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PomodoroTimer extends StatefulWidget {
  final int workMinutes;
  final int breakMinutes;
  final int cycles;
  final bool firstStart;
  final String workSound;
  final String breakSound;

  const PomodoroTimer({
    super.key,
    required this.workMinutes,
    required this.breakMinutes,
    required this.cycles,
    this.firstStart = false,
    required this.workSound,
    required this.breakSound,
  });

  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  late int minutes;
  late int seconds;
  late int remainingCycles;
  int completedWorkCycles = 0;
  Timer? _timer;
  bool isWorking = true;
  bool isRunning = false;
  bool isPreparing = false;
  bool hasPreparedOnce = false;
  int prepSeconds = 3;
  late List<String> cycleStates; //Ciclo estados bajo temporizador
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool musicMuted = true; // Nuevo estado para mutear/desmutear la música
  String selectedMusic = 'meditacion.mp3';
  double musicVolume = 0.5;
  double currentVolume = 0.5; // Almacena el volumen real cuando está desmuteado

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool showFeedbackPopup = true;
  String? selectedEmoji;
  bool noShowFeedbackChecked = false;

  final Map<String, String> musicOptions = {
    'meditacion.mp3': 'Meditación Tranquila',
    'lluvia.mp3': 'Sonidos de Lluvia',
    'fogata.mp3': 'Fogata Relajante',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _audioPlayer.setVolume(0.5); // Volumen predeterminado para notificaciones
    _musicPlayer.setVolume(musicVolume);
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    remainingCycles = widget.cycles;
    cycleStates =
        List.generate(widget.cycles, (_) => '🐟'); // Inicializa ciclos
    _startBackgroundMusic();
    _resetPomodoro(); //revisar
  }

  @override
  void dispose() {
    _stopBackgroundMusic(); // Detiene el sonido al salir de la página
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      showFeedbackPopup = prefs.getBool('showFeedbackPopup') ?? true;
    });
  }

  Future<void> _setNoShowFeedback() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFeedbackPopup', !noShowFeedbackChecked);
  }

  void _showFeedbackDialog() {
    if (!showFeedbackPopup) return;

    TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¿Cómo te sientes después de la sesión?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEmojiButton(context, Icons.sentiment_very_satisfied,
                          'happy', Colors.green, setModalState),
                      _buildEmojiButton(context, Icons.sentiment_neutral,
                          'neutral', Colors.orange, setModalState),
                      _buildEmojiButton(
                          context,
                          Icons.sentiment_very_dissatisfied,
                          'sad',
                          Colors.red,
                          setModalState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (selectedEmoji != null)
                    TextField(
                      controller: commentController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Comentario (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: noShowFeedbackChecked,
                            onChanged: (bool? value) {
                              setModalState(() {
                                noShowFeedbackChecked = value ?? false;
                              });
                            },
                          ),
                          const Text('No volver a preguntar'),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (noShowFeedbackChecked) {
                            _setNoShowFeedback();
                          }
                          print('Emoji seleccionado: $selectedEmoji');
                          print('Comentario: ${commentController.text}');
                          Navigator.pop(context);
                        },
                        child: const Text('Enviar'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmojiButton(BuildContext context, IconData icon,
      String emojiType, Color color, StateSetter setModalState) {
    return IconButton(
      icon: Icon(
        icon,
        size: 40,
        color: selectedEmoji == emojiType ? color : Colors.grey,
      ),
      onPressed: () {
        setModalState(() {
          selectedEmoji = emojiType;
        });
      },
    );
  }

  Future<void> _saveFeedback(String? emoji, String comment) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("Usuario no autenticado. No se puede guardar el feedback.");
      return;
    }

    try {
      final feedbackData = {
        'userId': user.uid,
        'emoji': emoji,
        'comment': comment.trim(),
        'timestamp': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('feedback_sessions')
          .add(feedbackData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback enviado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el feedback: $e')),
      );
    }
  }

  void _startBackgroundMusic() async {
    await _musicPlayer.setVolume(musicMuted ? 0.0 : currentVolume);
    await _musicPlayer.play(AssetSource('music/$selectedMusic'));
  }

  Future<void> _stopBackgroundMusic() async {
    await _musicPlayer.stop(); // Detiene la música
  }

  void _toggleMusicMute() {
    setState(() {
      musicMuted = !musicMuted;
      _musicPlayer.setVolume(musicMuted ? 0.0 : currentVolume);
    });
  }

  void _playSound(String filePath) async {
    if (soundEnabled) {
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.play(AssetSource('sounds/$filePath'));
    }
  }

  void _startPreparationTimer() {
    if (!hasPreparedOnce) {
      setState(() {
        isPreparing = true;
        prepSeconds = 3;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (prepSeconds > 1) {
            prepSeconds--;
          } else {
            isPreparing = false;
            hasPreparedOnce = true;
            _timer!.cancel();
            _startTimer();
          }
        });
      });
    } else {
      _startTimer();
    }
  }

  void _resetPomodoro() {
    setState(() {
      remainingCycles = widget.cycles;
      isWorking = true;
      minutes = widget.workMinutes;
      seconds = 0;
      _timer?.cancel();
      isRunning = false;
      isPreparing = false;
      hasPreparedOnce = false;
      cycleStates =
          List.generate(widget.cycles, (_) => '🐟'); // Reinicia ciclos
    });
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Reinicio"),
          content: const Text(
              "¿Estás seguro de que quieres reiniciar el temporizador?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                _resetPomodoro(); // Llamar a tu método de reinicio
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Reiniciar"),
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() {
      isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (seconds == 0) {
          if (minutes == 0) {
            // Al finalizar un ciclo
            if (isWorking && remainingCycles > 0) {
              print("Trabajo terminado. Cambiando a descanso...");
              _playSound(widget.workSound);
              _completeWorkCycle();
            } else if (!isWorking && remainingCycles > 0) {
              print("Descanso terminado. Cambiando al siguiente ciclo...");
              _playSound(widget.breakSound);
              _completeBreakCycle();
            } else {
              // Fin del temporizador
              print("Todos los ciclos completados.");
              _timer!.cancel();
              isRunning = false;
              if (vibrationEnabled) Vibration.vibrate(duration: 1000);
              _playSound(widget.workSound);
              _showFeedbackDialog();
              _resetPomodoro();
            }
          } else {
            // Reducir minutos
            minutes--;
            seconds = 59;
          }
        } else {
          // Reducir segundos
          seconds--;
        }
      });
    });
  }

  void _completeWorkCycle() {
    setState(() {
      int currentCycle = widget.cycles - remainingCycles;
      cycleStates[currentCycle] = '🌊'; // Marca como "vaso medio"
      print("Ciclo $currentCycle: trabajo terminado, estado -> 🌊");

      isWorking = false; // Cambia a descanso
      minutes = widget.breakMinutes;
      seconds = 0;
    });
    if (vibrationEnabled) Vibration.vibrate(duration: 500);
    _playSound(widget.workSound);
  }

  void _completeBreakCycle() {
    setState(() {
      int currentCycle = widget.cycles - remainingCycles;
      cycleStates[currentCycle] = '🐉'; // Marca como "vaso lleno"
      print("Ciclo $currentCycle: descanso terminado, estado -> 🐉");

      remainingCycles--; // Reduce ciclos restantes
      print("Ciclos restantes: $remainingCycles");

      if (remainingCycles > 0) {
        int nextCycle = widget.cycles - remainingCycles;
        cycleStates[nextCycle] =
            '🐟'; // Inicia el siguiente ciclo con "vaso vacío"
        print("Ciclo $nextCycle: iniciado, estado -> 🐟");

        isWorking = true;
        minutes = widget.workMinutes;
        seconds = 0;
      } else {
        // Todos los ciclos completados
        _timer?.cancel();
        isRunning = false;
        if (vibrationEnabled) Vibration.vibrate(duration: 1000);
        _playSound(widget.breakSound);
        _showFeedbackDialog();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void _toggleSound() {
    setState(() {
      soundEnabled = !soundEnabled;
    });
  }

  void _toggleVibration() {
    setState(() {
      vibrationEnabled = !vibrationEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Fondo dinámico
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                isRunning
                    ? 'assets/image/pomodoro_start.jpg' // Fondo cuando está en marcha
                    : 'assets/image/pomodoro_pause.jpg', // Fondo cuando está pausado
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        // Contenido principal
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6), // Fondo semitransparente
              borderRadius: BorderRadius.circular(16), // Bordes redondeados
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWorking ? '¡A trabajar!' : '¡Descanso!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Temporizador con círculo animado
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _getProgress(), // Progreso del temporizador
                        strokeWidth: 10,
                        backgroundColor:
                            Colors.grey.withOpacity(0.2), // Fondo del círculo
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isWorking
                              ? Colors.red // Color del progreso (modo trabajo)
                              : Colors
                                  .blue, // Color del progreso (modo descanso)
                        ),
                      ),
                    ),
                    Text(
                      isPreparing
                          ? 'Prepárate\n${prepSeconds.toString()}'
                          : '${_formatTime(minutes)}:${_formatTime(seconds)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Indicador de ciclos
                if (widget.cycles > 1)
                  Wrap(
                    alignment: WrapAlignment.center, // Centra los elementos
                    spacing: 8, // Espaciado horizontal entre emojis
                    runSpacing: 8, // Espaciado vertical si hay desbordamiento
                    children: cycleStates.map((emoji) {
                      String imagePath;
                      switch (emoji) {
                        case '🐟':
                          imagePath = 'assets/image/vaso_vacio.png';
                          break;
                        case '🌊':
                          imagePath = 'assets/image/vaso_medio.png';
                          break;
                        case '🐉':
                          imagePath = 'assets/image/vaso_lleno.png';
                          break;
                        default:
                          imagePath = 'assets/image/vaso_vacio.png';
                      }
                      return Image.asset(
                        imagePath,
                        width: 36,
                        height: 36,
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),
                // Botones de inicio y reinicio
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        isRunning ? Icons.pause : Icons.play_arrow,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: isPreparing
                          ? null
                          : (isRunning ? _pauseTimer : _startPreparationTimer),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: isPreparing ? null : _showResetDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Controles de vibración, sonido, música y volumen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        soundEnabled ? Icons.volume_up : Icons.volume_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          soundEnabled = !soundEnabled;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        vibrationEnabled
                            ? Icons.vibration
                            : Icons.phone_android,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          vibrationEnabled = !vibrationEnabled;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        musicMuted ? Icons.headset_off : Icons.headphones,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMusicMute,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Selector de música
                DropdownButton<String>(
                  value: selectedMusic,
                  dropdownColor: Colors.black87, // Fondo del Dropdown
                  style:
                      const TextStyle(color: Colors.white), // Color del texto
                  items: musicOptions.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMusic = value!;
                      _startBackgroundMusic();
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Control de volumen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Volumen de la Música',
                      style: TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: musicVolume,
                        onChanged: (value) {
                          setState(() {
                            musicVolume = value;
                            currentVolume = value;
                            if (!musicMuted) {
                              _musicPlayer.setVolume(musicVolume);
                            }
                          });
                        },
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ]),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

// Método para calcular el progreso del temporizador
  double _getProgress() {
    // Tiempo total en segundos según si es trabajo o descanso
    final totalSeconds =
        isWorking ? widget.workMinutes * 60 : widget.breakMinutes * 60;
    // Tiempo restante en segundos
    final remainingSeconds = (minutes * 60) + seconds;
    // Calcula el progreso como un valor entre 0.0 y 1.0
    return 1 - (remainingSeconds / totalSeconds);
  }

// Método para formatear el tiempo
  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }
}
