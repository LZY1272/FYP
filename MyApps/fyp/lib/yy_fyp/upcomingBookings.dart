import 'package:flutter/material.dart';

class upcomingBookings extends StatelessWidget {
  final List<Map<String, dynamic>> bookings = [
    {
      "hotelName": "MOV Hotel",
      "date": "Sun, 05 Jan - Mon, 06 Jan",
      "guests": "2 guests, 1 room",
      "imageUrl": "https://cf.bstatic.com/xdata/images/hotel/max1280x900/620719916.jpg?k=ceed2b9aad8b462072dd6b20713bf4d5fc11ccc6d1dcd36f483df6ae861a592a&o=&hp=1", 
    },
    {
      "hotelName": "Grand Hyatt",
      "date": "Fri, 10 Feb - Sun, 12 Feb",
      "guests": "3 guests, 2 rooms",
      "imageUrl": "https://cf.bstatic.com/xdata/images/hotel/max1280x900/465549886.jpg?k=d0cd93422b4a56e56d4e52fb0c68f6f8d5ff754e94b6bd1317e737b31111c309&o=&hp=1",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Upcoming Bookings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      booking["imageUrl"],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking["hotelName"],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            booking["date"],
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            booking["guests"],
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
