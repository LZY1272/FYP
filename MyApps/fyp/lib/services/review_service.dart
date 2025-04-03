import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;
import 'config.dart'; // Import config.dart

class ReviewService {
  // Add a review
  static Future<bool> addReview(Map<String, dynamic> reviewData) async {
    final Uri url = Uri.parse(addreview); // Ensure addreview is a String URL

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reviewData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          "Error adding review: ${response.statusCode} - ${response.body}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("Exception adding review: $e");
      return false;
    }
  }

  // Fetch all reviews
  static Future<List<Map<String, dynamic>>> getReviews() async {
    final Uri url = Uri.parse(getreview); // Ensure getreview is a String URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true && responseData['success'] is List) {
          return List<Map<String, dynamic>>.from(
            responseData['success'].map((review) {
              return {
                "_id": review["_id"] ?? "MISSING_ID", // ✅ Include _id
                "userId": review["userId"],
                "placeId": review["placeId"] ?? "",
                "placeName": review["placeName"] ?? "Unknown",
                "rating":
                    (review["rating"] is int)
                        ? (review["rating"] as int).toDouble()
                        : (review["rating"] ?? 0.0),
                "reviewText": review["reviewText"] ?? "",
                "createdAt": review["createdAt"] ?? "",
              };
            }),
          );
        } else {
          debugPrint("Invalid response format: ${response.body}");
          return [];
        }
      } else {
        debugPrint(
          "Error fetching reviews: ${response.statusCode} - ${response.body}",
        );
        return [];
      }
    } catch (e) {
      debugPrint("Exception fetching reviews: $e");
      return [];
    }
  }

  // Update Review - Fixed Version
  static Future<bool> updateReview(
    String reviewId,
    Map<String, dynamic> updatedReviewData,
  ) async {
    final Uri url = Uri.parse(
      updatereview(reviewId),
    ); // Ensure getreview is a String URL

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedReviewData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == true) {
          return true;
        } else {
          debugPrint('Error updating review: ${response.body}');
          return false;
        }
      } else {
        debugPrint(
          "Error updating review, status code: ${response.statusCode}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("Exception updating review: $e");
      return false;
    }
  }

  // Delete Review - Fixed Version
  static Future<bool> deleteReview(String reviewId) async {
    final Uri url = Uri.parse(
      deletereview(reviewId),
    ); // Ensure addreview is a String URL

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == true) {
          return true;
        } else {
          debugPrint('Error deleting review: ${response.body}');
          return false;
        }
      } else {
        debugPrint(
          "Error deleting review, status code: ${response.statusCode}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("Exception deleting review: $e");
      return false;
    }
  }
}
