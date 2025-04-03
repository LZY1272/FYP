// Add these imports at the top of your file
import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart'; // You'll need to add this package
import '../services/review_service.dart';
import 'package:flutter/material.dart';
import '../services/search.dart';
import '../services/photo.dart';
import 'review_screen.dart';

class AllReviewsScreen extends StatefulWidget {
  final String currentUserId;

  const AllReviewsScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  _AllReviewsScreenState createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  List<Map<String, dynamic>> _allReviews = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  double? _ratingFilter;
  Map<String, String> _userNames = {};

  // For places filter
  List<String> _places = [];
  String? _selectedPlace;

  // For pull-to-refresh
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();
    _fetchAllReviews();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllReviews() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all reviews
      List<Map<String, dynamic>> reviews = await ReviewService.getReviews();

      // Get unique place names for filter
      Set<String> uniquePlaces = {};

      // Set for tracking unique user IDs
      Set<String> userIds = {};

      // Process each review
      for (var review in reviews) {
        // Add to places set if it has a place name
        if (review.containsKey("placeName") && review["placeName"] != null) {
          uniquePlaces.add(review["placeName"]);
        }

        // Track user IDs to fetch names later
        if (review.containsKey("userId") && review["userId"] != null) {
          userIds.add(review["userId"]);
        }

        // Fetch photos for each review
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

      // Convert places set to list and sort alphabetically
      _places = uniquePlaces.toList()..sort();

      if (mounted) {
        setState(() {
          _allReviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load reviews: ${e.toString()}";
          _isLoading = false;
        });
      }
    }

