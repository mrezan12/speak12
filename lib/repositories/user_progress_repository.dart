import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_progress.dart';

class UserProgressRepository {
  UserProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  UserProgress defaultProgress(String userId) {
    return UserProgress(
      userId: userId,
      currentLevel: 'A1',
      dailyGoal: 10,
      currentStreak: 0,
      longestStreak: 0,
      lastStudyDate: null,
      totalLearned: 0,
    );
  }

  Future<UserProgress> getUserProgress(String userId) async {
    final snapshot = await _userDoc(userId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      final created = defaultProgress(userId);
      await saveUserProgress(created);
      return created;
    }

    final data = Map<String, dynamic>.from(snapshot.data()!);
    data.putIfAbsent('userId', () => userId);
    return UserProgress.fromMap(data);
  }

  Future<void> saveUserProgress(UserProgress progress) async {
    await _userDoc(progress.userId).set(
      progress.toMap(),
      SetOptions(merge: true),
    );
  }

  Stream<UserProgress?> watchUserProgress(String userId) {
    return _userDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);
      data.putIfAbsent('userId', () => userId);
      return UserProgress.fromMap(data);
    });
  }
}
