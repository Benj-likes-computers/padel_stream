import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Create user profile in Firestore on signup
  Future<void> createUserProfile({
    required String role, // 'club' or 'player'
    String? clubName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': role,
      'clubName': clubName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get current user role
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  // Generate a voucher code (club only)
  Future<String> generateVoucher({required String matchId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Generate random code
    final code = _generateCode();

    await _db.collection('vouchers').doc(code).set({
      'code': code,
      'matchId': matchId,
      'isUsed': false,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'usedBy': null,
      'usedAt': null,
    });

    return code;
  }

  // Redeem a voucher code (player only)
  Future<bool> redeemVoucher({required String code}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final voucherRef = _db.collection('vouchers').doc(code);
    final voucher = await voucherRef.get();

    // Check if voucher exists
    if (!voucher.exists) return false;

    // Check if already used
    if (voucher.data()?['isUsed'] == true) return false;

    // Mark as used
    await voucherRef.update({
      'isUsed': true,
      'usedBy': user.uid,
      'usedAt': FieldValue.serverTimestamp(),
    });

    // Save to user's redeemed vouchers
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('redeemedVouchers')
        .doc(code)
        .set({
      'code': code,
      'matchId': voucher.data()?['matchId'],
      'redeemedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  // Check if user has access to a match
  Future<bool> hasMatchAccess({required String matchId}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final vouchers = await _db
        .collection('users')
        .doc(user.uid)
        .collection('redeemedVouchers')
        .where('matchId', isEqualTo: matchId)
        .get();

    return vouchers.docs.isNotEmpty;
  }

  // Generate a random voucher code
  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(12, (index) {
      return chars[(DateTime.now().microsecondsSinceEpoch + index * 7) % chars.length];
    });
    // Format as XXXX-XXXX-XXXX
    return '${random.sublist(0, 4).join()}-${random.sublist(4, 8).join()}-${random.sublist(8, 12).join()}';
  }
  // Get all matches
  Stream<List<Map<String, dynamic>>> getMatches() {
    return _db
        .collection('matches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

// Create a new match (club only)
  Future<String> createMatch({
    required String team1,
    required String team2,
    required String club,
    required String playbackId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final doc = await _db.collection('matches').add({
      'team1': team1,
      'team2': team2,
      'club': club,
      'playbackId': playbackId,
      'isLive': false,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }
  // Get current user's redeemed matches
  Stream<List<Map<String, dynamic>>> getMyMatches() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('redeemedVouchers')
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final matches = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final matchId = doc.data()['matchId'] as String?;
        if (matchId == null) continue;

        final matchDoc =
        await _db.collection('matches').doc(matchId).get();
        if (!matchDoc.exists) continue;

        matches.add({
          'id': matchDoc.id,
          'redeemedAt': doc.data()['redeemedAt'],
          ...matchDoc.data()!,
        });
      }

      return matches;
    });
  }
  // Update match status (start/stop recording)
  Future<void> updateMatchStatus({
    required String matchId,
    required bool isLive,
  }) async {
    await _db.collection('matches').doc(matchId).update({
      'isLive': isLive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

// Delete a match (club only)
  Future<void> deleteMatch({required String matchId}) async {
    await _db.collection('matches').doc(matchId).delete();
  }

// Get club's own matches
  Stream<List<Map<String, dynamic>>> getClubMatches() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('matches')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }
}