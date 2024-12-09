import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'pomodoro.dart';
import 'package:flutter_keiko/widgets/bottom_navigation.dart';

class PomodoroConfig extends StatefulWidget {
  const PomodoroConfig({super.key});

  @override
  _PomodoroConfigState createState() => _PomodoroConfigState();
}

class VolumeSlider extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const VolumeSlider({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Volumen'),
        Expanded(
          child: Slider(
            value: volume,
            onChanged: onVolumeChanged, // Llama a la función de actualización
            min: 0.0,
            max: 1.0,
          ),
        ),
      ],
    );
  }
}

class _PomodoroConfigState extends State<PomodoroConfig> {
  int workMinutes = 25;
  int breakMinutes = 5;
  int cycles = 1;

  String selectedWorkSound = 'notification1.mp3';
  String selectedBreakSound = 'notification1.mp3';
  double volume = 0.5;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final Map<String, String> soundOptions = {
    'notification1.mp3': 'Campana Zen',
    'drum.mp3': 'Tambor Taiko',
    'yoooo.mp3': 'Clamor del Samurai',
  };

  void _playPreview(String sound) async {
    await _audioPlayer.setVolume(volume);
    await _audioPlayer.play(AssetSource('sounds/$sound'));
  }

  void _showPicker(BuildContext context, List<int> items, int selectedValue,
      Function(int) onSelected) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Colors.white,
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
              initialItem: items.indexOf(selectedValue)),
          itemExtent: 40,
          onSelectedItemChanged: (index) {
            onSelected(items[index]);
          },
          children: items
              .map((item) => Center(child: Text(item.toString())))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo dinámico
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/image/pomodoro_config.jpg'), // Ruta de fondo
                fit: BoxFit.cover,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botón para mostrar/ocultar configuraciones avanzadas
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                              left: 16.0,
                              right: 16.0,
                              top: 16.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Configuraciones Avanzadas',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: selectedWorkSound,
                                  decoration: const InputDecoration(
                                      labelText: 'Sonido de trabajo terminado'),
                                  items: soundOptions.entries.map((entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedWorkSound = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: selectedBreakSound,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Sonido de descanso terminado'),
                                  items: soundOptions.entries.map((entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedBreakSound = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                VolumeSlider(
                                  volume: volume,
                                  onVolumeChanged: (value) {
                                    setState(() {
                                      volume = value;
                                    });
                                    _audioPlayer.setVolume(volume);
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _playPreview(selectedWorkSound),
                                  child: const Text(
                                      'Previsualizar sonido de trabajo'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _playPreview(selectedBreakSound),
                                  child: const Text(
                                      'Previsualizar sonido de descanso'),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(
                                      context), // Cierra el BottomSheet
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Configuraciones Avanzadas'),
                  ),
                  const SizedBox(height: 20),
                  // Minutos de trabajo
                  _buildConfigBox(
                    label: 'Minutos de Trabajo',
                    value: '$workMinutes min',
                    onPressed: () {
                      _showPicker(
                        context,
                        List.generate(45, (index) => index + 1),
                        workMinutes,
                        (value) {
                          setState(() {
                            workMinutes = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Minutos de descanso
                  _buildConfigBox(
                    label: 'Minutos de Descanso',
                    value: '$breakMinutes min',
                    onPressed: () {
                      _showPicker(
                        context,
                        List.generate(10, (index) => index + 1),
                        breakMinutes,
                        (value) {
                          setState(() {
                            breakMinutes = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Número de ciclos
                  _buildConfigBox(
                    label: 'Número de Ciclos',
                    value: '$cycles ciclo${cycles > 1 ? 's' : ''}',
                    onPressed: () {
                      _showPicker(
                        context,
                        List.generate(4, (index) => index + 1),
                        cycles,
                        (value) {
                          setState(() {
                            cycles = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Botón para iniciar el Pomodoro
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PomodoroTimer(
                            workMinutes: workMinutes,
                            breakMinutes: breakMinutes,
                            cycles: cycles,
                            firstStart: true,
                            workSound: selectedWorkSound,
                            breakSound: selectedBreakSound,
                          ),
                        ),
                      );
                    },
                    child: const Text('Iniciar Pomodoro'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

// Widget para crear cada sección (e.g., Minutos de Trabajo)
  Widget _buildConfigBox({
    required String label,
    required String value,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          ElevatedButton(
            onPressed: onPressed,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
