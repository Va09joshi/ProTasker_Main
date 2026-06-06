import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/models/models.dart';

class ClientPostProblemScreen extends ConsumerStatefulWidget {
  const ClientPostProblemScreen({super.key});

  @override
  ConsumerState<ClientPostProblemScreen> createState() => _ClientPostProblemScreenState();
}

class _ClientPostProblemScreenState extends ConsumerState<ClientPostProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitProblem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception("User not found");

      // In a real app we'd fetch precise GPS coordinates here. 
      // For now, using mock coordinates or profile coordinates.
      final lat = user.address.lat;
      final lng = user.address.lng;

      final newProblemRef = FirebaseFirestore.instance.collection('task_requests').doc();
      
      final taskRequest = TaskRequestModel(
        id: newProblemRef.id,
        clientId: user.uid,
        clientName: user.name,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        latitude: lat,
        longitude: lng,
        status: TaskRequestStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await newProblemRef.set(taskRequest.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Problem posted successfully! Providers nearby will see it.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post problem: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Problem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Describe your task',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                'Providers nearby will be able to see your request and connect with you to solve it.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Problem Title',
                  hintText: 'E.g., Plumber needed for leaking pipe',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide details about the issue...',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProblem,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Post Problem'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
