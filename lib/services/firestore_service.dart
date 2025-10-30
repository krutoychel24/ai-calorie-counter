
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/nutrition_data.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profile and Goals --- //

  Future<void> saveUserSetup(String uid, Map<String, dynamic> userData) async {
    // This method saves the initial user profile and calculated goals.
    // It's one write operation.
    await _db.collection('users').doc(uid).set(userData, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    // Gets the user's main document.
    // One read operation.
    return await _db.collection('users').doc(uid).get();
  }

  Future<bool> checkIfUserExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> deleteUserData(String uid) async {
    // Deletes the entire user document. Used for resetting the setup.
    await _db.collection('users').doc(uid).delete();
  }

  // --- Storage --- //

  Future<String> uploadAvatar(String uid, File image) async {
    final storageRef = FirebaseStorage.instance.ref();
    final avatarRef = storageRef.child('user_avatars/$uid.jpg');
    await avatarRef.putFile(image);
    return await avatarRef.getDownloadURL();
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // --- Daily Meal Data --- //

  String _getDateKey(DateTime date) => date.toIso8601String().split('T').first; // yyyy-MM-dd

  Future<void> addMeal(String uid, String mealType, NutritionData meal, DateTime date) async {
    // Adds a new meal to a subcollection for the specific day.
    // One write operation.
    final dateKey = _getDateKey(date);
    await _db
        .collection('users').doc(uid)
        .collection('dailyMeals').doc(dateKey)
        .collection(mealType).add(meal.toJson());
  }

  Future<Map<String, List<NutritionData>>> getMealsForDate(String uid, DateTime date) async {
    // This is more complex and can be costly if not handled well.
    // We read all meals for a given day.
    final dateKey = _getDateKey(date);
    Map<String, List<NutritionData>> dailyMeals = {
      'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': [],
    };

    for (var mealType in dailyMeals.keys) {
      final querySnapshot = await _db
          .collection('users').doc(uid)
          .collection('dailyMeals').doc(dateKey)
          .collection(mealType).get();
      
      if (querySnapshot.docs.isNotEmpty) {
        dailyMeals[mealType] = querySnapshot.docs
            .map((doc) => NutritionData.fromJson(doc.data(), id: doc.id))
            .toList();
      }
    }
    // This costs 4 reads per day load (Breakfast, Lunch, Dinner, Snacks).
    // This is a reasonable trade-off for data structure simplicity.
    return dailyMeals;
  }
  
  Future<void> deleteMeal(String uid, String mealType, String mealId, DateTime date) async {
    final dateKey = _getDateKey(date);
    await _db
        .collection('users').doc(uid)
        .collection('dailyMeals').doc(dateKey)
        .collection(mealType).doc(mealId).delete();
  }
}
