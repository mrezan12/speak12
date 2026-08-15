import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sentence_review.dart';

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviews(String userId) {
    return _firestore.collection('users').doc(userId).collection('reviews');
  }

  Future<SentenceReview?> getReview(String userId, String sentenceId) async {
    final snapshot = await _reviews(userId).doc(sentenceId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final data = Map<String, dynamic>.from(snapshot.data()!);
    data.putIfAbsent('sentenceId', () => sentenceId);
    return SentenceReview.fromMap(data);
  }

  Future<void> saveReview(String userId, SentenceReview review) async {
    await _reviews(userId).doc(review.sentenceId).set(
          review.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<List<SentenceReview>> getDueReviews(
    String userId, {
    DateTime? now,
    int limit = 20,
  }) async {
    final at = now ?? DateTime.now();
    final snapshot = await _reviews(userId)
        .where('dueAt', isLessThanOrEqualTo: Timestamp.fromDate(at))
        .orderBy('dueAt')
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data.putIfAbsent('sentenceId', () => doc.id);
      return SentenceReview.fromMap(data);
    }).toList();
  }

  Future<void> deleteAllReviews(String userId) async {
    const pageSize = 200;
    while (true) {
      final snapshot = await _reviews(userId).limit(pageSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < pageSize) return;
    }
  }
}
