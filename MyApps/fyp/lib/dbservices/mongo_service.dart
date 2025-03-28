// import 'package:mongo_dart/mongo_dart.dart';

// class MongoService {
//   static const String MONGO_URL =
//       "mongodb+srv://LZY1272:Ling_1272@cluster0.pqdov.mongodb.net/";
//   static const String DB_NAME = "app"; // Change this if needed
//   static const String COLLECTION_NAME = "itineraries";

//   static Future<void> saveItinerary(Map<String, dynamic> itineraryData) async {
//     var db = await Db.create(MONGO_URL);
//     await db.open();

//     var collection = db.collection(COLLECTION_NAME);
//     await collection.insertOne(itineraryData);

//     await db.close();
//   }
// }
