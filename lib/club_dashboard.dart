import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firestore_service.dart';
import 'create_match_screen.dart';

class ClubDashboard extends StatefulWidget {
  const ClubDashboard({super.key});

  @override
  State<ClubDashboard> createState() => _ClubDashboardState();
}

class _ClubDashboardState extends State<ClubDashboard> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Club Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateMatchScreen(),
                ),
              );
              if (created == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Match created successfully!'),
                    backgroundColor: Color(0xFF00E676),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add, color: Color(0xFF00E676)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getClubMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            );
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_tennis,
                      color: Color(0xFF00E676), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No matches yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to create your first match',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateMatchScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Match'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length + 1,
            itemBuilder: (context, index) {
              // Header stats card
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF00E676)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total Matches',
                          value: '${matches.length}',
                          icon: Icons.sports_tennis,
                        ),
                        _StatItem(
                          label: 'Live Now',
                          value: '${matches.where((m) => m['isLive'] == true).length}',
                          icon: Icons.circle,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final match = matches[index - 1];
              final isLive = match['isLive'] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLive
                          ? const Color(0xFF00E676)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isLive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676),
                                          borderRadius:
                                          BorderRadius.circular(4),
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
                                    if (isLive) const SizedBox(width: 8),
                                    Text(
                                      '${match['team1']} vs ${match['team2']}',
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
                                  match['club'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Delete button
                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  title: const Text(
                                    'Delete Match?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'This cannot be undone.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete',
                                          style:
                                          TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _firestoreService.deleteMatch(
                                    matchId: match['id']);
                              }
                            },
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Start/Stop Match buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLive
                                  ? null
                                  : () async {
                                await _firestoreService
                                    .updateMatchStatus(
                                  matchId: match['id'],
                                  isLive: true,
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Match'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLive
                                    ? Colors.grey
                                    : const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLive
                                  ? () async {
                                await _firestoreService
                                    .updateMatchStatus(
                                  matchId: match['id'],
                                  isLive: false,
                                );
                              }
                                  : null,
                              icon: const Icon(Icons.stop),
                              label: const Text('End Match'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLive
                                    ? Colors.red
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Generate voucher button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showVoucherDialog(
                              context, match['id']),
                          icon: const Icon(Icons.confirmation_number,
                              color: Color(0xFF00E676)),
                          label: const Text(
                            'Generate Voucher',
                            style: TextStyle(color: Color(0xFF00E676)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF00E676)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showVoucherDialog(
      BuildContext context, String matchId) async {
    String? generatedCode;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            '🎫 Generate Voucher',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (generatedCode == null)
                const Text(
                  'Generate a unique voucher code for this match',
                  style: TextStyle(color: Colors.grey),
                )
              else
                Column(
                  children: [
                    const Text(
                      'Share this code with the player:',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(8),
                        border:
                        Border.all(color: const Color(0xFF00E676)),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            generatedCode!,
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: generatedCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copied!'),
                                  backgroundColor: Color(0xFF00E676),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy,
                                color: Color(0xFF00E676)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: Colors.grey)),
            ),
            if (generatedCode == null)
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  setState(() => isLoading = true);
                  final code =
                  await _firestoreService.generateVoucher(
                    matchId: matchId,
                  );
                  setState(() {
                    generatedCode = code;
                    isLoading = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Generate'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}