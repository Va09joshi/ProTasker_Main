import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';

class BookingFlowState {
  final int currentStep;
  final DateTime? selectedDate;
  final String? timeSlot;
  final Address? address;
  final String notes;
  final List<String> specialInstructions;
  final List<File> tempPhotos;
  final bool isLoading;
  final bool isEmergency;

  BookingFlowState({
    this.currentStep = 0,
    this.selectedDate,
    this.timeSlot,
    this.address,
    this.notes = '',
    this.specialInstructions = const [],
    this.tempPhotos = const [],
    this.isLoading = false,
    this.isEmergency = false,
  });

  BookingFlowState copyWith({
    int? currentStep,
    DateTime? selectedDate,
    String? timeSlot,
    Address? address,
    String? notes,
    List<String>? specialInstructions,
    List<File>? tempPhotos,
    bool? isLoading,
    bool? isEmergency,
  }) {
    return BookingFlowState(
      currentStep: currentStep ?? this.currentStep,
      selectedDate: selectedDate ?? this.selectedDate,
      timeSlot: timeSlot ?? this.timeSlot,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      tempPhotos: tempPhotos ?? this.tempPhotos,
      isLoading: isLoading ?? this.isLoading,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }
}

final bookingFlowProvider = NotifierProvider<BookingFlowNotifier, BookingFlowState>(() {
  return BookingFlowNotifier();
});

class BookingFlowNotifier extends Notifier<BookingFlowState> {
  @override
  BookingFlowState build() => BookingFlowState();

  void setStep(int step) => state = state.copyWith(currentStep: step);
  void setDate(DateTime date) => state = state.copyWith(selectedDate: date, timeSlot: null);
  void setTimeSlot(String slot) => state = state.copyWith(timeSlot: slot);
  void setAddress(Address addr) => state = state.copyWith(address: addr);
  void setNotes(String notes) => state = state.copyWith(notes: notes);
  void toggleEmergency(bool val) => state = state.copyWith(isEmergency: val);
  
  void toggleInstruction(String inst) {
    final list = List<String>.from(state.specialInstructions);
    if (list.contains(inst)) {
      list.remove(inst);
    } else {
      list.add(inst);
    }
    state = state.copyWith(specialInstructions: list);
  }

  void addPhoto(File file) {
    if (state.tempPhotos.length < 3) {
      state = state.copyWith(tempPhotos: [...state.tempPhotos, file]);
    }
  }

  void removePhoto(int index) {
    final list = List<File>.from(state.tempPhotos);
    list.removeAt(index);
    state = state.copyWith(tempPhotos: list);
  }

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
}

final providerBookedSlotsProvider = FutureProvider.autoDispose.family<List<String>, ({String providerId, DateTime date})>((ref, args) async {
  final startOfDay = DateTime(args.date.year, args.date.month, args.date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: args.providerId)
      .where('status', whereIn: [BookingStatus.pending.name, BookingStatus.accepted.name, BookingStatus.onTheWay.name, BookingStatus.inProgress.name])
      .where('scheduledAt', isGreaterThanOrEqualTo: startOfDay)
      .where('scheduledAt', isLessThan: endOfDay)
      .get();

  return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc).timeSlot).toList();
});

final bookingProviderUserModelProvider = FutureProvider.autoDispose.family<UserModel?, String>((ref, providerId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(providerId).get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});