    // Complete the refresh if it was triggered by pull-to-refresh
    _refreshController.refreshCompleted();
  }

  // Handle review deletion
  Future<void> _deleteReview(String reviewId) async {
    try {
      bool success = await ReviewService.deleteReview(reviewId);
      if (success) {
        setState(() {
          _allReviews.removeWhere((review) => review["_id"] == reviewId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Review deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete review"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting review: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigate to review detail with refresh on return
  void _navigateToReviewDetail(Map<String, dynamic> review) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ReviewScreen(review: review, userId: widget.currentUserId),
      ),
    );

    // Refresh if the review was updated or deleted
    if (result == true) {
      _fetchAllReviews();
    }
  }

  List<Map<String, dynamic>> get filteredReviews {
    return _allReviews.where((review) {
      // Apply search filter
      bool matchesSearch =
          _searchQuery.isEmpty ||
          (review["placeName"]?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          (review["reviewText"]?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      // Apply rating filter
      bool matchesRating =
          _ratingFilter == null || review["rating"] >= _ratingFilter;

      // Apply place filter
      bool matchesPlace =
          _selectedPlace == null || review["placeName"] == _selectedPlace;

      return matchesSearch && matchesRating && matchesPlace;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Community Reviews",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF0CB9CE),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAllReviews,
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
                    Text("Loading community reviews..."),
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
                      onPressed: _fetchAllReviews,
                      child: Text("Try Again"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0CB9CE),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Search and filter bar
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Search reviews...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Filters row
                        Row(
                          children: [
                            // Rating filter
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<double?>(
                                    hint: Text("Rating"),
                                    value: _ratingFilter,
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down),
                                    items:
                                        [null, 1.0, 2.0, 3.0, 4.0, 5.0]
                                            .map(
                                              (
                                                rating,
                                              ) => DropdownMenuItem<double?>(
                                                value: rating,
                                                child: Text(
                                                  rating == null
                                                      ? "Any Rating"
                                                      : "≥ ${rating.toInt()} ★",
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _ratingFilter = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),

                            // Place filter
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    hint: Text("Place"),
                                    value: _selectedPlace,
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down),
                                    items:
                                        [null, ..._places]
                                            .map(
                                              (place) =>
                                                  DropdownMenuItem<String?>(
                                                    value: place,
                                                    child: Text(
                                                      place ?? "All Places",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPlace = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        // Filter tags/chips
                        Wrap(
                          spacing: 8,
                          children: [
                            if (_ratingFilter != null)
                              _buildFilterChip(
                                "≥ ${_ratingFilter!.toInt()} ★",
                                () => setState(() => _ratingFilter = null),
                              ),
                            if (_selectedPlace != null)
                              _buildFilterChip(
                                _selectedPlace!,
                                () => setState(() => _selectedPlace = null),
                              ),
                            if (_searchQuery.isNotEmpty)
                              _buildFilterChip(
                                "\"$_searchQuery\"",
                                () => setState(() => _searchQuery = ""),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Results count
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${filteredReviews.length} ${filteredReviews.length == 1 ? 'review' : 'reviews'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _ratingFilter != null ||
                            _selectedPlace != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = "";
                                _ratingFilter = null;
                                _selectedPlace = null;
                              });
                            },
                            child: Text("Clear All"),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF0CB9CE),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Reviews list with pull-to-refresh
                  Expanded(
                    child: SmartRefresher(
                      controller: _refreshController,
                      onRefresh: _fetchAllReviews,
                      header: WaterDropHeader(
                        waterDropColor: Color(0xFF0CB9CE),
                      ),
                      child:
                          filteredReviews.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No reviews found",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Try adjusting your filters",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: EdgeInsets.only(bottom: 20),
                                itemCount: filteredReviews.length,
                                itemBuilder: (context, index) {
                                  final review = filteredReviews[index];
                                  final userName =
                                      review.containsKey("userId")
                                          ? _userNames[review["userId"]] ??
                                              "Unknown User"
                                          : "Anonymous";

                                  // Check if the current user is the author of this review
                                  final isAuthor =
                                      review["userId"] == widget.currentUserId;

                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        _navigateToReviewDetail(review);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Header with place name and menu (for author)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    review["placeName"] ??
                                                        "Unknown Place",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isAuthor)
                                                  PopupMenuButton<String>(
                                                    icon: Icon(
                                                      Icons.more_vert,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    itemBuilder:
                                                        (context) => [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.edit,
                                                                  size: 18,
                                                                ),
                                                                SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  'Edit Review',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.delete,
                                                                  size: 18,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  'Delete Review',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                    onSelected: (value) async {
                                                      if (value == 'edit') {
                                                        _navigateToReviewDetail(
                                                          review,
                                                        );
                                                      } else if (value ==
                                                          'delete') {
                                                        // Show confirmation dialog
                                                        showDialog(
                                                          context: context,
                                                          builder:
                                                              (
                                                                context,
                                                              ) => AlertDialog(
                                                                title: Text(
                                                                  'Delete Review',
                                                                ),
                                                                content: Text(
                                                                  'Are you sure you want to delete this review? This action cannot be undone.',
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          context,
                                                                        ),
                                                                    child: Text(
                                                                      'Cancel',
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.pop(
                                                                        context,
                                                                      );
                                                                      _deleteReview(
                                                                        review["_id"],
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      'Delete',
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colors.red,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                              ],
                                            ),
                                            SizedBox(height: 12),

                                            // Place photo and info
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Place photo
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    review["photoUrl"] ??
                                                        'https://dummyimage.com/100',
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          width: 80,
                                                          height: 80,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade200,
                                                          child: Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(width: 16),

                                                // Rating and user info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Rating
                                                      Row(
                                                        children: [
                                                          ...List.generate(
                                                            5,
                                                            (i) => Icon(
                                                              i <
                                                                      (review["rating"] ??
                                                                          0)
                                                                  ? Icons.star
                                                                  : Icons
                                                                      .star_border,
                                                              size: 18,
                                                              color: Color(
                                                                0xFFFFB74D,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            "${review["rating"]?.toStringAsFixed(1) ?? '0.0'}",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),

                                                      // User and date
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.person,
                                                            size: 14,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              isAuthor
                                                                  ? "You"
                                                                  : userName,
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade600,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    isAuthor
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .normal,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 4),
                                                      if (review.containsKey(
                                                            "createdAt",
                                                          ) &&
                                                          review["createdAt"] !=
                                                              null)
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              _formatDate(
                                                                review["createdAt"],
                                                              ),
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade600,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Review text
                                            if (review.containsKey(
                                                  "reviewText",
                                                ) &&
                                                review["reviewText"] != null &&
                                                review["reviewText"].isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 12.0,
                                                ),
                                                child: Text(
                                                  review["reviewText"],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),

                                            // Tags
                                            if (review.containsKey("tags") &&
                                                review["tags"] != null &&
                                                (review["tags"] as List)
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 12.0,
                                                ),
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children:
                                                      (review["tags"] as List)
                                                          .map(
                                                            (tag) => Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Color(
                                                                  0xFF0CB9CE,
                                                                ).withOpacity(
                                                                  0.1,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      16,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                tag,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                    0xFF0CB9CE,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                ),
                                              ),

                                            // "Read more" indicator
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  _navigateToReviewDetail(
                                                    review,
                                                  );
                                                },
                                                child: Text("Read more"),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Color(
                                                    0xFF0CB9CE,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size(0, 0),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(fontSize: 12),
      backgroundColor: Color(0xFF0CB9CE).withOpacity(0.1),
      deleteIcon: Icon(Icons.close, size: 16),
      deleteIconColor: Color(0xFF0CB9CE),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (date is String) {
      try {
        DateTime parsedDate = DateTime.parse(date);
        return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
      } catch (e) {
        return date;
      }
    }
    return "Unknown date";
  }
}
