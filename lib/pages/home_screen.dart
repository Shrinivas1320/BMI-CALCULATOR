import 'dart:math';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:flutter_3d_choice_chip/flutter_3d_choice_chip.dart';
import 'package:pretty_gauge/pretty_gauge.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BmiHistoryEntry {
  final DateTime dateTime;
  final double bmi;
  final int age;
  final String status;

  BmiHistoryEntry({
    required this.dateTime,
    required this.bmi,
    required this.age,
    required this.status,
  });
}

class HomeScreen extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;
  const HomeScreen({Key? key, required this.username, required this.onLogout}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _gender = 0;
  int _height = 150;
  int _age = 30;
  int _weight = 50;
  bool _isFinished = false;
  double _bmiScore = 0;
  bool isDarkMode = false;

  final TextEditingController _heightController = TextEditingController(text: "150");
  final TextEditingController _weightController = TextEditingController(text: "50");
  final TextEditingController _ageController = TextEditingController(text: "30");

  List<BmiHistoryEntry> _history = [];

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void calculateBmi() {
    _bmiScore = _weight / pow(_height / 100, 2);
  }

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  void _addToHistory(double bmi, int age, String status) {
    setState(() {
      _history.insert(
        0,
        BmiHistoryEntry(
          dateTime: DateTime.now(),
          bmi: bmi,
          age: age,
          status: status,
        ),
      );
    });
  }

  void _deleteHistoryEntry(int index) {
    setState(() {
      _history.removeAt(index);
    });
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          history: _history,
          onDelete: _deleteHistoryEntry,
          onClear: _clearHistory,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    return Theme(
      data: theme,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text("Welcome, ${widget.username}"),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.blue,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('History'),
                onTap: () {
                  Navigator.pop(context);
                  _openHistory(context);
                },
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: isDarkMode,
                onChanged: _toggleTheme,
                secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () async {
                  Navigator.pop(context);
                  await _signOut();
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                child: Card(
                  elevation: 12,
                  shape: const RoundedRectangleBorder(),
                  child: Column(
                    children: [
                      GenderWidget(
                        onChange: (genderVal) {
                          setState(() {
                            _gender = genderVal;
                          });
                        },
                      ),
                      HeightWidget(
                        value: _height,
                        controller: _heightController,
                        onChange: (heightVal) {
                          setState(() {
                            _height = heightVal;
                            _heightController.text = heightVal.toString();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AgeWeightWidget(
                            value: _age,
                            controller: _ageController,
                            onChange: (ageVal) {
                              setState(() {
                                _age = ageVal;
                                _ageController.text = ageVal.toString();
                              });
                            },
                            title: "Age",
                            min: 10,
                            max: 120,
                            maxLength: 3,
                          ),
                          AgeWeightWidget(
                            value: _weight,
                            controller: _weightController,
                            onChange: (weightVal) {
                              setState(() {
                                _weight = weightVal;
                                _weightController.text = weightVal.toString();
                              });
                            },
                            title: "Weight(Kg)",
                            min: 10,
                            max: 999,
                            maxLength: 3,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 60),
                        child: SwipeableButtonView(
                          isFinished: _isFinished,
                          onFinish: () async {
                            String status = ScoreScreen.getBmiStatus(_bmiScore);
                            _addToHistory(_bmiScore, _age, status);
                            await Navigator.push(
                              context,
                              PageTransition(
                                child: ScoreScreen(
                                  bmiScore: _bmiScore,
                                  age: _age,
                                  username: widget.username,
                                  isDarkMode: isDarkMode,
                                ),
                                type: PageTransitionType.fade,
                              ),
                            );
                            setState(() {
                              _isFinished = false;
                            });
                          },
                          onWaitingProcess: () {
                            calculateBmi();
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                _isFinished = true;
                              });
                            });
                          },
                          activeColor: Colors.blue,
                          buttonWidget: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.black,
                          ),
                          buttonText: "CALCULATE",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                " App By Shrinivas ",
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class HeightWidget extends StatelessWidget {
  final int value;
  final TextEditingController controller;
  final Function(int) onChange;

  const HeightWidget({
    Key? key,
    required this.value,
    required this.controller,
    required this.onChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 12,
        shape: const RoundedRectangleBorder(),
        child: Column(
          children: [
            const Text(
              "Height",
              style: TextStyle(fontSize: 25, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: "",
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 100 && parsed <= 299) {
                        onChange(parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 10),
                const Text(
                  "cm",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (value > 100) onChange(value - 1);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (value < 299) onChange(value + 1);
                  },
                ),
              ],
            ),
            Slider(
              min: 100,
              max: 299,
              value: value.toDouble(),
              thumbColor: Colors.red,
              onChanged: (val) {
                onChange(val.toInt());
                controller.text = val.toInt().toString();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AgeWeightWidget extends StatelessWidget {
  final int value;
  final TextEditingController controller;
  final Function(int) onChange;
  final String title;
  final int min;
  final int max;
  final int maxLength;

  const AgeWeightWidget({
    Key? key,
    required this.value,
    required this.controller,
    required this.onChange,
    required this.title,
    required this.min,
    required this.max,
    this.maxLength = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 12,
        shape: const RoundedRectangleBorder(),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (value > min) onChange(value - 1);
                  },
                ),
                SizedBox(
                  width: 40,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: maxLength,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: "",
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= min && parsed <= max) {
                        onChange(parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (value < max) onChange(value + 1);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GenderWidget extends StatefulWidget {
  final Function(int) onChange;

  const GenderWidget({Key? key, required this.onChange}) : super(key: key);

  @override
  _GenderWidgetState createState() => _GenderWidgetState();
}

class _GenderWidgetState extends State<GenderWidget> {
  int _gender = 0;

  final ChoiceChip3DStyle selectedStyle = ChoiceChip3DStyle(
    topColor: Colors.grey[200]!,
    backColor: Colors.grey,
    borderRadius: BorderRadius.circular(20),
  );

  final ChoiceChip3DStyle unselectedStyle = ChoiceChip3DStyle(
    topColor: Colors.white,
    backColor: Colors.grey[300]!,
    borderRadius: BorderRadius.circular(20),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip3D(
            border: Border.all(color: Colors.grey),
            style: _gender == 1 ? selectedStyle : unselectedStyle,
            onSelected: () {
              setState(() {
                _gender = 1;
              });
              widget.onChange(_gender);
            },
            onUnSelected: () {},
            selected: _gender == 1,
            child: Column(
              children: [
                Image.network(
                  "https://cdn-icons-png.flaticon.com/512/236/236832.png",
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 5),
                const Text("Male"),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ChoiceChip3D(
            border: Border.all(color: Colors.grey),
            style: _gender == 2 ? selectedStyle : unselectedStyle,
            onSelected: () {
              setState(() {
                _gender = 2;
              });
              widget.onChange(_gender);
            },
            selected: _gender == 2,
            onUnSelected: () {},
            child: Column(
              children: [
                Image.network(
                  "https://cdn-icons-png.flaticon.com/512/6833/6833591.png",
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person_outline, size: 50),
                ),
                const SizedBox(height: 5),
                const Text("Female"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreScreen extends StatelessWidget {
  final double bmiScore;
  final int age;
  final String username;
  final bool isDarkMode;

  String? bmiStatus;
  String? bmiInterpretation;
  Color? bmiStatusColor;

  ScoreScreen({
    Key? key,
    required this.bmiScore,
    required this.age,
    required this.username,
    required this.isDarkMode,
  }) : super(key: key);

  static String getBmiStatus(double bmiScore) {
    if (bmiScore > 30) {
      return "Obese";
    } else if (bmiScore >= 25) {
      return "Overweight";
    } else if (bmiScore >= 18.5) {
      return "Normal";
    } else {
      return "Underweight";
    }
  }

  @override
  Widget build(BuildContext context) {
    setBmiInterpretation();
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("BMI Score"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 12,
              shape: const RoundedRectangleBorder(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Your Score",
                    style: TextStyle(fontSize: 30, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  PrettyGauge(
                    gaugeSize: 300,
                    minValue: 0,
                    maxValue: 40,
                    segments: [
                      GaugeSegment('UnderWeight', 18.5, Colors.red),
                      GaugeSegment('Normal', 6.4, Colors.green),
                      GaugeSegment('OverWeight', 5, Colors.orange),
                      GaugeSegment('Obese', 10.1, Colors.pink),
                    ],
                    valueWidget: Text(
                      bmiScore.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 40),
                    ),
                    currentValue: bmiScore.toDouble(),
                    needleColor: Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bmiStatus!,
                    style: TextStyle(fontSize: 20, color: bmiStatusColor!),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bmiInterpretation!,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final pdf = pw.Document();
                      pdf.addPage(
                        pw.Page(
                          build: (pw.Context context) => pw.Center(
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text("BMI Report", style: pw.TextStyle(fontSize: 32)),
                                pw.SizedBox(height: 20),
                                pw.Text("User: $username"),
                                pw.Text("Age: $age"),
                                pw.Text("BMI: ${bmiScore.toStringAsFixed(1)}"),
                                pw.Text("Status: $bmiStatus"),
                                pw.Text("Interpretation: $bmiInterpretation"),
                                pw.SizedBox(height: 20),
                                pw.Text("BMI Chart", style: pw.TextStyle(fontSize: 20)),
                                pw.Table(
                                  border: pw.TableBorder.all(),
                                  children: [
                                    pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('BMI Range', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('Underweight'),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('< 18.5'),
                                        ),
                                      ],
                                    ),
                                    pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('Normal'),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('18.5 - 24.9'),
                                        ),
                                      ],
                                    ),
                                    pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('Overweight'),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('25 - 29.9'),
                                        ),
                                      ],
                                    ),
                                    pw.TableRow(
                                      children: [
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('Obese'),
                                        ),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.all(4),
                                          child: pw.Text('30+'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      await Printing.sharePdf(
                        bytes: await pdf.save(),
                        filename: 'bmi_report.pdf',
                      );
                    },
                    child: const Text("Share PDF"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Re-calculate"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void setBmiInterpretation() {
    if (bmiScore > 30) {
      bmiStatus = "Obese";
      bmiInterpretation = "Please work to reduce obesity";
      bmiStatusColor = Colors.pink;
    } else if (bmiScore >= 25) {
      bmiStatus = "Overweight";
      bmiInterpretation = "Do regular exercise & reduce the weight";
      bmiStatusColor = Colors.orange;
    } else if (bmiScore >= 18.5) {
      bmiStatus = "Normal";
      bmiInterpretation = "Enjoy, You are fit";
      bmiStatusColor = Colors.green;
    } else if (bmiScore < 18.5) {
      bmiStatus = "Underweight";
      bmiInterpretation = "Try to increase the weight";
      bmiStatusColor = Colors.red;
    }
  }
}

class HistoryScreen extends StatelessWidget {
  final List<BmiHistoryEntry> history;
  final void Function(int) onDelete;
  final VoidCallback onClear;
  const HistoryScreen({
    Key? key,
    required this.history,
    required this.onDelete,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear All',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All History?'),
                    content: const Text('Are you sure you want to delete all history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          onClear();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text('No history yet.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return Dismissible(
                  key: ValueKey(entry.dateTime.toIso8601String()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => onDelete(index),
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text('BMI: ${entry.bmi.toStringAsFixed(1)} (${entry.status})'),
                    subtitle: Text('Age: ${entry.age}  •  ${dateFormat.format(entry.dateTime)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}