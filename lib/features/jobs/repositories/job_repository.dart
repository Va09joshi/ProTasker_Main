import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_post.dart';

final jobRepositoryProvider = Provider((ref) => JobRepository());

class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'jobs';

  Future<void> createJob(JobPost job) async {
    await _firestore.collection(_collection).add(job.toMap());
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _firestore.collection(_collection).doc(jobId).update({'status': status});
  }

  // Get all open jobs for the provider feed
  Stream<List<JobPost>> getOpenJobs() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get jobs posted by a specific client
  Stream<List<JobPost>> getClientJobs(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get a single job by ID
  Stream<JobPost?> getJobById(String jobId) {
    return _firestore
        .collection(_collection)
        .doc(jobId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? JobPost.fromMap(snapshot.data()!, snapshot.id) : null);
  }
}
