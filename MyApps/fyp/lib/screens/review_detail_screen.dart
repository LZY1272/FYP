import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewDetailScreen extends StatefulWidget {
  final String reviewId;
  final String placeName;
  final double rating;
  final String reviewText;
  final VoidCallback onReviewUpdated;

  const ReviewDetailScreen({
    Key? key,
    required this.reviewId,
    required this.placeName,
    required this.rating,
    required this.reviewText,
    required this.onReviewUpdated,
  }) : super(key: key);

  @override
  _ReviewDetailScreenState createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late TextEditingController _reviewController;
  late double _rating;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController(text: widget.reviewText);
    _rating = widget.rating;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _updateReview() async {
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Review text cannot be empty')));
      return;
    }

    Map<String, dynamic> updatedReview = {
      "rating": _rating,
      "reviewText": _reviewController.text,
    };

    bool success = await ReviewService.updateReview(
      widget.reviewId,
      updatedReview,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Review updated successfully!')));
      widget.onReviewUpdated();
      Navigator.pop(context); // Go back after updating
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update review')));
    }
  }

  Future<void> _deleteReview() async {
    bool success = await ReviewService.deleteReview(widget.reviewId);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Review deleted successfully!')));
      widget.onReviewUpdated();
      Navigator.pop(context); // Go back after deleting
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete review')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Details"),
        backgroundColor: Color(0xFF0CB9CE),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.placeName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Rating:", style: TextStyle(fontSize: 16)),
            Slider(
              value: _rating,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              label: _rating.toString(),
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(labelText: "Your Review"),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _updateReview,
                  icon: Icon(Icons.save),
                  label: Text("Update"),
                ),
                ElevatedButton.icon(
                  onPressed: _deleteReview,
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text("Delete"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
