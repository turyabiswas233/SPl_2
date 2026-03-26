const mapboxClient = require("@mapbox/mapbox-sdk");
const geocoding = require("@mapbox/mapbox-sdk/services/geocoding");

// Use your Mapbox secret token or public token with appropriate permissions
const mapboxToken = process.env.MAPBOX_ACCESS_TOKEN;
const mbxClient = mapboxClient({ accessToken: mapboxToken });
const mbxGeocoding = geocoding(mbxClient);

const getLocationsBySearch = async (req, res) => {
  try {
    const searchQuery = req.query.q;
    const lm =5; // Optional limit parameter
    if (!searchQuery) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }

    const response = await mbxGeocoding
      .forwardGeocode({
        query: searchQuery,
        limit: lm,
      })
      .send();

    if (response.statusCode === 200) {
      res.json(response.body.features); // Send the location data back to the client
    } else {
      res.status(response.statusCode).json({ error: response.body.message });
    }
  } catch (error) {
    console.error("Error during geocoding:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports = {
  getLocationsBySearch,
};
