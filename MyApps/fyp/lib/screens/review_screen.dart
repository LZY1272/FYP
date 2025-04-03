import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../services/search.dart';
import '../services/photo.dart';
import 'review_detail_screen.dart';
import 'all_review_screen.dart'; // New import for all reviews screen

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic>? review; // Make review optional
  final String userId;

  const ReviewScreen({
    Key? key,
    required this.userId,
    this.review, // Optional parameter
  }) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserReviews();
  }

  // Modified to fetch only the current user's reviews
  Future<void> _fetchUserReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all reviews
      List<Map<String, dynamic>> allReviews = await ReviewService.getReviews();

      // Filter for current user's reviews only
      List<Map<String, dynamic>> userReviews =
          allReviews
              .where((review) => review["userId"] == widget.userId)
              .toList();

      // Fetch photos for each review
      for (var review in userReviews) {
        if (review.containsKey("placeName")) {
          Map<String, dynamic>? placeDetails = await SearchAPI.getPlaceDetails(
            review["placeName"],
          );

          if (placeDetails != null && placeDetails.containsKey("business_id")) {
            String businessId = placeDetails["business_id"];
            String? photoUrl = await PhotoAPI.getPlacePhoto(businessId);
            review["photoUrl"] = photoUrl ?? 'https://dummyimage.com/100';
          } else {
            review["photoUrl"] = 'https://dummyimage.com/100';
          }
        }
      }

      setState(() {
        _reviews = userReviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load your reviews: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  void _showAddReviewDialog() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController placeController = TextEditingController();
        double rating = 3.0;
        TextEditingController reviewController = TextEditingController();
        List<String> suggestions = [];
        bool showSuggestions = false;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.rate_review, color: Color(0xFF0CB9CE)),
                  SizedBox(width: 10),
                  Text(
                    "Add Review",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: placeController,
                        decoration: InputDecoration(
                          labelText: "Place Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.place),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a place name';
                          }
                          return null;
                        },
                        onChanged: (value) async {
                          if (value.isNotEmpty) {
                            List<String> results =
                                await SearchAPI.getPlaceSuggestions(value);
                            setDialogState(() {
                              suggestions = results;
                              showSuggestions = results.isNotEmpty;
                            });
                          } else {
                            setDialogState(() {
                              showSuggestions = false;
                            });
                          }
                        },
                      ),
                      if (showSuggestions)
                        Container(
                          height: 150,
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView(
                            children:
                                suggestions
                                    .map(
                                      (suggestion) => ListTile(
                                        title: Text(suggestion),
                                        onTap: () {
                                          placeController.text = suggestion;
                                          setDialogState(() {
                                            showSuggestions = false;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      SizedBox(height: 16),
                      Text(
                        "Rating",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: rating,
                              min: 1.0,
                              max: 5.0,
                              divisions: 4,
                              label: rating.toString(),
                              activeColor: Color(0xFF0CB9CE),
                              onChanged:
                                  (value) =>
                                      setDialogState(() => rating = value),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF0CB9CE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: reviewController,
                        decoration: InputDecoration(
                          labelText: "Your Review",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.comment),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your review';
                          }
                          if (value.length < 10) {
                            return 'Review must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text("Cancel"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              setDialogState(() {
                                isSubmitting = true;
                              });

                              try {
                                // Get business_id from place name
                                Map<String, dynamic>? placeDetails =
                                    await SearchAPI.getPlaceDetails(
                                      placeController.text,
                                    );

                                if (placeDetails == null ||
                                    !placeDetails.containsKey('business_id')) {
                                  throw Exception(
                                    'Failed to retrieve place details',
                                  );
                                }

                                Map<String, dynamic> reviewData = {
                                  "userId": widget.userId,
                                  "placeId": placeDetails['business_id'],
                                  "placeName": placeController.text,
                                  "rating": rating,
                                  "reviewText": reviewController.text,
                                  "createdAt": DateTime.now().toIso8601String(),
                                };

                                bool success = await ReviewService.addReview(
                                  reviewData,
                                );

                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Review added successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  _fetchUserReviews(); // Refresh reviews
                                } else {
                                  throw Exception('Failed to add review');
                                }
                              } catch (e) {
                                setDialogState(() {
                                  isSubmitting = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                  child:
                      isSubmitting
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text("Submit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0CB9CE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Reviews",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF0CB9CE),
        actions: [
          IconButton(
            icon: Icon(Icons.public),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          AllReviewsScreen(currentUserId: widget.userId),
                ),
              );
            },
            tooltip: 'See all reviews',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchUserReviews,
            tooltip: 'Refresh reviews',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0CB9CE)),
                    SizedBox(height: 16),
                    Text("Loading your reviews..."),
                  ],
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(_errorMessage!),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchUserReviews,
                      child: Text("Try Again"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0CB9CE),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
              : _reviews.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 60,
                      color: Color(0xFF0CB9CE).withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "You haven't added any reviews yet",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("Tap the + button to add your first review"),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddReviewDialog,
                      icon: Icon(Icons.add),
                      label: Text("Add Review"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0CB9CE),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchUserReviews,
                color: Color(0xFF0CB9CE),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    return ReviewCard(
                      review: _reviews[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ReviewDetailScreen(
                                  reviewId: _reviews[index]['_id'] ?? '',
                                  placeName: _reviews[index]['placeName'],
                                  rating: _reviews[index]['rating'],
                                  reviewText: _reviews[index]['reviewText'],
                                  onReviewUpdated: _fetchUserReviews,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        backgroundColor: Color(0xFF0CB9CE),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Review', style: TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onTap;

  const ReviewCard({Key? key, required this.review, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place image with rating overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    review['photoUrl'] ?? 'https://dummyimage.com/400x200',
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text(
                          (review['rating'] as num).toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Review details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['placeName'] ?? 'Unknown Place',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < (review['rating'] as num).floor()
                            ? Icons.star
                            : starIndex < (review['rating'] as num)
                            ? Icons.star_half
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  SizedBox(height: 8),
                  Text(
                    review['reviewText'] ?? '',
                    style: TextStyle(color: Colors.black87),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (review.containsKey('createdAt'))
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatDate(review['createdAt']),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
