const express = require("express");
const { getLocationsBySearch, getRoute, getPlaceNameFromCoords } = require("../../controllers/mapboxController");
const { protect } = require("../../middleware/auth");
const router = express.Router();

router.get("/search-location", getLocationsBySearch);
router.get("/route", getRoute);
router.get("/place-name", getPlaceNameFromCoords);

module.exports = router;
