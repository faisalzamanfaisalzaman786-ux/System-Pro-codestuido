import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:workmanager/workmanager.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// WORKMANAGER CALLBACK
// ============================================================================
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final NotificationService notificationService = NotificationService();
    await notificationService.initialize();
    
    switch (task) {
      case 'medicationReminder':
        await notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: 'Medication Reminder',
          body: 'Time to take your TB medication',
        );
        break;
      case 'symptomCheck':
        await notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: 'Symptom Check',
          body: 'How are you feeling today? Log your symptoms.',
        );
        break;
      case 'appointmentReminder':
        await notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: 'Upcoming Appointment',
          body: 'You have a doctor appointment tomorrow',
        );
        break;
    }
    return Future.value(true);
  });
}

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();
  
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  await Workmanager().registerPeriodicTask(
    'medicationReminder',
    'medicationReminder',
    frequency: Duration(hours: 1),
  );
  
  await DatabaseHelper.instance.init();
  
  await _requestPermissions();
  
  runApp(TBApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.notification,
    Permission.camera,
    Permission.storage,
    Permission.location,
  ].request();
}

// ============================================================================
// MAIN APP WIDGET
// ============================================================================
class TBApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: MaterialApp(
        title: 'TB Care Assistant',
        theme: ThemeData(
          primaryColor: Color(0xFF2563EB),
          scaffoldBackgroundColor: Color(0xFFF8FAFC),
          fontFamily: GoogleFonts.poppins().fontFamily,
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ============================================================================
// SPLASH SCREEN
// ============================================================================
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext ctx) => isFirstTime ? OnboardingScreen() : HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.health_and_safety, size: 80, color: Color(0xFF2563EB)),
              ),
              SizedBox(height: 30),
              Text('TB Care Assistant', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text('Your Partner in TB Treatment', style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 40),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ONBOARDING SCREEN
// ============================================================================
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Track Your Medication', 'desc': 'Never miss a dose with smart reminders', 'icon': Icons.medication, 'color': Color(0xFF3B82F6)},
    {'title': 'Monitor Symptoms', 'desc': 'Log daily symptoms and track recovery', 'icon': Icons.favorite, 'color': Color(0xFF10B981)},
    {'title': 'Doctor Appointments', 'desc': 'Schedule and manage medical appointments', 'icon': Icons.calendar_today, 'color': Color(0xFFF59E0B)},
    {'title': 'Educational Resources', 'desc': 'Learn about TB treatment and stay informed', 'icon': Icons.school, 'color': Color(0xFF8B5CF6)},
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (BuildContext context, int index) {
                final page = _pages[index];
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(color: page['color'].withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(page['icon'], size: 100, color: page['color']),
                      ),
                      SizedBox(height: 48),
                      Text(page['title'], style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      Text(page['desc'], style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (int index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == index ? Color(0xFF2563EB) : Colors.grey[300]),
                  )),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _currentPage == _pages.length - 1 ? _complete() : _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HOME SCREEN
// ============================================================================
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    DashboardScreen(),
    MedicationScreen(),
    SymptomScreen(),
    AppointmentScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Medication'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Symptoms'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1E40AF)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome Back!', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          const Text('Sarah Ahmed', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Treatment Day 42 of 180', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: 42 / 180,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Medication', '95%', Icons.medication, const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Symptoms', 'Good', Icons.favorite, const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Appointments', '2', Icons.calendar_today, const Color(0xFF3B82F6))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionButton('Log Symptoms', Icons.favorite, () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => SymptomScreen()));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton('Take Meds', Icons.medication, () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => MedicationScreen()));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton('Call Doctor', Icons.phone, () async {
              final Uri url = Uri(scheme: 'tel', path: '03001234567');
              if (await canLaunchUrl(url)) await launchUrl(url);
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: const Column(
            children: [
              ListTile(title: Text('Morning medication taken'), subtitle: Text('Today, 9:00 AM'), leading: Icon(Icons.check_circle, color: Colors.green)),
              Divider(),
              ListTile(title: Text('Symptoms logged - No fever'), subtitle: Text('Yesterday, 8:30 PM'), leading: Icon(Icons.favorite, color: Colors.red)),
              Divider(),
              ListTile(title: Text('Next appointment: Dr. Khan'), subtitle: Text('Tomorrow, 10:00 AM'), leading: Icon(Icons.event, color: Colors.blue)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MEDICATION SCREEN
// ============================================================================
class MedicationScreen extends StatefulWidget {
  @override
  _MedicationScreenState createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  void _loadMedications() {
    _medications.addAll([
      Medication(name: 'Rifampicin', dosage: '600mg', time: '9:00 AM', frequency: 'Daily', taken: false),
      Medication(name: 'Isoniazid', dosage: '300mg', time: '9:00 AM', frequency: 'Daily', taken: false),
      Medication(name: 'Pyrazinamide', dosage: '1500mg', time: '9:00 AM', frequency: 'Daily', taken: false),
      Medication(name: 'Ethambutol', dosage: '1200mg', time: '9:00 AM', frequency: 'Daily', taken: false),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medications'), elevation: 0, actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})]),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info, color: Color(0xFFD97706)),
                SizedBox(width: 12),
                Expanded(child: Text('Take medications at the same time daily. Never skip a dose.', style: TextStyle(color: Color(0xFF92400E)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _medications.length,
              itemBuilder: (BuildContext context, int index) {
                final med = _medications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Checkbox(
                        value: med.taken,
                        onChanged: (bool? val) => setState(() => med.taken = val ?? false),
                        activeColor: const Color(0xFF10B981),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('${med.dosage} • ${med.frequency}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                        child: Text(med.time, style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SYMPTOM SCREEN
// ============================================================================
class SymptomScreen extends StatefulWidget {
  @override
  _SymptomScreenState createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> {
  final List<String> _commonSymptoms = ['Cough', 'Fever', 'Night Sweats', 'Weight Loss', 'Fatigue', 'Chest Pain'];
  final Map<String, bool> _selectedSymptoms = {};
  int _severity = 3;
  String _notes = '';

  @override
  void initState() {
    super.initState();
    for (var symptom in _commonSymptoms) {
      _selectedSymptoms[symptom] = false;
    }
  }

  Future<void> _saveSymptoms(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Symptoms saved successfully!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Symptoms'), elevation: 0, actions: [
        TextButton(
          onPressed: () => _saveSymptoms(context),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        )
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How are you feeling today?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Symptoms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _commonSymptoms.map((String symptom) => FilterChip(
                label: Text(symptom),
                selected: _selectedSymptoms[symptom] ?? false,
                onSelected: (bool val) => setState(() => _selectedSymptoms[symptom] = val),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFFDBEAFE),
                checkmarkColor: const Color(0xFF2563EB),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Severity (1-5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (int index) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _severity = index + 1),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _severity == index + 1 ? const Color(0xFF2563EB) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${index + 1}', textAlign: TextAlign.center, style: TextStyle(color: _severity == index + 1 ? Colors.white : Colors.black)),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 20),
            const Text('Additional Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter any additional symptoms or notes...', fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none)),
              onChanged: (String val) => _notes = val,
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () => _saveSymptoms(context), child: const Text('Save Symptoms Log')),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// APPOINTMENT SCREEN
// ============================================================================
class AppointmentScreen extends StatefulWidget {
  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    _appointments.addAll([
      Appointment(doctorName: 'Dr. Ahmed Khan', specialty: 'Pulmonologist', date: DateTime.now().add(const Duration(days: 1)), time: '10:00 AM', location: 'City Hospital, Room 204'),
      Appointment(doctorName: 'Dr. Fatima Ali', specialty: 'Follow-up', date: DateTime.now().add(const Duration(days: 14)), time: '2:30 PM', location: 'TB Clinic, Floor 3'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments'), elevation: 0, actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (BuildContext context, int index) {
          final apt = _appointments[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.person, color: Color(0xFF2563EB))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(apt.doctorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(apt.specialty, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)), child: const Text('Upcoming', style: TextStyle(fontSize: 10, color: Color(0xFFD97706)))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(DateFormat('MMM dd, yyyy').format(apt.date))]),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(apt.time)]),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(apt.location))]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Reschedule'), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2563EB))))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: () async {
                      final Uri url = Uri(scheme: 'tel', path: '03001234567');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    }, child: const Text('Call Clinic'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// PROFILE SCREEN
// ============================================================================
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.person, size: 50, color: Color(0xFF2563EB))),
            const SizedBox(height: 12),
            const Text('Sarah Ahmed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('sarah.ahmed@email.com', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildSettingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildInfoRow('Diagnosis Date', 'January 15, 2024'),
          const Divider(),
          _buildInfoRow('Treatment Phase', 'Intensive Phase'),
          const Divider(),
          _buildInfoRow('Doctor', 'Dr. Ahmed Khan'),
          const Divider(),
          _buildInfoRow('Hospital', 'City General Hospital'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildSettingsTile(Icons.notifications, 'Notifications', () {}),
          const Divider(height: 1),
          _buildSettingsTile(Icons.lock, 'Privacy Settings', () {}),
          const Divider(height: 1),
          _buildSettingsTile(Icons.help, 'Help & Support', () {}),
          const Divider(height: 1),
          _buildSettingsTile(Icons.info, 'About TB Care', () {}),
          const Divider(height: 1),
          _buildSettingsTile(Icons.logout, 'Logout', () {
            showDialog(
              context: context,
              builder: (BuildContext ctx) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => OnboardingScreen())),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ============================================================================
// NOTIFICATION SERVICE
// ============================================================================
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(settings);
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tb_care_channel', 'TB Care Notifications', importance: Importance.high, priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.show(id, title, body, details);
  }
}

// ============================================================================
// DATABASE HELPER
// ============================================================================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tb_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, filePath);
    return await openDatabase(fullPath, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        frequency TEXT NOT NULL,
        taken INTEGER DEFAULT 0,
        date TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE symptoms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symptoms TEXT NOT NULL,
        severity INTEGER NOT NULL,
        notes TEXT,
        date TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');
  }

  Future<void> init() async {
    await database;
  }
}

// ============================================================================
// MODELS
// ============================================================================
class Medication {
  String name;
  String dosage;
  String time;
  String frequency;
  bool taken;
  
  Medication({required this.name, required this.dosage, required this.time, required this.frequency, required this.taken});
}

class Appointment {
  String doctorName;
  String specialty;
  DateTime date;
  String time;
  String location;
  
  Appointment({required this.doctorName, required this.specialty, required this.date, required this.time, required this.location});
}

// ============================================================================
// PROVIDERS
// ============================================================================
class UserProvider extends ChangeNotifier {
  String _name = 'Sarah Ahmed';
  String _email = 'sarah.ahmed@email.com';
  int _treatmentDay = 42;
  
  String get name => _name;
  String get email => _email;
  int get treatmentDay => _treatmentDay;
  
  void updateProfile(String name, String email) {
    _name = name;
    _email = email;
    notifyListeners();
  }
}

class MedicationProvider extends ChangeNotifier {
  List<Medication> _medications = [];
  
  List<Medication> get medications => _medications;
  
  void addMedication(Medication medication) {
    _medications.add(medication);
    notifyListeners();
  }
  
  void toggleTaken(int index) {
    _medications[index].taken = !_medications[index].taken;
    notifyListeners();
  }
}

class SymptomProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _logs = [];
  
  List<Map<String, dynamic>> get logs => _logs;
  
  void addLog(Map<String, dynamic> log) {
    _logs.add(log);
    notifyListeners();
  }
}

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  
  List<Appointment> get appointments => _appointments;
  
  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    notifyListeners();
  }
}