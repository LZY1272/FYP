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

    // Randomly select one attraction per day without duplicates
    topAttractions.shuffle();
    List<Map<String, dynamic>> selectedAttractions =
        topAttractions.take(numberOfDays).toList();

    List<List<Map<String, dynamic>>> itinerary = [];

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

      // ✅ Ensure fallback options in case no places are found
      if (nearbyRestaurants == null) nearbyRestaurants = [];
      if (nearbyFunPlaces == null) nearbyFunPlaces = [];

      if (nearbyRestaurants.isEmpty || nearbyFunPlaces.isEmpty) {
        print("⚠️ Not enough nearby places found. Skipping day.");
        continue;
      }

      // Sort by rating
      nearbyRestaurants.sort(
        (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0),
      );
      nearbyFunPlaces.sort(
        (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0),
      );

      List<Map<String, dynamic>> dayPlan = [];
      Set<String> addedPlaces = {};
      int foodIndex = 0;
      int funIndex = 0;

      for (int i = 0; i < TIMESLOTS_PER_DAY; i++) {
        if (i % 2 == 0) {
          // Even index = Eat (Food)
          while (foodIndex < nearbyRestaurants.length) {
            if (!addedPlaces.contains(nearbyRestaurants[foodIndex]['name'])) {
              dayPlan.add(nearbyRestaurants[foodIndex]);
              addedPlaces.add(nearbyRestaurants[foodIndex]['name']);
              foodIndex++;
              break;
            }
            foodIndex++;
          }
        } else {
          // Odd index = Fun (Tourist Attraction)
          while (funIndex < nearbyFunPlaces.length) {
            if (!addedPlaces.contains(nearbyFunPlaces[funIndex]['name'])) {
              dayPlan.add(nearbyFunPlaces[funIndex]);
              addedPlaces.add(nearbyFunPlaces[funIndex]['name']);
              funIndex++;
              break;
            }
            funIndex++;
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
