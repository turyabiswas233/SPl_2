const mapboxClient = require("@mapbox/mapbox-sdk");
const geocoding = require("@mapbox/mapbox-sdk/services/geocoding");
const directions = require("@mapbox/mapbox-sdk/services/directions");

// Use your Mapbox secret token or public token with appropriate permissions
const mapboxToken = process.env.MAPBOX_ACCESS_TOKEN;
const mbxClient = mapboxClient({ accessToken: mapboxToken });
const mbxGeocoding = geocoding(mbxClient);
const mbxDirections = directions(mbxClient);

const getLocationsBySearch = async (req, res) => {
  try {
    const searchQuery = req.query.q;
    const lm = 10; // Optional limit parameter
    if (!searchQuery) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }

    const response = await mbxGeocoding
      .forwardGeocode({
        query: searchQuery,
        limit: lm,
        types: ["place", "locality", "address", "district", "poi"],
        mode: "mapbox.places",
        countries: ["BD"],
        language: ["en"],
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

const getRoute = async (req, res) => {
  try {
    const { startLng, startLat, destLng, destLat, steps } = req.query;
    console.log(req.query);
    if (!startLng || !startLat || !destLng || !destLat) {
      return res.status(400).json({
        error:
          "Missing required parameters: startLng, startLat, destLng, destLat",
      });
    }

    const response = await mbxDirections
      .getDirections({
        profile: "driving",
        waypoints: [
          { coordinates: [parseFloat(startLng), parseFloat(startLat)] },
          { coordinates: [parseFloat(destLng), parseFloat(destLat)] },
        ],
        geometries: "geojson",
        language: "en",
        overview: "full",
        steps: String(steps).toString() == "true" ? true : false,
      })
      .send();

    if (response.statusCode === 200) {
      const routeCoordinates =
        response.body?.routes[0]?.geometry?.coordinates?.map((coord) => {
          return {
            longitude: coord[0],
            latitude: coord[1],
          };
        });
      console.log(
        "Route data:",
        response.body?.routes[0]?.distance,
        response.body?.routes[0]?.duration,
        routeCoordinates.length,
      );
      res.status(200).json({
        distance: response.body?.routes[0]?.distance,
        duration: response.body?.routes[0]?.duration,
        coordinates: routeCoordinates,
      });
    } else {
      res.status(response.statusCode).json({ error: response.body.message });
    }
  } catch (error) {
    console.error("Error during directions:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

const getPlaceNameFromCoords = async (req, res) => {
  try {
    const { lng, lat } = req.query;

    if (!lng || !lat) {
      return res.status(400).json({
        error:
          "Missing required parameters: lng (longitude) and lat (latitude)",
      });
    }

    // Validate that coordinates are numbers
    const longitude = parseFloat(lng);
    const latitude = parseFloat(lat);

    if (isNaN(longitude) || isNaN(latitude)) {
      return res.status(400).json({
        error: "Invalid coordinates: lng and lat must be valid numbers",
      });
    }

    // Reverse geocoding: get place name from coordinates
    const response = await mbxGeocoding
      .reverseGeocode({
        query: [longitude, latitude],
        countries: ["BD"],
      })
      .send();

    if (response.statusCode === 200) {
      const features = response.body.features;
      if (features && features.length > 0) {
        const placeData = {
          place_name: `${features[0].place_name}`,
          coordinates: features[0].geometry.coordinates,
          all_results: features,
        };
        res.json(placeData);
      } else {
        res.status(404).json({
          error: "No place found for the given coordinates",
        });
      }
    } else {
      res.status(response.statusCode).json({ error: response.body.message });
    }
  } catch (error) {
    console.error("Error during reverse geocoding:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports = {
  getLocationsBySearch,
  getRoute,
  getPlaceNameFromCoords,
};
