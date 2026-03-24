import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'video_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padel_stream/auth_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'club_dashboard.dart';
import 'firestore_service.dart';
import 'redeem_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PadelStreamApp());
}

class PadelStreamApp extends StatelessWidget {
  const PadelStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PadelStream',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E676),
          secondary: const Color(0xFF1B5E20),
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Color(0xFF00E676),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFF00E676),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF121212),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E676),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _userRole = 'player';
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _firestoreService.getUserRole();
    setState(() => _userRole = role ?? 'player');
  }

  List<Widget> get _screens => _userRole == 'club'
      ? [
    const ClubDashboard(),
    const MyMatchesScreen(),
    const ProfileScreen(),
  ]
      : [
    const HomeScreen(),
    const MyMatchesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _userRole == 'club' ? Icons.dashboard : Icons.home,
            ),
            label: _userRole == 'club' ? 'Dashboard' : 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.sports_tennis),
            label: 'My Matches',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎾 PadelStream',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00E676),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final matches = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF00E676)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to PadelStream',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Watch your matches anytime, anywhere.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Matches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (matches.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.sports_tennis,
                            color: Colors.grey, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No matches yet',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back after your next game!',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...matches.map((match) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MatchCard(
                    team1: match['team1'] ?? '',
                    team2: match['team2'] ?? '',
                    date: match['createdAt'] != null
                        ? _formatDate(
                        (match['createdAt'] as Timestamp).toDate())
                        : 'Date unknown',
                    club: match['club'] ?? '',
                    isLive: match['isLive'] ?? false,
                    matchId: match['id'] ?? '',
                    playbackId: match['playbackId'] ?? '',
                  ),
                )),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today, ${_formatTime(date)}';
    if (diff.inDays == 1) return 'Yesterday, ${_formatTime(date)}';
    return '${date.day}/${date.month}/${date.year}, ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _MatchCard extends StatefulWidget {
  final String team1;
  final String team2;
  final String date;
  final String club;
  final bool isLive;
  final String matchId;
  final String playbackId;

  const _MatchCard({
    required this.team1,
    required this.team2,
    required this.date,
    required this.club,
    required this.isLive,
    required this.matchId,
    required this.playbackId,
  });

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  final _firestoreService = FirestoreService();
  bool _hasAccess = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final access = await _firestoreService.hasMatchAccess(
      matchId: widget.matchId,
    );
    setState(() {
      _hasAccess = access;
      _isChecking = false;
    });
  }

  Future<void> _onTap() async {
    if (_hasAccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoScreen(
            playbackId: widget.playbackId,
            matchTitle: '${widget.team1} vs ${widget.team2}',
          ),
        ),
      );
    } else {
      final redeemed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RedeemScreen(
            matchId: widget.matchId,
            matchTitle: '${widget.team1} vs ${widget.team2}',
          ),
        ),
      );
      if (redeemed == true) {
        _checkAccess();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isChecking ? null : _onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isLive
                ? const Color(0xFF00E676)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (widget.isLive) const SizedBox(width: 8),
                      Text(
                        '${widget.team1} vs ${widget.team2}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.club,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    widget.date,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            _isChecking
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF00E676),
                strokeWidth: 2,
              ),
            )
                : Icon(
              _hasAccess
                  ? Icons.play_circle_filled
                  : Icons.lock,
              color: _hasAccess
                  ? const Color(0xFF00E676)
                  : Colors.grey,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Matches Screen ─────────────────────────────────────────────────────────
class MyMatchesScreen extends StatelessWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Matches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getMyMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00E676),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open,
                      color: Color(0xFF00E676), size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No unlocked matches yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Redeem a voucher to unlock your first match',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoScreen(
                        playbackId: match['playbackId'] ?? '',
                        matchTitle:
                        '${match['team1']} vs ${match['team2']}',
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E676),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sports_tennis,
                            color: Color(0xFF00E676),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${match['team1']} vs ${match['team2']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                match['club'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lock_open,
                                    color: Color(0xFF00E676),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unlocked',
                                    style: TextStyle(
                                      color: const Color(0xFF00E676),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_filled,
                          color: Color(0xFF00E676),
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Profile Screen ────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_outline,
                color: Color(0xFF00E676), size: 64),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'No email',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Player',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}