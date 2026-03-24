import 'package:flutter/material.dart';
import 'firestore_service.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _clubController = TextEditingController();
  final _playbackIdController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _clubController.dispose();
    _playbackIdController.dispose();
    super.dispose();
  }

  Future<void> _createMatch() async {
    if (_team1Controller.text.trim().isEmpty ||
        _team2Controller.text.trim().isEmpty ||
        _clubController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.createMatch(
        team1: _team1Controller.text.trim(),
        team2: _team2Controller.text.trim(),
        club: _clubController.text.trim(),
        playbackId: _playbackIdController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create match: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Create Match',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                    '🎾 New Match',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fill in the match details below',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Team 1
            _buildTextField(
              controller: _team1Controller,
              label: 'Team 1',
              hint: 'e.g. Ben & John',
              icon: Icons.group,
            ),
            const SizedBox(height: 16),
            // Team 2
            _buildTextField(
              controller: _team2Controller,
              label: 'Team 2',
              hint: 'e.g. Mike & Dave',
              icon: Icons.group,
            ),
            const SizedBox(height: 16),
            // Club name
            _buildTextField(
              controller: _clubController,
              label: 'Club Name',
              hint: 'e.g. Bulawayo Padel Club',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            // Playback ID
            _buildTextField(
              controller: _playbackIdController,
              label: 'Mux Playback ID (optional)',
              hint: 'Add after recording',
              icon: Icons.play_circle,
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 You can add the Playback ID later once the match is recorded',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            const SizedBox(height: 24),
            // Create button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createMatch,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.add),
              label: Text(
                _isLoading ? 'Creating...' : 'Create Match',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E676)),
        ),
      ),
    );
  }
}