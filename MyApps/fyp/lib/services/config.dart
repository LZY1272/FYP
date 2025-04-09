final url = 'http://172.20.10.3:3000/';

// User Authentication
final registration = "${url}registration";
final login = "${url}login";

// To-Do Management
final addtodo = "${url}storeTodo";
final getTodoList = "${url}getUserTodoList";
final deleteTodo = "${url}deleteTodo";

// Itinerary Management
final saveItinerary = "${url}saveItinerary";
final deleteItinerary = "${url}deleteItinerary";
final updateItinerary = "${url}updateItinerary";

String getItinerary(String userId) {
  return "${url}getUserItineraries/$userId";
}

// Reviews
final addreview = "${url}addReview";
final getreview = "${url}getReview";

String updatereview(String reviewId) {
  return "${url}updateReview/$reviewId";
}

String deletereview(String reviewId) {
  return "${url}deleteReview/$reviewId";
}

// ✅ New APIs for User Preferences
final updatePreferences = "${url}updatePreferences";

String getUserPreferences(String userId) {
  return "${url}preferences/$userId";
}

String getRecommendation(String userId) {
  return "${url}getRecommendations/$userId";
}
