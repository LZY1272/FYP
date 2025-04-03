import '../services/search.dart'; // Import the search API functions
import '../services/nearby.dart'; // Import the nearby search API functions

class ItineraryGenerator {
  static const int TIMESLOTS_PER_DAY = 6;
  static const List<String> timeslotLabels = [
    'Eat',
    'Fun',
    'Eat',
    'Fun',
    'Eat',
    'Fun',
  ];

  static Future<List<List<Map<String, dynamic>>>> generateItinerary(
    String userId,
    String destination,
    int numberOfDays,
  ) async {
    print("📍 Fetching top tourist attractions for: $destination...");

    List<Map<String, dynamic>>? topAttractions =
        await SearchAPI.searchTopTouristAttractions(destination);

    if (topAttractions == null || topAttractions.isEmpty) {
      print("⚠️ No tourist attractions found.");
      return [];
    }

    print("✅ Top Attractions found!");

    // Shuffle and take unique attractions for each day
    topAttractions.shuffle();
    List<Map<String, dynamic>> selectedAttractions =
        topAttractions.take(numberOfDays).toList();

    List<List<Map<String, dynamic>>> itinerary = [];
    Set<String> globalAddedPlaces = {}; // Track all added places globally

    for (var attraction in selectedAttractions) {
      double lat = attraction["latitude"];
      double lng = attraction["longitude"];

      print(
        "\n🔍 Fetching nearby food and fun places for: ${attraction['name']}...",
      );

      List<Map<String, dynamic>>? nearbyRestaurants =
          await NearbyAPI.searchNearby(lat, lng, "restaurant");
      List<Map<String, dynamic>>? nearbyFunPlaces =
          await NearbyAPI.searchNearby(lat, lng, "tourist_attraction");

      if (nearbyRestaurants == null) nearbyRestaurants = [];
      if (nearbyFunPlaces == null) nearbyFunPlaces = [];

      if (nearbyRestaurants.isEmpty || nearbyFunPlaces.isEmpty) {
        print("⚠️ Not enough nearby places found. Skipping day.");
        continue;
      }

      // Sort places by rating
      nearbyRestaurants.sort(
        (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0),
      );
      nearbyFunPlaces.sort(
        (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0),
      );

      List<Map<String, dynamic>> dayPlan = [];
      Set<String> dailyAddedPlaces = {}; // Track places for each day
      int foodIndex = 0, funIndex = 0;

      for (int i = 0; i < TIMESLOTS_PER_DAY; i++) {
        if (i % 2 == 0) {
          // Eat
          while (foodIndex < nearbyRestaurants.length) {
            String placeName = nearbyRestaurants[foodIndex]['name'];
            if (!globalAddedPlaces.contains(placeName)) {
              dayPlan.add(nearbyRestaurants[foodIndex]);
              globalAddedPlaces.add(placeName);
              dailyAddedPlaces.add(placeName);
              foodIndex++;
              break;
            }
            foodIndex++;
          }
        } else {
          // Fun
          while (funIndex < nearbyFunPlaces.length) {
            String placeName = nearbyFunPlaces[funIndex]['name'];
            if (!globalAddedPlaces.contains(placeName)) {
              dayPlan.add(nearbyFunPlaces[funIndex]);
              globalAddedPlaces.add(placeName);
              dailyAddedPlaces.add(placeName);
              funIndex++;
              break;
            }
            funIndex++;
          }
        }
      }

      // Backup strategy: If not enough places, allow slightly lower-rated ones
      if (dayPlan.length < TIMESLOTS_PER_DAY) {
        for (var place in nearbyRestaurants) {
          if (!dailyAddedPlaces.contains(place['name'])) {
            dayPlan.add(place);
            if (dayPlan.length == TIMESLOTS_PER_DAY) break;
          }
        }
        for (var place in nearbyFunPlaces) {
          if (!dailyAddedPlaces.contains(place['name'])) {
            dayPlan.add(place);
            if (dayPlan.length == TIMESLOTS_PER_DAY) break;
          }
        }
      }

      itinerary.add(dayPlan);
    }

    print("\n📆 Final Itinerary:");
    for (int day = 0; day < itinerary.length; day++) {
      print("🗓 Day ${day + 1}:");
      for (int i = 0; i < itinerary[day].length; i++) {
        print(
          "📌 Timeslot ${i + 1}: ${itinerary[day][i]['name']} - Rating: ${itinerary[day][i]['rating']}",
        );
      }
    }

    return itinerary;
  }
}
