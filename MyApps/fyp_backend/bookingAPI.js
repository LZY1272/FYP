const axios = require("axios");
const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const API_KEY = "da6baaaa31msh2a7ee36c4be592fp177311jsnfe3b9cc43c04";  // Replace with your actual API key
const API_HOST = "booking-com.p.rapidapi.com";

// 🔹 1. Get location ID based on user input
async function getLocationId(destination) {
    try {
        console.log(`📩 Fetching location for: ${destination}`);

        const response = await axios.get(`https://${API_HOST}/v1/hotels/locations`, {
            headers: {
                "X-RapidAPI-Key": API_KEY,
                "X-RapidAPI-Host": API_HOST
            },
            params: { name: destination, locale: "en-gb" }
        });

        if (response.data.length === 0) {
            console.log("❌ No valid location found.");
            return null;
        }

        const location = response.data[0];
        console.log(`📍 Location Found: ${location.dest_id} (${location.name})`);
        return location.dest_id;
    } catch (error) {
        console.error("❌ Location API Error:", error.response ? error.response.data : error.message);
        return null;
    }
}

// 🔹 2. Fetch hotels from Booking.com
async function getHotels(dest_id, checkin, checkout, guests, rooms) {
    try {
        console.log(`📩 Fetching hotels for: Destination ID: ${dest_id}, Check-in: ${checkin}, Check-out: ${checkout}, Guests: ${guests}, Rooms: ${rooms}`);

        const response = await axios.get(`https://${API_HOST}/v1/hotels/search`, {
            headers: {
                "X-RapidAPI-Key": API_KEY,
                "X-RapidAPI-Host": API_HOST
            },
            params: {
                dest_id,
                dest_type: "city",
                checkin_date: checkin,
                checkout_date: checkout,
                room_number: rooms,
                adults_number: guests,
                children_number: 1, // Default to 0 if not specified
                currency: "MYR",
                locale: "en-gb",
                order_by: "popularity",
                units: "metric",
                include_adjacency: "true",
                filter_by_currency: "MYR",
                page_number: 0,
                categories_filter_ids: "class::2,class::3,class::4,class::5",
                min_review_score: 7.0,
                length_of_stay: Math.floor((new Date(checkout) - new Date(checkin)) / (1000 * 60 * 60 * 24))
            }
        });

        console.log(`✅ ${response.data.result.length} hotels found.`);
        return response.data.result;
    } catch (error) {
        console.error("❌ Hotels API Error:", error.response ? error.response.data : error.message);
        return { hotels: [] };
    }
}

// 🔹 3. API Route: Fetch hotels
app.get("/hotels", async (req, res) => {
    const { destination, checkin, checkout, guests, rooms } = req.query;

    if (!destination || !checkin || !checkout || !guests || !rooms) {
        return res.status(400).json({ message: "❌ Missing required parameters" });
    }

    const locationId = await getLocationId(destination);
    if (!locationId) {
        return res.status(404).json({ message: "❌ Destination not found." });
    }

    const hotels = await getHotels(locationId, checkin, checkout, guests, rooms);
    res.json({ hotels });
});

// Start the server
const PORT = 8000;
app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));
