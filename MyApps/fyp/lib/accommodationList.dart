import 'package:flutter/material.dart';
import 'accommodationDetails.dart';

class accommodationList extends StatefulWidget {
  final String destination;
  final String selectedDateRange;
  final int selectedBeds;
  final int selectedGuests;
  final List<Map<String, dynamic>> hotels;

  accommodationList({
    required this.destination,
    required this.selectedDateRange,
    required this.selectedBeds,
    required this.selectedGuests,
    required this.hotels,
  });

  @override
  _AccommodationListState createState() => _AccommodationListState();
}

class _AccommodationListState extends State<accommodationList> {
  late List<Map<String, dynamic>> hotels;
  String _sortBy = "price_low"; // Default sort option

  @override
  void initState() {
    super.initState();
    hotels = List.from(widget.hotels); // Copy the list
    _sortHotels();
  }

  void _sortHotels() {
    setState(() {
      if (_sortBy == "price_low") {
        hotels.sort((a, b) => double.parse(a["price"]).compareTo(double.parse(b["price"])));
      } else if (_sortBy == "price_high") {
        hotels.sort((a, b) => double.parse(b["price"]).compareTo(double.parse(a["price"])));
      } else if (_sortBy == "stars_high") {
        hotels.sort((a, b) => b["stars"].compareTo(a["stars"]));
      } else if (_sortBy == "stars_low") {
        hotels.sort((a, b) => a["stars"].compareTo(b["stars"]));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hotels in ${widget.destination}")),
      body: Column(
        children: [
          // 🔹 Sort By Dropdown
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Sort by: ", style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                        _sortHotels();
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(value: "price_low", child: Text("Price (Low to High)")),
                    DropdownMenuItem(value: "price_high", child: Text("Price (High to Low)")),
                    DropdownMenuItem(value: "stars_high", child: Text("Stars (High to Low)")),
                    DropdownMenuItem(value: "stars_low", child: Text("Stars (Low to High)")),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Hotel List
          Expanded(
            child: hotels.isEmpty
                ? Center(child: Text("No hotels found"))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: hotels.length,
                    itemBuilder: (context, index) {
                      final hotel = hotels[index];

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              hotel["image"],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset("assets/no_image.png", width: 80, height: 80);
                              },
                            ),
                          ),
                          title: Text(hotel["name"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("RM ${hotel["price"]}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Row(
                                children: List.generate(hotel["stars"], (index) => Icon(Icons.star, color: Colors.amber, size: 16)),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => accommodationDetails(
                                    name: hotel["name"],
                                    image: hotel["image"],
                                    stars: hotel["stars"] is int ? hotel["stars"] : int.tryParse(hotel["stars"].toString()) ?? 0, 
                                    address: hotel["address"],
                                    contact: hotel["contact"],
                                    price: hotel["price"] is int ? hotel["price"] : int.tryParse(hotel["price"].toString()) ?? 0, 
                                    selectedDateRange: widget.selectedDateRange,
                                    selectedBeds: widget.selectedBeds is int ? widget.selectedBeds : int.tryParse(widget.selectedBeds.toString()) ?? 1,
                                    selectedGuests: widget.selectedGuests is int ? widget.selectedGuests : int.tryParse(widget.selectedGuests.toString()) ?? 1,
                                  ),
                                ),
                              );
                            },
                            child: Text("View"),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
